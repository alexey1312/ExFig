import Foundation

/// Formats `OutputPathConflict` for readable terminal display using TOON format
struct ConflictFormatter {
    /// Format an array of OutputPathConflicts for terminal display
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
