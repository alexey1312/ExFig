import Foundation

public enum XcodeRenderMode: String, Decodable, Sendable {
    case `default`
    case template
    case original
}
