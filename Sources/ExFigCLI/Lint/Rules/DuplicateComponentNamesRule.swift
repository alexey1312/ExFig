import ExFigConfig
import ExFigCore
import FigmaAPI
import Foundation

/// Checks for duplicate component names within configured frames/pages.
/// Duplicate names cause one to silently overwrite the other during export,
/// which is especially dangerous for dark mode pairs.
struct DuplicateComponentNamesRule: LintRule {
    let id = "duplicate-component-names"
    let name = "Duplicate component names"
    let description = "No duplicate component names in configured frames"
    let severity: LintSeverity = .error

    func check(context: LintContext) async throws -> [LintDiagnostic] {
        let config = context.config
        let defaultFileId = config.figma?.lightFileId ?? ""

        let configEntries = collectConfiguredEntries(from: config, defaultFileId: defaultFileId)
        guard !configEntries.isEmpty else { return [] }

        var diagnostics: [LintDiagnostic] = []
        let grouped = Dictionary(grouping: configEntries) { $0.fileId }

        for (fileId, entries) in grouped {
            guard !fileId.isEmpty else {
                diagnostics.append(diagnostic(
                    message: "No figma.lightFileId configured — skipping rule",
                    suggestion: "Set figma.lightFileId in your PKL config"
                ))
                continue
            }

            let components: [Component]
            do {
                components = try await context.cache.components(for: fileId, client: context.client)
            } catch {
                diagnostics.append(diagnostic(
                    severity: .error,
                    message: "Cannot fetch components for file '\(fileId)': \(error.localizedDescription)",
                    suggestion: "Check FIGMA_PERSONAL_TOKEN and file permissions"
                ))
                continue
            }

            checkFileComponents(components, entries: entries, diagnostics: &diagnostics)
        }

        return diagnostics
    }

    private func checkFileComponents(
        _ components: [Component],
        entries: [ConfigEntry],
        diagnostics: inout [LintDiagnostic]
    ) {
        // Filter to only components matching configured frame/page pairs
        // Skip RTL variants — they share names across component sets
        let relevant = components.filter { comp in
            if comp.containingFrame.containingComponentSet != nil,
               comp.name.contains("RTL=")
            {
                return false
            }
            return entries.contains { entry in
                matchesEntry(comp: comp, entry: entry)
            }
        }

        // Deduplicate variants: collapse all variants of the same component set
        // into one representative (variants share iconName but differ in comp.name)
        var uniqueBySource: [String: Component] = [:]
        for comp in relevant {
            let sourceId = comp.containingFrame.containingComponentSet?.nodeId ?? comp.nodeId
            if uniqueBySource[sourceId] == nil {
                uniqueBySource[sourceId] = comp
            }
        }

        // Group by (pageName, iconName) to find duplicates
        var seen: [String: [Component]] = [:]
        for comp in uniqueBySource.values {
            let page = comp.containingFrame.pageName ?? "(unknown)"
            let key = "\(page)|\(comp.iconName)"
            seen[key, default: []].append(comp)
        }

        for (key, duplicates) in seen where duplicates.count > 1 {
            let parts = key.split(separator: "|", maxSplits: 1)
            let page = parts.first.map(String.init) ?? "(unknown)"
            let compName = parts.count > 1 ? String(parts[1]) : key
            let frames = duplicates.compactMap(\.containingFrame.name)
                .map { "'\($0)'" }
            let uniqueFrames = Array(Set(frames)).sorted()

            diagnostics.append(diagnostic(
                severity: .error,
                message: "'\(compName)' appears \(duplicates.count)x on page '\(page)'"
                    + (uniqueFrames.count > 1 ? " in \(uniqueFrames.joined(separator: ", "))" : ""),
                componentName: compName,
                nodeId: duplicates.first?.nodeId,
                suggestion: "Rename duplicates or move to different pages"
            ))
        }
    }

    private func matchesEntry(comp: Component, entry: ConfigEntry) -> Bool {
        if let page = entry.pageName, comp.containingFrame.pageName != page {
            return false
        }
        if let frame = entry.frameName, comp.containingFrame.name != frame {
            return false
        }
        return true
    }

    private struct ConfigEntry {
        let fileId: String
        let frameName: String?
        let pageName: String?
    }

    private func collectConfiguredEntries(
        from config: ExFig.ModuleImpl,
        defaultFileId: String
    ) -> [ConfigEntry] {
        var entries: [ConfigEntry] = []

        func add(_ icons: [some Common_FrameSource]?) {
            for entry in icons ?? [] {
                entries.append(ConfigEntry(
                    fileId: entry.figmaFileId ?? defaultFileId,
                    frameName: entry.figmaFrameName,
                    pageName: entry.figmaPageName
                ))
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
