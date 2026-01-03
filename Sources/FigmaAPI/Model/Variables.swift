public struct Mode: Codable, Sendable {
    public var modeId: String
    public var name: String

    enum CodingKeys: String, CodingKey {
        case name
        case modeId = "mode_id"
    }
}

public struct VariableCollectionValue: Codable, Sendable {
    public var defaultModeId: String
    public var id: String
    public var name: String
    public var modes: [Mode]
    public var variableIds: [String]

    enum CodingKeys: String, CodingKey {
        case id, name, modes
        case defaultModeId = "default_mode_id"
        case variableIds = "variable_ids"
    }
}

public struct VariableAlias: Codable, Sendable {
    public var id: String
    public var type: String

    enum CodingKeys: String, CodingKey {
        case id, type
    }
}

public enum ValuesByMode: Codable, Sendable {
    case variableAlias(VariableAlias)
    case color(PaintColor)
    case string(String)
    case number(Double)
    case boolean(Bool)

    public init(from decoder: Decoder) throws {
        if let variableAlias = try? VariableAlias(from: decoder) {
            self = .variableAlias(variableAlias)
        } else if let color = try? PaintColor(from: decoder) {
            self = .color(color)
        } else if let string = try? String(from: decoder) {
            self = .string(string)
        } else if let number = try? Double(from: decoder) {
            self = .number(number)
        } else if let boolean = try? Bool(from: decoder) {
            self = .boolean(boolean)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Data didn't match any expected type."
            ))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .variableAlias(alias):
            try container.encode(alias)
        case let .color(color):
            try container.encode(color)
        case let .string(str):
            try container.encode(str)
        case let .number(num):
            try container.encode(num)
        case let .boolean(bool):
            try container.encode(bool)
        }
    }
}

public struct VariableValue: Codable, Sendable {
    public var id: String
    public var name: String
    public var variableCollectionId: String
    public var valuesByMode: [String: ValuesByMode]
    public var description: String

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case variableCollectionId = "variable_collection_id"
        case valuesByMode = "values_by_mode"
    }
}

public typealias VariableId = String
public typealias VariableCollectionId = String

public struct VariablesMeta: Codable, Sendable {
    public var variableCollections: [VariableCollectionId: VariableCollectionValue]
    public var variables: [VariableId: VariableValue]

    enum CodingKeys: String, CodingKey {
        case variableCollections = "variable_collections"
        case variables
    }
}

public struct VariablesResponse: Codable, Sendable {
    public let meta: VariablesMeta

    enum CodingKeys: String, CodingKey {
        case meta
    }
}
