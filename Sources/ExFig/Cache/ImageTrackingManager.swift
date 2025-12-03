import FigmaAPI
import Foundation
import Logging

/// Result of checking file versions for changes.
enum VersionCheckResult: Sendable {
    /// All files have changed or are not in cache, full export needed.
    case exportNeeded(files: [FileVersionInfo])

    /// No files have changed, export can be skipped.
    case noChanges(files: [FileVersionInfo])

    /// Some files changed, some didn't (for multi-file exports).
    case partialChanges(changed: [FileVersionInfo], unchanged: [FileVersionInfo])
}

/// Information about a file's version status.
struct FileVersionInfo: Sendable {
    let fileId: String
    let fileName: String
    let currentVersion: String
    let cachedVersion: String?
    let needsExport: Bool
}

/// Manages Figma file version tracking and caching.
/// Used to skip exports when files haven't changed since last export.
final class ImageTrackingManager: @unchecked Sendable {
    private let client: Client
    private let cachePath: URL
    private let logger: Logger
    private var cache: ImageTrackingCache

    /// Creates a new tracking manager.
    /// - Parameters:
    ///   - client: Figma API client for fetching file metadata.
    ///   - cachePath: Path to the cache file (nil uses default).
    ///   - logger: Logger for debug output.
    init(client: Client, cachePath: String? = nil, logger: Logger) {
        self.client = client
        self.cachePath = ImageTrackingCache.resolvePath(customPath: cachePath)
        self.logger = logger
        cache = ImageTrackingCache.load(from: self.cachePath)
    }

    // MARK: - Version Checking

    /// Checks if any of the specified files have changed since last export.
    /// - Parameters:
    ///   - fileIds: List of Figma file IDs to check.
    ///   - force: If true, always returns exportNeeded regardless of cache.
    /// - Returns: Result indicating which files need export.
    func checkForChanges(fileIds: [String], force: Bool = false) async throws -> VersionCheckResult {
        // If force mode, skip cache check entirely
        if force {
            let infos = try await fetchFileVersions(fileIds: fileIds)
            return .exportNeeded(files: infos)
        }

        // Fetch current versions from Figma API
        let infos = try await fetchFileVersions(fileIds: fileIds)

        let changed = infos.filter(\.needsExport)
        let unchanged = infos.filter { !$0.needsExport }

        if changed.isEmpty {
            return .noChanges(files: unchanged)
        } else if unchanged.isEmpty {
            return .exportNeeded(files: changed)
        } else {
            return .partialChanges(changed: changed, unchanged: unchanged)
        }
    }

    /// Fetches file versions in parallel and compares with cache.
    private func fetchFileVersions(fileIds: [String]) async throws -> [FileVersionInfo] {
        try await withThrowingTaskGroup(of: FileVersionInfo.self) { [self] group in
            for fileId in fileIds {
                group.addTask { [fileId] in
                    let metadata = try await self.fetchFileMetadata(fileId: fileId)
                    let cachedVersion = self.cache.cachedVersion(for: fileId)
                    let needsExport = self.cache.needsExport(fileId: fileId, currentVersion: metadata.version)

                    return FileVersionInfo(
                        fileId: fileId,
                        fileName: metadata.name,
                        currentVersion: metadata.version,
                        cachedVersion: cachedVersion,
                        needsExport: needsExport
                    )
                }
            }

            var results: [FileVersionInfo] = []
            for try await info in group {
                results.append(info)
            }
            return results
        }
    }

    /// Fetches file metadata from Figma API.
    private func fetchFileMetadata(fileId: String) async throws -> FileMetadata {
        let endpoint = FileMetadataEndpoint(fileId: fileId)
        return try await client.request(endpoint)
    }

    // MARK: - Cache Management

    /// Updates cache after successful export.
    /// - Parameters:
    ///   - fileInfos: File version information to cache.
    func updateCache(with fileInfos: [FileVersionInfo]) throws {
        for info in fileInfos {
            cache.updateFileVersion(
                fileId: info.fileId,
                version: info.currentVersion,
                fileName: info.fileName
            )
        }
        try cache.save(to: cachePath)
        logger.info("Cache updated at \(cachePath.path)")
    }

    /// Updates cache for a single file after successful export.
    func updateCache(fileId: String, version: String, fileName: String? = nil) throws {
        cache.updateFileVersion(fileId: fileId, version: version, fileName: fileName)
        try cache.save(to: cachePath)
    }

    /// Clears all cached data.
    func clearCache() throws {
        cache = ImageTrackingCache()
        try cache.save(to: cachePath)
        logger.info("Cache cleared")
    }

    /// Returns the current cache path.
    var currentCachePath: URL {
        cachePath
    }
}

// MARK: - Convenience Extensions

extension ImageTrackingManager {
    /// Checks if files need export based on light and optional dark file IDs.
    /// - Parameters:
    ///   - lightFileId: Light mode file ID.
    ///   - darkFileId: Optional dark mode file ID.
    ///   - force: If true, always returns exportNeeded.
    /// - Returns: Result indicating if export is needed.
    func checkForChanges(
        lightFileId: String,
        darkFileId: String? = nil,
        force: Bool = false
    ) async throws -> VersionCheckResult {
        var fileIds = [lightFileId]
        if let darkFileId {
            fileIds.append(darkFileId)
        }
        return try await checkForChanges(fileIds: fileIds, force: force)
    }
}
