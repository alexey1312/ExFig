import Foundation

/// Cache model for tracking Figma file versions.
/// Used to skip exports when files haven't changed since last export.
struct ImageTrackingCache: Codable, Sendable {
    /// Current schema version for cache file format.
    static let currentSchemaVersion = 1

    /// Default cache file name.
    static let defaultFileName = ".exfig-cache.json"

    /// Schema version for cache format migration.
    let schemaVersion: Int

    /// Cached file versions keyed by file ID.
    var files: [String: CachedFileInfo]

    /// Creates a new empty cache.
    init() {
        schemaVersion = Self.currentSchemaVersion
        files = [:]
    }

    /// Creates cache with existing data.
    init(schemaVersion: Int, files: [String: CachedFileInfo]) {
        self.schemaVersion = schemaVersion
        self.files = files
    }
}

// MARK: - CachedFileInfo

/// Information about a cached Figma file.
struct CachedFileInfo: Codable, Sendable {
    /// Figma file version identifier.
    /// Changes when library is published or version is manually saved.
    let version: String

    /// ISO 8601 timestamp of last successful export.
    let lastExport: String

    /// Optional: file name for debugging/display purposes.
    let fileName: String?

    /// Creates cached file info.
    init(version: String, lastExport: Date = Date(), fileName: String? = nil) {
        self.version = version
        self.lastExport = ISO8601DateFormatter().string(from: lastExport)
        self.fileName = fileName
    }
}

// MARK: - Cache Persistence

extension ImageTrackingCache {
    /// Loads cache from a file at the specified path.
    /// Returns an empty cache if file doesn't exist or is invalid.
    static func load(from path: URL) -> ImageTrackingCache {
        guard FileManager.default.fileExists(atPath: path.path) else {
            return ImageTrackingCache()
        }

        do {
            let data = try Data(contentsOf: path)
            let decoder = JSONDecoder()
            let cache = try decoder.decode(ImageTrackingCache.self, from: data)

            // Check schema version and migrate if needed
            if cache.schemaVersion != currentSchemaVersion {
                // For now, just return empty cache on schema mismatch
                // Future: implement migration logic
                return ImageTrackingCache()
            }

            return cache
        } catch {
            // Invalid cache file, return empty cache
            return ImageTrackingCache()
        }
    }

    /// Saves cache to a file at the specified path.
    func save(to path: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: path, options: .atomic)
    }

    /// Resolves cache file path from optional custom path.
    static func resolvePath(customPath: String?) -> URL {
        if let customPath {
            return URL(fileURLWithPath: customPath)
        }
        return URL(fileURLWithPath: defaultFileName)
    }
}

// MARK: - Cache Operations

extension ImageTrackingCache {
    /// Checks if file version has changed since last export.
    /// Returns true if export is needed (version changed or file not in cache).
    func needsExport(fileId: String, currentVersion: String) -> Bool {
        guard let cached = files[fileId] else {
            // File not in cache, needs export
            return true
        }
        return cached.version != currentVersion
    }

    /// Updates cache with new file version after successful export.
    mutating func updateFileVersion(fileId: String, version: String, fileName: String? = nil) {
        files[fileId] = CachedFileInfo(
            version: version,
            lastExport: Date(),
            fileName: fileName
        )
    }

    /// Returns cached version for a file, if available.
    func cachedVersion(for fileId: String) -> String? {
        files[fileId]?.version
    }
}
