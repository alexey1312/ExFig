import ExFigCore
import Foundation

public final class XcodeIconsExporter: XcodeImagesExporterBase {
    /// Exports icons to Xcode project.
    ///
    /// - Parameters:
    ///   - icons: Icon asset pairs to export (may be filtered subset for granular cache).
    ///   - allIconNames: Optional complete list of all icon names for Swift extension generation.
    ///                   When provided, extensions include all icons even if only a subset is exported.
    ///   - allAssetMetadata: Optional full asset metadata for Code Connect generation.
    ///                       When provided, Code Connect includes all icons even if only a subset is exported.
    ///   - append: Whether to append to existing extension files.
    /// - Returns: File contents to write.
    public func export(
        icons: [AssetPair<ImagePack>],
        allIconNames: [String]? = nil,
        allAssetMetadata: [AssetMetadata]? = nil,
        append: Bool
    ) throws -> [FileContents] {
        // Generate metadata (Assets.xcassets/Icons/Contents.json)
        let contentsFile = XcodeEmptyContents().makeFileContents(to: output.assetsFolderURL)

        // Generate assets
        let assetsFolderURL = output.assetsFolderURL
        let preservesVectorRepresentation = output.preservesVectorRepresentation
        let filter = AssetsFilter(filters: preservesVectorRepresentation ?? [])

        let imageAssetsFiles = try icons.flatMap { imagePack -> [FileContents] in
            let preservesVector = filter.match(name: imagePack.light.name)
            return try imagePack.makeFileContents(
                to: assetsFolderURL,
                preservesVector: preservesVector,
                renderMode: imagePack.light.renderMode
            )
        }

        // Generate extensions - use allIconNames if provided, otherwise derive from icons
        let imageNames = allIconNames ?? icons.map { normalizeName($0.light.name) }
        let extensionFiles = try generateExtensions(names: imageNames, append: append)

        var result = [contentsFile] + imageAssetsFiles + extensionFiles

        // Generate Code Connect file if URL is configured
        if let codeConnectURL = output.codeConnectSwiftURL {
            if let codeConnectFile = try generateCodeConnect(
                imagePacks: icons,
                url: codeConnectURL,
                allAssetMetadata: allAssetMetadata
            ) {
                result.append(codeConnectFile)
            }
        }

        return result
    }
}
