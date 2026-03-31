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

        let grouped = Dictionary(grouping: entries) { $0.fileId }

        for (entryFileId, fileEntries) in grouped {
            guard !entryFileId.isEmpty else {
                diagnostics.append(diagnostic(
                    message: "No figma.lightFileId configured — skipping rule",
                    suggestion: "Set figma.lightFileId in your PKL config"
                ))
                continue
            }

            let components: [Component]
            do {
                components = try await context.cache.components(for: entryFileId, client: context.client)
            } catch {
                diagnostics.append(diagnostic(
                    severity: .error,
                    message: "Cannot fetch components for file '\(entryFileId)': \(error.localizedDescription)",
                    suggestion: "Check FIGMA_PERSONAL_TOKEN and file permissions"
                ))
                continue
            }

            for entry in fileEntries {
                checkEntry(entry, components: components, diagnostics: &diagnostics)
            }
        }

        return diagnostics
    }

    // MARK: - Per-Entry Check

    private func checkEntry(
        _ entry: RegexEntry,
        components: [Component],
        diagnostics: inout [LintDiagnostic]
    ) {
        guard let pattern = entry.regex else { return }
        let regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern)
        } catch {
            diagnostics.append(diagnostic(
                severity: .warning,
                message: "Invalid regex pattern: '\(pattern)'",
                suggestion: "Fix the nameValidateRegexp in your PKL config"
            ))
            return
        }

        let relevant = components.filter { comp in
            if let pageName = entry.pageName, comp.containingFrame.pageName != pageName {
                return false
            }
            if let frameName = entry.frameName {
                return comp.containingFrame.name == frameName
            }
            return true
        }

        for comp in relevant {
            let range = NSRange(comp.name.startIndex..., in: comp.name)
            if regex.firstMatch(in: comp.name, range: range) == nil {
                diagnostics.append(diagnostic(
                    severity: .error,
                    message: "Name '\(comp.name)' doesn't match pattern '\(pattern)'",
                    componentName: comp.name,
                    nodeId: comp.nodeId,
                    suggestion: "Rename the component to match the expected pattern"
                ))
            }
        }
    }

    // MARK: - Entry Collection

    private struct RegexEntry {
        let fileId: String
        let frameName: String?
        let pageName: String?
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
                    pageName: entry.figmaPageName,
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
            addEntries(flutter.images)
        }
        if let web = config.web {
            addEntries(web.icons)
        }

        return entries
    }
}
