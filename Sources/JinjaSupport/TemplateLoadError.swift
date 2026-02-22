import Foundation

public enum TemplateLoadError: Error, LocalizedError {
    case notFound(String)

    public var errorDescription: String? {
        switch self {
        case let .notFound(name):
            "Template not found: \(name)"
        }
    }
}
