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
}
