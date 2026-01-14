import ExFigCore
import Foundation

public class XcodeImagesExporterBase: XcodeExporterBase {
    enum Error: LocalizedError {
        case templateDoesNotSupportAppending

        var errorDescription: String? {
            "Custom templates not supported with append=true"
        }

        var recoverySuggestion: String? {
            "Use default templates or set append=false in config"
        }
    }

    let output: XcodeImagesOutput

    public init(output: XcodeImagesOutput) {
        self.output = output
    }

    func generateExtensions(names: [String], append: Bool) throws -> [FileContents] {
        if output.templatesPath != nil, append == true {
            throw Error.templateDoesNotSupportAppending
        }

        var files = [FileContents]()

        // SwiftUI extension for Image
        if let url = output.swiftUIImageExtensionURL {
            try files.append(makeSwiftUIExtension(for: names, append: append, extensionFileURL: url))
        }

        // UIKit extension for UIImage
        if let url = output.uiKitImageExtensionURL {
            try files.append(makeUIKitExtension(for: names, append: append, extensionFileURL: url))
        }

        return files
    }

    private func makeSwiftUIExtension(
        for names: [String],
        append: Bool,
        extensionFileURL url: URL
    ) throws -> FileContents {
        let contents: String
        if append {
            let partialContents = try makeExtensionContents(
                names: names,
                templateName: "Image+extension.swift.stencil.include"
            )
            contents = try appendContent(string: partialContents, to: url)
        } else {
            contents = try makeExtensionContents(names: names, templateName: "Image+extension.swift.stencil")
        }
        return try makeFileContents(for: contents, url: url)
    }

    private func makeUIKitExtension(
        for names: [String],
        append: Bool,
        extensionFileURL url: URL
    ) throws -> FileContents {
        let contents: String

        if append {
            let partialContents = try makeExtensionContents(
                names: names,
                templateName: "UIImage+extension.swift.stencil.include"
            )
            contents = try appendContent(string: partialContents, to: url)
        } else {
            contents = try makeExtensionContents(names: names, templateName: "UIImage+extension.swift.stencil")
        }

        return try makeFileContents(for: contents, url: url)
    }

    private func makeExtensionContents(names: [String], templateName: String) throws -> String {
        let context: [String: Any] = [
            "addObjcPrefix": output.addObjcAttribute,
            "assetsInSwiftPackage": output.assetsInSwiftPackage,
            "resourceBundleNames": output.resourceBundleNames ?? [],
            "assetsInMainBundle": output.assetsInMainBundle,
            "images": names.map { ["name": $0] },
        ]
        let env = makeEnvironment(templatesPath: output.templatesPath)
        return try env.renderTemplate(name: templateName, context: context)
    }

    private func appendContent(string: String, to fileURL: URL) throws -> String {
        var existingContents = try String(
            contentsOf: URL(fileURLWithPath: fileURL.path),
            encoding: .utf8
        )
        let string = string + "\n}\n"

        if let index = existingContents.dropLast(2).lastIndex(of: "}") {
            let newIndex = existingContents.index(after: index)
            existingContents.replaceSubrange(
                newIndex ..< existingContents.endIndex,
                with: string
            )
        }
        return existingContents
    }

    // MARK: - Code Connect Generation

    /// Generates Figma Code Connect file for the given image packs.
    ///
    /// - Parameters:
    ///   - imagePacks: Image packs with nodeId and fileId for Code Connect URLs.
    ///   - url: Output URL for the generated .figma.swift file.
    ///   - allAssetMetadata: Optional full asset metadata for granular cache mode.
    ///     When provided, generates Code Connect for ALL assets (not just changed ones).
    /// - Returns: File contents to write, or nil if no valid assets with nodeId.
    func generateCodeConnect(
        imagePacks: [AssetPair<ImagePack>],
        url: URL,
        allAssetMetadata: [AssetMetadata]? = nil
    ) throws -> FileContents? {
        // If full metadata is provided (granular cache mode), use it to generate ALL structs
        let assets: [[String: String]]
        if let allMetadata = allAssetMetadata, !allMetadata.isEmpty {
            assets = allMetadata.map { meta in
                // Convert nodeId format: "12016:2218" -> "12016-2218" for URL
                let urlNodeId = meta.nodeId.replacingOccurrences(of: ":", with: "-")

                // Create struct name: sanitize for Swift identifier (replace non-alphanumeric with _)
                let sanitizedName = meta.name.map { $0.isLetter || $0.isNumber ? $0 : Character("_") }
                let structName = "Asset_\(String(sanitizedName))"

                // Build Figma URL
                let figmaUrl = "https://www.figma.com/design/\(meta.fileId)?node-id=\(urlNodeId)"

                return [
                    "name": meta.name,
                    "structName": structName,
                    "nodeId": urlNodeId,
                    "fileId": meta.fileId,
                    "figmaUrl": figmaUrl,
                ]
            }
        } else {
            // Filter to assets with valid nodeId and fileId
            let validAssets = imagePacks.filter { pack in
                pack.light.nodeId != nil && pack.light.fileId != nil
            }
            guard !validAssets.isEmpty else { return nil }

            assets = validAssets.map { pack -> [String: String] in
                let name = pack.light.name
                let nodeId = pack.light.nodeId ?? ""
                let fileId = pack.light.fileId ?? ""

                // Convert nodeId format: "12016:2218" -> "12016-2218" for URL
                let urlNodeId = nodeId.replacingOccurrences(of: ":", with: "-")

                // Create struct name: sanitize for Swift identifier (replace non-alphanumeric with _)
                let sanitizedName = name.map { $0.isLetter || $0.isNumber ? $0 : Character("_") }
                let structName = "Asset_\(String(sanitizedName))"

                // Build Figma URL
                let figmaUrl = "https://www.figma.com/design/\(fileId)?node-id=\(urlNodeId)"

                return [
                    "name": name,
                    "structName": structName,
                    "nodeId": urlNodeId,
                    "fileId": fileId,
                    "figmaUrl": figmaUrl,
                ]
            }
        }

        guard !assets.isEmpty else { return nil }

        // Sort by asset name for stable output across regenerations
        let sortedAssets = assets.sorted { ($0["name"] ?? "") < ($1["name"] ?? "") }

        let context: [String: Any] = ["assets": sortedAssets]
        let env = makeEnvironment(templatesPath: output.templatesPath)
        let contents = try env.renderTemplate(name: "CodeConnect.figma.swift.stencil", context: context)

        return try makeFileContents(for: contents, url: url)
    }
}
