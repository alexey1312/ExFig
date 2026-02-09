import ExFig_Flutter
import ExFigCore
import FlutterExport
import Foundation

// MARK: - Flutter Colors Export

extension ExFigCommand.ExportColors {
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
