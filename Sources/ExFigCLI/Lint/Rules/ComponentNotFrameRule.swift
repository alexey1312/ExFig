import ExFigConfig
import ExFigCore
import FigmaAPI
import Foundation

/// Checks that exported icons/images are Figma components (not plain frames).
/// If a frame configured for export has zero published components, it likely contains
/// plain frames instead of components.
struct ComponentNotFrameRule: LintRule {
    let id = "component-not-frame"
    let name = "Assets are components"
    let description = "Configured frames must contain published components"
    let severity: LintSeverity = .error

    func check(context: LintContext) async throws -> [LintDiagnostic] {
        let config = context.config
        let defaultFileId = config.figma?.lightFileId ?? ""

        var diagnostics: [LintDiagnostic] = []

        // Collect frame names from config
        let entries = collectFrameEntries(from: config, defaultFileId: defaultFileId)
        guard !entries.isEmpty else { return [] }

        let grouped = Dictionary(grouping: entries) { $0.fileId }

        for (fileId, fileEntries) in grouped {
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

            for entry in fileEntries {
                guard let frameName = entry.frameName else { continue }

                let matchingComponents = components.filter { comp in
                    let frameMatch = comp.containingFrame.name == frameName
                    if let pageName = entry.pageName {
                        return frameMatch && comp.containingFrame.pageName == pageName
                    }
                    return frameMatch
                }

                if matchingComponents.isEmpty {
                    diagnostics.append(diagnostic(
                        severity: .error,
                        message: "Frame '\(frameName)' has no published components",
                        suggestion: "Convert frames to Components (⌥⌘K) and publish to Team Library"
                    ))
                }
            }
        }

        return diagnostics
    }

    private struct FrameEntry {
        let fileId: String
        let frameName: String?
        let pageName: String?
    }

    private func collectFrameEntries(from config: PKLConfig, defaultFileId: String) -> [FrameEntry] {
        var entries: [FrameEntry] = []

        func add(_ icons: [some Common_FrameSource]?) {
            for entry in icons ?? [] {
                entries.append(FrameEntry(
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
