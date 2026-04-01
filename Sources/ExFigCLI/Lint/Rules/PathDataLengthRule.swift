import ExFigConfig
import ExFigCore
import FigmaAPI
import Foundation
import SVGKit

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Checks that icon SVG paths don't exceed the AAPT 32,767-byte pathData limit.
///
/// Fetches SVGs via Figma Images API and validates pathData lengths using SVGKit.
/// Checks icons from all platform entries (iOS, Android, Flutter, Web).
struct PathDataLengthRule: LintRule {
    let id = "path-data-length"
    let name = "PathData length within Android limits"
    let description = "Icon SVG paths must not exceed 32,767 bytes (Android AAPT limit)"
    let severity: LintSeverity = .error

    /// Maximum node IDs per ImageEndpoint batch.
    private static let batchSize = 50

    /// Maximum concurrent SVG downloads.
    private static let maxConcurrentDownloads = 10

    func check(context: LintContext) async throws -> [LintDiagnostic] {
        let config = context.config
        let defaultFileId = config.figma?.lightFileId ?? ""

        let entries = collectIconEntries(from: config, defaultFileId: defaultFileId)
        guard !entries.isEmpty else { return [] }

        // Group entries by fileId to minimize API calls
        let grouped = Dictionary(grouping: entries) { $0.fileId }

        // Check each fileId concurrently
        return try await withThrowingTaskGroup(of: [LintDiagnostic].self) { group in
            for (fileId, fileEntries) in grouped {
                group.addTask {
                    try await checkFileEntries(
                        fileEntries, fileId: fileId, context: context
                    )
                }
            }
            var allDiagnostics: [LintDiagnostic] = []
            for try await diagnostics in group {
                allDiagnostics.append(contentsOf: diagnostics)
            }
            return allDiagnostics
        }
    }

    // MARK: - Per-File Check

    // swiftlint:disable function_body_length
    private func checkFileEntries(
        _ entries: [IconEntry],
        fileId: String,
        context: LintContext
    ) async throws -> [LintDiagnostic] {
        var diagnostics: [LintDiagnostic] = []

        guard !fileId.isEmpty else {
            diagnostics.append(diagnostic(
                message: "No figma.lightFileId configured — skipping pathData check",
                suggestion: "Set figma.lightFileId in your PKL config"
            ))
            return diagnostics
        }

        // Fetch components once per fileId (shared cache with other rules)
        let components: [Component]
        do {
            components = try await context.cache.components(for: fileId, client: context.client)
        } catch {
            diagnostics.append(diagnostic(
                severity: .error,
                message: "Cannot fetch components for file '\(fileId)': \(error.localizedDescription)",
                suggestion: "Check FIGMA_PERSONAL_TOKEN and file permissions"
            ))
            return diagnostics
        }

        // Filter components by all entries' frame/page configs, deduplicate
        let relevantComponents = collectRelevantComponents(from: components, entries: entries)
        guard !relevantComponents.isEmpty else { return diagnostics }

        // Fetch SVG URLs via ImageEndpoint in batches
        let svgItems = try await fetchSVGURLs(
            components: relevantComponents, fileId: fileId,
            context: context, diagnostics: &diagnostics
        )
        guard !svgItems.isEmpty else { return diagnostics }

        // Download SVGs and validate pathData
        let validationDiags = try await downloadAndValidate(svgItems: svgItems)
        diagnostics.append(contentsOf: validationDiags)

        return diagnostics
    }

    // swiftlint:enable function_body_length

    // MARK: - SVG URL Fetching

    private func fetchSVGURLs(
        components: [Component],
        fileId: String,
        context: LintContext,
        diagnostics: inout [LintDiagnostic]
    ) async throws -> [SVGItem] {
        var results: [SVGItem] = []

        let batches = stride(from: 0, to: components.count, by: Self.batchSize).map {
            Array(components[$0 ..< min($0 + Self.batchSize, components.count)])
        }

        for batch in batches {
            let nodeIds = batch.map(\.nodeId)

            let imageURLs: [NodeId: ImagePath?]
            do {
                imageURLs = try await context.client.request(
                    ImageEndpoint(fileId: fileId, nodeIds: nodeIds, params: SVGParams())
                )
            } catch {
                let batchNames = batch.prefix(5).map(\.iconName).joined(separator: ", ")
                let suffix = batch.count > 5 ? " and \(batch.count - 5) more" : ""
                let msg = "Cannot fetch SVG URLs for \(batch.count) icon(s) "
                    + "(\(batchNames)\(suffix)): \(error.localizedDescription)"
                diagnostics.append(diagnostic(
                    severity: .warning,
                    message: msg,
                    suggestion: "Check FIGMA_PERSONAL_TOKEN and file permissions"
                ))
                continue
            }

            var missingURLNames: [String] = []
            for comp in batch {
                if let urlOpt = imageURLs[comp.nodeId], let url = urlOpt {
                    results.append(SVGItem(
                        name: comp.iconName, nodeId: comp.nodeId, url: url
                    ))
                } else {
                    missingURLNames.append(comp.iconName)
                }
            }
            if !missingURLNames.isEmpty {
                let names = missingURLNames.prefix(5).joined(separator: ", ")
                let suffix = missingURLNames.count > 5 ? " and \(missingURLNames.count - 5) more" : ""
                diagnostics.append(diagnostic(
                    severity: .warning,
                    message: "Figma returned no SVG URL for \(missingURLNames.count) icon(s): \(names)\(suffix)",
                    suggestion: "These icons could not be rendered — check they are not empty components"
                ))
            }
        }

        return results
    }

