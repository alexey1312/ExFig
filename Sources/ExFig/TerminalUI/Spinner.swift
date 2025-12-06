import Foundation
import Rainbow

/// Animated spinner for terminal progress indication.
/// Uses a dedicated high-priority DispatchQueue to ensure smooth animation
/// regardless of Swift concurrency thread pool load.
final class Spinner: @unchecked Sendable {
    /// Spinner animation frames (Braille pattern)
    private static let frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]

    /// Animation interval (80ms = 12.5 FPS)
    private static let intervalMs: Int = 80

    /// Dedicated high-priority queue for spinner rendering
    private static let renderQueue = DispatchQueue(
        label: "com.exfig.spinner",
        qos: .userInteractive
    )

    private let lock = NSLock()
    private var _message: String
    private var _isRunning = false
    private var frameIndex = 0
    private var timer: DispatchSourceTimer?
    private let useColors: Bool
    private let useAnimations: Bool

    private var message: String {
        get { lock.withLock { _message } }
        set { lock.withLock { _message = newValue } }
    }

    private var isRunning: Bool {
        get { lock.withLock { _isRunning } }
        set { lock.withLock { _isRunning = newValue } }
    }

    init(message: String, useColors: Bool = true, useAnimations: Bool = true) {
        _message = message
        self.useColors = useColors
        self.useAnimations = useAnimations
    }

    /// Start the spinner animation
    func start() {
        Self.renderQueue.async { [self] in
            guard !isRunning else { return }
            isRunning = true
            TerminalOutputManager.shared.hasActiveAnimation = true

            if useAnimations {
                TerminalOutputManager.shared.writeDirect(ANSICodes.hideCursor)

                let timer = DispatchSource.makeTimerSource(queue: Self.renderQueue)
                timer.schedule(
                    deadline: .now(),
                    repeating: .milliseconds(Self.intervalMs)
                )
                timer.setEventHandler { [weak self] in
                    self?.render()
                }
                self.timer = timer
                timer.resume()
            } else {
                TerminalOutputManager.shared.writeDirect("\(message)\n")
            }
        }
    }

    /// Update the spinner message
    func update(message: String) {
        self.message = message
        if !useAnimations {
            Self.renderQueue.async {
                TerminalOutputManager.shared.writeDirect("\(message)\n")
            }
        }
    }

    /// Stop the spinner with success state
    func succeed(message: String? = nil) {
        stop(success: true, message: message)
    }

    /// Stop the spinner with failure state
    func fail(message: String? = nil) {
        stop(success: false, message: message)
    }

    /// Stop the spinner
    private func stop(success: Bool, message: String?) {
        Self.renderQueue.async { [self] in
            guard isRunning else { return }
            isRunning = false
            TerminalOutputManager.shared.hasActiveAnimation = false
            TerminalOutputManager.shared.clearAnimationState()
            timer?.cancel()
            timer = nil

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
    }

    /// Render a single frame of the spinner
    private func render() {
        guard isRunning else { return }
        let currentMessage = message
        let frame = Self.frames[frameIndex % Self.frames.count]
        let coloredFrame = useColors ? frame.cyan : frame
        TerminalOutputManager.shared.writeAnimationFrame("\(coloredFrame) \(currentMessage)")
        frameIndex += 1
    }
}
