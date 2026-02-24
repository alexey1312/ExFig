import Foundation

/// Tracks file write operations for asset manifest generation.
///
/// Only active when `--report` is specified — zero overhead otherwise.
/// Set via `ManifestTrackerStorage.current` before export, cleared after.
///
/// Initialized with a default `assetType` since each export command handles
/// one asset type (colors/icons/images/typography).
actor ManifestTracker {
    private var entries: [ManifestEntry] = []

    /// Default asset type for all recorded entries.
    let defaultAssetType: String

    init(assetType: String) {
        defaultAssetType = assetType
    }

    /// Record a file write operation.
    ///
    /// Determines action by checking whether the file existed before and comparing
    /// content hashes via `FNV1aHasher.hashToHex()`.
    ///
    /// - Parameters:
    ///   - path: Absolute path to the written file.
    ///   - data: Content that was written (used for checksum).
    ///   - assetType: Type of asset. Defaults to tracker's `defaultAssetType`.
    func recordWrite(path: String, data: Data, assetType: String? = nil) {
        let assetType = assetType ?? defaultAssetType
        let relativePath = makeRelativePath(path)
        let newChecksum = FNV1aHasher.hashToHex(data)
        let fileExisted = FileManager.default.fileExists(atPath: path)

        let action: FileAction
        if !fileExisted {
            action = .created
        } else if let existingData = FileManager.default.contents(atPath: path) {
            let existingChecksum = FNV1aHasher.hashToHex(existingData)
            action = existingChecksum == newChecksum ? .unchanged : .modified
        } else {
            action = .modified
        }

        entries.append(ManifestEntry(
            path: relativePath,
            action: action,
            checksum: newChecksum,
            assetType: assetType
        ))
    }

    /// Record a file copy operation (for files copied from local source).
    ///
    /// - Parameters:
    ///   - path: Absolute path to the destination file.
    ///   - sourceURL: URL of the source file being copied.
    ///   - assetType: Type of asset. Defaults to tracker's `defaultAssetType`.
    func recordCopy(path: String, sourceURL: URL, assetType: String? = nil) {
        let assetType = assetType ?? defaultAssetType
        let relativePath = makeRelativePath(path)

        guard let sourceData = try? Data(contentsOf: sourceURL) else {
            entries.append(ManifestEntry(
                path: relativePath,
                action: .created,
                checksum: nil,
                assetType: assetType
            ))
            return
        }

        let newChecksum = FNV1aHasher.hashToHex(sourceData)
        let fileExisted = FileManager.default.fileExists(atPath: path)

        let action: FileAction
        if !fileExisted {
            action = .created
        } else if let existingData = FileManager.default.contents(atPath: path) {
            let existingChecksum = FNV1aHasher.hashToHex(existingData)
            action = existingChecksum == newChecksum ? .unchanged : .modified
        } else {
            action = .modified
        }

        entries.append(ManifestEntry(
            path: relativePath,
            action: action,
            checksum: newChecksum,
            assetType: assetType
        ))
    }

    /// Get all recorded manifest entries.
    func getAll() -> [ManifestEntry] {
        entries
    }

    /// Build an `AssetManifest` from recorded entries.
    ///
    /// If `previousReportPath` is provided, detects deleted files by comparing
    /// against the previous report's manifest.
    func buildManifest(previousReportPath: String? = nil) -> AssetManifest {
        var allEntries = entries

        if let previousPath = previousReportPath,
           let previousData = FileManager.default.contents(atPath: previousPath),
           let previousReport = try? JSONDecoder().decode(PreviousReportManifest.self, from: previousData)
        {
            let currentPaths = Set(entries.map(\.path))
            for previousEntry in previousReport.manifest?.files ?? []
                where !currentPaths.contains(previousEntry.path)
            {
                allEntries.append(ManifestEntry(
                    path: previousEntry.path,
                    action: .deleted,
                    checksum: nil,
                    assetType: previousEntry.assetType
                ))
            }
        }

        return AssetManifest(files: allEntries)
    }

    /// Make path relative to current working directory.
    private func makeRelativePath(_ absolutePath: String) -> String {
        let cwd = FileManager.default.currentDirectoryPath
        if absolutePath.hasPrefix(cwd + "/") {
            return String(absolutePath.dropFirst(cwd.count + 1))
        }
        return absolutePath
    }
}

/// Lightweight Decodable for reading only the manifest from a previous report.
private struct PreviousReportManifest: Decodable {
    let manifest: PreviousManifest?

    struct PreviousManifest: Decodable {
        let files: [PreviousEntry]
    }

    struct PreviousEntry: Decodable {
        let path: String
        let assetType: String
    }
}

/// Global storage for the active manifest tracker.
///
/// Same pattern as `WarningCollectorStorage` — `nonisolated(unsafe)` static var.
enum ManifestTrackerStorage {
    nonisolated(unsafe) static var current: ManifestTracker?
}
