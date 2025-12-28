/// Protocol for reporting export progress to UI (CLI or GUI).
///
/// Implementations should be `Sendable` to support concurrent exports.
/// The protocol is designed to support both:
/// - CLI: spinner + progress bar via TerminalUI
/// - GUI: SwiftUI progress views with cancellation
public protocol ProgressReporter: Sendable {
    // MARK: - Phases

    /// Begin a new export phase (e.g., "Loading colors", "Fetching icons")
    func beginPhase(_ name: String) async

    /// End the current phase
    func endPhase() async

    // MARK: - Progress

    /// Report batch progress (e.g., 3 of 10 batches completed)
    func reportBatchProgress(completed: Int, total: Int) async

    /// Report item progress (e.g., 45 of 100 images downloaded)
    func reportItemProgress(completed: Int, total: Int) async

    // MARK: - Messages

    /// Log an info message
    func info(_ message: String) async

    /// Log a warning message
    func warning(_ message: String) async

    /// Log an error message
    func error(_ message: String) async

    /// Log a success message
    func success(_ message: String) async

    // MARK: - Debug

    /// Log a debug message (only shown in verbose mode)
    func debug(_ message: String) async
}

// MARK: - Default Implementations

public extension ProgressReporter {
    /// Default no-op implementation for debug
    func debug(_: String) async {}
}

// MARK: - BatchProgressCallback Bridge

/// Callback type for batch progress reporting.
/// Used to bridge between old callback-based API and new ProgressReporter.
public typealias BatchProgressCallback = @Sendable (Int, Int) -> Void

public extension ProgressReporter {
    /// Create a BatchProgressCallback that forwards to this reporter.
    func batchProgressCallback() -> BatchProgressCallback {
        { [self] completed, total in
            Task {
                await self.reportBatchProgress(completed: completed, total: total)
            }
        }
    }
}

// MARK: - Silent Reporter

/// A no-op progress reporter for use in tests or when progress is not needed.
public struct SilentProgressReporter: ProgressReporter {
    public init() {}

    public func beginPhase(_: String) async {}
    public func endPhase() async {}
    public func reportBatchProgress(completed _: Int, total _: Int) async {}
    public func reportItemProgress(completed _: Int, total _: Int) async {}
    public func info(_: String) async {}
    public func warning(_: String) async {}
    public func error(_: String) async {}
    public func success(_: String) async {}
    public func debug(_: String) async {}
}
