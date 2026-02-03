import ExFigCore
import Foundation
import WebExport

/// Exports colors from Figma Variables to CSS variables and TypeScript constants.
///
/// This exporter handles the full export cycle:
/// 1. Loading colors from Figma Variables API
/// 2. Processing colors with kebab-case naming for CSS
/// 3. Generating CSS, TypeScript, and JSON files
public struct WebColorsExporter: ColorsExporter {
    public typealias Entry = WebColorsEntry
    public typealias PlatformConfig = WebPlatformConfig

    public init() {}

    /// Exports colors from Figma to Web project.
    ///
    /// - Parameters:
    ///   - entries: Array of colors configuration entries.
    ///   - platformConfig: Web platform configuration.
    ///   - context: Export context with dependencies.
    /// - Returns: Total number of colors exported.
    public func exportColors(
        entries: [WebColorsEntry],
        platformConfig: WebPlatformConfig,
        context: some ColorsExportContext
    ) async throws -> Int {
        var totalCount = 0

        for entry in entries {
            totalCount += try await exportSingleEntry(
                entry: entry,
                platformConfig: platformConfig,
                context: context
            )
        }

        if !context.isBatchMode {
            context.success("Done! Exported \(totalCount) colors to Web project.")
        }

        return totalCount
    }

    // MARK: - Private

    private func exportSingleEntry(
        entry: WebColorsEntry,
        platformConfig: WebPlatformConfig,
        context: some ColorsExportContext
    ) async throws -> Int {
        // 1. Load colors from Figma
        let colors = try await context.withSpinner(
            "Fetching colors from Figma (\(entry.tokensCollectionName))..."
        ) {
            try await context.loadColors(from: entry.colorsSourceInput)
        }

        // 2. Process colors (Web uses kebab-case for CSS variables)
        let processResult = try await context.withSpinner("Processing colors for Web...") {
            try context.processColors(
                colors,
                platform: .web,
                nameValidateRegexp: entry.nameValidateRegexp,
                nameReplaceRegexp: entry.nameReplaceRegexp,
                nameStyle: .kebabCase
            )
        }

        if let warning = processResult.warning {
            context.warning(warning)
        }

        let colorPairs = processResult.colorPairs

        // 3. Export to Web
        try await context.withSpinner("Exporting colors to Web project...") {
            try exportToWeb(
                colorPairs: colorPairs,
                entry: entry,
                platformConfig: platformConfig,
                context: context
            )
        }

        return colorPairs.count
    }

    private func exportToWeb(
        colorPairs: [AssetPair<Color>],
        entry: WebColorsEntry,
        platformConfig: WebPlatformConfig,
        context: some ColorsExportContext
    ) throws {
        // Determine output directory
        let outputDirectory: URL = if let entryOutput = entry.outputDirectory {
            platformConfig.output.appendingPathComponent(entryOutput)
        } else {
            platformConfig.output
        }

        // Create output configuration
        let output = WebOutput(
            outputDirectory: outputDirectory,
            templatesPath: platformConfig.templatesPath
        )

        // Export
        let exporter = WebColorExporter(
            output: output,
            cssFileName: entry.cssFileName,
            tsFileName: entry.tsFileName,
            jsonFileName: entry.jsonFileName
        )
        let files = try exporter.export(colorPairs: colorPairs)

        // Write files
        try context.writeFiles(files)
    }
}
