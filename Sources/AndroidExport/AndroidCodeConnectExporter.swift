import ExFigCore
import Foundation
import Stencil

/// Generates Figma Code Connect Kotlin files for Jetpack Compose.
///
/// Code Connect files link Figma design components to Compose code,
/// enabling designers to see the corresponding Compose implementation
/// in Figma Dev Mode.
public final class AndroidCodeConnectExporter: AndroidExporter {
    override public init(templatesPath: URL? = nil) {
        super.init(templatesPath: templatesPath)
    }

    /// Generates a Code Connect Kotlin file from asset packs (icons or images).
    ///
    /// - Parameters:
    ///   - imagePacks: Asset packs with nodeId and fileId for Code Connect URLs.
    ///   - url: Output URL for the generated `.figma.kt` file.
    ///   - packageName: Kotlin package name for the generated file.
    ///   - xmlResourcePackage: Package for the `R` class import.
    ///   - allAssetMetadata: Optional full asset metadata for granular cache mode.
    ///     When provided, generates Code Connect for ALL assets (not just changed ones).
    /// - Returns: File contents to write, or nil if no valid assets with nodeId.
    public func generateCodeConnect(
        imagePacks: [AssetPair<ImagePack>],
        url: URL,
        packageName: String,
        xmlResourcePackage: String,
        allAssetMetadata: [AssetMetadata]? = nil
    ) throws -> FileContents? {
        let assets: [[String: String]]

        if let allMetadata = allAssetMetadata, !allMetadata.isEmpty {
            let validMetadata = allMetadata.filter { !$0.nodeId.isEmpty && !$0.fileId.isEmpty }
            guard !validMetadata.isEmpty else { return nil }
            assets = validMetadata.map { meta in
                makeAssetContext(name: meta.name, nodeId: meta.nodeId, fileId: meta.fileId)
            }
        } else {
            assets = imagePacks.compactMap { pack -> [String: String]? in
                guard let nodeId = pack.light.nodeId, let fileId = pack.light.fileId else { return nil }
                return makeAssetContext(name: pack.light.name, nodeId: nodeId, fileId: fileId)
            }
            guard !assets.isEmpty else { return nil }
        }

        let sortedAssets = assets.sorted { ($0["name"] ?? "") < ($1["name"] ?? "") }

        let context: [String: Any] = [
            "package": packageName,
            "xmlResourcePackage": xmlResourcePackage,
            "assets": sortedAssets,
        ]

        let env = makeEnvironment()
        let contents = try env.renderTemplate(name: "CodeConnect.figma.kt.stencil", context: context)

        let directory = url.deletingLastPathComponent()
        let file = URL(fileURLWithPath: url.lastPathComponent)
        return try makeFileContents(for: contents, directory: directory, file: file)
    }

    // MARK: - Private

    /// Builds a template context dictionary for a single asset.
    ///
    /// - `resourceName`: sanitized for `R.drawable.*` (non-alphanumeric → `_`, no leading digit).
    /// - `className`: unique Composable function name (`Asset_<sanitized>`).
    private func makeAssetContext(name: String, nodeId: String, fileId: String) -> [String: String] {
        let urlNodeId = nodeId.replacingOccurrences(of: ":", with: "-")
        let sanitizedName = name.map { $0.isLetter || $0.isNumber ? $0 : Character("_") }
        let className = "Asset_\(String(sanitizedName))"

        // Sanitize for R.drawable: only [a-z0-9_], no leading digit
        var resourceName = name.map { $0.isLetter || $0.isNumber || $0 == Character("_") ? $0 : Character("_") }
        if let first = resourceName.first, first.isNumber {
            resourceName.insert(Character("_"), at: resourceName.startIndex)
        }

        let figmaUrl = "https://www.figma.com/design/\(fileId)?node-id=\(urlNodeId)"

        return [
            "name": name,
            "resourceName": String(resourceName),
            "className": className,
            "nodeId": urlNodeId,
            "fileId": fileId,
            "figmaUrl": figmaUrl,
        ]
    }
}
