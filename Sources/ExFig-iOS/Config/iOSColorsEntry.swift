// swiftlint:disable type_name

import ExFigConfig
import ExFigCore
import Foundation

/// iOS colors export configuration entry.
///
/// Defines how colors from Figma Variables are exported to an iOS/Xcode project.
/// Supports both xcassets color sets and Swift extensions.
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
/// - `useColorAssets`: Generate .xcassets color sets
/// - `colorSwift`: Generate UIColor extension
/// - `swiftuiColorSwift`: Generate SwiftUI Color extension
public struct iOSColorsEntry: Decodable, Sendable {
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

    // MARK: - Output (iOS-specific)

    /// Whether to generate xcassets color sets.
    public let useColorAssets: Bool

    /// Folder name inside xcassets for colors.
    public let assetsFolder: String?

    /// Naming style for generated Swift identifiers.
    public let nameStyle: NameStyle

    /// Whether to group colors using Swift namespaces.
    public let groupUsingNamespace: Bool?

    /// Path to generate UIColor extension.
    public let colorSwift: URL?

    /// Path to generate SwiftUI Color extension.
    public let swiftuiColorSwift: URL?

    // MARK: - Code Syntax Sync

    /// Sync generated code names back to Figma Variables codeSyntax.iOS field.
    public let syncCodeSyntax: Bool?

    /// Template for codeSyntax.iOS. Use {name} for variable name.
    /// Example: "Color.{name}" → "Color.backgroundAccent"
    public let codeSyntaxTemplate: String?

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
        useColorAssets: Bool = true,
        assetsFolder: String? = nil,
        nameStyle: NameStyle = .camelCase,
        groupUsingNamespace: Bool? = nil,
        colorSwift: URL? = nil,
        swiftuiColorSwift: URL? = nil,
        syncCodeSyntax: Bool? = nil,
        codeSyntaxTemplate: String? = nil
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
        self.useColorAssets = useColorAssets
        self.assetsFolder = assetsFolder
        self.nameStyle = nameStyle
        self.groupUsingNamespace = groupUsingNamespace
        self.colorSwift = colorSwift
        self.swiftuiColorSwift = swiftuiColorSwift
        self.syncCodeSyntax = syncCodeSyntax
        self.codeSyntaxTemplate = codeSyntaxTemplate
    }
}

// MARK: - Convenience Extensions

public extension iOSColorsEntry {
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

// swiftlint:enable type_name
