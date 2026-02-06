import ExFigConfig
import ExFigCore
import Foundation

/// Android colors export configuration entry.
///
/// Defines how colors from Figma Variables are exported to an Android project.
/// Supports XML resources, Kotlin extensions, and theme attributes.
///
/// ## Source Configuration
///
/// Colors are loaded from Figma Variables API:
/// - `tokensFileId`: Figma file containing the variable collection
/// - `tokensCollectionName`: Name of the variable collection
/// - `lightModeName`: Mode name for light appearance
/// - `darkModeName`: Mode name for dark appearance (optional)
///
/// ## Output Configuration
///
/// - `xmlOutputFileName`: XML resource file name
/// - `colorKotlin`: Generate Jetpack Compose Color extension
/// - `themeAttributes`: Generate theme attributes in styles.xml
public struct AndroidColorsEntry: Decodable, Sendable {
    // MARK: - Source (Figma Variables)

    /// Figma file ID containing the variable collection.
    public let tokensFileId: String

    /// Name of the variable collection in Figma.
    public let tokensCollectionName: String

    /// Mode name for light appearance values.
    public let lightModeName: String

    /// Mode name for dark appearance values. Optional.
    public let darkModeName: String?

    /// Mode name for light high contrast values. Optional.
    public let lightHCModeName: String?

    /// Mode name for dark high contrast values. Optional.
    public let darkHCModeName: String?

    /// Mode name for primitive/base values. Optional.
    public let primitivesModeName: String?

    // MARK: - Name Processing

    /// Regex pattern for validating/filtering color names.
    public let nameValidateRegexp: String?

    /// Replacement pattern using captured groups from nameValidateRegexp.
    public let nameReplaceRegexp: String?

    // MARK: - Output (Android-specific)

    /// XML resource file name (e.g., "colors.xml").
    public let xmlOutputFileName: String?

    /// When true, skip XML generation entirely. Useful for Compose-only projects.
    public let xmlDisabled: Bool?

    /// Package name for generated Compose code.
    public let composePackageName: String?

    /// Path to generate Jetpack Compose Color extension.
    public let colorKotlin: URL?

    // MARK: - Theme Attributes

    /// Theme attributes configuration for styles.xml generation.
    public let themeAttributes: ThemeAttributes?

    // MARK: - Initializer

    public init(
        tokensFileId: String,
        tokensCollectionName: String,
        lightModeName: String,
        darkModeName: String? = nil,
        lightHCModeName: String? = nil,
        darkHCModeName: String? = nil,
        primitivesModeName: String? = nil,
        nameValidateRegexp: String? = nil,
        nameReplaceRegexp: String? = nil,
        xmlOutputFileName: String? = nil,
        xmlDisabled: Bool? = nil,
        composePackageName: String? = nil,
        colorKotlin: URL? = nil,
        themeAttributes: ThemeAttributes? = nil
    ) {
        self.tokensFileId = tokensFileId
        self.tokensCollectionName = tokensCollectionName
        self.lightModeName = lightModeName
        self.darkModeName = darkModeName
        self.lightHCModeName = lightHCModeName
        self.darkHCModeName = darkHCModeName
        self.primitivesModeName = primitivesModeName
        self.nameValidateRegexp = nameValidateRegexp
        self.nameReplaceRegexp = nameReplaceRegexp
        self.xmlOutputFileName = xmlOutputFileName
        self.xmlDisabled = xmlDisabled
        self.composePackageName = composePackageName
        self.colorKotlin = colorKotlin
        self.themeAttributes = themeAttributes
    }
}

// MARK: - Theme Attributes

/// Configuration for Android theme attributes generation.
public struct ThemeAttributes: Decodable, Sendable {
    /// Whether theme attributes generation is enabled.
    public let enabled: Bool?

    /// Path to attrs.xml relative to mainRes.
    public let attrsFile: String?

    /// Path to styles.xml relative to mainRes.
    public let stylesFile: String?

    /// Path to styles-night.xml relative to mainRes.
    public let stylesNightFile: String?

