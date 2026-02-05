import Foundation

// MARK: - Figma Variables Source

/// Configuration for Figma Variables API source.
/// Used for colors that come from Figma Variables (design tokens).
public struct VariablesSourceConfig: Decodable, Sendable {
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

    public init(
        tokensFileId: String,
        tokensCollectionName: String,
        lightModeName: String,
        darkModeName: String? = nil,
        lightHCModeName: String? = nil,
        darkHCModeName: String? = nil,
        primitivesModeName: String? = nil
    ) {
        self.tokensFileId = tokensFileId
        self.tokensCollectionName = tokensCollectionName
        self.lightModeName = lightModeName
        self.darkModeName = darkModeName
        self.lightHCModeName = lightHCModeName
        self.darkHCModeName = darkHCModeName
        self.primitivesModeName = primitivesModeName
    }
}

// MARK: - Figma Frame Source

/// Configuration for Figma Frame source.
/// Used for icons and images that come from Figma frames.
public struct FrameSourceConfig: Decodable, Sendable {
    /// Name of the Figma frame to export from. Optional — uses common config if nil.
    public let figmaFrameName: String?

    public init(figmaFrameName: String? = nil) {
        self.figmaFrameName = figmaFrameName
    }
}

// MARK: - Combined Source

/// Combined source configuration for entries that need both Variables and Frame.
/// Used when an entry needs to specify both variable source and frame override.
public struct CombinedSourceConfig: Decodable, Sendable {
    // Variables source
    public let tokensFileId: String?
    public let tokensCollectionName: String?
    public let lightModeName: String?
    public let darkModeName: String?
    public let lightHCModeName: String?
    public let darkHCModeName: String?
    public let primitivesModeName: String?

    /// Frame source
    public let figmaFrameName: String?

    public init(
        tokensFileId: String? = nil,
        tokensCollectionName: String? = nil,
        lightModeName: String? = nil,
        darkModeName: String? = nil,
        lightHCModeName: String? = nil,
        darkHCModeName: String? = nil,
        primitivesModeName: String? = nil,
        figmaFrameName: String? = nil
    ) {
        self.tokensFileId = tokensFileId
        self.tokensCollectionName = tokensCollectionName
        self.lightModeName = lightModeName
        self.darkModeName = darkModeName
        self.lightHCModeName = lightHCModeName
        self.darkHCModeName = darkHCModeName
        self.primitivesModeName = primitivesModeName
        self.figmaFrameName = figmaFrameName
    }

    /// Returns a VariablesSourceConfig if all required fields are present.
    public var variablesSource: VariablesSourceConfig? {
        guard let tokensFileId, let tokensCollectionName, let lightModeName else {
            return nil
        }
        return VariablesSourceConfig(
            tokensFileId: tokensFileId,
            tokensCollectionName: tokensCollectionName,
            lightModeName: lightModeName,
            darkModeName: darkModeName,
            lightHCModeName: lightHCModeName,
            darkHCModeName: darkHCModeName,
            primitivesModeName: primitivesModeName
        )
    }

    /// Returns a FrameSourceConfig if figmaFrameName is present.
    public var frameSource: FrameSourceConfig? {
        guard figmaFrameName != nil else { return nil }
        return FrameSourceConfig(figmaFrameName: figmaFrameName)
    }
}
