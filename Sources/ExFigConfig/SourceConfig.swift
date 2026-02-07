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
