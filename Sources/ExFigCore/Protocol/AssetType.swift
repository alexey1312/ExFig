import Foundation

/// The type of asset being exported.
///
/// ExFig supports exporting four types of design assets from Figma:
/// - Colors (from Figma Variables)
/// - Icons (from Figma Frames with vector content)
/// - Images (from Figma Frames with raster content)
/// - Typography (from Figma Text Styles)
public enum AssetType: String, Sendable, CaseIterable {
    /// Color tokens exported from Figma Variables.
    /// Generates color assets, Swift/Kotlin extensions, CSS variables.
    case colors

    /// Vector icons exported from Figma Frames.
    /// Generates SVG files, PDF assets, ImageVector/VectorDrawable code.
    case icons

    /// Raster images exported from Figma Frames.
    /// Generates PNG/WebP/HEIC assets at multiple scales.
    case images

    /// Text styles exported from Figma Text Styles.
    /// Generates font configurations, Swift/Kotlin/Dart typography code.
    case typography
}
