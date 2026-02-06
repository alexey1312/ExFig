import ExFigCore
import Foundation

/// Flutter icons export configuration entry.
///
/// Supports SVG output format with Dart code generation.
public struct FlutterIconsEntry: Decodable, Sendable {
    // MARK: - Source (Figma Frame)

    /// Figma frame name containing icons. Overrides common.icons.figmaFrameName.
    public let figmaFrameName: String?

    // MARK: - Name Processing

    /// Regex pattern for validating/filtering icon names.
    public let nameValidateRegexp: String?

    /// Replacement pattern using captured groups from nameValidateRegexp.
    public let nameReplaceRegexp: String?

    /// Naming style for generated identifiers.
    public let nameStyle: NameStyle?

    // MARK: - Output (Flutter-specific)

    /// Output directory for SVG assets (e.g., "assets/icons").
    public let output: String

    /// Dart file name for generated code (e.g., "icons.dart").
    public let dartFile: String?

    /// Class name for generated Dart code (e.g., "AppIcons").
    public let className: String?

    // MARK: - Initializer

    public init(
        figmaFrameName: String? = nil,
        nameValidateRegexp: String? = nil,
        nameReplaceRegexp: String? = nil,
        nameStyle: NameStyle? = nil,
        output: String,
        dartFile: String? = nil,
        className: String? = nil
    ) {
        self.figmaFrameName = figmaFrameName
        self.nameValidateRegexp = nameValidateRegexp
        self.nameReplaceRegexp = nameReplaceRegexp
        self.nameStyle = nameStyle
        self.output = output
        self.dartFile = dartFile
        self.className = className
    }
}

// MARK: - Convenience Extensions

public extension FlutterIconsEntry {
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
        nameStyle ?? .snakeCase
    }
}
