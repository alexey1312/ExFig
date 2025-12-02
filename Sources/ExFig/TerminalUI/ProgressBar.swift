import Foundation
import Rainbow

/// Progress bar for terminal progress indication
actor ProgressBar {
    private let total: Int
    private var current: Int = 0
    private var message: String
    private let startTime: Date
    private let width: Int
    private let useColors: Bool
    private let useAnimations: Bool

    init(
        message: String,
        total: Int,
        width: Int = 30,
        useColors: Bool = true,
        useAnimations: Bool = true
    ) {
        self.message = message
        self.total = max(total, 1) // Prevent division by zero
        self.width = width
        startTime = Date()
        self.useColors = useColors
        self.useAnimations = useAnimations
    }

    /// Update progress
    func update(current: Int, message: String? = nil) {
        self.current = min(current, total)
        if let msg = message {
            self.message = msg
        }
        render()
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
        let finalMessage = message ?? self.message
        let icon: String = if useColors {
            success ? "✓".green : "✗".red
        } else {
            success ? "✓" : "✗"
        }

        if useAnimations {
            print("\(ANSICodes.carriageReturn)\(ANSICodes.clearToEndOfLine)\(icon) \(finalMessage)")
        } else {
            print("\(icon) \(finalMessage)")
        }
        ANSICodes.flushStdout()
    }

    /// Render the progress bar
    private func render() {
        let percentage = Double(current) / Double(total)
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
        let countStr = "\(current)/\(total)"
        let eta = calculateETA()

        let line = "\(bar) \(percentStr) \(countStr) \(eta) \(message)"

        if useAnimations {
            print("\(ANSICodes.carriageReturn)\(ANSICodes.clearToEndOfLine)\(line)", terminator: "")
        } else {
            // Plain mode: print on new line only for significant progress
            if current == 1 || current == total || current % max(total / 10, 1) == 0 {
                print("\(message): \(current)/\(total)")
            }
        }
        ANSICodes.flushStdout()
    }

    /// Calculate estimated time remaining
    private func calculateETA() -> String {
        guard current > 0 else { return "" }

        let elapsed = Date().timeIntervalSince(startTime)
        let rate = Double(current) / elapsed
        let remaining = Double(total - current) / rate

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
