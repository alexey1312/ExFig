@testable import ExFig
import XCTest

final class ImageTrackingCacheTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Initialization

    func testInitCreatesEmptyCache() {
        let cache = ImageTrackingCache()

        XCTAssertEqual(cache.schemaVersion, ImageTrackingCache.currentSchemaVersion)
        XCTAssertTrue(cache.files.isEmpty)
    }

    // MARK: - needsExport

    func testNeedsExportReturnsTrueForNewFile() {
        let cache = ImageTrackingCache()

        XCTAssertTrue(cache.needsExport(fileId: "abc123", currentVersion: "v1"))
    }

    func testNeedsExportReturnsFalseForSameVersion() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "abc123", version: "v1")

        XCTAssertFalse(cache.needsExport(fileId: "abc123", currentVersion: "v1"))
    }

    func testNeedsExportReturnsTrueForDifferentVersion() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "abc123", version: "v1")

        XCTAssertTrue(cache.needsExport(fileId: "abc123", currentVersion: "v2"))
    }

    // MARK: - updateFileVersion

    func testUpdateFileVersionAddsNewEntry() {
        var cache = ImageTrackingCache()

        cache.updateFileVersion(fileId: "abc123", version: "v1", fileName: "Design System")

        XCTAssertEqual(cache.files.count, 1)
        XCTAssertEqual(cache.files["abc123"]?.version, "v1")
        XCTAssertEqual(cache.files["abc123"]?.fileName, "Design System")
    }

    func testUpdateFileVersionReplacesExistingEntry() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "abc123", version: "v1")
        cache.updateFileVersion(fileId: "abc123", version: "v2")

        XCTAssertEqual(cache.files["abc123"]?.version, "v2")
    }

    // MARK: - cachedVersion

    func testCachedVersionReturnsNilForUnknownFile() {
        let cache = ImageTrackingCache()

        XCTAssertNil(cache.cachedVersion(for: "unknown"))
    }

    func testCachedVersionReturnsVersionForKnownFile() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "abc123", version: "v1")

        XCTAssertEqual(cache.cachedVersion(for: "abc123"), "v1")
    }

    // MARK: - Persistence

    func testSaveAndLoadCache() throws {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "file1", version: "v1", fileName: "File 1")
        cache.updateFileVersion(fileId: "file2", version: "v2", fileName: "File 2")

        let cachePath = tempDirectory.appendingPathComponent("test-cache.json")
        try cache.save(to: cachePath)

        let loadedCache = ImageTrackingCache.load(from: cachePath)

        XCTAssertEqual(loadedCache.files.count, 2)
        XCTAssertEqual(loadedCache.cachedVersion(for: "file1"), "v1")
        XCTAssertEqual(loadedCache.cachedVersion(for: "file2"), "v2")
    }

    func testLoadReturnsEmptyCacheForMissingFile() {
        let nonExistentPath = tempDirectory.appendingPathComponent("non-existent.json")

        let cache = ImageTrackingCache.load(from: nonExistentPath)

        XCTAssertTrue(cache.files.isEmpty)
    }

    func testLoadReturnsEmptyCacheForInvalidJSON() throws {
        let invalidPath = tempDirectory.appendingPathComponent("invalid.json")
        try Data("invalid json".utf8).write(to: invalidPath)

        let cache = ImageTrackingCache.load(from: invalidPath)

        XCTAssertTrue(cache.files.isEmpty)
    }

    // MARK: - Path Resolution

    func testResolvePathUsesDefaultWhenNil() {
        let path = ImageTrackingCache.resolvePath(customPath: nil)

        XCTAssertEqual(path.lastPathComponent, ImageTrackingCache.defaultFileName)
    }

    func testResolvePathUsesCustomPath() {
        let customPath = "/custom/path/cache.json"

        let path = ImageTrackingCache.resolvePath(customPath: customPath)

        XCTAssertEqual(path.path, customPath)
    }

    // MARK: - Schema Migration v1 → v2

    func testMigrationFromV1PreservesExistingFiles() throws {
        // Create a v1 cache JSON (without nodeHashes)
        let v1JSON = """
        {
            "schemaVersion": 1,
            "files": {
                "fileA": {
                    "version": "v1",
                    "lastExport": "2025-01-01T00:00:00Z",
                    "fileName": "File A"
                }
            }
        }
        """

        let cachePath = tempDirectory.appendingPathComponent("v1-cache.json")
        try Data(v1JSON.utf8).write(to: cachePath)

        let cache = ImageTrackingCache.load(from: cachePath)

        // File data should be preserved
        XCTAssertEqual(cache.files["fileA"]?.version, "v1")
        XCTAssertEqual(cache.files["fileA"]?.fileName, "File A")
        // nodeHashes should be nil for migrated files
        XCTAssertNil(cache.files["fileA"]?.nodeHashes)
        // Schema version should be updated
        XCTAssertEqual(cache.schemaVersion, ImageTrackingCache.currentSchemaVersion)
    }

    // MARK: - Node Hashes - changedNodeIds

    func testChangedNodeIdsReturnsAllWhenNoCachedHashes() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")

        let currentHashes = ["1:1": "hash1", "1:2": "hash2", "1:3": "hash3"]

        let changed = cache.changedNodeIds(fileId: "fileA", currentHashes: currentHashes)

        XCTAssertEqual(Set(changed), Set(["1:1", "1:2", "1:3"]))
    }

    func testChangedNodeIdsReturnsEmptyWhenAllHashesMatch() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1", "1:2": "hash2"])

        let currentHashes = ["1:1": "hash1", "1:2": "hash2"]

        let changed = cache.changedNodeIds(fileId: "fileA", currentHashes: currentHashes)

        XCTAssertTrue(changed.isEmpty)
    }

    func testChangedNodeIdsReturnsOnlyChangedWhenSomeDiffer() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        cache.updateNodeHashes(fileId: "fileA", hashes: [
            "1:1": "hash1",
            "1:2": "hash2",
            "1:3": "hash3",
        ])

        // 1:2 changed, others unchanged
        let currentHashes = [
            "1:1": "hash1",
            "1:2": "hash2-changed",
            "1:3": "hash3",
        ]

        let changed = cache.changedNodeIds(fileId: "fileA", currentHashes: currentHashes)

        XCTAssertEqual(changed, ["1:2"])
    }

    func testChangedNodeIdsReturnsNewIds() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1"])

        // 1:2 is new
        let currentHashes = ["1:1": "hash1", "1:2": "hash2"]

        let changed = cache.changedNodeIds(fileId: "fileA", currentHashes: currentHashes)

        XCTAssertEqual(changed, ["1:2"])
    }

    func testChangedNodeIdsExcludesDeletedNodes() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        cache.updateNodeHashes(fileId: "fileA", hashes: [
            "1:1": "hash1",
            "1:2": "hash2", // will be deleted
        ])

        // 1:2 no longer exists in current nodes
        let currentHashes = ["1:1": "hash1"]

        let changed = cache.changedNodeIds(fileId: "fileA", currentHashes: currentHashes)

        // Should not include deleted node
        XCTAssertTrue(changed.isEmpty)
    }

    // MARK: - Node Hashes - updateNodeHashes

    func testUpdateNodeHashesStoresHashes() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")

        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1", "1:2": "hash2"])

        XCTAssertEqual(cache.files["fileA"]?.nodeHashes?["1:1"], "hash1")
        XCTAssertEqual(cache.files["fileA"]?.nodeHashes?["1:2"], "hash2")
    }

    func testUpdateNodeHashesReplacesExisting() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1"])
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1-new", "1:2": "hash2"])

        XCTAssertEqual(cache.files["fileA"]?.nodeHashes?["1:1"], "hash1-new")
        XCTAssertEqual(cache.files["fileA"]?.nodeHashes?["1:2"], "hash2")
    }

    // MARK: - Node Hashes - clearNodeHashes

    func testClearNodeHashesRemovesHashes() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1"])

        cache.clearNodeHashes(fileId: "fileA")

        XCTAssertNil(cache.files["fileA"]?.nodeHashes)
    }

    func testClearNodeHashesPreservesVersion() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1", fileName: "File A")
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1"])

        cache.clearNodeHashes(fileId: "fileA")

        // Version info should be preserved
        XCTAssertEqual(cache.files["fileA"]?.version, "v1")
        XCTAssertEqual(cache.files["fileA"]?.fileName, "File A")
    }

    // MARK: - Node Hashes - clearAllNodeHashes

    func testClearAllNodeHashesRemovesHashesFromAllFiles() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        cache.updateFileVersion(fileId: "fileB", version: "v2")
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1"])
        cache.updateNodeHashes(fileId: "fileB", hashes: ["2:1": "hash2", "2:2": "hash3"])

        cache.clearAllNodeHashes()

        XCTAssertNil(cache.files["fileA"]?.nodeHashes)
        XCTAssertNil(cache.files["fileB"]?.nodeHashes)
    }

    func testClearAllNodeHashesPreservesVersions() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1", fileName: "File A")
        cache.updateFileVersion(fileId: "fileB", version: "v2", fileName: "File B")
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1"])
        cache.updateNodeHashes(fileId: "fileB", hashes: ["2:1": "hash2"])

        cache.clearAllNodeHashes()

        // Version info should be preserved for all files
        XCTAssertEqual(cache.files["fileA"]?.version, "v1")
        XCTAssertEqual(cache.files["fileA"]?.fileName, "File A")
        XCTAssertEqual(cache.files["fileB"]?.version, "v2")
        XCTAssertEqual(cache.files["fileB"]?.fileName, "File B")
    }

    // MARK: - Node Hashes Persistence

    func testNodeHashesPersistAfterSaveAndLoad() throws {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1", "1:2": "hash2"])

        let cachePath = tempDirectory.appendingPathComponent("node-hash-cache.json")
        try cache.save(to: cachePath)

        let loadedCache = ImageTrackingCache.load(from: cachePath)

        XCTAssertEqual(loadedCache.files["fileA"]?.nodeHashes?["1:1"], "hash1")
        XCTAssertEqual(loadedCache.files["fileA"]?.nodeHashes?["1:2"], "hash2")
    }

    // MARK: - Hash Merge Tests

    func testUpdateNodeHashesMergesWithExisting() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")

        // First update: add hashes for nodes 1:1, 1:2
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1", "1:2": "hash2"])

        // Second update: add hashes for nodes 1:3, 1:4
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:3": "hash3", "1:4": "hash4"])

        // All 4 hashes should be present
        let hashes = cache.files["fileA"]?.nodeHashes
        XCTAssertEqual(hashes?.count, 4)
        XCTAssertEqual(hashes?["1:1"], "hash1")
        XCTAssertEqual(hashes?["1:2"], "hash2")
        XCTAssertEqual(hashes?["1:3"], "hash3")
        XCTAssertEqual(hashes?["1:4"], "hash4")
    }

    func testUpdateNodeHashesOverwritesExistingForSameNode() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")

        // First update: add hash for node 1:1
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "oldHash"])

        // Second update: update hash for same node 1:1
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "newHash"])

        // New hash should overwrite old
        let hashes = cache.files["fileA"]?.nodeHashes
        XCTAssertEqual(hashes?.count, 1)
        XCTAssertEqual(hashes?["1:1"], "newHash")
    }

    func testUpdateNodeHashesMergesMultipleUpdates() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")

        // Simulate batch mode: multiple configs updating same file
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1", "1:2": "hash2"])
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:3": "hash3"])
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:4": "hash4", "1:5": "hash5"])

        // All hashes should be present
        let hashes = cache.files["fileA"]?.nodeHashes
        XCTAssertEqual(hashes?.count, 5)
        XCTAssertEqual(hashes?["1:1"], "hash1")
        XCTAssertEqual(hashes?["1:2"], "hash2")
        XCTAssertEqual(hashes?["1:3"], "hash3")
        XCTAssertEqual(hashes?["1:4"], "hash4")
        XCTAssertEqual(hashes?["1:5"], "hash5")
    }
}
