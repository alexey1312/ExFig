import ExFigCore
import Foundation
import Stencil

public final class FlutterIconsExporter: FlutterExporter {
    private let output: FlutterOutput
    private let outputFileName: String
    private let nameStyle: NameStyle

    public init(output: FlutterOutput, outputFileName: String?, nameStyle: NameStyle = .snakeCase) {
        self.output = output
        self.outputFileName = outputFileName ?? "icons.dart"
        self.nameStyle = nameStyle
        super.init(templatesPath: output.templatesPath)
    }

    /// Transforms a name according to the configured naming style.
    private func transformName(_ name: String) -> String {
        switch nameStyle {
        case .camelCase:
            name.lowerCamelCased()
        case .snakeCase:
            name.snakeCased()
        case .pascalCase:
            name.camelCased()
        case .kebabCase:
            name.kebabCased()
        case .flatCase:
            name.flatCased()
        case .screamingSnakeCase:
            name.screamingSnakeCased()
        }
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
            allNames.sorted().map { name in
                let camelName = name.lowerCamelCased()
                let styledName = transformName(name)
                return [
                    "name": camelName,
                    "lightPath": "\(relativePath)/\(styledName).svg",
                    "hasDark": false,
                ] as [String: Any]
            }
        } else {
            icons.sorted { $0.light.name < $1.light.name }.map { iconPair in
                let name = iconPair.light.name.lowerCamelCased()
                let styledName = transformName(iconPair.light.name)
                let hasDark = iconPair.dark != nil

                var result: [String: Any] = [
                    "name": name,
                    "lightPath": "\(relativePath)/\(styledName).svg",
                    "hasDark": hasDark,
                ]

                if hasDark {
                    result["darkPath"] = "\(relativePath)/\(styledName)\(nameStyle.darkSuffix).svg"
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
                let styledName = transformName(iconPair.light.name)
                let fileName = "\(styledName).svg"
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
                let styledName = transformName(dark.name)
                let fileName = "\(styledName)\(nameStyle.darkSuffix).svg"
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
