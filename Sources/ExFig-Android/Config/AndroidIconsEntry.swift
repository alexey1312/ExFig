import ExFigConfig
import ExFigCore
import Foundation

/// Typealias for backward compatibility with consumers.
public typealias AndroidIconsEntry = Android.IconsEntry

/// Typealias for generated ComposeIconFormat.
public typealias ComposeIconFormat = Android.ComposeIconFormat

// MARK: - Convenience Extensions

public extension Android.IconsEntry {
    /// Returns an IconsSourceInput for use with IconsExportContext.
    func iconsSourceInput(darkFileId: String? = nil) -> IconsSourceInput {
        IconsSourceInput(
            darkFileId: darkFileId,
            frameName: figmaFrameName ?? "Icons",
            format: .svg,
            useSingleFile: darkFileId == nil,
            darkModeSuffix: "_dark",
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp
        )
    }

    /// Effective name style, defaulting to snake_case.
    var effectiveNameStyle: NameStyle {
        guard let nameStyle else { return .snakeCase }
        return nameStyle.coreNameStyle
    }

    /// Effective compose format, defaulting to resourceReference.
    var effectiveComposeFormat: Android.ComposeIconFormat {
        composeFormat ?? .resourceReference
    }
}
