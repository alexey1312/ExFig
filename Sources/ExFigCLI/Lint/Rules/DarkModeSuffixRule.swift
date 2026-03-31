import ExFigConfig
import ExFigCore
import FigmaAPI
import Foundation

/// When suffixDarkMode is configured, checks that each light component has a matching dark pair.
/// Only checks components within frames configured for export, not all components in the file.
struct DarkModeSuffixRule: LintRule {
    let id = "dark-mode-suffix"
    let name = "Dark mode suffix pairs"
    let description = "With suffixDarkMode, each light component needs a matching dark pair"
    let severity: LintSeverity = .warning

    func check(context: LintContext) async throws -> [LintDiagnostic] {
        let config = context.config

        let suffix: String
        if let sdm = config.common?.icons?.suffixDarkMode {
            suffix = sdm.suffix
        } else if let sdm = config.common?.images?.suffixDarkMode {
            suffix = sdm.suffix
        } else {
            return []
        }

        let defaultFileId = config.figma?.lightFileId ?? ""
        guard !defaultFileId.isEmpty else {
            return [diagnostic(
                message: "No figma.lightFileId configured — skipping rule",
                suggestion: "Set figma.lightFileId in your PKL config"
            )]
        }

        let components: [Component]
        do {
            components = try await context.cache.components(for: defaultFileId, client: context.client)
        } catch {
            return [diagnostic(
                severity: .error,
                message: "Cannot fetch components for file '\(defaultFileId)': \(error.localizedDescription)",
                suggestion: "Check FIGMA_PERSONAL_TOKEN and file permissions"
            )]
        }

        let configuredEntries = collectConfiguredEntries(from: config)
        let relevant = filterRelevantComponents(components, entries: configuredEntries)
        return checkDarkPairs(relevant: relevant, suffix: suffix)
    }

    // MARK: - Filtering

    private func filterRelevantComponents(
        _ components: [Component],
        entries: [FrameEntry]
    ) -> [Component] {
        components.filter { comp in
            guard let frameName = comp.containingFrame.name else { return false }
            if comp.containingFrame.containingComponentSet != nil,
               comp.name.contains("RTL=")
            {
                return false
            }
            return entries.contains { entry in
                if entry.frameName != frameName { return false }
                if let pageName = entry.pageName, comp.containingFrame.pageName != pageName {
                    return false
                }
                return true
            }
        }
    }

    private func checkDarkPairs(relevant: [Component], suffix: String) -> [LintDiagnostic] {
        let relevantNames = Set(relevant.map(\.name))
        var diagnostics: [LintDiagnostic] = []

        for component in relevant {
            if component.name.hasSuffix(suffix) { continue }

            let expectedDark = component.name + suffix
            if !relevantNames.contains(expectedDark) {
                diagnostics.append(diagnostic(
                    message: "'\(component.name)' has no dark pair '\(expectedDark)'",
                    componentName: component.name,
                    nodeId: component.nodeId,
                    suggestion: "Create a component named '\(expectedDark)'"
                ))
            }
        }

        return diagnostics
    }

    // MARK: - Entry Collection

    private struct FrameEntry {
        let frameName: String
        let pageName: String?
    }

    private func collectConfiguredEntries(from config: ExFig.ModuleImpl) -> [FrameEntry] {
        var entries: [FrameEntry] = []

        func add(_ icons: [some Common_FrameSource]?) {
            for entry in icons ?? [] {
                if let frame = entry.figmaFrameName {
                    entries.append(FrameEntry(frameName: frame, pageName: entry.figmaPageName))
                }
            }
        }

        if let ios = config.ios {
            add(ios.icons)
            add(ios.images)
        }
        if let android = config.android {
            add(android.icons)
            add(android.images)
        }
        if let flutter = config.flutter {
            add(flutter.icons)
            add(flutter.images)
        }
        if let web = config.web {
            add(web.icons)
        }

        return entries
    }
}
