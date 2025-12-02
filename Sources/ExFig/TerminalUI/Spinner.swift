import Foundation
import Rainbow

/// Animated spinner for terminal progress indication
actor Spinner {
    /// Spinner animation frames (Braille pattern)
    private static let frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]

    /// Animation interval in nanoseconds (80ms)
    private static let intervalNanoseconds: UInt64 = 80_000_000

    private var message: String
    private var isRunning = false
    private var frameIndex = 0
    private var task: Task<Void, Never>?
    private let useColors: Bool
    private let useAnimations: Bool

    init(message: String, useColors: Bool = true, useAnimations: Bool = true) {
        self.message = message
        self.useColors = useColors
        self.useAnimations = useAnimations
    }

    /// Start the spinner animation
    func start() {
        guard !isRunning else { return }
        isRunning = true

        if useAnimations {
            print(ANSICodes.hideCursor, terminator: "")
            task = Task { [weak self] in
                while await self?.isRunning == true {
                    await self?.render()
                    try? await Task.sleep(nanoseconds: Self.intervalNanoseconds)
                }
            }
        } else {
            // Plain mode: just print the message
            print(message)
        }
    }

    /// Update the spinner message
    func update(message: String) {
        self.message = message
        if !useAnimations {
            print(message)
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
        isRunning = false
        task?.cancel()
        task = nil

        let finalMessage = message ?? self.message
        let icon: String = if useColors {
            success ? "✓".green : "✗".red
        } else {
            success ? "✓" : "✗"
        }

        if useAnimations {
            print("\(ANSICodes.carriageReturn)\(ANSICodes.clearToEndOfLine)\(icon) \(finalMessage)")
            print(ANSICodes.showCursor, terminator: "")
        } else {
            print("\(icon) \(finalMessage)")
        }
        ANSICodes.flushStdout()
    }

    /// Render a single frame of the spinner
    private func render() {
        let frame = Self.frames[frameIndex % Self.frames.count]
        let coloredFrame = useColors ? frame.cyan : frame
        print("\(ANSICodes.carriageReturn)\(ANSICodes.clearToEndOfLine)\(coloredFrame) \(message)", terminator: "")
        ANSICodes.flushStdout()
        frameIndex += 1
    }
}
