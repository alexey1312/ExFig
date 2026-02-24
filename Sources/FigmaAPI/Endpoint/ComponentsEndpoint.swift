import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public struct ComponentsEndpoint: BaseEndpoint {
    public typealias Content = [Component]

    private let fileId: String

    public init(fileId: String) {
        self.fileId = fileId
    }

    func content(from root: ComponentsResponse) -> [Component] {
        root.meta.components
    }

    public func makeRequest(baseURL: URL) -> URLRequest {
        let url = baseURL
            .appendingPathComponent("files")
            .appendingPathComponent(fileId)
            .appendingPathComponent("components")
        return URLRequest(url: url)
    }
}

// MARK: - Response

struct ComponentsResponse: Codable {
    let meta: Meta
}

struct Meta: Codable {
    let components: [Component]
}

public struct Component: Codable, Sendable {
    public let key: String
    public let nodeId: String
    public let name: String
    public let description: String?
    public let containingFrame: ContainingFrame

    private enum CodingKeys: String, CodingKey {
        case key
        case nodeId = "node_id"
        case name
        case description
        case containingFrame = "containing_frame"
    }
}

// MARK: - ContainingFrame

public struct ContainingFrame: Codable, Sendable {
    public let nodeId: String?
    public let name: String?
    public let pageId: String?
    public let pageName: String?
    public let backgroundColor: String?
    public let containingComponentSet: ContainingComponentSet?
}

// MARK: - ContainingComponentSet

/// Represents the parent COMPONENT_SET for variant components.
/// Present when a component is a variant inside a component set.
public struct ContainingComponentSet: Codable, Sendable {
    public let nodeId: String?
    public let name: String?
}
