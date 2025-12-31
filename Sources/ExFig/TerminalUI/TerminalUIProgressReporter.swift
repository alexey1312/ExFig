import ExFigKit

/// Adapter that bridges ProgressReporter protocol to TerminalUI.
///
/// This allows loaders to use the abstract ProgressReporter protocol
/// while CLI commands use the concrete TerminalUI for output.
final class TerminalUIProgressReporter: ProgressReporter, @unchecked Sendable {
    private let ui: TerminalUI

    /// Current spinner for phase tracking (if animations enabled)
    private var spinner: Spinner?

    /// Current phase name for message context
    private var currentPhase: String?

    init(ui: TerminalUI) {
        self.ui = ui
    }

    // MARK: - Phases

    func beginPhase(_ name: String) async {
        currentPhase = name

        // In batch mode, phases are tracked by BatchProgressView
        if BatchProgressViewStorage.progressView != nil {
            return
        }

        // Start spinner if animations enabled
        if ui.outputMode.showProgress {
            spinner = Spinner(message: name, useColors: ui.outputMode.useColors)
            spinner?.start()
        } else {
            ui.info(name)
        }
    }

    func endPhase() async {
        spinner?.succeed()
        spinner = nil
        currentPhase = nil
    }

    // MARK: - Progress

    func reportBatchProgress(completed: Int, total: Int) async {
        guard let phase = currentPhase, let spinner else { return }

        // Update spinner message with progress count
        spinner.update(message: "\(phase) (\(completed)/\(total))")
    }

    func reportItemProgress(completed: Int, total: Int) async {
        // Item-level progress could use a progress bar, but for simplicity
        // we just update the spinner message if active
        guard let phase = currentPhase, let spinner else { return }

        let percent = total > 0 ? Int(Double(completed) / Double(total) * 100) : 0
        spinner.update(message: "\(phase) \(percent)%")
    }

    // MARK: - Messages

    func info(_ message: String) async {
        ui.info(message)
    }

    func warning(_ message: String) async {
        ui.warning(message)
    }

    func error(_ message: String) async {
        ui.error(message)
    }

    func success(_ message: String) async {
        ui.success(message)
    }

    func debug(_ message: String) async {
        ui.debug(message)
    }
}
