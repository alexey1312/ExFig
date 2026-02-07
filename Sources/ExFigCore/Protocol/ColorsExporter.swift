import Foundation

/// Protocol for platform-specific colors exporters.
///
/// A `ColorsExporter` handles the full export cycle for colors:
/// 1. Loading color data from Figma Variables
/// 2. Processing colors into platform-specific format
/// 3. Writing color assets and code files
///
/// Each platform (iOS, Android, Flutter, Web) provides its own
/// implementation with platform-specific entry and config types.
///
/// ## Implementation
///
/// ```swift
/// struct iOSColorsExporter: ColorsExporter {
///     typealias Entry = iOSColorsEntry
///     typealias PlatformConfig = iOSPlatformConfig
///
///     func exportColors(
///         entries: [Entry],
///         platformConfig: PlatformConfig,
///         context: some ColorsExportContext
///     ) async throws -> Int {
///         // Platform-specific export logic
///     }
/// }
/// ```
public protocol ColorsExporter: AssetExporter {
    /// The configuration entry type for colors.
    associatedtype Entry: Sendable

    /// The platform configuration type.
    associatedtype PlatformConfig: Sendable

    /// Exports colors from Figma to the target platform.
    ///
    /// - Parameters:
    ///   - entries: Array of colors configuration entries.
    ///   - platformConfig: Platform-wide configuration.
    ///   - context: Export context with dependencies.
    /// - Returns: Number of colors exported.
    func exportColors(
        entries: [Entry],
        platformConfig: PlatformConfig,
        context: some ColorsExportContext
    ) async throws -> Int
}

/// Default implementation for AssetExporter conformance
public extension ColorsExporter {
    var assetType: AssetType {
        .colors
    }
}
