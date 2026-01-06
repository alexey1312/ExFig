// swiftlint:disable file_length type_body_length
import ExFigCore
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
        // Suppress in batch mode - progress view shows status
        if BatchProgressViewStorage.progressView != nil { return }
        if useColors {
            TerminalOutputManager.shared.print(message.cyan)
        } else {
            TerminalOutputManager.shared.print(message)
        }
    }

    /// Print a success message
    func success(_ message: String) {
        guard outputMode != .quiet else { return }
        // Suppress in batch mode - progress view shows status
        if BatchProgressViewStorage.progressView != nil { return }
        let icon = useColors ? "✓".green : "✓"
        TerminalOutputManager.shared.print("\(icon) \(message)")
    }

    /// Print a warning message (handles multi-line properly)
    func warning(_ message: String) {
        // In batch mode, queue for coordinated output to prevent race conditions
        if let progressView = BatchProgressViewStorage.progressView {
            let formatted = formatWarningForQueue(message)
            Task {
                await progressView.queueLogMessage(formatted)
            }
            return
        }

        printWarning(message)
    }

    /// Internal helper to print warning message with formatting
    private func printWarning(_ message: String) {
        let icon = useColors ? "⚠".yellow : "⚠"

        // Split message into lines and apply formatting to each
        let lines = message.split(separator: "\n", omittingEmptySubsequences: false)

        for (index, line) in lines.enumerated() {
            let lineStr = String(line)
            let text = useColors ? lineStr.yellow : lineStr

            if index == 0 {
                // First line gets the icon
                TerminalOutputManager.shared.print("\(icon) \(text)")
            } else {
                // Subsequent lines are indented to align with text after icon
                TerminalOutputManager.shared.print("  \(text)")
            }
        }
    }

    /// Print a formatted AssetsValidatorWarning
    func warning(_ warning: AssetsValidatorWarning) {
        let formatter = WarningFormatter()
        let formattedMessage = formatter.format(warning)

        guard !formattedMessage.isEmpty else { return }

        self.warning(formattedMessage)
    }

    /// Print a formatted ExFigWarning
    func warning(_ warning: ExFigWarning) {
        let formatter = ExFigWarningFormatter()
        let formattedMessage = formatter.format(warning)
        self.warning(formattedMessage)
    }

    /// Print an error message
    func error(_ message: String) {
        // In batch mode, queue for coordinated output to prevent race conditions
        if let progressView = BatchProgressViewStorage.progressView {
            let formatted = formatErrorForQueue(message)
            Task {
                await progressView.queueLogMessage(formatted)
            }
            return
        }

        printError(message)
    }

    /// Internal helper to print error message with formatting
    private func printError(_ message: String) {
        let icon = useColors ? "✗".red : "✗"

        // Split message into lines and apply formatting to each
        let lines = message.split(separator: "\n", omittingEmptySubsequences: false)

        for (index, line) in lines.enumerated() {
            let lineStr = String(line)
            let text = useColors ? lineStr.red : lineStr

            if index == 0 {
                // First line gets the icon
                TerminalOutputManager.shared.print("\(icon) \(text)")
            } else {
                // Subsequent lines are indented to align with text after icon
                TerminalOutputManager.shared.print("  \(text)")
            }
        }
    }

    /// Print a formatted LocalizedError with optional recovery suggestion
    func error(_ error: any LocalizedError) {
        let formatter = ExFigErrorFormatter()
        let formattedMessage = formatter.format(error)
        self.error(formattedMessage)
    }

    /// Print a formatted Error
    func error(_ error: any Error) {
        let formatter = ExFigErrorFormatter()
        let formattedMessage = formatter.format(error)
        self.error(formattedMessage)
    }

    /// Print a debug message (only in verbose mode)
    func debug(_ message: String) {
        guard outputMode == .verbose else { return }
        // Suppress in batch mode - progress view shows status
        if BatchProgressViewStorage.progressView != nil { return }
        let prefix = useColors ? "[DEBUG]".lightBlack : "[DEBUG]"
        TerminalOutputManager.shared.print("\(prefix) \(message)")
    }

    // MARK: - Batch Mode Log Formatting

    /// Format warning message for batch mode queue (includes icon and coloring)
    private func formatWarningForQueue(_ message: String) -> String {
        let icon = useColors ? "⚠".yellow : "⚠"
        let lines = message.split(separator: "\n", omittingEmptySubsequences: false)

        return lines.enumerated().map { index, line in
            let lineStr = String(line)
            let text = useColors ? lineStr.yellow : lineStr
            return index == 0 ? "\(icon) \(text)" : "  \(text)"
        }.joined(separator: "\n")
    }

    /// Format error message for batch mode queue (includes icon and coloring)
    private func formatErrorForQueue(_ message: String) -> String {
        let icon = useColors ? "✗".red : "✗"
        let lines = message.split(separator: "\n", omittingEmptySubsequences: false)

        return lines.enumerated().map { index, line in
            let lineStr = String(line)
            let text = useColors ? lineStr.red : lineStr
            return index == 0 ? "\(icon) \(text)" : "  \(text)"
        }.joined(separator: "\n")
    }

    // MARK: - Spinner Operations

    /// Execute an operation with a spinner
    func withSpinner<T: Sendable>(
        _ message: String,
        operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        // Suppress in batch mode to avoid corrupting multi-line progress display
        if BatchProgressViewStorage.progressView != nil {
            return try await operation()
        }

        guard outputMode.showProgress else {
            // Quiet mode or plain mode without animations
            if outputMode != .quiet {
                TerminalOutputManager.shared.print(message)
            }
            return try await operation()
        }

        let spinner = Spinner(
            message: message,
            useColors: useColors,
            useAnimations: useAnimations
        )

        spinner.start()

        do {
            let result = try await operation()
            spinner.succeed()
            return result
        } catch {
            spinner.fail()
            throw error
        }
    }

    /// Execute an operation with a spinner and custom completion message
    func withSpinner<T: Sendable>(
        _ message: String,
        successMessage: String,
        operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        // Suppress in batch mode to avoid corrupting multi-line progress display
        if BatchProgressViewStorage.progressView != nil {
            return try await operation()
        }

        guard outputMode.showProgress else {
            if outputMode != .quiet {
                TerminalOutputManager.shared.print(message)
            }
            let result = try await operation()
            if outputMode != .quiet {
                TerminalOutputManager.shared.print("✓ \(successMessage)")
            }
            return result
        }

        let spinner = Spinner(
            message: message,
            useColors: useColors,
            useAnimations: useAnimations
        )

        spinner.start()

        do {
            let result = try await operation()
            spinner.succeed(message: successMessage)
            return result
        } catch {
            spinner.fail()
            throw error
        }
    }

    /// Execute an operation with a spinner that shows batch progress (current/total)
    func withSpinnerProgress<T: Sendable>(
        _ message: String,
        operation: @Sendable @escaping (@escaping @Sendable (Int, Int) -> Void) async throws -> T
    ) async rethrows -> T {
        // Suppress in batch mode to avoid corrupting multi-line progress display
        if BatchProgressViewStorage.progressView != nil {
            return try await operation { _, _ in }
        }

        guard outputMode.showProgress else {
            if outputMode != .quiet {
                TerminalOutputManager.shared.print(message)
            }
            // Provide no-op progress callback in quiet/plain mode
            return try await operation { _, _ in }
        }

        let spinner = Spinner(
            message: message,
            useColors: useColors,
            useAnimations: useAnimations
        )

        spinner.start()

        do {
            let result = try await operation { current, total in
                spinner.update(message: "\(message) (\(current)/\(total) batches)")
            }
            spinner.succeed()
            return result
        } catch {
            spinner.fail()
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
        // Suppress in batch mode to avoid corrupting multi-line progress display
        if BatchProgressViewStorage.progressView != nil {
            let silentProgress = ProgressBar(
                message: message,
                total: max(total, 1),
                useColors: false,
                useAnimations: false,
                isSilent: true
            )
            return try await operation(silentProgress)
        }

        guard outputMode.showProgress, total > 0 else {
            if outputMode != .quiet {
                TerminalOutputManager.shared.print(message)
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

        progressBar.start()

        do {
            let result = try await operation(progressBar)
            progressBar.succeed()
            return result
        } catch {
            progressBar.fail()
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

    // MARK: - Input

    /// Prompts the user for confirmation (y/n)
    func confirm(_ message: String, defaultToYes: Bool = false) -> Bool {
        guard TTYDetector.isTTY else { return false }

        let options = defaultToYes ? "[Y/n]" : "[y/N]"
        let text = "\(message) \(options) "
        let formattedText = useColors ? text.bold : text

        TerminalOutputManager.shared.writeDirect(formattedText)
        ANSICodes.flushStdout()

        guard let input = readLine() else {
            TerminalOutputManager.shared.writeDirect("\n")
            return false
        }

        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty {
            return defaultToYes
        }

        return trimmed == "y" || trimmed == "yes"
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
