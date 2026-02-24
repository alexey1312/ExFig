import Foundation

/// Collects warnings emitted during export for inclusion in the report.
///
/// Follows the `SharedThemeAttributesCollector` actor pattern.
/// Active only when `--report` is specified — otherwise `nil` and zero overhead.
///
/// ## Usage
///
/// ```swift
/// let collector = WarningCollector()
/// WarningCollectorStorage.current = collector
/// // ... run export (TerminalUI.warning() forwards to collector) ...
/// let warnings = await collector.getAll()
/// WarningCollectorStorage.current = nil
/// ```
actor WarningCollector {
    private var warnings: [String] = []

    /// Add a warning message.
    func add(_ message: String) {
        warnings.append(message)
    }

    /// Get all collected warnings.
    func getAll() -> [String] {
        warnings
    }

    /// Number of collected warnings.
    var count: Int {
        warnings.count
    }
}

/// Global storage for the active warning collector.
///
/// Uses a simple `nonisolated(unsafe)` static var (same pattern as
/// `ExFigCommand.terminalUI`). Set before export, cleared after.
/// Not using `@TaskLocal` to avoid nesting issues — this is only active
/// in single-command mode where there is no TaskLocal contention.
enum WarningCollectorStorage {
    nonisolated(unsafe) static var current: WarningCollector?
}
