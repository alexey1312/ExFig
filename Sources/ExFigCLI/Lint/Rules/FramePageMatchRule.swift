import ExFigConfig
import ExFigCore
import FigmaAPI
import Foundation

/// Checks that frame and page names from the config exist in the Figma file.
/// Uses the Components API to discover available frame/page names.
struct FramePageMatchRule: LintRule {
    let id = "frame-page-match"
    let name = "Frame/page names match"
    let description = "Frame and page names in config must exist in the Figma file"
    let severity: LintSeverity = .error

    func check(context: LintContext) async throws -> [LintDiagnostic] {
        let entries = collectEntries(from: context.config)
        guard !entries.isEmpty else { return [] }

        var diagnostics: [LintDiagnostic] = []
        let grouped = Dictionary(grouping: entries) { $0.fileId }

        for (fileId, fileEntries) in grouped {
            guard !fileId.isEmpty else { continue }
            let result = try await checkFile(fileId: fileId, entries: fileEntries, client: context.client)
            diagnostics.append(contentsOf: result)
        }

        return diagnostics
    }

    // MARK: - Per-File Check

    private func checkFile(
        fileId: String,
        entries: [EntryInfo],
        client: any FigmaAPI.Client
    ) async throws -> [LintDiagnostic] {
        let components: [Component]
        do {
            components = try await client.request(ComponentsEndpoint(fileId: fileId))
        } catch {
            return [LintDiagnostic(
                ruleId: id, ruleName: name, severity: .error,
                message: "Cannot access Figma file '\(fileId)': \(error.localizedDescription)",
                componentName: nil, nodeId: nil,
                suggestion: "Check FIGMA_PERSONAL_TOKEN and file permissions"
            )]
        }

        let pageNames = Set(components.compactMap(\.containingFrame.pageName))
        let frameNames = Set(components.compactMap(\.containingFrame.name))
        var framesByPage: [String: Set<String>] = [:]
        for comp in components {
            if let page = comp.containingFrame.pageName, let frame = comp.containingFrame.name {
                framesByPage[page, default: []].insert(frame)
            }
        }

        return entries.flatMap { entry in
            validateEntry(entry, pageNames: pageNames, frameNames: frameNames, framesByPage: framesByPage)
        }
    }

    private func validateEntry(
        _ entry: EntryInfo,
        pageNames: Set<String>,
        frameNames: Set<String>,
        framesByPage: [String: Set<String>]
    ) -> [LintDiagnostic] {
        var diagnostics: [LintDiagnostic] = []

        if let pageName = entry.pageName, !pageNames.contains(pageName) {
            diagnostics.append(LintDiagnostic(
                ruleId: id, ruleName: name, severity: .error,
                message: "Page '\(pageName)' not found in Figma file",
                componentName: nil, nodeId: nil,
                suggestion: "Available pages: \(pageNames.sorted().joined(separator: ", "))"
            ))
        }

        if let frameName = entry.frameName {
            if let pageName = entry.pageName {
                let pageFrames = framesByPage[pageName] ?? []
                if !pageFrames.contains(frameName) {
                    diagnostics.append(LintDiagnostic(
                        ruleId: id, ruleName: name, severity: .error,
                        message: "Frame '\(frameName)' not found on page '\(pageName)'",
                        componentName: nil, nodeId: nil,
                        suggestion: "Available frames on '\(pageName)': "
                            + "\(pageFrames.sorted().joined(separator: ", "))"
                    ))
                }
            } else if !frameNames.contains(frameName) {
                diagnostics.append(LintDiagnostic(
                    ruleId: id, ruleName: name, severity: .error,
                    message: "Frame '\(frameName)' not found in any page",
                    componentName: nil, nodeId: nil,
                    suggestion: "Available frames: \(frameNames.sorted().joined(separator: ", "))"
                ))
            }
        }

        return diagnostics
    }

    // MARK: - Entry Collection

    private struct EntryInfo {
        let fileId: String
        let frameName: String?
        let pageName: String?
    }

    private func collectEntries(from config: ExFig.ModuleImpl) -> [EntryInfo] {
        var entries: [EntryInfo] = []
        let fileId = config.figma?.lightFileId ?? ""

        func addIconEntries(_ icons: [some Common_FrameSource]?) {
            for entry in icons ?? [] {
                entries.append(EntryInfo(
                    fileId: entry.figmaFileId ?? fileId,
                    frameName: entry.figmaFrameName,
                    pageName: entry.figmaPageName
                ))
            }
        }

        if let ios = config.ios {
            addIconEntries(ios.icons)
            addIconEntries(ios.images)
        }
        if let android = config.android {
            addIconEntries(android.icons)
            addIconEntries(android.images)
        }
        if let flutter = config.flutter {
            addIconEntries(flutter.icons)
            addIconEntries(flutter.images)
        }
        if let web = config.web {
            addIconEntries(web.icons)
        }

        return entries
    }
}
