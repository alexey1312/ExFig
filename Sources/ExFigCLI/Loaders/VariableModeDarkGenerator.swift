import ExFigCore
import FigmaAPI
import Foundation
import Logging

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Generates dark SVG variants from light SVGs by resolving Figma Variable bindings.
///
/// Given light icon packs and a variables collection with light/dark modes, this generator:
/// 1. Fetches variable definitions from the Figma Variables API
/// 2. Fetches icon nodes to discover `boundVariables` on fills/strokes
/// 3. Resolves each variable's dark mode value (following alias chains)
/// 4. Downloads light SVGs, replaces hex colors, and writes dark SVGs to temp files
struct VariableModeDarkGenerator {
    struct Config {
        let fileId: String
        let collectionName: String
        let lightModeName: String
        let darkModeName: String
        let primitivesModeName: String?
    }

    /// Resolved mode IDs for variable resolution.
    private struct ModeContext {
        let lightModeId: String
        let darkModeId: String
        let primitivesModeId: String?
    }

    private let client: Client
    private let logger: Logger

    init(client: Client, logger: Logger) {
        self.client = client
        self.logger = logger
    }

    /// Generates dark SVG variants by resolving variable bindings and replacing colors.
    ///
    /// - Parameters:
    ///   - lightPacks: Light mode icon packs (must be SVG format with Figma URLs).
    ///   - config: Variables collection configuration.
    /// - Returns: Dark mode icon packs with modified SVGs saved to temp files.
    func generateDarkVariants(
        lightPacks: [ImagePack],
        config: Config
    ) async throws -> [ImagePack] {
        guard !lightPacks.isEmpty else { return [] }

        // 1. Fetch variable definitions
        let variablesMeta = try await loadVariables(fileId: config.fileId)

        // 2. Find collection and extract mode IDs
        guard let modes = findModeIds(in: variablesMeta, config: config) else {
            logger.warning("Variables collection '\(config.collectionName)' not found or missing modes")
            return []
        }

        // 3. Fetch nodes to discover boundVariables on paints
        let nodeIds = lightPacks.compactMap(\.nodeId)

        guard !nodeIds.isEmpty else { return [] }

        let nodeMap = try await fetchNodesBatched(fileId: config.fileId, nodeIds: nodeIds)

        // 4. For each icon, build light→dark color map from boundVariables
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("exfig-variable-dark-\(ProcessInfo.processInfo.processIdentifier)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        var darkPacks: [ImagePack] = []

        for pack in lightPacks {
            guard let nodeId = pack.nodeId,
                  let node = nodeMap[nodeId]
            else { continue }

            // Collect all bound variable colors from the node tree
            let colorMap = buildColorMap(
                node: node,
                variablesMeta: variablesMeta,
                modes: modes
            )

            guard !colorMap.isEmpty else {
                // No bound variables — skip dark generation for this icon
                continue
            }

            // Download light SVG and replace colors
            guard let svgImage = pack.images.first,
                  let svgData = try? Data(contentsOf: svgImage.url),
                  let svgContent = String(data: svgData, encoding: .utf8)
            else { continue }

            let darkSVG = SVGColorReplacer.replaceColors(in: svgContent, colorMap: colorMap)

            // Write dark SVG to temp file
            let safeName = pack.name
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: " ", with: "_")
            let tempURL = tempDir.appendingPathComponent("\(safeName)_dark.svg")
            try Data(darkSVG.utf8).write(to: tempURL)

            darkPacks.append(ImagePack(
                name: pack.name,
                images: [Image(
                    name: pack.name,
                    scale: .all,
                    url: tempURL,
                    format: "svg"
                )],
                platform: pack.platform,
                nodeId: pack.nodeId,
                fileId: pack.fileId
            ))
        }

        return darkPacks
    }

    // MARK: - Private

    private func loadVariables(fileId: String) async throws -> VariablesMeta {
        let endpoint = VariablesEndpoint(fileId: fileId)
        return try await client.request(endpoint)
    }

    private func findModeIds(in meta: VariablesMeta, config: Config) -> ModeContext? {
        for collection in meta.variableCollections.values {
            guard collection.name == config.collectionName else { continue }

            var lightModeId: String?
            var darkModeId: String?
            var primitivesModeId: String?

            for mode in collection.modes {
                if mode.name == config.lightModeName {
                    lightModeId = mode.modeId
                } else if mode.name == config.darkModeName {
                    darkModeId = mode.modeId
                } else if mode.name == config.primitivesModeName {
                    primitivesModeId = mode.modeId
                }
            }

            guard let light = lightModeId, let dark = darkModeId else { continue }
            return ModeContext(lightModeId: light, darkModeId: dark, primitivesModeId: primitivesModeId)
        }
        return nil
    }