    /// Theme name used in markers (e.g., "Theme.MyApp.Main").
    public let themeName: String

    /// Custom marker start text (default: "FIGMA COLORS MARKER START").
    public let markerStart: String?

    /// Custom marker end text (default: "FIGMA COLORS MARKER END").
    public let markerEnd: String?

    /// Name transformation configuration.
    public let nameTransform: NameTransform?

    /// If true, create file with markers if missing.
    public let autoCreateMarkers: Bool?

    public var isEnabled: Bool {
        enabled ?? false
    }

    public var resolvedMarkerStart: String {
        markerStart ?? "FIGMA COLORS MARKER START"
    }

    public var resolvedMarkerEnd: String {
        markerEnd ?? "FIGMA COLORS MARKER END"
    }

    public var shouldAutoCreateMarkers: Bool {
        autoCreateMarkers ?? false
    }

    public var resolvedAttrsFile: String {
        attrsFile ?? "values/attrs.xml"
    }

    public var resolvedStylesFile: String {
        stylesFile ?? "values/styles.xml"
    }

    public var resolvedStylesNightFile: String {
        stylesNightFile ?? "values-night/styles.xml"
    }

    public init(
        enabled: Bool? = nil,
        attrsFile: String? = nil,
        stylesFile: String? = nil,
        stylesNightFile: String? = nil,
        themeName: String,
        markerStart: String? = nil,
        markerEnd: String? = nil,
        nameTransform: NameTransform? = nil,
        autoCreateMarkers: Bool? = nil
    ) {
        self.enabled = enabled
        self.attrsFile = attrsFile
        self.stylesFile = stylesFile
        self.stylesNightFile = stylesNightFile
        self.themeName = themeName
        self.markerStart = markerStart
        self.markerEnd = markerEnd
        self.nameTransform = nameTransform
        self.autoCreateMarkers = autoCreateMarkers
    }
}

/// Name transformation configuration for theme attributes.
public struct NameTransform: Decodable, Sendable {
    /// Prefix to add to color names (default: "color").
    public let prefix: String?

    /// Suffix to add to color names.
    public let suffix: String?

    /// Target case style for attribute names (default: PascalCase).
    public let style: NameStyle?

    /// Prefixes to strip from color names before transformation.
    public let stripPrefixes: [String]?

    public var resolvedStyle: NameStyle {
        style ?? .pascalCase
    }

    public var resolvedPrefix: String {
        prefix ?? "color"
    }

    public var resolvedStripPrefixes: [String] {
        stripPrefixes ?? []
    }

    public init(
        prefix: String? = nil,
        suffix: String? = nil,
        style: NameStyle? = nil,
        stripPrefixes: [String]? = nil
    ) {
        self.prefix = prefix
        self.suffix = suffix
        self.style = style
        self.stripPrefixes = stripPrefixes
    }
}

// MARK: - Convenience Extensions

public extension AndroidColorsEntry {
    /// Returns a VariablesSourceConfig for this entry.
    var variablesSource: VariablesSourceConfig {
        VariablesSourceConfig(
            tokensFileId: tokensFileId,
            tokensCollectionName: tokensCollectionName,
            lightModeName: lightModeName,
            darkModeName: darkModeName,
            lightHCModeName: lightHCModeName,
            darkHCModeName: darkHCModeName,
            primitivesModeName: primitivesModeName
        )
    }

    /// Returns a NameProcessingConfig for this entry.
    var nameProcessing: NameProcessingConfig {
        NameProcessingConfig(
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp
        )
    }

    /// Returns a ColorsSourceInput for use with ColorsExportContext.
    var colorsSourceInput: ColorsSourceInput {
        ColorsSourceInput(
            tokensFileId: tokensFileId,
            tokensCollectionName: tokensCollectionName,
            lightModeName: lightModeName,
            darkModeName: darkModeName,
            lightHCModeName: lightHCModeName,
            darkHCModeName: darkHCModeName,
            primitivesModeName: primitivesModeName,
            nameValidateRegexp: nameValidateRegexp,
            nameReplaceRegexp: nameReplaceRegexp
        )
    }
}
