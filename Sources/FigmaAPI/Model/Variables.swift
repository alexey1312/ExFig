public struct Mode: Decodable, Sendable {
    public var modeId: String
    public var name: String
}

public struct VariableCollectionValue: Decodable, Sendable {
    public var defaultModeId: String
    public var id: String
    public var name: String
    public var modes: [Mode]
    public var variableIds: [String]
}

public struct VariableAlias: Codable, Sendable {
    public var id: String
    public var type: String
}

public enum ValuesByMode: Decodable, Sendable {
    case variableAlias(VariableAlias)
    case color(PaintColor)
    case string(String)
    case number(Double)
    case boolean(Bool)

    public enum CodingKeys: CodingKey {
        case variableAlias
        case color
        case string
        case number
        case boolean
    }

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
}

public struct VariableValue: Decodable, Sendable {
    public var id: String
    public var name: String
    public var variableCollectionId: String
    public var valuesByMode: [String: ValuesByMode]
    public var description: String
}

public typealias VariableId = String
public typealias VariableCollectionId = String

public struct VariablesMeta: Decodable, Sendable {
    public var variableCollections: [VariableCollectionId: VariableCollectionValue]
    public var variables: [VariableId: VariableValue]
}

public struct VariablesResponse: Decodable, Sendable {
    public let meta: VariablesMeta
}
