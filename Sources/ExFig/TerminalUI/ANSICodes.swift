import Foundation

/// ANSI escape codes for terminal control
///
/// Note: For text colors and styles, use Rainbow library instead.
/// This enum provides only cursor and line control codes.
enum ANSICodes {
    /// Escape character
    static let escape = "\u{001B}"

    /// Control Sequence Introducer
    static let csi = "\(escape)["

    // MARK: - Cursor Control

    /// Hide cursor
    static let hideCursor = "\(csi)?25l"

    /// Show cursor
    static let showCursor = "\(csi)?25h"

    /// Move cursor up n lines
    static func cursorUp(_ n: Int = 1) -> String {
        "\(csi)\(n)A"
    }

    /// Move cursor down n lines
    static func cursorDown(_ n: Int = 1) -> String {
        "\(csi)\(n)B"
    }

    /// Move cursor to beginning of line
    static let carriageReturn = "\r"

    /// Save cursor position
    static let saveCursor = "\(csi)s"

    /// Restore cursor position
    static let restoreCursor = "\(csi)u"

    // MARK: - Line Control

    /// Clear from cursor to end of line
    static let clearToEndOfLine = "\(csi)K"

    /// Clear entire line
    static let clearLine = "\(csi)2K"

    /// Clear from cursor to end of screen
    static let clearToEndOfScreen = "\(csi)J"

    // MARK: - Output Control

    /// Flush stdout in a concurrency-safe manner
    ///
    /// On Linux, `stdout` is shared mutable state which triggers Swift 6 concurrency warnings.
    /// We use `FileHandle.standardOutput.synchronize()` as a cross-platform alternative.
    @inline(__always)
    static func flushStdout() {
        try? FileHandle.standardOutput.synchronize()
    }
}
