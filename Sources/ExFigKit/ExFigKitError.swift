import Foundation

/// Errors thrown by ExFigKit operations.
public enum ExFigKitError: LocalizedError, Sendable {
    case invalidFileName(String)
    case stylesNotFound
    case componentsNotFound
    case accessTokenNotFound
    case colorsAssetsFolderNotSpecified
    case configurationError(String)
    case custom(errorString: String)

    public var errorDescription: String? {
        switch self {
        case let .invalidFileName(name):
            "Invalid file name: \(name)"
        case .stylesNotFound:
            "Styles not found in Figma file"
        case .componentsNotFound:
            "Components not found in Figma file"
        case .accessTokenNotFound:
            "FIGMA_PERSONAL_TOKEN not set"
        case .colorsAssetsFolderNotSpecified:
            "Config missing: ios.colors.assetsFolder"
        case let .configurationError(message):
            "Config error: \(message)"
        case let .custom(errorString):
            errorString
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidFileName:
            "Use alphanumeric characters, underscores, and hyphens only"
        case .stylesNotFound:
            "Publish Styles to the Team Library in Figma"
        case .componentsNotFound:
            "Publish Components to the Team Library in Figma"
        case .accessTokenNotFound:
            "Run: export FIGMA_PERSONAL_TOKEN=your_token"
        case .colorsAssetsFolderNotSpecified:
            "Add ios.colors.assetsFolder to your config file"
        case .configurationError, .custom:
            nil
        }
    }
}

/// Backwards compatibility alias
public typealias ExFigError = ExFigKitError
