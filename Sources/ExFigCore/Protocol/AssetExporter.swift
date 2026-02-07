import Foundation

/// Protocol for asset exporters that handle the load-process-export cycle.
///
/// An `AssetExporter` is responsible for:
/// 1. Loading raw asset data from Figma
/// 2. Processing/transforming the data into platform-specific format
/// 3. Exporting the processed data to files
///
/// Each exporter handles a single `AssetType` (colors, icons, images, or typography).
///
/// ## Conformance
///
/// Conforming types are typically actors to ensure thread-safe state management:
///
/// ```swift
/// actor iOSColorsExporter: AssetExporter {
///     let assetType: AssetType = .colors
///
///     func load() async throws -> [Color] {
///         // Fetch colors from Figma Variables API
///     }
///
///     func process(_ data: [Color]) async throws -> [ProcessedColor] {
///         // Transform to iOS color format
///     }
///
///     func export(_ data: [ProcessedColor]) async throws -> ExportResult {
///         // Write xcassets and Swift extensions
///     }
/// }
/// ```
public protocol AssetExporter: Sendable {
    /// The type of asset this exporter handles.
    var assetType: AssetType { get }
}
