import ExFigCore
import Foundation

/// Structured JSON report for a single export command.
///
/// Analogous to `BatchReport` (used by `exfig batch --report`) but tailored
/// for single-command exports (`colors`, `icons`, `images`, `typography`).
struct ExportReport: Encodable {
    /// Report schema version for forward compatibility.
    let version: Int

    /// Command name (e.g., "colors", "icons", "images", "typography").
    let command: String

    /// Path to the PKL config file used.
    let config: String

    /// Export start time (ISO8601).
    let startTime: String

    /// Export end time (ISO8601).
    let endTime: String

    /// Duration in seconds.
    let duration: TimeInterval

    /// Whether the export succeeded.
    let success: Bool

    /// Error description if export failed, `nil` on success.
    let error: String?

    /// Asset counts.
    let stats: ReportStats

    /// Warnings collected during export.
    let warnings: [String]

    /// Asset manifest (present when file tracking is enabled).
    let manifest: AssetManifest?

    /// Current report schema version.
    static let currentVersion = 1

    init(
        version: Int = ExportReport.currentVersion,
        command: String,
        config: String,
        startTime: String,
        endTime: String,
        duration: TimeInterval,
        success: Bool,
        error: String?,
        stats: ReportStats,
        warnings: [String],
        manifest: AssetManifest?
    ) {
        self.version = version
        self.command = command
        self.config = config
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.success = success
        self.error = error
        self.stats = stats
        self.warnings = warnings
        self.manifest = manifest
    }

    /// Serializes the report to pretty-printed JSON with sorted keys.
    func jsonData() throws -> Data {
        try JSONCodec.encodePrettySorted(self)
    }
}

/// Asset counts for a single export command report.
///
/// Separate from `ExportStats` (which contains batch-only fields like
/// `computedNodeHashes` and `granularCacheStats` that are not `Codable`).
struct ReportStats: Encodable {
    let colors: Int
    let icons: Int
    let images: Int
    let typography: Int

    static let zero = ReportStats(colors: 0, icons: 0, images: 0, typography: 0)

    static func colors(_ count: Int) -> ReportStats {
        .init(colors: count, icons: 0, images: 0, typography: 0)
    }

    static func icons(_ count: Int) -> ReportStats {
        .init(colors: 0, icons: count, images: 0, typography: 0)
    }

    static func images(_ count: Int) -> ReportStats {
        .init(colors: 0, icons: 0, images: count, typography: 0)
    }

    static func typography(_ count: Int) -> ReportStats {
        .init(colors: 0, icons: 0, images: 0, typography: count)
    }
}
