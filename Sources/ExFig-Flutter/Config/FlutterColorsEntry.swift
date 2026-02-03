import ExFigConfig
import ExFigCore
import Foundation

/// Flutter colors export configuration entry.
///
/// Defines how colors from Figma Variables are exported to a Flutter project.
/// Generates Dart code with color constants.
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
/// - `output`: Path to output Dart file
/// - `className`: Class name for generated Dart code
public struct FlutterColorsEntry: Decodable, Sendable {
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

    // MARK: - Output (Flutter-specific)

    /// Path to output Dart file.
    public let output: String?

    /// Class name for generated Dart code (e.g., "AppColors").
    public let className: String?

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
        output: String? = nil,
        className: String? = nil
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
        self.output = output
        self.className = className
    }
}

// MARK: - Convenience Extensions

public extension FlutterColorsEntry {
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
