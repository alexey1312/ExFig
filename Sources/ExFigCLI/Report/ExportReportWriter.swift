import Foundation

/// Writes an export report to disk. Failure is non-fatal — logs a warning.
///
/// Same pattern as `Batch.swift` report writing (lines 710-716):
/// wrap write in do/catch, warn on failure, never propagate the error.
func writeExportReport(_ report: ExportReport, to path: String, ui: TerminalUI) {
    let data: Data
    do {
        data = try report.jsonData()
    } catch {
        ui.warning("Failed to serialize export report: \(error.localizedDescription)")
        return
    }

    do {
        let url = URL(fileURLWithPath: path)
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: url)
        ui.info("Report written to: \(path)")
    } catch {
        ui.warning("Failed to write report to \(path): \(error.localizedDescription)")
    }
}
