import ExFigConfig
import ExFigCore
import FigmaAPI
import Foundation

/// When variablesDarkMode is configured, checks that icon fills are bound to Variables.
/// Unbound (hardcoded hex) fills are silently skipped by VariableModeDarkGenerator.
struct DarkModeVariablesRule: LintRule {
    let id = "dark-mode-variables"
    let name = "Dark mode fills bound to variables"
    let description = "With variablesDarkMode, icon fills must be bound to Variables"
    let severity: LintSeverity = .error

    func check(context: LintContext) async throws -> [LintDiagnostic] {
        let config = context.config
        let defaultFileId = config.figma?.lightFileId ?? ""
        var diagnostics: [LintDiagnostic] = []

        let entries = collectVDMEntries(from: config, defaultFileId: defaultFileId)
        guard !entries.isEmpty else { return [] }

        for entry in entries {
            try await checkEntry(entry, context: context, diagnostics: &diagnostics)
        }

        return diagnostics
    }

    // MARK: - Per-Entry Check

    // swiftlint:disable function_body_length
    private func checkEntry(
        _ entry: VDMEntry,
        context: LintContext,
        diagnostics: inout [LintDiagnostic]
    ) async throws {
        guard !entry.fileId.isEmpty else {
            diagnostics.append(diagnostic(
                message: "No figma.lightFileId configured — skipping entry",
                suggestion: "Set figma.lightFileId in your PKL config"
            ))
            return
        }

        let components: [Component]
        do {
            components = try await context.cache.components(for: entry.fileId, client: context.client)
        } catch {
            diagnostics.append(diagnostic(
                severity: .error,
                message: "Cannot fetch components for file '\(entry.fileId)': \(error.localizedDescription)",
                suggestion: "Check FIGMA_PERSONAL_TOKEN and file permissions"
            ))
            return
        }

        let relevant = components.filter { comp in
            if let page = entry.pageName, comp.containingFrame.pageName != page { return false }
            if let frame = entry.frameName, comp.containingFrame.name != frame { return false }
            if comp.containingFrame.containingComponentSet != nil, comp.name.contains("RTL=") { return false }
            return true
        }

        // Sample to avoid excessive API calls (NodesEndpoint is rate-limited)
        let sampled = Array(relevant.prefix(50))
        if relevant.count > 50 {
            diagnostics.append(diagnostic(
                severity: .info,
                message: "Checked 50 of \(relevant.count) components (sampling for API limits)",
                suggestion: nil
            ))
        }
        guard !sampled.isEmpty else { return }

        let nodeIds = sampled.map(\.nodeId)
        let nodes: [NodeId: Node]
        do {
            nodes = try await context.client.request(NodesEndpoint(fileId: entry.fileId, nodeIds: nodeIds))
        } catch {
            diagnostics.append(diagnostic(
                severity: .error,
                message: "Cannot fetch nodes for file '\(entry.fileId)': \(error.localizedDescription)",
                suggestion: "Check FIGMA_PERSONAL_TOKEN and file permissions"
            ))
            return
        }

        for (nodeId, node) in nodes {
            let compName = sampled.first { $0.nodeId == nodeId }?.name ?? nodeId
            checkChildrenFills(
                children: node.document.children ?? [],
                componentName: compName,
                diagnostics: &diagnostics
            )
        }
    }

    // swiftlint:enable function_body_length

    // MARK: - Node Fill Checking

    /// Check fills only on leaf/vector nodes, not on the root component frame.
    /// Root frames often have background fills (#FFFFFF) that aren't meant to be variable-bound.
    private func checkChildrenFills(
        children: [Document],
        componentName: String,
        diagnostics: inout [LintDiagnostic]
    ) {
        for child in children {
            checkNodeFills(node: child, componentName: componentName, diagnostics: &diagnostics)
        }
    }

    private func checkNodeFills(
        node: Document,
        componentName: String,
        diagnostics: inout [LintDiagnostic]
    ) {
        for fill in node.fills {
            if fill.type == .image { continue }
            if fill.opacity == 0 { continue }

            if fill.boundVariables == nil || fill.boundVariables?["color"] == nil {
                let colorDesc: String = if let color = fill.color {
                    String(
                        format: "#%02X%02X%02X",
                        Int(color.r * 255),
                        Int(color.g * 255),
                        Int(color.b * 255)
                    )
                } else {
                    fill.type.rawValue
                }

                diagnostics.append(diagnostic(
                    severity: .error,
                    message: "Fill \(colorDesc) in '\(componentName)' not bound to Variable",
                    componentName: componentName,
                    nodeId: node.id,
                    suggestion: "Bind this fill to a color Variable for dark mode generation"
                ))
            }
        }

        for child in node.children ?? [] {
            checkNodeFills(node: child, componentName: componentName, diagnostics: &diagnostics)
        }
    }

    // MARK: - Entry Collection

    private struct VDMEntry {
        let fileId: String
        let frameName: String?
        let pageName: String?
    }

    private func collectVDMEntries(from config: ExFig.ModuleImpl, defaultFileId: String) -> [VDMEntry] {
        var entries: [VDMEntry] = []

        func addIcons(_ icons: [some Common_FrameSource]?) {
            for entry in icons ?? [] where entry.variablesDarkMode != nil {
                entries.append(VDMEntry(
                    fileId: entry.figmaFileId ?? defaultFileId,
                    frameName: entry.figmaFrameName,
                    pageName: entry.figmaPageName
                ))
            }
        }

        if let ios = config.ios { addIcons(ios.icons) }
        if let android = config.android { addIcons(android.icons) }
        if let flutter = config.flutter { addIcons(flutter.icons) }
        if let web = config.web { addIcons(web.icons) }

        return entries
    }
}
