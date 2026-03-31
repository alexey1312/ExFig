import Foundation

/// Engine that runs lint rules against a PKL configuration.
struct LintEngine {
    /// All registered lint rules.
    let rules: [any LintRule]

    /// Run all applicable rules (or filtered subset) and return diagnostics.
    func run(
        context: LintContext,
        ruleFilter: Set<String>? = nil,
        minSeverity: LintSeverity = .info
    ) async throws -> [LintDiagnostic] {
        let applicableRules = rules.filter { rule in
            if let filter = ruleFilter, !filter.contains(rule.id) {
                return false
            }
            return severityRank(rule.severity) >= severityRank(minSeverity)
        }

        var allDiagnostics: [LintDiagnostic] = []

        for rule in applicableRules {
            do {
                let diagnostics = try await rule.check(context: context)
                allDiagnostics.append(contentsOf: diagnostics)
            } catch {
                // Rule failure becomes an info diagnostic
                allDiagnostics.append(LintDiagnostic(
                    ruleId: rule.id,
                    ruleName: rule.name,
                    severity: .info,
                    message: "Rule check failed: \(error.localizedDescription)",
                    componentName: nil,
                    nodeId: nil,
                    suggestion: nil
                ))
            }
        }

        return allDiagnostics
    }

    private func severityRank(_ severity: LintSeverity) -> Int {
        switch severity {
        case .error: 2
        case .warning: 1
        case .info: 0
        }
    }
}

extension LintEngine {
    /// Default engine with all built-in rules.
    static let `default` = LintEngine(rules: [
        FramePageMatchRule(),
        NamingConventionRule(),
        ComponentNotFrameRule(),
        DeletedVariablesRule(),
        AliasChainIntegrityRule(),
        DarkModeVariablesRule(),
        DarkModeSuffixRule(),
    ])
}
