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

    private func reportText(diagnostics: [LintDiagnostic], ui: TerminalUI) {
        if diagnostics.isEmpty {
            ui.success("All lint checks passed")
            return
        }

        let errors = diagnostics.filter { $0.severity == .error }
        let warnings = diagnostics.filter { $0.severity == .warning }
        let infos = diagnostics.filter { $0.severity == .info }

        // Summary line
        var parts: [String] = []
        if !errors.isEmpty {
            parts.append(NooraUI.format(.danger("\(errors.count) error(s)")))
        }
        if !warnings.isEmpty {
            parts.append(NooraUI.format(.accent("\(warnings.count) warning(s)")))
        }
        if !infos.isEmpty {
            parts.append(NooraUI.format(.muted("\(infos.count) info(s)")))
        }
        ui.info("Lint: \(parts.joined(separator: ", "))")

        // Group by rule
        let grouped = Dictionary(grouping: diagnostics) { $0.ruleId }
        for (ruleId, items) in grouped.sorted(by: { $0.key < $1.key }) {
            let first = items[0]
            let icon = severityIcon(first.severity)
            ui.info("\(icon) \(first.ruleName) [\(ruleId)] (\(items.count))")

            for diag in items.prefix(10) {
                let name = diag.componentName ?? diag.nodeId ?? "unknown"
                ui.info("  \(name): \(diag.message)")
                if let suggestion = diag.suggestion {
                    ui.info("    → \(suggestion)")
                }
            }
            if items.count > 10 {
                ui.info("  ... +\(items.count - 10) more")
            }
        }
    }

    private func severityIcon(_ severity: LintSeverity) -> String {
        switch severity {
        case .error: useColors ? NooraUI.format(.danger("✗")) : "✗"
        case .warning: useColors ? NooraUI.format(.accent("⚠")) : "⚠"
        case .info: useColors ? NooraUI.format(.muted("ℹ")) : "ℹ"
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
