import Foundation

public enum NameStyle: String, Decodable, Sendable {
    case camelCase
    case snakeCase = "snake_case"
}
