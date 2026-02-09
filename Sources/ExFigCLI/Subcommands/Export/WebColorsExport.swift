import ExFig_Web
import ExFigCore
import Foundation
import WebExport

// MARK: - Web Colors Export

extension ExFigCommand.ExportColors {
    // MARK: - Web Entry Export

    func exportWebColorsEntry(
        colorPairs: [AssetPair<Color>],
        entry: WebColorsEntry,
        web: PKLConfig.Web
    ) throws {
        let outputDir = if let dir = entry.outputDirectory {
            web.outputURL.appendingPathComponent(dir)
        } else {
            web.outputURL
        }

        let output = WebOutput(
            outputDirectory: outputDir,
            templatesPath: web.templatesPathURL
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
