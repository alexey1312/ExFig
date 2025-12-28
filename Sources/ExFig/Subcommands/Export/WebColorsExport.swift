import ExFigCore
import ExFigKit
import FigmaAPI
import Foundation
import WebExport

// MARK: - Web Colors Export

extension ExFigCommand.ExportColors {
    /// Exports Web colors using multiple entries format.
    func exportWebColorsMultiple(
        entries: [Params.Web.ColorsEntry],
        web: Params.Web,
        client: Client,
        ui: TerminalUI
    ) async throws -> Int {
        var totalCount = 0

        for entry in entries {
            let colors = try await ui.withSpinner(
                "Fetching colors from Figma (\(entry.tokensCollectionName))..."
            ) {
                let loader = ColorsVariablesLoader(
                    client: client,
                    figmaParams: options.params.figma,
                    variableParams: Params.Common.VariablesColors(
                        tokensFileId: entry.tokensFileId,
                        tokensCollectionName: entry.tokensCollectionName,
                        lightModeName: entry.lightModeName,
                        darkModeName: entry.darkModeName,
                        lightHCModeName: entry.lightHCModeName,
                        darkHCModeName: entry.darkHCModeName,
                        primitivesModeName: entry.primitivesModeName,
                        nameValidateRegexp: entry.nameValidateRegexp,
                        nameReplaceRegexp: entry.nameReplaceRegexp
                    ),
                    filter: filter
                )
                return try await loader.load()
            }

            let colorPairs = try await ui.withSpinner("Processing colors for Web...") {
                let processor = ColorsProcessor(
                    platform: .web,
                    nameValidateRegexp: entry.nameValidateRegexp,
                    nameReplaceRegexp: entry.nameReplaceRegexp,
                    nameStyle: .kebabCase
                )
                let result = processor.process(light: colors.light, dark: colors.dark)
                if let warning = result.warning {
                    ui.warning(warning)
                }
                return try result.get()
            }

            try await ui.withSpinner("Exporting colors to Web project...") {
                try exportWebColorsEntry(colorPairs: colorPairs, entry: entry, web: web)
            }

            totalCount += colorPairs.count
        }

        if BatchProgressViewStorage.progressView == nil {
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        ui.success("Done! Exported \(totalCount) colors to Web project.")
        return totalCount
    }

    /// Exports Web colors using legacy format (common.variablesColors or common.colors).
    func exportWebColorsLegacy(
        colorsConfig: Params.Web.ColorsConfiguration,
        web: Params.Web,
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
        entry: Params.Web.ColorsEntry,
        web: Params.Web
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
