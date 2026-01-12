import Foundation

/// A protocol representing a design asset that can be exported from Figma.
///
/// Assets are the core building blocks of ExFig, representing design elements
/// like colors, images, icons, and text styles. Each asset has a name that
/// identifies it in the exported code and an optional platform association.
///
/// Conforming types include:
/// - ``Color``: Color definitions with RGBA components
/// - ``ImagePack``: Collections of images at different scales
/// - ``TextStyle``: Typography definitions
public protocol Asset: Hashable, Sendable {
    /// The name of the asset, used for code generation.
    /// This name will be sanitized and formatted according to platform conventions.
    var name: String { get set }

    /// The target platform for this asset, if platform-specific.
    /// When `nil`, the asset is considered cross-platform.
    var platform: Platform? { get }
}

/// Metadata for an asset needed for Code Connect generation.
///
/// This struct contains the minimal information needed to generate Figma Code Connect
/// files that link code to design components. It includes the asset name, Figma node ID,
/// and file ID needed to construct the Figma URL.
public struct AssetMetadata: Sendable, Hashable {
    /// The asset name (after processing).
    public let name: String

    /// The Figma node ID (e.g., "12016:2218").
    public let nodeId: String

    /// The Figma file ID.
    public let fileId: String

    public init(name: String, nodeId: String, fileId: String) {
        self.name = name
        self.nodeId = nodeId
        self.fileId = fileId
    }
}
