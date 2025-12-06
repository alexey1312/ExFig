import FigmaAPI
import Foundation

/// Metadata wrapper for raw Figma export.
public struct RawExportMetadata: Codable, Sendable {
    /// The name of the Figma file.
    public let name: String

    /// The Figma file ID.
    public let fileId: String

    /// Timestamp when the export was created (ISO 8601 format).
    public let exportedAt: String

    /// Version of ExFig used for the export.
    public let exfigVersion: String

    public init(name: String, fileId: String, exfigVersion: String) {
        self.name = name
        self.fileId = fileId
        self.exfigVersion = exfigVersion
        exportedAt = ISO8601DateFormatter().string(from: Date())
    }
}

/// Output structure for raw Figma API export.
public struct RawExportOutput<T: Encodable & Sendable>: Encodable, Sendable {
    /// Source metadata about the export.
    public let source: RawExportMetadata

    /// Raw Figma API response data.
    public let data: T

    public init(source: RawExportMetadata, data: T) {
        self.source = source
        self.data = data
    }
}

/// Serializes raw Figma data to JSON.
public struct RawExporter: Sendable {
    public init() {}

    /// Serializes the raw export output to JSON.
    ///
    /// - Parameters:
    ///   - output: The raw export output to serialize.
    ///   - compact: If true, outputs minified JSON; otherwise pretty-printed.
    /// - Returns: JSON data.
    public func serialize(_ output: RawExportOutput<some Encodable & Sendable>, compact: Bool) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = compact ? [.sortedKeys] : [.prettyPrinted, .sortedKeys]
        return try encoder.encode(output)
    }
}
