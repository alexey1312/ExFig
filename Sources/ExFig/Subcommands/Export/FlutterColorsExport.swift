import ExFigCore
import FigmaAPI
import FlutterExport
import Foundation

// MARK: - Flutter Colors Export

extension ExFigCommand.ExportColors {
    /// Exports Flutter colors using multiple entries format.
    func exportFlutterColorsMultiple(
        entries: [Params.Flutter.ColorsEntry],
        flutter: Params.Flutter,
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

            let colorPairs = try await ui.withSpinner("Processing colors for Flutter...") {
                let processor = ColorsProcessor(
                    platform: .flutter,
                    nameValidateRegexp: entry.nameValidateRegexp,
                    nameReplaceRegexp: entry.nameReplaceRegexp,
                    nameStyle: .camelCase
                )
                let result = processor.process(light: colors.light, dark: colors.dark)
                if let warning = result.warning {
                    ui.warning(warning)
                }
                return try result.get()
            }

            try await ui.withSpinner("Exporting colors to Flutter project...") {
                try exportFlutterColorsEntry(colorPairs: colorPairs, entry: entry, flutter: flutter)
            }

            totalCount += colorPairs.count
        }

        if BatchProgressViewStorage.progressView == nil {
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        ui.success("Done! Exported \(totalCount) colors to Flutter project.")
        return totalCount
    }

    /// Exports Flutter colors using legacy format (common.variablesColors or common.colors).
    func exportFlutterColorsLegacy(
        colorsConfig: Params.Flutter.ColorsConfiguration,
        flutter: Params.Flutter,
        config: LegacyExportConfig
    ) async throws -> Int {
        try validateLegacyConfig(config.commonParams)

        let colors = try await loadLegacyColors(config: config)

        let (finalNameValidateRegexp, finalNameReplaceRegexp) = extractNameRegexps(
            from: config.commonParams
        )

        let entry = colorsConfig.entries[0]

        let colorPairs = try await config.ui.withSpinner("Processing colors for Flutter...") {
            let processor = ColorsProcessor(
                platform: .flutter,
                nameValidateRegexp: finalNameValidateRegexp,
                nameReplaceRegexp: finalNameReplaceRegexp,
                nameStyle: .camelCase
            )
            let result = processor.process(light: colors.light, dark: colors.dark)
            if let warning = result.warning {
                config.ui.warning(warning)
            }
            return try result.get()
        }

        try await config.ui.withSpinner("Exporting colors to Flutter project...") {
            try exportFlutterColorsEntry(colorPairs: colorPairs, entry: entry, flutter: flutter)
        }

        if BatchProgressViewStorage.progressView == nil {
            await checkForUpdate(logger: ExFigCommand.logger)
        }

        config.ui.success("Done! Exported \(colorPairs.count) colors to Flutter project.")
        return colorPairs.count
    }

    // MARK: - Flutter Entry Export

    func exportFlutterColorsEntry(
        colorPairs: [AssetPair<Color>],
        entry: Params.Flutter.ColorsEntry,
        flutter: Params.Flutter
    ) throws {
        let output = FlutterOutput(
            outputDirectory: flutter.output,
            templatesPath: flutter.templatesPath,
            colorsClassName: entry.className
        )
        let exporter = FlutterColorExporter(
            output: output,
            outputFileName: entry.output
        )
        let files = try exporter.export(colorPairs: colorPairs)

        let fileName = entry.output ?? "colors.dart"
        let colorsFileURL = flutter.output.appendingPathComponent(fileName)

        try? FileManager.default.removeItem(atPath: colorsFileURL.path)

        try ExFigCommand.fileWriter.write(files: files)
    }
}
