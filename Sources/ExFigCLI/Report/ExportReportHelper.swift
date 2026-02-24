import Foundation

// swiftlint:disable function_parameter_count

/// Wraps export execution with report generation boilerplate.
///
/// Sets up `WarningCollectorStorage` and `ManifestTrackerStorage` before export,
/// captures timing and errors, builds the report, and guarantees cleanup via `defer`.
///
/// - Parameters:
///   - command: Export command name (e.g., "colors", "icons").
///   - assetType: Asset type for manifest tracking (e.g., "color", "icon").
///   - reportPath: Path to write JSON report. If `nil`, report generation is skipped entirely.
///   - configInput: PKL config path (for the report's `config` field).
///   - ui: Terminal UI for output.
///   - buildStats: Closure that converts the export count into `ReportStats`.
///   - export: The actual export operation. Returns the exported asset count.
/// - Throws: Re-throws the export error after writing the report.
func withExportReport(
    command: String,
    assetType: String,
    reportPath: String?,
    configInput: String?,
    ui: TerminalUI,
    buildStats: (Int) -> ReportStats,
    export: () async throws -> Int
) async throws {
    guard let reportPath else {
        _ = try await export()
        return
    }

    let warningCollector = WarningCollector()
    let manifestTracker = ManifestTracker(assetType: assetType)
    WarningCollectorStorage.current = warningCollector
    ManifestTrackerStorage.current = manifestTracker
    defer {
        WarningCollectorStorage.current = nil
        ManifestTrackerStorage.current = nil
    }

    let startTime = Date()
    var exportCount = 0
    var exportError: (any Error)?

    do {
        exportCount = try await export()
    } catch {
        exportError = error
    }

    let endTime = Date()
    let formatter = ISO8601DateFormatter()

    let exportReport = ExportReport(
        version: ExportReport.currentVersion,
        command: command,
        config: configInput ?? "exfig.pkl",
        startTime: formatter.string(from: startTime),
        endTime: formatter.string(from: endTime),
        duration: endTime.timeIntervalSince(startTime),
        success: exportError == nil,
        error: exportError.map { describeExportError($0) },
        stats: buildStats(exportCount),
        warnings: warningCollector.getAll(),
        manifest: manifestTracker.buildManifest(previousReportPath: reportPath)
    )
    writeExportReport(exportReport, to: reportPath, ui: ui)

    if let error = exportError {
        throw error
    }
}

// swiftlint:enable function_parameter_count

private func describeExportError(_ error: any Error) -> String {
    if let localized = error as? LocalizedError,
       let description = localized.errorDescription
    {
        return description
    }
    return String(describing: error)
}
