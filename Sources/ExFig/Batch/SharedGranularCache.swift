import Foundation

/// Shared granular cache for batch processing.
///
/// When batch processing multiple configs with `--experimental-granular-cache`,
/// this storage allows sharing pre-loaded node hashes across all parallel workers,
/// avoiding race conditions on cache file read/write.
///
/// ## Problem Solved
///
/// Without shared cache, each parallel worker:
/// 1. Loads cache from disk independently (race on read)
/// 2. Updates cache after export (race on write - last writer wins)
/// 3. Only one config benefits from granular cache
///
/// ## Solution
///
/// 1. Load cache once before parallel execution
/// 2. Share via `@TaskLocal` (read-only during execution)
/// 3. Workers return computed hashes in `ExportStats`
/// 4. Merge all hashes and save once after batch completes
struct SharedGranularCache: Sendable {
    /// Pre-loaded cache data (read-only during batch execution).
    let cache: ImageTrackingCache

    /// Path to save updated cache after batch completes.
    let cachePath: URL

    /// Get cached node hashes for a Figma file.
    /// - Parameter fileId: The Figma file ID.
    /// - Returns: Map of node ID to hash, or nil if not cached.
    func nodeHashes(for fileId: String) -> [String: String]? {
        cache.files[fileId]?.nodeHashes
    }

    /// Check if a file has cached node hashes.
    /// - Parameter fileId: The Figma file ID.
    /// - Returns: True if node hashes exist for this file.
    func hasNodeHashes(for fileId: String) -> Bool {
        cache.files[fileId]?.nodeHashes != nil
    }
}

/// TaskLocal storage for shared granular cache.
///
/// This is used by batch processing to share pre-loaded node hashes across
/// multiple config executions. When running individual commands (not in batch mode),
/// the storage is `nil` and commands load cache from disk as usual.
///
/// ## Usage in Batch Mode
///
/// ```swift
/// let cachePath = ImageTrackingCache.resolvePath(customPath: cachePath)
/// let cacheData = ImageTrackingCache.load(from: cachePath)
/// let sharedCache = SharedGranularCache(cache: cacheData, cachePath: cachePath)
///
/// await SharedGranularCacheStorage.$cache.withValue(sharedCache) {
///     // All configs executed here will use shared cache
///     await executor.execute(configs: configs) { ... }
/// }
///
/// // After batch: merge computed hashes and save once
/// ```
///
/// ## Usage in ImageTrackingManager
///
/// ```swift
/// if let shared = SharedGranularCacheStorage.cache {
///     // Use shared cache (batch mode)
///     return shared.nodeHashes(for: fileId)
/// }
/// // Fall back to disk cache (standalone mode)
/// ```
enum SharedGranularCacheStorage {
    @TaskLocal static var cache: SharedGranularCache?
}
