import ExFigConfig
import ExFigCore
import Foundation

/// Typealias for backward compatibility with consumers.
public typealias FlutterIconsEntry = Flutter.IconsEntry

// MARK: - Convenience Extensions

public extension Flutter.IconsEntry {
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
        guard let nameStyle else { return .snakeCase }
        switch nameStyle {
        case .camelCase: return .camelCase
        case .snake_case: return .snakeCase
        case .pascalCase: return .pascalCase
        case .flatCase: return .flatCase
        case .kebabCase: return .kebabCase
        case .sCREAMING_SNAKE_CASE: return .screamingSnakeCase
        }
    }

    // MARK: - Entry-Level Override Resolution

    /// Resolved templates path: entry override or platform config fallback.
    func resolvedTemplatesPath(fallback: URL?) -> URL? {
        templatesPath.map { URL(fileURLWithPath: $0) } ?? fallback
    }

    /// Resolved Figma file ID: entry override or global fallback.
    func resolvedFigmaFileId(fallback: String?) -> String? {
        figmaFileId ?? fallback
    }
}
