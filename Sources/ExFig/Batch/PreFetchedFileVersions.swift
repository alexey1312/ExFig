import FigmaAPI

/// Pre-fetched file metadata for batch processing optimization.
///
/// When batch processing multiple configs that reference the same Figma files,
/// this storage allows sharing pre-fetched file metadata across all configs,
/// avoiding redundant API calls.
struct PreFetchedFileVersions: Sendable {
    /// Stored file metadata keyed by fileId.
    private let versions: [String: FileMetadata]

    /// Creates a new storage with pre-fetched versions.
    /// - Parameter versions: Dictionary mapping fileId to its metadata.
    init(versions: [String: FileMetadata]) {
        self.versions = versions
    }

    /// Get pre-fetched metadata for a fileId.
    /// - Parameter fileId: The Figma file ID to look up.
    /// - Returns: The metadata if pre-fetched, nil otherwise.
    func metadata(for fileId: String) -> FileMetadata? {
        versions[fileId]
    }

    /// Check if a fileId has pre-fetched metadata.
    /// - Parameter fileId: The Figma file ID to check.
    /// - Returns: True if metadata exists for this fileId.
    func hasMetadata(for fileId: String) -> Bool {
        versions[fileId] != nil
    }

    /// Number of pre-fetched file versions.
    var count: Int {
        versions.count
    }

    /// All file IDs that have been pre-fetched.
    var allFileIds: [String] {
        Array(versions.keys)
    }
}

/// TaskLocal storage for pre-fetched file versions.
///
/// This is used by batch processing to share pre-fetched file metadata across
/// multiple config executions. When running individual commands (not in batch mode),
/// the storage is `nil` and commands fetch their own metadata.
///
/// ## Usage in Batch Mode
///
/// ```swift
/// let preFetched = try await preFetcher.preFetch(fileIds: uniqueIds)
/// await PreFetchedVersionsStorage.$versions.withValue(preFetched) {
///     // All configs executed here will use pre-fetched versions
///     await executor.execute(configs: configs) { ... }
/// }
/// ```
///
/// ## Usage in ImageTrackingManager
///
/// ```swift
/// if let preFetched = PreFetchedVersionsStorage.versions,
///    let metadata = preFetched.metadata(for: fileId) {
///     return metadata  // Use pre-fetched
/// }
/// // Fall back to API request
/// ```
enum PreFetchedVersionsStorage {
    @TaskLocal static var versions: PreFetchedFileVersions?
}
