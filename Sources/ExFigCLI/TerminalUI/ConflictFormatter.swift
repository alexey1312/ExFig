import Foundation
import Noora

/// Formats `OutputPathConflict` for readable terminal display.
///
/// Supports two output modes:
/// - `format()`: Returns a formatted string (for `ui.warning()` and testing)
/// - `display()`: Renders a Noora table directly to stdout
struct ConflictFormatter {
    /// Format an array of OutputPathConflicts as a plain text string.
    /// - Parameter conflicts: The conflicts to format
    /// - Returns: A formatted multi-line string suitable for terminal output
    func format(_ conflicts: [OutputPathConflict]) -> String {
        guard !conflicts.isEmpty else {
            return ""
        }

        var result = "Output path conflicts detected:"

        for conflict in conflicts {
            result += "\n" + formatConflict(conflict)
        }

        return result
    }

    /// Display conflicts as a Noora table directly to stdout.
    /// - Parameter conflicts: The conflicts to display
    func display(_ conflicts: [OutputPathConflict]) {
        guard !conflicts.isEmpty else { return }

        print("Output path conflicts detected:")

        let headers: [TableCellStyle] = [
            .plain("Path"),
            .plain("Configs"),
        ]

        let rows: [StyledTableRow] = conflicts.map { conflict in
            let configNames = conflict.configs.map(\.lastPathComponent).joined(separator: ", ")
            return [.plain(conflict.path), .warning(configNames)]
        }

        NooraUI.shared.table(headers: headers, rows: rows)
    }

    // MARK: - Private Helpers

    private func formatConflict(_ conflict: OutputPathConflict) -> String {
        let configNames = conflict.configs.map(\.lastPathComponent)

        var result = "  path: \(conflict.path)"
        result += "\n  configs[\(configNames.count)]:"

        for name in configNames {
            result += "\n    \(name)"
        }

        return result
    }
}