    /// Fetches nodes in batches of 100 (Figma API limit).
    private func fetchNodesBatched(
        fileId: String,
        nodeIds: [String]
    ) async throws -> [String: Node] {
        var allNodes: [String: Node] = [:]
        let batchSize = 100

        for batchStart in stride(from: 0, to: nodeIds.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, nodeIds.count)
            let batch = Array(nodeIds[batchStart ..< batchEnd])
            let endpoint = NodesEndpoint(fileId: fileId, nodeIds: batch)
            let nodes = try await client.request(endpoint)
            for (key, value) in nodes {
                allNodes[key] = value
            }
        }

        return allNodes
    }

    /// Walks a node tree and collects light→dark color mappings from boundVariables on paints.
    private func buildColorMap(
        node: Node,
        variablesMeta: VariablesMeta,
        modes: ModeContext
    ) -> [String: String] {
        var colorMap: [String: String] = [:]
        collectBoundColors(
            from: node.document,
            variablesMeta: variablesMeta,
            modes: modes,
            colorMap: &colorMap
        )
        return colorMap
    }

    private func collectBoundColors(
        from document: Document,
        variablesMeta: VariablesMeta,
        modes: ModeContext,
        colorMap: inout [String: String]
    ) {
        // Check fills
        for paint in document.fills {
            collectFromPaint(paint, variablesMeta: variablesMeta, modes: modes, colorMap: &colorMap)
        }

        // Check strokes
        if let strokes = document.strokes {
            for paint in strokes {
                collectFromPaint(paint, variablesMeta: variablesMeta, modes: modes, colorMap: &colorMap)
            }
        }

        // Recurse into children
        if let children = document.children {
            for child in children {
                collectBoundColors(from: child, variablesMeta: variablesMeta, modes: modes, colorMap: &colorMap)
            }
        }
    }

    private func collectFromPaint(
        _ paint: Paint,
        variablesMeta: VariablesMeta,
        modes: ModeContext,
        colorMap: inout [String: String]
    ) {
        guard let boundVars = paint.boundVariables,
              let colorAlias = boundVars["color"],
              let lightColor = paint.color
        else { return }

        let lightHex = SVGColorReplacer.normalizeColor(
            r: lightColor.r,
            g: lightColor.g,
            b: lightColor.b
        )

        // Resolve dark value for this variable
        if let darkHex = resolveDarkColor(
            variableId: colorAlias.id,
            modeId: modes.darkModeId,
            variablesMeta: variablesMeta,
            primitivesModeId: modes.primitivesModeId
        ) {
            if lightHex != darkHex {
                colorMap[lightHex] = darkHex
            }
        }
    }

    /// Resolves a variable to its concrete color value in the given mode, following alias chains.
    private func resolveDarkColor(
        variableId: String,
        modeId: String,
        variablesMeta: VariablesMeta,
        primitivesModeId: String?,
        depth: Int = 0
    ) -> String? {
        guard depth < 10 else { return nil }

        guard let variable = variablesMeta.variables[variableId] else { return nil }

        // Try the requested mode first, fall back to default mode of the collection
        let value = variable.valuesByMode[modeId]
            ?? variablesMeta.variableCollections[variable.variableCollectionId]
            .flatMap { collection in
                variable.valuesByMode[collection.defaultModeId]
            }

        switch value {
        case let .color(color):
            return SVGColorReplacer.normalizeColor(r: color.r, g: color.g, b: color.b)

        case let .variableAlias(alias):
            // Resolve alias — use primitives mode if available, else use the same mode
            let resolvedVariable = variablesMeta.variables[alias.id]
            let resolveModeId: String = if let primId = primitivesModeId {
                primId
            } else if let resolvedVar = resolvedVariable,
                      let collection = variablesMeta.variableCollections[resolvedVar.variableCollectionId]
            {
                collection.defaultModeId
            } else {
                modeId
            }

            return resolveDarkColor(
                variableId: alias.id,
                modeId: resolveModeId,
                variablesMeta: variablesMeta,
                primitivesModeId: primitivesModeId,
                depth: depth + 1
            )

        default:
            return nil
        }
    }
}
