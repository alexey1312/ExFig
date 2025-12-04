import Foundation
import Rainbow

/// Main facade for terminal UI operations
final class TerminalUI: Sendable {
    let outputMode: OutputMode

    private let useColors: Bool
    private let useAnimations: Bool

    init(outputMode: OutputMode) {
        self.outputMode = outputMode
        useColors = outputMode.useColors && TTYDetector.colorsEnabled
        useAnimations = outputMode.useAnimations && TTYDetector.isTTY
    }

    // MARK: - Convenience Initializer

    /// Create TerminalUI from CLI flags
    static func create(verbose: Bool, quiet: Bool) -> TerminalUI {
        let mode = TTYDetector.effectiveMode(verbose: verbose, quiet: quiet)
        return TerminalUI(outputMode: mode)
    }

    // MARK: - Simple Output

    /// Print an info message
    func info(_ message: String) {
        guard outputMode != .quiet else { return }
        if useColors {
            print(message.cyan)
        } else {
            print(message)
        }
    }

    /// Print a success message
    func success(_ message: String) {
        guard outputMode != .quiet else { return }
        let icon = useColors ? "✓".green : "✓"
        print("\(icon) \(message)")
    }

    /// Print a warning message
    func warning(_ message: String) {
        let icon = useColors ? "⚠".yellow : "⚠"
        let text = useColors ? message.yellow : message
        print("\(icon) \(text)")
    }

    /// Print an error message
    func error(_ message: String) {
        let icon = useColors ? "✗".red : "✗"
        let text = useColors ? message.red : message
        print("\(icon) \(text)")
    }

    /// Print a debug message (only in verbose mode)
    func debug(_ message: String) {
        guard outputMode == .verbose else { return }
        let prefix = useColors ? "[DEBUG]".lightBlack : "[DEBUG]"
        print("\(prefix) \(message)")
    }

    // MARK: - Spinner Operations

    /// Execute an operation with a spinner
    func withSpinner<T: Sendable>(
        _ message: String,
        operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        guard outputMode.showProgress else {
            // Quiet mode or plain mode without animations
            if outputMode != .quiet {
                print(message)
            }
            return try await operation()
        }

        let spinner = Spinner(
            message: message,
            useColors: useColors,
            useAnimations: useAnimations
        )

        await spinner.start()

        do {
            let result = try await operation()
            await spinner.succeed()
            return result
        } catch {
            await spinner.fail()
            throw error
        }
    }

    /// Execute an operation with a spinner and custom completion message
    func withSpinner<T: Sendable>(
        _ message: String,
        successMessage: String,
        operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        guard outputMode.showProgress else {
            if outputMode != .quiet {
                print(message)
            }
            let result = try await operation()
            if outputMode != .quiet {
                print("✓ \(successMessage)")
            }
            return result
        }

        let spinner = Spinner(
            message: message,
            useColors: useColors,
            useAnimations: useAnimations
        )

        await spinner.start()

        do {
            let result = try await operation()
            await spinner.succeed(message: successMessage)
            return result
        } catch {
            await spinner.fail()
            throw error
        }
    }

    // MARK: - Progress Bar Operations

    /// Execute an operation with a progress bar
    func withProgress<T: Sendable>(
        _ message: String,
        total: Int,
        operation: @Sendable (ProgressBar) async throws -> T
    ) async rethrows -> T {
        guard outputMode.showProgress, total > 0 else {
            if outputMode != .quiet {
                print(message)
            }
            let dummyProgress = ProgressBar(
                message: message,
                total: max(total, 1),
                useColors: false,
                useAnimations: false
            )
            return try await operation(dummyProgress)
        }

        let progressBar = ProgressBar(
            message: message,
            total: total,
            useColors: useColors,
            useAnimations: useAnimations
        )

        do {
            let result = try await operation(progressBar)
            await progressBar.succeed()
            return result
        } catch {
            await progressBar.fail()
            throw error
        }
    }

    // MARK: - Multi-Progress Operations

    /// Create a multi-progress manager for concurrent operations
    func createMultiProgress() -> MultiProgressManager {
        MultiProgressManager(useColors: useColors, useAnimations: useAnimations)
    }

    /// Create a batch progress view for batch processing
    func createBatchProgress() -> BatchProgressView {
        BatchProgressView(useColors: useColors, useAnimations: useAnimations)
    }

    /// Create a dispatch source for terminal resize events (SIGWINCH).
    /// - Parameter handler: Closure to call when terminal is resized.
    /// - Returns: The dispatch source that must be retained while monitoring.
    func createResizeSource(_ handler: @escaping @Sendable () -> Void) -> DispatchSourceSignal? {
        guard useAnimations else { return nil }

        #if os(macOS) || os(Linux)
            // Ignore the default SIGWINCH handler
            signal(SIGWINCH, SIG_IGN)

            let source = DispatchSource.makeSignalSource(signal: SIGWINCH, queue: .main)
            source.setEventHandler {
                handler()
            }
            source.resume()
            return source
        #else
            return nil
        #endif
    }

    // MARK: - Cursor Control

    /// Hide the terminal cursor
    func hideCursor() {
        guard useAnimations else { return }
        print(ANSICodes.hideCursor, terminator: "")
        ANSICodes.flushStdout()
    }

    /// Show the terminal cursor
    func showCursor() {
        guard useAnimations else { return }
        print(ANSICodes.showCursor, terminator: "")
        ANSICodes.flushStdout()
    }

    /// Ensure cursor is visible (call on cleanup/exit)
    func cleanup() {
        showCursor()
    }
}

// MARK: - Signal Handling

extension TerminalUI {
    /// Install signal handlers to restore cursor on interruption
    func installSignalHandlers() {
        guard useAnimations else { return }

        signal(SIGINT) { _ in
            print(ANSICodes.showCursor, terminator: "")
            ANSICodes.flushStdout()
            exit(130)
        }

        signal(SIGTERM) { _ in
            print(ANSICodes.showCursor, terminator: "")
            ANSICodes.flushStdout()
            exit(143)
        }
    }
}
