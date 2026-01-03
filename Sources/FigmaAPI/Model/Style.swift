public enum StyleType: String, Decodable, Sendable {
    case fill = "FILL"
    case text = "TEXT"
    case effect = "EFFECT"
    case grid = "GRID"
}

public struct Style: Decodable, Sendable {
    public let styleType: StyleType
    public let nodeId: String
    public let name: String
    public let description: String

    enum CodingKeys: String, CodingKey {
        case name, description
        case styleType = "style_type"
        case nodeId = "node_id"
    }

    public init(styleType: StyleType, nodeId: String, name: String, description: String) {
        self.styleType = styleType
        self.nodeId = nodeId
        self.name = name
        self.description = description
    }
}

public struct StylesResponse: Decodable, Sendable {
    public let error: Bool
    public let status: Int
    public let meta: StylesResponseContents

    enum CodingKeys: String, CodingKey {
        case error, status, meta
    }
}

public struct StylesResponseContents: Decodable, Sendable {
    public let styles: [Style]

    enum CodingKeys: String, CodingKey {
        case styles
    }
}
