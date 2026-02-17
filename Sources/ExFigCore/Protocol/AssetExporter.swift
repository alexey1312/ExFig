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
/// Conforming types are typically structs marked as Sendable:
///
/// ```swift
/// struct iOSColorsExporter: ColorsExporter {
///     let assetType: AssetType = .colors
///
///     func exportColors(
///         entries: [iOSColorsEntry],
///         platformConfig: iOS.PlatformImpl,
///         context: ColorsExportContext
///     ) async throws -> ColorsExportResult {
///         // Load via context, process, write files
///     }
/// }
/// ```
public protocol AssetExporter: Sendable {
    /// The type of asset this exporter handles.
    var assetType: AssetType { get }
}
