import ExFigConfig
import ExFigCore
import FigmaAPI
import Foundation

/// Checks that component names match the nameValidateRegexp from config entries.
struct NamingConventionRule: LintRule {
    let id = "naming-convention"
    let name = "Naming conventions"
    let description = "Component names must match nameValidateRegexp patterns in config"
    let severity: LintSeverity = .error

    func check(context: LintContext) async throws -> [LintDiagnostic] {
        let config = context.config
        var diagnostics: [LintDiagnostic] = []
        let fileId = config.figma?.lightFileId ?? ""

        let entries = collectEntriesWithRegex(from: config, defaultFileId: fileId)
        guard !entries.isEmpty else { return [] }

        // Group by fileId
        let grouped = Dictionary(grouping: entries) { $0.fileId }

        for (entryFileId, fileEntries) in grouped {
            guard !entryFileId.isEmpty else { continue }

            let components: [Component]
            do {
                components = try await context.client.request(ComponentsEndpoint(fileId: entryFileId))
            } catch {
                continue
            }

            for entry in fileEntries {
                guard let pattern = entry.regex else { continue }
                let regex: NSRegularExpression
                do {
                    regex = try NSRegularExpression(pattern: pattern)
                } catch {
                    diagnostics.append(LintDiagnostic(
                        ruleId: id,
                        ruleName: name,
                        severity: .warning,
                        message: "Invalid regex pattern: '\(pattern)'",
                        componentName: nil,
                        nodeId: nil,
                        suggestion: "Fix the nameValidateRegexp in your PKL config"
                    ))
                    continue
                }

                // Filter components by frame name if specified
                let relevant = components.filter { comp in
                    if let frameName = entry.frameName {
                        return comp.containingFrame.name == frameName
                    }
                    return true
                }

                for comp in relevant {
                    let range = NSRange(comp.name.startIndex..., in: comp.name)
                    if regex.firstMatch(in: comp.name, range: range) == nil {
                        diagnostics.append(LintDiagnostic(
                            ruleId: id,
                            ruleName: name,
                            severity: .error,
                            message: "Name '\(comp.name)' doesn't match pattern '\(pattern)'",
                            componentName: comp.name,
                            nodeId: comp.nodeId,
                            suggestion: "Rename the component to match the expected pattern"
                        ))
                    }
                }
            }
        }

        return diagnostics
    }

    // MARK: - Entry Collection

    private struct RegexEntry {
        let fileId: String
        let frameName: String?
        let regex: String?
    }

    private func collectEntriesWithRegex(
        from config: PKLConfig,
        defaultFileId: String
    ) -> [RegexEntry] {
        var entries: [RegexEntry] = []

        func addEntries(_ icons: [some Common_FrameSource & Common_NameProcessing]?) {
            for entry in icons ?? [] where entry.nameValidateRegexp != nil {
                entries.append(RegexEntry(
                    fileId: entry.figmaFileId ?? defaultFileId,
                    frameName: entry.figmaFrameName,
                    regex: entry.nameValidateRegexp
                ))
            }
        }

        if let ios = config.ios {
            addEntries(ios.icons)
            addEntries(ios.images)
        }
        if let android = config.android {
            addEntries(android.icons)
            addEntries(android.images)
        }
        if let flutter = config.flutter {
            addEntries(flutter.icons)
        }
        if let web = config.web {
            addEntries(web.icons)
        }

        return entries
    }
}
