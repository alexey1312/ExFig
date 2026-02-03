import Foundation

/// Protocol for platform-specific images exporters.
///
/// An `ImagesExporter` handles the full export cycle for images:
/// 1. Loading image data from Figma frames (as PNG, SVG, or other formats)
/// 2. Processing images into platform-specific format (scaling, format conversion)
/// 3. Writing image assets and code files
///
/// Each platform (iOS, Android, Flutter, Web) provides its own
/// implementation with platform-specific entry and config types.
///
/// ## Implementation
///
/// ```swift
/// struct iOSImagesExporter: ImagesExporter {
///     typealias Entry = iOSImagesEntry
///     typealias PlatformConfig = iOSPlatformConfig
///
///     func exportImages(
///         entries: [Entry],
///         platformConfig: PlatformConfig,
///         context: some ImagesExportContext
///     ) async throws -> Int {
///         // Platform-specific export logic
///     }
/// }
/// ```
public protocol ImagesExporter: AssetExporter {
    /// The configuration entry type for images.
    associatedtype Entry: Sendable

    /// The platform configuration type.
    associatedtype PlatformConfig: Sendable

    /// Exports images from Figma to the target platform.
    ///
    /// - Parameters:
    ///   - entries: Array of images configuration entries.
    ///   - platformConfig: Platform-wide configuration.
    ///   - context: Export context with dependencies.
    /// - Returns: Number of images exported.
    func exportImages(
        entries: [Entry],
        platformConfig: PlatformConfig,
        context: some ImagesExportContext
    ) async throws -> Int
}

// Default implementation for AssetExporter conformance
public extension ImagesExporter {
    var assetType: AssetType { .images }
}
