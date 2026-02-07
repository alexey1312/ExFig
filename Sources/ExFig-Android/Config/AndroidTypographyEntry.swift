import ExFigConfig
import ExFigCore
import Foundation

/// Typealias for backward compatibility with consumers.
public typealias AndroidTypographyEntry = Android.Typography

// MARK: - Convenience Extensions

public extension Android.Typography {
    /// Returns a TypographySourceInput for use with TypographyExportContext.
    func typographySourceInput(fileId: String, timeout: TimeInterval?) -> TypographySourceInput {
        TypographySourceInput(
            fileId: fileId,
            timeout: timeout
        )
    }

    /// Converts PKL NameStyle to ExFigCore NameStyle.
    var coreNameStyle: NameStyle {
        NameStyle(rawValue: nameStyle.rawValue) ?? .snakeCase
    }
}
