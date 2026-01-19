import ExFigCore
import Foundation
import Stencil

public final class WebIconsExporter: WebExporter {
    private let output: WebOutput
    private let generateReactComponents: Bool
    private let iconSize: Int

    public init(output: WebOutput, generateReactComponents: Bool, iconSize: Int = 24) {
        self.output = output
        self.generateReactComponents = generateReactComponents
        self.iconSize = iconSize
        super.init(templatesPath: output.templatesPath)
    }

    public struct ExportResult {
        public let componentFiles: [FileContents]
        public let assetFiles: [FileContents]
        public let typesFile: FileContents?
        public let barrelFile: FileContents?
    }

    /// Exports icons as SVG assets + React TSX components.
    ///
    /// - Parameters:
    ///   - icons: Icon asset pairs to export (may be filtered subset for granular cache).
    ///   - allIconNames: Optional complete list of all icon names for barrel file generation.
    ///                   When provided, barrel file includes all icons even if only a subset is exported.
    /// - Returns: ExportResult containing component files, asset files, types file, and barrel file.
    public func export(
        icons: [AssetPair<ImagePack>],
        allIconNames: [String]? = nil
    ) throws -> ExportResult {
        var componentFiles: [FileContents] = []
        var assetFiles: [FileContents] = []

        // Generate asset files (SVGs)
        assetFiles = makeIconsAssetFiles(icons: icons)

        // Generate React components if requested
        if generateReactComponents {
            componentFiles = try makeReactComponents(icons: icons)
        }

        // Generate types file if generating components
        let typesFile = generateReactComponents ? try makeTypesFile() : nil

        // Generate barrel file
        let barrelFile = try makeBarrelFile(icons: icons, allIconNames: allIconNames)

        return ExportResult(
            componentFiles: componentFiles,
            assetFiles: assetFiles,
            typesFile: typesFile,
            barrelFile: barrelFile
        )
    }

    // MARK: - Asset Files

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

    // MARK: - React Components

    /// Result of React component generation with diagnostic info.
    public struct ComponentGenerationResult {
        /// Successfully generated component files.
        public let files: [FileContents]
        /// Icon names that were skipped because SVG data was not found.
        public let missingDataIcons: [String]
        /// Icon names that failed JSX conversion with their error messages.
        public let conversionFailedIcons: [(name: String, error: String)]
    }

    /// Generates React TSX components from downloaded SVG data.
    ///
    /// - Parameters:
    ///   - icons: Icon asset pairs to export.
    ///   - svgDataMap: Dictionary mapping icon names (snake_case) to downloaded SVG data.
    /// - Returns: ComponentGenerationResult with files and diagnostic info.
    public func generateReactComponentsFromSVGData(
        icons: [AssetPair<ImagePack>],
        svgDataMap: [String: Data]
    ) throws -> ComponentGenerationResult {
        guard generateReactComponents else {
            return ComponentGenerationResult(files: [], missingDataIcons: [], conversionFailedIcons: [])
        }

        var files: [FileContents] = []
        var missingDataIcons: [String] = []
        var conversionFailedIcons: [(name: String, error: String)] = []

        for iconPair in icons {
            let componentName = iconPair.light.name.camelCased()
            let snakeName = iconPair.light.name.snakeCased()
            let fileName = componentName

            // Get SVG data for this icon
            guard let svgData = svgDataMap[snakeName] else {
                missingDataIcons.append(snakeName)
                continue
            }

            // Convert SVG to JSX
            let conversion: SVGToJSXConverter.ConversionResult
            do {
                conversion = try SVGToJSXConverter.convert(svgData: svgData)
            } catch {
                conversionFailedIcons.append((name: snakeName, error: error.localizedDescription))
                continue
            }

            let context: [String: Any] = [
                "componentName": componentName,
                "viewBox": conversion.viewBox,
                "svgContent": conversion.jsxContent,
            ]

            let env = makeEnvironment()
            let content = try env.renderTemplate(name: "Icon.tsx.stencil", context: context)

            guard let fileURL = URL(string: "\(fileName).tsx") else {
                continue
            }

            let file = try makeFileContents(
                for: content,
                directory: output.outputDirectory,
                file: fileURL
            )
            files.append(file)
        }

        return ComponentGenerationResult(
            files: files,
            missingDataIcons: missingDataIcons,
            conversionFailedIcons: conversionFailedIcons
        )
    }

    private func makeReactComponents(icons: [AssetPair<ImagePack>]) throws -> [FileContents] {
        // Note: This method generates placeholder components.
        // For production use, call generateReactComponentsFromSVGData after downloading SVGs.
        var files: [FileContents] = []

        for iconPair in icons {
            let componentName = iconPair.light.name.camelCased()
            let fileName = componentName

            let context: [String: Any] = [
                "componentName": componentName,
                "viewBox": "0 0 \(iconSize) \(iconSize)",
                "svgContent": "{/* SVG content placeholder */}",
            ]

            let env = makeEnvironment()
            let content = try env.renderTemplate(name: "Icon.tsx.stencil", context: context)

            guard let fileURL = URL(string: "\(fileName).tsx") else {
                continue
            }

            let file = try makeFileContents(
                for: content,
                directory: output.outputDirectory,
                file: fileURL
            )
            files.append(file)
        }

        return files
    }

    // MARK: - Types File

    private func makeTypesFile() throws -> FileContents {
        let env = makeEnvironment()
        let content = try env.renderTemplate(name: "types.ts.stencil", context: [:])

        guard let fileURL = URL(string: "types.ts") else {
            throw WebExportError.invalidFileName(name: "types.ts")
        }

        return try makeFileContents(
            for: content,
            directory: output.outputDirectory,
            file: fileURL
        )
    }

    // MARK: - Barrel File

    private func makeBarrelFile(
        icons: [AssetPair<ImagePack>],
        allIconNames: [String]? = nil
    ) throws -> FileContents {
        // Use allIconNames if provided, otherwise derive from icons
        let iconsList: [[String: String]] = if let allNames = allIconNames {
            allNames.sorted().map { name in
                let componentName = name.camelCased()
                return [
                    "componentName": componentName,
                    "fileName": componentName,
                ]
            }
        } else {
            icons.sorted { $0.light.name < $1.light.name }.map { iconPair in
                let componentName = iconPair.light.name.camelCased()
                return [
                    "componentName": componentName,
                    "fileName": componentName,
                ]
            }
        }

        let context: [String: Any] = [
            "icons": iconsList,
        ]

        let env = makeEnvironment()
        let content = try env.renderTemplate(name: "IconIndex.ts.stencil", context: context)

        guard let fileURL = URL(string: "index.ts") else {
            throw WebExportError.invalidFileName(name: "index.ts")
        }

        return try makeFileContents(
            for: content,
            directory: output.outputDirectory,
            file: fileURL
        )
    }
}
