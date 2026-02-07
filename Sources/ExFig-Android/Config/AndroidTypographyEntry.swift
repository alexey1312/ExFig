import ExFigConfig
import ExFigCore
import Foundation

/// Typealias for backward compatibility with consumers.
public typealias AndroidTypographyEntry = Android.Typography

// MARK: - Convenience Extensions

public extension Android.Typography {
    /// Returns a TypographySourceInput for use with TypographyExportContext.
    /// Per-entry fileId takes priority over the provided platform-level fileId.
    func typographySourceInput(fileId: String, timeout: TimeInterval?) -> TypographySourceInput {
        TypographySourceInput(
            fileId: self.fileId ?? fileId,
            timeout: timeout
        )
    }

    /// Converts PKL NameStyle to ExFigCore NameStyle.
    var coreNameStyle: NameStyle {
        switch nameStyle {
        case .camelCase: .camelCase
        case .snake_case: .snakeCase
        case .pascalCase: .pascalCase
        case .flatCase: .flatCase
        case .kebab_case: .kebabCase
        case .sCREAMING_SNAKE_CASE: .screamingSnakeCase
        }
    }
}
