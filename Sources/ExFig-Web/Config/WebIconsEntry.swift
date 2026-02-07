import ExFigConfig
import ExFigCore
import Foundation

/// Typealias for backward compatibility with consumers.
public typealias WebIconsEntry = Web.IconsEntry

// MARK: - Convenience Extensions

public extension Web.IconsEntry {
    /// Returns an IconsSourceInput for use with IconsExportContext.
    func iconsSourceInput(darkFileId: String? = nil) -> IconsSourceInput {
        IconsSourceInput(
            darkFileId: darkFileId,
            frameName: figmaFrameName ?? "Icons",
            useSingleFile: darkFileId == nil,
            darkModeSuffix: "_dark",
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp
        )
    }

    /// Effective name style, defaulting to snake_case.
    var effectiveNameStyle: NameStyle {
        nameStyle.flatMap { NameStyle(rawValue: $0.rawValue) } ?? .snakeCase
    }

    /// Whether to generate React components, defaulting to true.
    var effectiveGenerateReactComponents: Bool {
        generateReactComponents ?? true
    }

    /// Effective icon size, defaulting to 24.
    var effectiveIconSize: Int {
        iconSize ?? 24
    }
}
