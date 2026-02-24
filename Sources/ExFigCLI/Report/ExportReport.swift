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
}
