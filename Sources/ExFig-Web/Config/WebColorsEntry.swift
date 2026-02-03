import ExFigConfig
import Foundation

/// Web colors export configuration entry.
///
/// Defines how colors from Figma Variables are exported to a Web/React project.
/// Supports CSS variables, TypeScript constants, and JSON output.
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
/// - `outputDirectory`: Directory for output files
/// - `cssFileName`: CSS file with CSS custom properties
/// - `tsFileName`: TypeScript file with color constants
/// - `jsonFileName`: JSON file with color values
public struct WebColorsEntry: Decodable, Sendable {
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

    // MARK: - Output (Web-specific)

    /// Directory for output files.
    public let outputDirectory: String?

    /// CSS file name with CSS custom properties (e.g., "colors.css").
    public let cssFileName: String?

    /// TypeScript file name with color constants (e.g., "colors.ts").
    public let tsFileName: String?

    /// JSON file name with color values (e.g., "colors.json").
    public let jsonFileName: String?

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
        outputDirectory: String? = nil,
        cssFileName: String? = nil,
        tsFileName: String? = nil,
        jsonFileName: String? = nil
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
        self.outputDirectory = outputDirectory
        self.cssFileName = cssFileName
        self.tsFileName = tsFileName
        self.jsonFileName = jsonFileName
    }
}

// MARK: - Convenience Extensions

public extension WebColorsEntry {
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
}
