import Foundation

/// The result of an asset export operation.
///
/// Contains metadata about what was exported, including the number of files
/// written and the type of asset that was processed.
public struct ExportResult: Sendable, Equatable {
    /// The number of files written during the export operation.
    public let filesWritten: Int

    /// The type of asset that was exported.
    public let assetType: AssetType

    /// Creates a new export result.
    ///
    /// - Parameters:
    ///   - filesWritten: The number of files written during export.
    ///   - assetType: The type of asset that was exported.
    public init(filesWritten: Int, assetType: AssetType) {
        self.filesWritten = filesWritten
        self.assetType = assetType
    }
}
