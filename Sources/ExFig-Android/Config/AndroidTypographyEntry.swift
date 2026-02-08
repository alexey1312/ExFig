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

    /// Converts PKL NameStyle to ExFigCore NameStyle via centralized bridging.
    var coreNameStyle: NameStyle {
        nameStyle.coreNameStyle
    }
}
