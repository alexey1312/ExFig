import Foundation

/// Protocol for platform-specific icons exporters.
///
/// An `IconsExporter` handles the full export cycle for icons:
/// 1. Loading icon data from Figma frames (as SVG or PDF)
/// 2. Processing icons into platform-specific format
/// 3. Writing icon assets and code files
///
/// Each platform (iOS, Android, Flutter, Web) provides its own
/// implementation with platform-specific entry and config types.
///
/// ## Implementation
///
/// ```swift
/// struct iOSIconsExporter: IconsExporter {
///     typealias Entry = iOSIconsEntry
///     typealias PlatformConfig = iOSPlatformConfig
///
///     func exportIcons(
///         entries: [Entry],
///         platformConfig: PlatformConfig,
///         context: some IconsExportContext
///     ) async throws -> Int {
///         // Platform-specific export logic
///     }
/// }
/// ```
public protocol IconsExporter: AssetExporter {
    /// The configuration entry type for icons.
    associatedtype Entry: Sendable

    /// The platform configuration type.
    associatedtype PlatformConfig: Sendable

    /// Exports icons from Figma to the target platform.
    ///
    /// - Parameters:
    ///   - entries: Array of icons configuration entries.
    ///   - platformConfig: Platform-wide configuration.
    ///   - context: Export context with dependencies.
    /// - Returns: Number of icons exported.
    func exportIcons(
        entries: [Entry],
        platformConfig: PlatformConfig,
        context: some IconsExportContext
    ) async throws -> Int
}

// Default implementation for AssetExporter conformance
public extension IconsExporter {
    var assetType: AssetType { .icons }
}
