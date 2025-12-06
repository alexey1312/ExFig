import Foundation

/// Centralized manager for all terminal output.
/// Coordinates between spinner/progress animations and log messages.
final class TerminalOutputManager: @unchecked Sendable {
    static let shared = TerminalOutputManager()

    private let lock = NSLock()
    private var _hasActiveAnimation = false

    private init() {}

    var hasActiveAnimation: Bool {
        get { lock.withLock { _hasActiveAnimation } }
        set { lock.withLock { _hasActiveAnimation = newValue } }
    }

    /// Print message, coordinating with active animations.
    /// If an animation is active, clears the current line first.
    func print(_ message: String) {
        lock.withLock {
            if _hasActiveAnimation {
                // Clear current line before printing
                printDirectUnsafe("\(ANSICodes.carriageReturn)\(ANSICodes.clearToEndOfLine)")
            }
            printDirectUnsafe("\(message)\n")
            // Animation will redraw on next timer tick
        }
    }

    /// Direct write to stdout, bypassing Swift's print buffering.
    /// Must be called within lock for thread safety.
    private func printDirectUnsafe(_ string: String) {
        FileHandle.standardOutput.write(Data(string.utf8))
    }
}
