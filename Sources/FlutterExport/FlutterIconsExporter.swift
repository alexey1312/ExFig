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

    /// Exports icons as SVG assets + Dart constants file
    /// Returns FileContents for both the Dart file and the SVG asset files
    public func export(icons: [AssetPair<ImagePack>]) throws -> (dartFile: FileContents, assetFiles: [FileContents]) {
        let dartFile = try makeIconsDartFileContents(icons: icons)
        let assetFiles = makeIconsAssetFiles(icons: icons)
        return (dartFile, assetFiles)
    }

    private func makeIconsDartFileContents(icons: [AssetPair<ImagePack>]) throws -> FileContents {
        let contents = try makeIconsDartContents(icons)

        guard let fileURL = URL(string: outputFileName) else {
            fatalError("Invalid file URL: \(outputFileName)")
        }

        return try makeFileContents(for: contents, directory: output.outputDirectory, file: fileURL)
    }

    private func makeIconsDartContents(_ icons: [AssetPair<ImagePack>]) throws -> String {
        let className = output.iconsClassName ?? "AppIcons"

        guard let assetsDirectory = output.iconsAssetsDirectory else {
            fatalError("iconsAssetsDirectory is required for icon export")
        }

        let relativePath = assetsDirectory.path

        let iconsList: [[String: Any]] = icons.map { iconPair in
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
