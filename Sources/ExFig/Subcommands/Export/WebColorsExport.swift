import ExFig_Web
import ExFigCore
import FigmaAPI
import Foundation
import WebExport

// MARK: - Web Colors Export

extension ExFigCommand.ExportColors {
    /// Exports Web colors using legacy format (common.variablesColors or common.colors).
    func exportWebColorsLegacy(
        colorsConfig: PKLConfig.Web.ColorsConfiguration,
        web: PKLConfig.Web,
        config: LegacyExportConfig
    ) async throws -> Int {
        try validateLegacyConfig(config.commonParams)

        let colors = try await loadLegacyColors(config: config)

        let (finalNameValidateRegexp, finalNameReplaceRegexp) = extractNameRegexps(
            from: config.commonParams
        )

        let entry = colorsConfig.entries[0]

        let colorPairs = try await config.ui.withSpinner("Processing colors for Web...") {
            let processor = ColorsProcessor(
                platform: .web,
                nameValidateRegexp: finalNameValidateRegexp,
                nameReplaceRegexp: finalNameReplaceRegexp,
                nameStyle: .kebabCase
            )
            let result = processor.process(light: colors.light, dark: colors.dark)
            if let warning = result.warning {
                config.ui.warning(warning)
            }
            return try result.get()
        }

        try await config.ui.withSpinner("Exporting colors to Web project...") {
            try exportWebColorsEntry(colorPairs: colorPairs, entry: entry, web: web)
        }

        if BatchProgressViewStorage.progressView == nil {
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        config.ui.success("Done! Exported \(colorPairs.count) colors to Web project.")
        return colorPairs.count
    }

    // MARK: - Web Entry Export

    func exportWebColorsEntry(
        colorPairs: [AssetPair<Color>],
        entry: WebColorsEntry,
        web: PKLConfig.Web
    ) throws {
        let outputDir = if let dir = entry.outputDirectory {
            web.output.appendingPathComponent(dir)
        } else {
            web.output
        }

        let output = WebOutput(
            outputDirectory: outputDir,
            templatesPath: web.templatesPath
        )
        let exporter = WebColorExporter(
            output: output,
            cssFileName: entry.cssFileName,
            tsFileName: entry.tsFileName,
            jsonFileName: entry.jsonFileName
        )
        let files = try exporter.export(colorPairs: colorPairs)

        // Remove existing files
        let cssFileName = entry.cssFileName ?? "theme.css"
        let tsFileName = entry.tsFileName ?? "variables.ts"

        let cssFileURL = outputDir.appendingPathComponent(cssFileName)
        let tsFileURL = outputDir.appendingPathComponent(tsFileName)

        try? FileManager.default.removeItem(atPath: cssFileURL.path)
        try? FileManager.default.removeItem(atPath: tsFileURL.path)

        if let jsonFileName = entry.jsonFileName {
            let jsonFileURL = outputDir.appendingPathComponent(jsonFileName)
            try? FileManager.default.removeItem(atPath: jsonFileURL.path)
        }

        try ExFigCommand.fileWriter.write(files: files)
    }
}
