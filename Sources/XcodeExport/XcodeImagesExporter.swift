import ExFigCore
import Foundation

public final class XcodeImagesExporter: XcodeImagesExporterBase {
    /// Exports images to Xcode project.
    ///
    /// - Parameters:
    ///   - assets: Image asset pairs to export (may be filtered subset for granular cache).
    ///   - allAssetNames: Optional complete list of all asset names for Swift extension generation.
    ///                    When provided, extensions include all images even if only a subset is exported.
    ///   - append: Whether to append to existing extension files.
    /// - Returns: File contents to write.
    public func export(
        assets: [AssetPair<ImagePack>],
        allAssetNames: [String]? = nil,
        append: Bool
    ) throws -> [FileContents] {
        // Generate assets
        let assetsFolderURL = output.assetsFolderURL

        // Generate metadata (Assets.xcassets/Illustrations/Contents.json)
        let contentsFile = XcodeEmptyContents().makeFileContents(to: assetsFolderURL)

        let imageAssetsFiles = try assets.flatMap { pair -> [FileContents] in
            try pair.makeFileContents(to: assetsFolderURL, preservesVector: nil, renderMode: nil)
        }

        // Generate extensions - use allAssetNames if provided, otherwise derive from assets
        let imageNames = allAssetNames ?? assets.map { normalizeName($0.light.name) }
        let extensionFiles = try generateExtensions(names: imageNames, append: append)

        return [contentsFile] + imageAssetsFiles + extensionFiles
    }

    /// Exports only Swift extensions without asset catalog files.
    ///
    /// Use this when you're generating asset catalogs manually (e.g., SVG source with local rasterization)
    /// but still need the Swift UIImage/Image extensions.
    ///
    /// - Parameters:
    ///   - assets: Image asset pairs (used for name extraction if allAssetNames not provided).
    ///   - allAssetNames: Optional complete list of all asset names.
    ///   - append: Whether to append to existing extension files.
    /// - Returns: Swift extension file contents.
    public func exportSwiftExtensions(
        assets: [AssetPair<ImagePack>],
        allAssetNames: [String]? = nil,
        append: Bool
    ) throws -> [FileContents] {
        let imageNames = allAssetNames ?? assets.map { normalizeName($0.light.name) }
        return try generateExtensions(names: imageNames, append: append)
    }

    /// Exports images for HEIC conversion (PNG source → HEIC output).
    ///
    /// Generates asset catalog structure with PNG file references (for downloading)
    /// but Contents.json uses .heic extension (for final output after conversion).
    ///
    /// - Parameters:
    ///   - assets: Image asset pairs to export.
    ///   - allAssetNames: Optional complete list of all asset names for Swift extension generation.
    ///   - append: Whether to append to existing extension files.
    /// - Returns: File contents to write (PNGs to download, Contents.json with .heic references, extensions).
    public func exportForHeic(
        assets: [AssetPair<ImagePack>],
        allAssetNames: [String]? = nil,
        append: Bool
    ) throws -> [FileContents] {
        let assetsFolderURL = output.assetsFolderURL

        // Generate folder metadata
        let contentsFile = XcodeEmptyContents().makeFileContents(to: assetsFolderURL)

        // Generate image assets with HEIC Contents.json
        let imageAssetsFiles = try assets.flatMap { pair -> [FileContents] in
            try pair.makeFileContentsForHeic(to: assetsFolderURL)
        }

        // Generate extensions
        let imageNames = allAssetNames ?? assets.map { normalizeName($0.light.name) }
        let extensionFiles = try generateExtensions(names: imageNames, append: append)

        return [contentsFile] + imageAssetsFiles + extensionFiles
    }
}
