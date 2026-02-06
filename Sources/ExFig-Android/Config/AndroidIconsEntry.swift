import ExFigCore
import Foundation

/// Android icons export configuration entry.
///
/// Supports two output formats:
/// - VectorDrawable XML files (default)
/// - Jetpack Compose ImageVector Kotlin files
public struct AndroidIconsEntry: Decodable, Sendable {
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

    // MARK: - Output (Android-specific)

    /// Output directory name under res/ (e.g., "drawable" → res/drawable/).
    public let output: String

    /// Package name for Compose extension (required for Compose output).
    public let composePackageName: String?

    /// Compose output format.
    public let composeFormat: ComposeIconFormat?

    /// Extension target for Compose ImageVector (e.g., "Icons.Filled").
    public let composeExtensionTarget: String?

    // MARK: - Path Validation

    /// Coordinate precision for pathData (1-6, default 4).
    public let pathPrecision: Int?

    /// If true, exit with error when pathData exceeds 32,767 bytes (AAPT limit).
    public let strictPathValidation: Bool?

    // MARK: - Initializer

    public init(
        figmaFrameName: String? = nil,
        nameValidateRegexp: String? = nil,
        nameReplaceRegexp: String? = nil,
        nameStyle: NameStyle? = nil,
        output: String,
        composePackageName: String? = nil,
        composeFormat: ComposeIconFormat? = nil,
        composeExtensionTarget: String? = nil,
        pathPrecision: Int? = nil,
        strictPathValidation: Bool? = nil
    ) {
        self.figmaFrameName = figmaFrameName
        self.nameValidateRegexp = nameValidateRegexp
        self.nameReplaceRegexp = nameReplaceRegexp
        self.nameStyle = nameStyle
        self.output = output
        self.composePackageName = composePackageName
        self.composeFormat = composeFormat
        self.composeExtensionTarget = composeExtensionTarget
        self.pathPrecision = pathPrecision
        self.strictPathValidation = strictPathValidation
    }
}

// MARK: - Compose Icon Format

/// Output format for Compose icons.
public enum ComposeIconFormat: String, Decodable, Sendable {
    /// Generate drawable resource references (painterResource).
    case resourceReference

    /// Generate Kotlin ImageVector files.
    case imageVector
}

// MARK: - Convenience Extensions

public extension AndroidIconsEntry {
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
        nameStyle ?? .snakeCase
    }

    /// Effective compose format, defaulting to resourceReference.
    var effectiveComposeFormat: ComposeIconFormat {
        composeFormat ?? .resourceReference
    }
}
