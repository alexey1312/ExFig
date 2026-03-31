import ExFigConfig
import ExFigCore
import FigmaAPI
import Foundation

/// Severity level for lint diagnostics.
enum LintSeverity: String, CaseIterable, Codable {
    case error
    case warning
    case info
}

/// A single finding from a lint rule.
struct LintDiagnostic: Codable {
    let ruleId: String
    let ruleName: String
    let severity: LintSeverity
    let message: String
    let componentName: String?
    let nodeId: String?
    let suggestion: String?
}

/// Context provided to each lint rule for checking.
struct LintContext {
    /// The resolved PKL configuration.
    let config: ExFig.ModuleImpl
    /// Figma API client.
    let client: any FigmaAPI.Client
    /// Terminal UI for progress reporting.
    let ui: TerminalUI
}

/// Protocol for lint rules.
protocol LintRule: Sendable {
    /// Unique rule identifier (kebab-case).
    var id: String { get }
    /// Human-readable rule name.
    var name: String { get }
    /// Description of what this rule checks.
    var description: String { get }
    /// Default severity.
    var severity: LintSeverity { get }

    /// Run the check and return diagnostics (empty = all good).
    func check(context: LintContext) async throws -> [LintDiagnostic]
}
