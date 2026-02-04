import Foundation

/// Protocol for platform-specific typography exporters.
///
/// A `TypographyExporter` handles the full export cycle for typography:
/// 1. Loading text style data from Figma
/// 2. Processing text styles into platform-specific format
/// 3. Writing typography assets and code files
///
/// Each platform (iOS, Android) provides its own implementation
/// with platform-specific entry and config types.
///
/// ## Implementation
///
/// ```swift
/// struct iOSTypographyExporter: TypographyExporter {
///     typealias Entry = iOSTypographyEntry
///     typealias PlatformConfig = iOSPlatformConfig
///
///     func exportTypography(
///         entry: Entry,
///         platformConfig: PlatformConfig,
///         context: some TypographyExportContext
///     ) async throws -> Int {
///         // Platform-specific export logic
///     }
/// }
/// ```
public protocol TypographyExporter: AssetExporter {
    /// The configuration entry type for typography.
    associatedtype Entry: Sendable

    /// The platform configuration type.
    associatedtype PlatformConfig: Sendable

    /// Exports typography from Figma to the target platform.
    ///
    /// - Parameters:
    ///   - entry: Typography configuration entry.
    ///   - platformConfig: Platform-wide configuration.
    ///   - context: Export context with dependencies.
    /// - Returns: Number of text styles exported.
    func exportTypography(
        entry: Entry,
        platformConfig: PlatformConfig,
        context: some TypographyExportContext
    ) async throws -> Int
}

// Default implementation for AssetExporter conformance
public extension TypographyExporter {
    var assetType: AssetType { .typography }
}
