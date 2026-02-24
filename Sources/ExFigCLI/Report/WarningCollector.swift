import Foundation

/// Collects warnings emitted during export for inclusion in the report.
///
/// Uses `Lock<[String]>` for thread-safe access without requiring `await`,
/// eliminating the `DispatchSemaphore` bridge that was needed with the actor version.
/// Active only when `--report` is specified — otherwise `nil` and zero overhead.
///
/// ## Usage
///
/// ```swift
/// let collector = WarningCollector()
/// WarningCollectorStorage.current = collector
/// // ... run export (TerminalUI.warning() forwards to collector) ...
/// let warnings = collector.getAll()
/// WarningCollectorStorage.current = nil
/// ```
final class WarningCollector: Sendable {
    private let storage = Lock<[String]>([])

    /// Add a warning message.
    func add(_ message: String) {
        storage.withLock { $0.append(message) }
    }

    /// Get all collected warnings.
    func getAll() -> [String] {
        storage.withLock { $0 }
    }

    /// Number of collected warnings.
    var count: Int {
        storage.withLock { $0.count }
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
