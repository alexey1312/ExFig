import Foundation
import Rainbow

/// Progress bar for terminal progress indication.
/// Uses a dedicated high-priority DispatchQueue to ensure smooth animation
/// regardless of Swift concurrency thread pool load.
final class ProgressBar: @unchecked Sendable {
    /// Animation interval (80ms = 12.5 FPS, same as Spinner)
    private static let intervalMs: Int = 80

    /// Dedicated high-priority queue for progress bar rendering
    private static let renderQueue = DispatchQueue(
        label: "com.exfig.progressbar",
        qos: .userInteractive
    )

    private let lock = NSLock()
    private let total: Int
    private var _current: Int = 0
    private var _message: String
    private let startTime: Date
    private let width: Int
    private let useColors: Bool
    private let useAnimations: Bool
    private var _isRunning = false
    private var timer: DispatchSourceTimer?
    private var _needsRender = false

    private var current: Int {
        get { lock.withLock { _current } }
        set { lock.withLock { _current = min(newValue, total) } }
    }

    private var message: String {
        get { lock.withLock { _message } }
        set { lock.withLock { _message = newValue } }
    }

    private var isRunning: Bool {
        get { lock.withLock { _isRunning } }
        set { lock.withLock { _isRunning = newValue } }
    }

    private var needsRender: Bool {
        get { lock.withLock { _needsRender } }
        set { lock.withLock { _needsRender = newValue } }
    }

    init(
        message: String,
        total: Int,
        width: Int = 30,
        useColors: Bool = true,
        useAnimations: Bool = true
    ) {
        _message = message
        self.total = max(total, 1) // Prevent division by zero
        self.width = width
        startTime = Date()
        self.useColors = useColors
        self.useAnimations = useAnimations
    }

    /// Start the progress bar rendering loop
    func start() {
        guard !isRunning else { return }
        isRunning = true
        needsRender = true

        // Build initial frame synchronously
        let initialFrame = buildFrame(currentValue: 0)

        // Set animation flag and initial frame synchronously BEFORE dispatching
        // This ensures log messages see the animation state immediately
        TerminalOutputManager.shared.startAnimation(initialFrame: initialFrame)

        Self.renderQueue.async { [self] in
            if useAnimations {
                TerminalOutputManager.shared.writeDirect(ANSICodes.hideCursor)
                // First frame already rendered by startAnimation(), start timer for next frames

                // Use timer-based rendering like Spinner for consistent frame rate
                let timer = DispatchSource.makeTimerSource(queue: Self.renderQueue)
                timer.schedule(
                    deadline: .now() + .milliseconds(Self.intervalMs),
                    repeating: .milliseconds(Self.intervalMs)
                )
                timer.setEventHandler { [weak self] in
                    self?.renderIfNeeded()
                }
                self.timer = timer
                timer.resume()
            }
        }
    }

    /// Update progress
    func update(current: Int, message: String? = nil) {
        self.current = current
        if let msg = message {
            self.message = msg
        }
        needsRender = true

        // For non-animation mode, print immediately
        if !useAnimations {
            Self.renderQueue.async { [self] in
                renderPlainMode()
            }
        }
    }

    /// Increment progress by one
    func increment(message: String? = nil) {
        update(current: current + 1, message: message)
    }

    /// Complete the progress bar with success
    func succeed(message: String? = nil) {
        current = total
        finish(success: true, message: message)
    }

    /// Complete the progress bar with failure
    func fail(message: String? = nil) {
        finish(success: false, message: message)
    }

    /// Finish and clear the progress bar
    private func finish(success: Bool, message: String?) {
        guard isRunning else { return }
        isRunning = false

        // Stop animation state synchronously so subsequent print() calls don't coordinate
        TerminalOutputManager.shared.hasActiveAnimation = false
        TerminalOutputManager.shared.clearAnimationState()

        // Cancel timer synchronously on render queue
        Self.renderQueue.sync {
            timer?.cancel()
            timer = nil
        }

        let finalMessage = message ?? self.message
        let icon: String = if useColors {
            success ? "✓".green : "✗".red
        } else {
            success ? "✓" : "✗"
        }

        if useAnimations {
            TerminalOutputManager.shared.writeDirect(
                "\(ANSICodes.carriageReturn)\(ANSICodes.clearToEndOfLine)\(icon) \(finalMessage)\n"
            )
            TerminalOutputManager.shared.writeDirect(ANSICodes.showCursor)
        } else {
            TerminalOutputManager.shared.writeDirect("\(icon) \(finalMessage)\n")
        }
    }

    /// Render if there are pending changes (called by timer)
    private func renderIfNeeded() {
        guard isRunning, needsRender else { return }
        needsRender = false
        render()
    }

    /// Render the progress bar
    private func render() {
        let line = buildFrame(currentValue: current)
        TerminalOutputManager.shared.writeAnimationFrame(line)
    }

    /// Build the progress bar frame string
    private func buildFrame(currentValue: Int) -> String {
        let percentage = Double(currentValue) / Double(total)
        let filled = Int(percentage * Double(width))
        let empty = width - filled

        let filledBar = String(repeating: "█", count: filled)
        let emptyBar = String(repeating: "░", count: empty)

        let bar = if useColors {
            "[\(filledBar.cyan)\(emptyBar.lightBlack)]"
        } else {
            "[\(filledBar)\(emptyBar)]"
        }

        let percentStr = String(format: "%3.0f%%", percentage * 100)
        let countStr = "\(currentValue)/\(total)"
        let eta = calculateETA(currentValue: currentValue)

        return "\(bar) \(percentStr) \(countStr) \(eta) \(message)"
    }

    /// Render in plain mode (no animations)
    private func renderPlainMode() {
        let currentValue = current
        // Plain mode: print on new line only for significant progress
        if currentValue == 1 || currentValue == total || currentValue % max(total / 10, 1) == 0 {
            TerminalOutputManager.shared.writeDirect("\(message): \(currentValue)/\(total)\n")
        }
    }

    /// Calculate estimated time remaining
    private func calculateETA(currentValue: Int) -> String {
        guard currentValue > 0 else { return "" }

        let elapsed = Date().timeIntervalSince(startTime)
        let rate = Double(currentValue) / elapsed
        let remaining = Double(total - currentValue) / rate

        if remaining < 1 {
            return ""
        }

        return "ETA: \(formatTime(remaining))"
    }

    /// Format time interval as human-readable string
    private func formatTime(_ seconds: Double) -> String {
        if seconds < 60 {
            return "\(Int(seconds))s"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
            return "\(minutes)m \(secs)s"
        } else {
            let hours = Int(seconds / 3600)
            let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m"
        }
    }
}
