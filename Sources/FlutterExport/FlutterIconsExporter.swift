import ExFigCore
import Foundation
import Stencil

public final class FlutterIconsExporter: FlutterExporter {
    private let output: FlutterOutput
    private let outputFileName: String

    public init(output: FlutterOutput, outputFileName: String?) {
        self.output = output
        self.outputFileName = outputFileName ?? "icons.dart"
        super.init(templatesPath: output.templatesPath)
    }

    /// Exports icons as SVG assets + Dart constants file.
    ///
    /// - Parameters:
    ///   - icons: Icon asset pairs to export (may be filtered subset for granular cache).
    ///   - allIconNames: Optional complete list of all icon names for Dart file generation.
    ///                   When provided, Dart file includes all icons even if only a subset is exported.
    ///                   Note: When using allIconNames, dark mode variants are not included.
    ///   - assetsPath: Optional relative path for generated Dart code (e.g., "assets/icons").
    ///                 When provided, overrides the path extracted from iconsAssetsDirectory URL.
    /// - Returns: FileContents for both the Dart file and the SVG asset files.
    public func export(
        icons: [AssetPair<ImagePack>],
        allIconNames: [String]? = nil,
        assetsPath: String? = nil
    ) throws -> (dartFile: FileContents, assetFiles: [FileContents]) {
        let dartFile = try makeIconsDartFileContents(icons: icons, allIconNames: allIconNames, assetsPath: assetsPath)
        let assetFiles = makeIconsAssetFiles(icons: icons)
        return (dartFile, assetFiles)
    }

    private func makeIconsDartFileContents(
        icons: [AssetPair<ImagePack>],
        allIconNames: [String]? = nil,
        assetsPath: String? = nil
    ) throws -> FileContents {
        let contents = try makeIconsDartContents(icons, allIconNames: allIconNames, assetsPath: assetsPath)

        guard let fileURL = URL(string: outputFileName) else {
            fatalError("Invalid file URL: \(outputFileName)")
        }

        return try makeFileContents(for: contents, directory: output.outputDirectory, file: fileURL)
    }

    private func makeIconsDartContents(
        _ icons: [AssetPair<ImagePack>],
        allIconNames: [String]? = nil,
        assetsPath: String? = nil
    ) throws -> String {
        let className = output.iconsClassName ?? "AppIcons"

        guard let assetsDirectory = output.iconsAssetsDirectory else {
            fatalError("iconsAssetsDirectory is required for icon export")
        }

        let relativePath = assetsPath ?? assetsDirectory.path

        // Use allIconNames if provided (for granular cache), otherwise derive from icons
        let iconsList: [[String: Any]] = if let allNames = allIconNames {
            // When using allIconNames, dark mode is not tracked (simplified for granular cache)
            allNames.map { name in
                let camelName = name.lowerCamelCased()
                let snakeName = name.snakeCased()
                return [
                    "name": camelName,
                    "lightPath": "\(relativePath)/\(snakeName).svg",
                    "hasDark": false,
                ] as [String: Any]
            }
        } else {
            icons.map { iconPair in
                let name = iconPair.light.name.lowerCamelCased()
                let snakeName = iconPair.light.name.snakeCased()
                let hasDark = iconPair.dark != nil

                var result: [String: Any] = [
                    "name": name,
                    "lightPath": "\(relativePath)/\(snakeName).svg",
                    "hasDark": hasDark,
                ]

                if hasDark {
                    result["darkPath"] = "\(relativePath)/\(snakeName)_dark.svg"
                }

                return result
            }
        }

        let context: [String: Any] = [
            "className": className,
            "icons": iconsList,
        ]

        let env = makeEnvironment()
        return try env.renderTemplate(name: "icons.dart.stencil", context: context)
    }

    private func makeIconsAssetFiles(icons: [AssetPair<ImagePack>]) -> [FileContents] {
        guard let assetsDirectory = output.iconsAssetsDirectory else {
            return []
        }

        var files: [FileContents] = []

        for iconPair in icons {
            // Light icon
            if let image = iconPair.light.images.first {
                let snakeName = iconPair.light.name.snakeCased()
                let fileName = "\(snakeName).svg"
                if let fileURL = URL(string: fileName) {
                    let file = FileContents(
                        destination: Destination(directory: assetsDirectory, file: fileURL),
                        sourceURL: image.url
                    )
                    files.append(file)
                }
            }

            // Dark icon
            if let dark = iconPair.dark, let image = dark.images.first {
                let snakeName = dark.name.snakeCased()
                let fileName = "\(snakeName)_dark.svg"
                if let fileURL = URL(string: fileName) {
                    let file = FileContents(
                        destination: Destination(directory: assetsDirectory, file: fileURL),
                        sourceURL: image.url,
                        dark: true
                    )
                    files.append(file)
                }
            }
        }

        return files
    }
}
