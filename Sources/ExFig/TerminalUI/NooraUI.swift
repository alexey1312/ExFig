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
}
