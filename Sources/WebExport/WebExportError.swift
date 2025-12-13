import Foundation

public enum WebExportError: LocalizedError {
    case invalidFileName(name: String)

    public var errorDescription: String? {
        switch self {
        case let .invalidFileName(name):
            "Invalid file name: \(name)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidFileName:
            "Ensure the file name contains only valid characters"
        }
    }
}
