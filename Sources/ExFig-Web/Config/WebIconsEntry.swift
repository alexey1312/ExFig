import ExFigCore
import Foundation

/// Web icons export configuration entry.
///
/// Supports SVG output with optional React TSX component generation.
public struct WebIconsEntry: Decodable, Sendable {
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

    // MARK: - Output (Web-specific)

    /// Output directory for generated TypeScript components (e.g., "src/components/icons").
    public let outputDirectory: String

    /// Directory for SVG assets (e.g., "public/icons").
    public let svgDirectory: String?

    /// Generate React TSX components from SVGs. Defaults to true.
    public let generateReactComponents: Bool?

    /// Icon size in pixels for viewBox. Defaults to 24.
    public let iconSize: Int?

    // MARK: - Initializer

    public init(
        figmaFrameName: String? = nil,
        nameValidateRegexp: String? = nil,
        nameReplaceRegexp: String? = nil,
        nameStyle: NameStyle? = nil,
        outputDirectory: String,
        svgDirectory: String? = nil,
        generateReactComponents: Bool? = nil,
        iconSize: Int? = nil
    ) {
        self.figmaFrameName = figmaFrameName
        self.nameValidateRegexp = nameValidateRegexp
        self.nameReplaceRegexp = nameReplaceRegexp
        self.nameStyle = nameStyle
        self.outputDirectory = outputDirectory
        self.svgDirectory = svgDirectory
        self.generateReactComponents = generateReactComponents
        self.iconSize = iconSize
    }
}

// MARK: - Convenience Extensions

public extension WebIconsEntry {
    /// Returns an IconsSourceInput for use with IconsExportContext.
    func iconsSourceInput(fileId: String, darkFileId: String? = nil) -> IconsSourceInput {
        IconsSourceInput(
            fileId: fileId,
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

    /// Whether to generate React components, defaulting to true.
    var effectiveGenerateReactComponents: Bool {
        generateReactComponents ?? true
    }

    /// Effective icon size, defaulting to 24.
    var effectiveIconSize: Int {
        iconSize ?? 24
    }
}
