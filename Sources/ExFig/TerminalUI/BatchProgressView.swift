import FigmaAPI
import Foundation
import Rainbow

/// Progress display for batch processing of multiple configs.
///
/// Displays multi-line progress with per-config status and rate limit information:
/// ```
/// Batch Export (3/5 configs)
/// ├─ [████████░░] ios-app.yaml      Colors: 45/50  Icons: 120/120 ✓
/// ├─ [██████░░░░] android-app.yaml  Colors: 30/50  Icons: 80/120
/// ├─ [░░░░░░░░░░] web-app.yaml      Waiting...
/// └─ Rate limit: 8.5 req/s (10 max)
/// ```
actor BatchProgressView {
    // MARK: - Config State

    /// State of a config being processed.
    struct ConfigState: Sendable {
        let name: String
        var status: Status
        var exportProgress: ExportProgress

        enum Status: Sendable {
            case pending
            case running
            case succeeded
            case failed(String)
        }

        struct ExportProgress: Sendable {
            var colors: (current: Int, total: Int)?
            var icons: (current: Int, total: Int)?
            var images: (current: Int, total: Int)?
            var typography: (current: Int, total: Int)?
        }
    }

    // MARK: - Properties

    private var configStates: [String: ConfigState] = [:]
    private var configOrder: [String] = []
    private var lineCount: Int = 0
    private var rateLimiterStatus: RateLimiterStatus?

    private let useColors: Bool
    private let useAnimations: Bool
    private var cachedTerminalWidth: Int

    /// Progress bar width, dynamically calculated based on terminal width.
    private var progressWidth: Int {
        // Reserve space for: tree prefix (3) + status icon (2) + [] (2) + name column (26) + padding (5)
        let reservedWidth = 38
        let availableWidth = cachedTerminalWidth - reservedWidth
        // Progress bar between 10 and 30 characters
        return max(10, min(30, availableWidth / 4))
    }

    // MARK: - Initialization

    init(useColors: Bool = true, useAnimations: Bool = true) {
        self.useColors = useColors
        self.useAnimations = useAnimations
        cachedTerminalWidth = TTYDetector.terminalWidth
    }

    // MARK: - Config Management

    /// Register a config for progress tracking.
    func registerConfig(name: String) {
        configStates[name] = ConfigState(
            name: name,
            status: .pending,
            exportProgress: ConfigState.ExportProgress()
        )
        if !configOrder.contains(name) {
            configOrder.append(name)
        }
        render()
    }

    /// Mark a config as running.
    func startConfig(name: String) {
        guard var state = configStates[name] else { return }
        state.status = .running
        configStates[name] = state
        render()
    }

    /// Update export progress for a config.
    func updateProgress(
        name: String,
        colors: (current: Int, total: Int)? = nil,
        icons: (current: Int, total: Int)? = nil,
        images: (current: Int, total: Int)? = nil,
        typography: (current: Int, total: Int)? = nil
    ) {
        guard var state = configStates[name] else { return }
        if let colors { state.exportProgress.colors = colors }
        if let icons { state.exportProgress.icons = icons }
        if let images { state.exportProgress.images = images }
        if let typography { state.exportProgress.typography = typography }
        configStates[name] = state
        render()
    }

    /// Mark a config as succeeded.
    func succeedConfig(name: String) {
        guard var state = configStates[name] else { return }
        state.status = .succeeded
        configStates[name] = state
        render()
    }

    /// Mark a config as failed.
    func failConfig(name: String, error: String) {
        guard var state = configStates[name] else { return }
        state.status = .failed(error)
        configStates[name] = state
        render()
    }

    // MARK: - Rate Limit Status

    /// Update the rate limiter status display.
    func updateRateLimiterStatus(_ status: RateLimiterStatus) {
        rateLimiterStatus = status
        render()
    }

    // MARK: - Terminal Resize

    /// Handle terminal resize by updating cached width and re-rendering.
    func handleTerminalResize() {
        let newWidth = TTYDetector.terminalWidth
        guard newWidth != cachedTerminalWidth else { return }
        cachedTerminalWidth = newWidth
        // Clear and re-render with new dimensions
        clear()
        render()
    }

    // MARK: - Rendering

    /// Clear the progress display.
    func clear() {
        guard useAnimations, lineCount > 0 else { return }

        // Move up and clear all lines
        for _ in 0 ..< lineCount {
            print(ANSICodes.cursorUp(1), terminator: "")
            print(ANSICodes.clearLine, terminator: "")
        }
        lineCount = 0
        ANSICodes.flushStdout()
    }

    /// Render the batch progress view.
    private func render() {
        guard useAnimations else { return }

        // Clear previous render
        if lineCount > 0 {
            print(ANSICodes.cursorUp(lineCount), terminator: "")
        }

        var lines: [String] = []

        // Header
        let completed = configStates.values.filter { isCompleted($0.status) }.count
        let total = configStates.count
        let header = "Batch Export (\(completed)/\(total) configs)"
        lines.append(useColors ? header.bold : header)

        // Config lines
        let sortedConfigs = configOrder.compactMap { configStates[$0] }
        for (index, config) in sortedConfigs.enumerated() {
            let isLast = index == sortedConfigs.count - 1 && rateLimiterStatus == nil
            let prefix = isLast ? "└─" : "├─"
            let line = formatConfigLine(config, prefix: prefix)
            lines.append(line)
        }

        // Rate limit status line
        if let status = rateLimiterStatus {
            let line = formatRateLimitLine(status)
            lines.append(line)
        }

        // Print all lines
        for line in lines {
            print(ANSICodes.clearLine, terminator: "")
            print(line)
        }

        lineCount = lines.count
        ANSICodes.flushStdout()
    }

    // MARK: - Formatting Helpers

    private func isCompleted(_ status: ConfigState.Status) -> Bool {
        switch status {
        case .succeeded, .failed:
            true
        case .pending, .running:
            false
        }
    }

    private func formatConfigLine(_ config: ConfigState, prefix: String) -> String {
        let icon = statusIcon(config.status)
        let progressBar = formatProgressBar(config)
        let nameColumn = config.name.padding(toLength: 25, withPad: " ", startingAt: 0)
        let statusText = formatStatusText(config)

        return "\(prefix) \(icon) \(progressBar) \(nameColumn) \(statusText)"
    }

    private func statusIcon(_ status: ConfigState.Status) -> String {
        switch status {
        case .pending:
            useColors ? "○".lightBlack : "○"
        case .running:
            useColors ? "●".cyan : "●"
        case .succeeded:
            useColors ? "✓".green : "✓"
        case .failed:
            useColors ? "✗".red : "✗"
        }
    }

    private func formatProgressBar(_ config: ConfigState) -> String {
        let percentage = calculateOverallProgress(config)
        let filled = Int(percentage * Double(progressWidth))
        let empty = progressWidth - filled

        let filledBar = String(repeating: "█", count: filled)
        let emptyBar = String(repeating: "░", count: empty)

        if useColors {
            return "[\(filledBar.cyan)\(emptyBar.lightBlack)]"
        }
        return "[\(filledBar)\(emptyBar)]"
    }

    private func calculateOverallProgress(_ config: ConfigState) -> Double {
        var total = 0
        var completed = 0

        if let colors = config.exportProgress.colors {
            total += colors.total
            completed += colors.current
        }
        if let icons = config.exportProgress.icons {
            total += icons.total
            completed += icons.current
        }
        if let images = config.exportProgress.images {
            total += images.total
            completed += images.current
        }
        if let typography = config.exportProgress.typography {
            total += typography.total
            completed += typography.current
        }

        guard total > 0 else {
            switch config.status {
            case .succeeded:
                return 1.0
            case .failed, .pending:
                return 0.0
            case .running:
                return 0.1 // Show some progress when running
            }
        }

        return Double(completed) / Double(total)
    }

    private func formatStatusText(_ config: ConfigState) -> String {
        switch config.status {
        case .pending:
            return useColors ? "Waiting...".lightBlack : "Waiting..."
        case .running:
            return formatExportProgress(config.exportProgress)
        case .succeeded:
            return formatExportProgress(config.exportProgress) + (useColors ? " ✓".green : " ✓")
        case let .failed(error):
            let truncated = String(error.prefix(30))
            return useColors ? truncated.red : truncated
        }
    }

    private func formatExportProgress(_ progress: ConfigState.ExportProgress) -> String {
        var parts: [String] = []

        if let colors = progress.colors, colors.total > 0 {
            let status = colors.current >= colors.total
                ? (useColors ? "✓".green : "✓")
                : "\(colors.current)/\(colors.total)"
            parts.append("Colors: \(status)")
        }

        if let icons = progress.icons, icons.total > 0 {
            let status = icons.current >= icons.total
                ? (useColors ? "✓".green : "✓")
                : "\(icons.current)/\(icons.total)"
            parts.append("Icons: \(status)")
        }

        if let images = progress.images, images.total > 0 {
            let status = images.current >= images.total
                ? (useColors ? "✓".green : "✓")
                : "\(images.current)/\(images.total)"
            parts.append("Images: \(status)")
        }

        if let typography = progress.typography, typography.total > 0 {
            let status = typography.current >= typography.total
                ? (useColors ? "✓".green : "✓")
                : "\(typography.current)/\(typography.total)"
            parts.append("Typography: \(status)")
        }

        return parts.joined(separator: "  ")
    }

    private func formatRateLimitLine(_ status: RateLimiterStatus) -> String {
        let prefix = "└─"
        let rateText: String

        if status.isPaused {
            let retryStr = status.retryAfter.map { String(format: "%.0fs", $0) } ?? "unknown"
            rateText = useColors
                ? "Rate limit: Paused (retry after \(retryStr))".yellow
                : "Rate limit: Paused (retry after \(retryStr))"
        } else {
            let currentRate = String(format: "%.1f", status.currentRate)
            let maxRate = String(format: "%.0f", status.requestsPerMinute / 60.0)
            rateText = "Rate limit: \(currentRate) req/s (\(maxRate) max)"
        }

        return "\(prefix) \(rateText)"
    }
}
