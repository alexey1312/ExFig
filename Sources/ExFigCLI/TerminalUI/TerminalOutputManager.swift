import Foundation

/// Centralized manager for all terminal output.
/// Coordinates between spinner/progress animations and log messages.
/// All terminal output MUST go through this manager to prevent race conditions.
final class TerminalOutputManager: @unchecked Sendable {
    static let shared = TerminalOutputManager()

    private struct State {
        var hasActiveAnimation = false
        var lastAnimationLine: String = ""
    }

    private let state = Lock(State())

    private init() {}

    var hasActiveAnimation: Bool {
        get { state.withLock { $0.hasActiveAnimation } }
        set { state.withLock { $0.hasActiveAnimation = newValue } }
    }

    /// Start an animation with initial frame. Sets flag, stores frame, and renders it atomically.
    /// Call this synchronously when starting spinner/progress to ensure immediate coordination.
    func startAnimation(initialFrame: String) {
        state.withLock { state in
            state.hasActiveAnimation = true
            state.lastAnimationLine = initialFrame
            // Render initial frame immediately so it's visible before any logs arrive
            printDirectUnsafe(initialFrame)
        }
    }

    /// Print message, coordinating with active animations.
    /// If an animation is active, clears the current line first, then redraws animation.
    func print(_ message: String) {
        state.withLock { state in
            if state.hasActiveAnimation {
                // Clear current line before printing
                printDirectUnsafe("\(ANSICodes.carriageReturn)\(ANSICodes.clearToEndOfLine)")
                // Print message on new line
                printDirectUnsafe("\(message)\n")
                // Redraw the animation line immediately to prevent flicker
                if !state.lastAnimationLine.isEmpty {
                    printDirectUnsafe(state.lastAnimationLine)
                }
            } else {
                printDirectUnsafe("\(message)\n")
            }
        }
    }

    /// Write animation frame. Called by Spinner/ProgressBar.
    /// This tracks the current animation line for redrawing after log messages.
    func writeAnimationFrame(_ frame: String) {
        state.withLock { state in
            state.lastAnimationLine = frame
            printDirectUnsafe("\(ANSICodes.carriageReturn)\(ANSICodes.clearToEndOfLine)\(frame)")
        }
    }

    /// Write raw output without coordination (for cursor show/hide, final messages).
    func writeDirect(_ string: String) {
        state.withLock { _ in
            printDirectUnsafe(string)
        }
    }

    /// Clear animation state when animation stops.
    func clearAnimationState() {
        state.withLock { state in
            state.lastAnimationLine = ""
        }
    }

    /// Direct write to stdout, bypassing Swift's print buffering.
    /// Must be called within lock for thread safety.
    private func printDirectUnsafe(_ string: String) {
        FileHandle.standardOutput.write(Data(string.utf8))
    }
}
