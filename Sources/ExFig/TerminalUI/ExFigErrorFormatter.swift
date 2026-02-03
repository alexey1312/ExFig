import Foundation
import Noora

/// Formats LocalizedError for terminal display using TOON format.
///
/// Uses two styles:
/// - **Compact**: Single line error message for simple errors
/// - **With Recovery**: Error message followed by recovery suggestion on a new line
///
/// The formatter extracts `errorDescription` and `recoverySuggestion` from any `LocalizedError`.
struct ExFigErrorFormatter {
    /// Format a LocalizedError for terminal display.
    /// - Parameter error: The error to format.
    /// - Returns: A formatted string suitable for terminal output.
    func format(_ error: any LocalizedError) -> String {
        let description = error.errorDescription ?? error.localizedDescription

        if let recovery = error.recoverySuggestion {
            return "\(description)\n  → \(recovery)"
        }

        return description
    }

    /// Format an Error for terminal display.
    /// - Parameter error: The error to format.
    /// - Returns: A formatted string suitable for terminal output.
    func format(_ error: any Error) -> String {
        if let localizedError = error as? any LocalizedError {
            return format(localizedError)
        }
        return error.localizedDescription
    }

    // MARK: - TerminalText API

    /// Format a LocalizedError as semantic TerminalText.
    /// - Parameter error: The error to format.
    /// - Returns: A TerminalText suitable for NooraUI.format().
    func formatAsTerminalText(_ error: any LocalizedError) -> TerminalText {
        let description = error.errorDescription ?? error.localizedDescription

        if let recovery = error.recoverySuggestion {
            // Error message with recovery suggestion
            return "\(.danger("✗")) \(.danger(description))\n  → \(.muted(recovery))"
        }

        return "\(.danger("✗")) \(.danger(description))"
    }

    /// Format an Error as semantic TerminalText.
    /// - Parameter error: The error to format.
    /// - Returns: A TerminalText suitable for NooraUI.format().
    func formatAsTerminalText(_ error: any Error) -> TerminalText {
        if let localizedError = error as? any LocalizedError {
            return formatAsTerminalText(localizedError)
        }
        let description = error.localizedDescription
        return "\(.danger("✗")) \(.danger(description))"
    }
}
