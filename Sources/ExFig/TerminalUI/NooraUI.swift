import Noora

/// Adapter for Noora design system.
///
/// Provides a shared Noora instance with default theme for consistent
/// terminal text formatting across the CLI.
///
/// ## Usage
/// ```swift
/// let text: TerminalText = "Status: \(.success("OK"))"
/// print(NooraUI.format(text))
/// ```
enum NooraUI {
    /// Shared Noora instance with default theme.
    static let shared = Noora()

    /// Format TerminalText to a String with ANSI colors.
    /// - Parameter text: Semantic terminal text to format
    /// - Returns: String with ANSI escape codes for terminal display
    static func format(_ text: TerminalText) -> String {
        shared.format(text)
    }

    // MARK: - Convenience Methods

    /// Format a success message with checkmark icon.
    /// - Parameters:
    ///   - message: The message to display
    ///   - useColors: Whether to apply colors
    /// - Returns: Formatted string with success icon
    static func formatSuccess(_ message: String, useColors: Bool) -> String {
        guard useColors else { return "✓ \(message)" }
        let text: TerminalText = "\(.success("✓")) \(message)"
        return format(text)
    }

    /// Format an error message with cross icon.
    /// - Parameters:
    ///   - message: The message to display
    ///   - useColors: Whether to apply colors
    /// - Returns: Formatted string with error icon
    static func formatError(_ message: String, useColors: Bool) -> String {
        guard useColors else { return "✗ \(message)" }
        let text: TerminalText = "\(.danger("✗")) \(.danger(message))"
        return format(text)
    }

    /// Format a warning message with warning icon.
    /// - Parameters:
    ///   - message: The message to display
    ///   - useColors: Whether to apply colors
    /// - Returns: Formatted string with warning icon
    static func formatWarning(_ message: String, useColors: Bool) -> String {
        guard useColors else { return "⚠ \(message)" }
        let text: TerminalText = "\(.accent("⚠")) \(.accent(message))"
        return format(text)
    }

    /// Format an info message with primary color.
    /// - Parameters:
    ///   - message: The message to display
    ///   - useColors: Whether to apply colors
    /// - Returns: Formatted string
    static func formatInfo(_ message: String, useColors: Bool) -> String {
        guard useColors else { return message }
        let text: TerminalText = "\(.primary(message))"
        return format(text)
    }

    /// Format a debug message with muted prefix.
    /// - Parameters:
    ///   - message: The message to display
    ///   - useColors: Whether to apply colors
    /// - Returns: Formatted string with debug prefix
    static func formatDebug(_ message: String, useColors: Bool) -> String {
        guard useColors else { return "[DEBUG] \(message)" }
        let text: TerminalText = "\(.muted("[DEBUG]")) \(message)"
        return format(text)
    }

    /// Format multi-line error message with proper indentation.
    /// - Parameters:
    ///   - message: The message (may contain newlines)
    ///   - useColors: Whether to apply colors
    /// - Returns: Formatted string with error icon and indented lines
    static func formatMultilineError(_ message: String, useColors: Bool) -> String {
        let lines = message.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.enumerated().map { index, line in
            let lineStr = String(line)
            if index == 0 {
                return formatError(lineStr, useColors: useColors)
            } else {
                guard useColors else { return "  \(lineStr)" }
                let text: TerminalText = "  \(.danger(lineStr))"
                return format(text)
            }
        }.joined(separator: "\n")
    }

    /// Format multi-line warning message with proper indentation.
    /// - Parameters:
    ///   - message: The message (may contain newlines)
    ///   - useColors: Whether to apply colors
    /// - Returns: Formatted string with warning icon and indented lines
    static func formatMultilineWarning(_ message: String, useColors: Bool) -> String {
        let lines = message.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.enumerated().map { index, line in
            let lineStr = String(line)
            if index == 0 {
                return formatWarning(lineStr, useColors: useColors)
            } else {
                guard useColors else { return "  \(lineStr)" }
                let text: TerminalText = "  \(.accent(lineStr))"
                return format(text)
            }
        }.joined(separator: "\n")
    }
}
