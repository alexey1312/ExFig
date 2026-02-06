import FigmaAPI
import Foundation

/// Helper for processing multiple entries sequentially and aggregating results.
enum EntryProcessor {
    /// Process multiple entries sequentially, aggregating results.
    /// - Parameters:
    ///   - entries: Array of entries to process.
    ///   - process: Async closure to process each entry.
    /// - Returns: Aggregated result combining all entry results.
    static func processEntries<Entry>(
        entries: [Entry],
        process: (Entry) async throws -> PlatformExportResult
    ) async throws -> PlatformExportResult {
        var totalCount = 0
        var totalSkipped = 0
        var allHashes: [String: [NodeId: String]] = [:]

        for entry in entries {
            let result = try await process(entry)
            totalCount += result.count
            totalSkipped += result.skippedCount
            allHashes = HashMerger.merge(allHashes, result.hashes)
        }

        return PlatformExportResult(
            count: totalCount,
            hashes: allHashes,
            skippedCount: totalSkipped
        )
    }
}
