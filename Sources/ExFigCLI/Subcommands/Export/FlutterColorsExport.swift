import ExFig_Flutter
import ExFigConfig
import ExFigCore
import FigmaAPI
import FlutterExport
import Foundation

// MARK: - Flutter Colors Export

extension ExFigCommand.ExportColors {
    /// Exports Flutter colors using legacy format (common.variablesColors or common.colors).
    func exportFlutterColorsLegacy(
        entries: [FlutterColorsEntry],
        flutter: Flutter.FlutterConfig,
        config: LegacyExportConfig
    ) async throws -> Int {
        try validateLegacyConfig(config.commonParams)

        let colors = try await loadLegacyColors(config: config)

        let (finalNameValidateRegexp, finalNameReplaceRegexp) = extractNameRegexps(
            from: config.commonParams
        )

        let entry = entries[0]

        let colorPairs = try await config.ui.withSpinner("Processing colors for Flutter...") {
            let processor = ColorsProcessor(
                platform: .flutter,
                nameValidateRegexp: finalNameValidateRegexp,
                nameReplaceRegexp: finalNameReplaceRegexp,
                nameStyle: .camelCase
            )
            let result = processor.process(
                light: colors.light,
                dark: colors.dark,
                lightHC: colors.lightHC,
                darkHC: colors.darkHC
            )
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
        entry: FlutterColorsEntry,
        flutter: Flutter.FlutterConfig
    ) throws {
        let outputURL = URL(fileURLWithPath: flutter.output)
        let output = FlutterOutput(
            outputDirectory: outputURL,
            templatesPath: flutter.templatesPath.map { URL(fileURLWithPath: $0) },
            colorsClassName: entry.className
        )
        let exporter = FlutterColorExporter(
            output: output,
            outputFileName: entry.output
        )
        let files = try exporter.export(colorPairs: colorPairs)

        let fileName = entry.output ?? "colors.dart"
        let colorsFileURL = outputURL.appendingPathComponent(fileName)

        try? FileManager.default.removeItem(atPath: colorsFileURL.path)

        try ExFigCommand.fileWriter.write(files: files)
    }
}
