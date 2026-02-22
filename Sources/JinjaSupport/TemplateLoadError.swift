import Foundation

public enum TemplateLoadError: Error, LocalizedError {
    case notFound(name: String, searchedPaths: [String])

    public var errorDescription: String? {
        switch self {
        case let .notFound(name, paths):
            if paths.isEmpty {
                return "Template not found: \(name)"
            }
            return "Template not found: \(name). Searched paths:\n"
                + paths.map { "  - \($0)" }.joined(separator: "\n")
        }
    }
}
