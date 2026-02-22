import Foundation

public enum TemplateLoadError: Error, LocalizedError {
    case notFound(name: String, searchedPaths: [String])
    case renderFailed(templateName: String, underlyingError: Error)
    case contextConversionFailed(key: String, valueType: String, underlyingError: Error)

    public var errorDescription: String? {
        switch self {
        case let .notFound(name, paths):
            if paths.isEmpty {
                return "Template not found: \(name)"
            }
            return "Template not found: \(name). Searched paths:\n"
                + paths.map { "  - \($0)" }.joined(separator: "\n")
        case let .renderFailed(templateName, underlyingError):
            return "Failed to render template '\(templateName)': \(underlyingError.localizedDescription)"
        case let .contextConversionFailed(key, valueType, underlyingError):
            return "Failed to convert context key '\(key)' (type: \(valueType)) to Jinja value: "
                + "\(underlyingError.localizedDescription)"
        }
    }
}
