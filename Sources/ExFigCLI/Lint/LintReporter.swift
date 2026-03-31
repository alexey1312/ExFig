import ExFigCore
import Foundation
import Noora

/// Output format for lint results.
enum LintOutputFormat: String {
    case text
    case json
}

/// Formats and outputs lint results.
struct LintReporter {
    let format: LintOutputFormat
    let useColors: Bool

    func report(diagnostics: [LintDiagnostic], ui: TerminalUI) throws {
        switch format {
        case .text:
            reportText(diagnostics: diagnostics, ui: ui)
        case .json:
            try reportJSON(diagnostics: diagnostics)
        }
    }

    // MARK: - Text Output

    // swiftlint:disable function_body_length
    private func reportText(diagnostics: [LintDiagnostic], ui: TerminalUI) {
        if diagnostics.isEmpty {
            ui.success("All lint checks passed")
            return
        }

        let errors = diagnostics.filter { $0.severity == .error }
        let warnings = diagnostics.filter { $0.severity == .warning }

        // Summary header
        ui.info("")
        var summaryParts: [String] = []
        if !errors.isEmpty {
            summaryParts.append(NooraUI.format(.danger("\(errors.count) error(s)")))
        }
        if !warnings.isEmpty {
            summaryParts.append(NooraUI.format(.accent("\(warnings.count) warning(s)")))
        }
        ui.info("  \(summaryParts.joined(separator: "  "))")
        ui.info("")

        // Group by rule, sorted: errors first, then warnings
        let grouped = Dictionary(grouping: diagnostics) { $0.ruleId }
        let sortedGroups = grouped.sorted { lhs, rhs in
            let lSev = severityRank(lhs.value[0].severity)
            let rSev = severityRank(rhs.value[0].severity)
            if lSev != rSev { return lSev > rSev }
            return lhs.key < rhs.key
        }

        for (_, items) in sortedGroups {
            let first = items[0]
            let icon = severityIcon(first.severity)
            let countStr = useColors
                ? NooraUI.format(.muted("(\(items.count))"))
                : "(\(items.count))"

            ui.info("  \(icon) \(first.ruleName) \(countStr)")

            // Table: component name | message
            let tableItems = items.prefix(8)
            let maxNameLen = min(
                tableItems.compactMap(\.componentName).map(\.count).max() ?? 10,
                30
            )

            for diag in tableItems {
                let name = diag.componentName ?? diag.nodeId ?? "?"
                let truncated = name.count > 30 ? String(name.prefix(27)) + "..." : name
                let padded = truncated.padding(toLength: max(maxNameLen, truncated.count), withPad: " ", startingAt: 0)
                let nameStr = useColors ? NooraUI.format(.primary(padded)) : padded
                let msgStr = useColors ? NooraUI.format(.muted(diag.message)) : diag.message
                ui.info("    \(nameStr)  \(msgStr)")
            }

            if items.count > 8 {
                let moreStr = useColors
                    ? NooraUI.format(.muted("... +\(items.count - 8) more"))
                    : "... +\(items.count - 8) more"
                ui.info("    \(moreStr)")
            }
            ui.info("")
        }
    }

    // swiftlint:enable function_body_length

    private func severityIcon(_ severity: LintSeverity) -> String {
        switch severity {
        case .error: useColors ? NooraUI.format(.danger("✗")) : "✗"
        case .warning: useColors ? NooraUI.format(.accent("⚠")) : "⚠"
        case .info: useColors ? NooraUI.format(.muted("ℹ")) : "ℹ"
        }
    }

    private func severityRank(_ severity: LintSeverity) -> Int {
        switch severity {
        case .error: 2
        case .warning: 1
        case .info: 0
        }
    }

    // MARK: - JSON Output

    private func reportJSON(diagnostics: [LintDiagnostic]) throws {
        let report = LintReport(
            diagnosticsCount: diagnostics.count,
            errorsCount: diagnostics.filter { $0.severity == .error }.count,
            warningsCount: diagnostics.filter { $0.severity == .warning }.count,
            diagnostics: diagnostics
        )
        let data = try JSONCodec.encode(report)
        print(String(data: data, encoding: .utf8) ?? "{}")
    }
}

/// Top-level JSON report structure.
private struct LintReport: Codable {
    let diagnosticsCount: Int
    let errorsCount: Int
    let warningsCount: Int
    let diagnostics: [LintDiagnostic]
}