    // MARK: - Download & Validate

    private func downloadAndValidate(
        svgItems: [SVGItem]
    ) async throws -> [LintDiagnostic] {
        try await withThrowingTaskGroup(of: [LintDiagnostic].self) { group in
            var iterator = svgItems.makeIterator()
            var allDiagnostics: [LintDiagnostic] = []
            let initialBatch = min(Self.maxConcurrentDownloads, svgItems.count)

            for _ in 0 ..< initialBatch {
                if let item = iterator.next() {
                    group.addTask { [item] in
                        await validateSingleIcon(item: item)
                    }
                }
            }

            for try await diags in group {
                allDiagnostics.append(contentsOf: diags)
                if let item = iterator.next() {
                    group.addTask { [item] in
                        await validateSingleIcon(item: item)
                    }
                }
            }

            return allDiagnostics
        }
    }

    private func validateSingleIcon(item: SVGItem) async -> [LintDiagnostic] {
        guard let url = URL(string: item.url) else {
            return [diagnostic(
                severity: .warning,
                message: "Invalid SVG URL for '\(item.name)' — cannot validate pathData",
                componentName: item.name,
                nodeId: item.nodeId,
                suggestion: "Re-run lint; if persistent, the Figma API may be returning malformed URLs"
            )]
        }

        let svgData: Data
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            svgData = data
        } catch {
            return [diagnostic(
                severity: .warning,
                message: "Cannot download SVG for '\(item.name)': \(error.localizedDescription)",
                componentName: item.name,
                nodeId: item.nodeId,
                suggestion: "Check network connectivity"
            )]
        }

        let svg: ParsedSVG
        do {
            svg = try SVGParser().parse(svgData)
        } catch {
            return [diagnostic(
                severity: .warning,
                message: "Cannot parse SVG for '\(item.name)': \(error.localizedDescription)",
                componentName: item.name,
                nodeId: item.nodeId
            )]
        }

        return validateParsedSVG(svg, name: item.name, nodeId: item.nodeId)
    }

    /// Validates a parsed SVG and returns diagnostics for critical pathData issues.
    /// Internal for testability.
    func validateParsedSVG(_ svg: ParsedSVG, name: String, nodeId: String) -> [LintDiagnostic] {
        let issues = PathDataValidator().validate(svg: svg, iconName: name)

        // Only report critical issues (>32,767 bytes) — the 800-char lint threshold
        // is too noisy for most icon sets (flags, illustrations regularly exceed it)
        return issues.compactMap { issue in
            guard issue.isCritical else { return nil }
            return diagnostic(
                severity: .error,
                message: """
                pathData exceeds 32,767 bytes (\(issue.result.byteLength) bytes) \
                in \(name)/\(issue.pathName). \
                This will cause STRING_TOO_LARGE error during Android build.
                """,
                componentName: name,
                nodeId: nodeId,
                suggestion: "Simplify the path in Figma or use raster format (PNG/WebP)"
            )
        }
    }

    // MARK: - Types

    private struct SVGItem {
        let name: String
        let nodeId: String
        let url: String
    }

    private struct IconEntry {
        let fileId: String
        let frameName: String?
        let pageName: String?
    }

    // MARK: - Entry Collection

    private func collectIconEntries(
        from config: ExFig.ModuleImpl,
        defaultFileId: String
    ) -> [IconEntry] {
        var entries: [IconEntry] = []

        func addIcons(_ icons: [some Common_FrameSource]?) {
            for entry in icons ?? [] {
                entries.append(IconEntry(
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

        // Deduplicate entries with same fileId + frame + page
        var seen = Set<String>()
        return entries.filter { entry in
            let key = "\(entry.fileId)|\(entry.frameName ?? "")|\(entry.pageName ?? "")"
            return seen.insert(key).inserted
        }
    }

    /// Filters components matching any entry's frame/page, deduplicates variants.
    private func collectRelevantComponents(
        from components: [Component],
        entries: [IconEntry]
    ) -> [Component] {
        let filtered = components.filter { comp in
            // Skip RTL variants
            if comp.containingFrame.containingComponentSet != nil, comp.name.contains("RTL=") {
                return false
            }

            // Must match at least one entry's frame/page filter
            return entries.contains { entry in
                if let page = entry.pageName, comp.containingFrame.pageName != page { return false }
                if let frame = entry.frameName, comp.containingFrame.name != frame { return false }
                return true
            }
        }

        // Deduplicate variants by component set
        var seen = Set<String>()
        return filtered.filter { comp in
            let key = comp.containingFrame.containingComponentSet?.nodeId ?? comp.nodeId
            return seen.insert(key).inserted
        }
    }
}
