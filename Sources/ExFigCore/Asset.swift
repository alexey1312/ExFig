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
