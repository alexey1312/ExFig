import ExFigCore
import FigmaAPI

/// Loads text styles from Figma
final class TextStylesLoader: Sendable {
    private let client: Client
    private let params: Params.Figma

    init(client: Client, params: Params.Figma) {
        self.client = client
        self.params = params
    }

    func load() async throws -> [TextStyle] {
        try await loadTextStyles(fileId: params.lightFileId)
    }

    private func loadTextStyles(fileId: String) async throws -> [TextStyle] {
        let styles = try await loadStyles(fileId: fileId)

        guard !styles.isEmpty else {
            throw ExFigError.stylesNotFound
        }

        let nodes = try await loadNodes(fileId: fileId, nodeIds: styles.map(\.nodeId))

        return styles.compactMap { style -> TextStyle? in
            guard let node = nodes[style.nodeId] else { return nil }
            guard let textStyle = node.document.style else { return nil }

            let lineHeight: Double? = textStyle.lineHeightUnit == .intrinsic ? nil : textStyle.lineHeightPx

            let textCase: TextStyle.TextCase = switch textStyle.textCase {
            case .lower:
                .lowercased
            case .upper:
                .uppercased
            default:
                .original
            }

            return TextStyle(
                name: style.name,
                fontName: textStyle.fontPostScriptName ?? textStyle.fontFamily ?? "",
                fontSize: textStyle.fontSize,
                fontStyle: DynamicTypeStyle(rawValue: style.description),
                lineHeight: lineHeight,
                letterSpacing: textStyle.letterSpacing,
                textCase: textCase
            )
        }
    }

    private func loadStyles(fileId: String) async throws -> [Style] {
        let endpoint = StylesEndpoint(fileId: fileId)
        let styles = try await client.request(endpoint)
        return styles.filter { $0.styleType == .text }
    }

    private func loadNodes(fileId: String, nodeIds: [String]) async throws -> [NodeId: Node] {
        let endpoint = NodesEndpoint(fileId: fileId, nodeIds: nodeIds)
        return try await client.request(endpoint)
    }
}
