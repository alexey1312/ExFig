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

    /// Generates a Code Connect Kotlin file from image packs.
    ///
    /// - Parameters:
    ///   - imagePacks: Image packs with nodeId and fileId for Code Connect URLs.
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
            assets = allMetadata.map { meta in
                makeAssetContext(name: meta.name, nodeId: meta.nodeId, fileId: meta.fileId)
            }
        } else {
            let validAssets = imagePacks.filter { pack in
                pack.light.nodeId != nil && pack.light.fileId != nil
            }
            guard !validAssets.isEmpty else { return nil }

            assets = validAssets.map { pack in
                makeAssetContext(
                    name: pack.light.name,
                    nodeId: pack.light.nodeId ?? "",
                    fileId: pack.light.fileId ?? ""
                )
            }
        }

        guard !assets.isEmpty else { return nil }

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

    private func makeAssetContext(name: String, nodeId: String, fileId: String) -> [String: String] {
        let urlNodeId = nodeId.replacingOccurrences(of: ":", with: "-")
        let sanitizedName = name.map { $0.isLetter || $0.isNumber ? $0 : Character("_") }
        let className = "Asset_\(String(sanitizedName))"
        let figmaUrl = "https://www.figma.com/design/\(fileId)?node-id=\(urlNodeId)"

        return [
            "name": name,
            "className": className,
            "nodeId": urlNodeId,
            "fileId": fileId,
            "figmaUrl": figmaUrl,
        ]
    }
}
