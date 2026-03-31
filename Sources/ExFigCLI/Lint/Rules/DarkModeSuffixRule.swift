import ExFigConfig
import ExFigCore
import FigmaAPI
import Foundation

/// When suffixDarkMode is configured, checks that each light component has a matching dark pair.
struct DarkModeSuffixRule: LintRule {
    let id = "dark-mode-suffix"
    let name = "Dark mode suffix pairs"
    let description = "With suffixDarkMode, each light component needs a matching dark pair"
    let severity: LintSeverity = .warning

    func check(context: LintContext) async throws -> [LintDiagnostic] {
        let config = context.config
        var diagnostics: [LintDiagnostic] = []

        // Check if suffixDarkMode is configured
        let suffix: String
        if let sdm = config.common?.icons?.suffixDarkMode {
            suffix = sdm.suffix
        } else if let sdm = config.common?.images?.suffixDarkMode {
            suffix = sdm.suffix
        } else {
            return []
        }

        let fileId = config.figma?.lightFileId ?? ""
        guard !fileId.isEmpty else { return [] }

        let components: [Component]
        do {
            components = try await context.client.request(ComponentsEndpoint(fileId: fileId))
        } catch {
            return []
        }

        let allNames = Set(components.map(\.name))

        for component in components {
            if component.name.hasSuffix(suffix) { continue }

            let expectedDark = component.name + suffix
            if !allNames.contains(expectedDark) {
                diagnostics.append(LintDiagnostic(
                    ruleId: id,
                    ruleName: name,
                    severity: .warning,
                    message: "'\(component.name)' has no dark pair '\(expectedDark)'",
                    componentName: component.name,
                    nodeId: component.nodeId,
                    suggestion: "Create a component named '\(expectedDark)'"
                ))
            }
        }

        return diagnostics
    }
}
