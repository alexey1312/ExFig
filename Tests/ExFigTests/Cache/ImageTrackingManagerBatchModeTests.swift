@testable import ExFigCLI
@testable import FigmaAPI
import Logging
import XCTest

final class ImageTrackingManagerBatchModeTests: XCTestCase {
    var tempDirectory: URL!
    var mockClient: MockClient!
    var logger: Logger!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        mockClient = MockClient()
        logger = Logger(label: "test")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Batch Mode Detection

    func testBatchModeFlagIsSetWhenProvided() {
        let cachePath = tempDirectory.appendingPathComponent("cache.json").path
        let manager = ImageTrackingManager(
            client: mockClient,
            cachePath: cachePath,
            logger: logger,
            batchMode: true
        )

        XCTAssertTrue(manager.batchMode)
    }

    func testBatchModeFlagDefaultsToFalse() {
        let cachePath = tempDirectory.appendingPathComponent("cache.json").path
        let manager = ImageTrackingManager(
            client: mockClient,
            cachePath: cachePath,
            logger: logger
        )

        XCTAssertFalse(manager.batchMode)
    }

    // MARK: - Shared Cache in Batch Mode

    func testUsesSharedCacheInBatchMode() {
        // Create cache with pre-populated node hashes
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1"])

        let cachePath = tempDirectory.appendingPathComponent("shared-cache.json")
        let sharedCache = SharedGranularCache(cache: cache, cachePath: cachePath)
        let batchContext = BatchContext(granularCache: sharedCache)

        // Create manager in batch mode with shared cache
        BatchSharedState.$current.withValue(BatchSharedState(context: batchContext)) {
            let manager = ImageTrackingManager(
                client: mockClient,
                cachePath: nil,
                logger: logger,
                batchMode: true
            )

            // Manager should use shared cache path
            XCTAssertEqual(manager.currentCachePath, cachePath)

            // Granular cache manager should have access to node hashes
            let granularManager = manager.createGranularCacheManager()
            XCTAssertNotNil(granularManager)
        }
    }

    func testUsesLocalCacheWhenBatchModeButNoSharedCache() {
        let customPath = tempDirectory.appendingPathComponent("local-cache.json").path

        // batchMode=true but no BatchContextStorage.context set
        let manager = ImageTrackingManager(
            client: mockClient,
            cachePath: customPath,
            logger: logger,
            batchMode: true
        )

        // Should fall back to custom/default path
        XCTAssertEqual(manager.currentCachePath.path, customPath)
    }

    // MARK: - Node Hash Updates in Batch Mode

    func testUpdateNodeHashesIsNoOpInBatchMode() throws {
        let cachePath = tempDirectory.appendingPathComponent("cache.json")
        let manager = ImageTrackingManager(
            client: mockClient,
            cachePath: cachePath.path,
            logger: logger,
            batchMode: true
        )

        // Try to update node hashes
        try manager.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1"])

        // Cache file should not exist (no save happened)
        XCTAssertFalse(FileManager.default.fileExists(atPath: cachePath.path))
    }

    func testUpdateNodeHashesSavesToDiskInStandaloneMode() throws {
        let cachePath = tempDirectory.appendingPathComponent("cache.json")

        // Pre-populate cache with file entry (required for updateNodeHashes)
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        try cache.save(to: cachePath)

        // Create manager in standalone mode (batchMode=false)
        let manager = ImageTrackingManager(
            client: mockClient,
            cachePath: cachePath.path,
            logger: logger,
            batchMode: false
        )

        // Update node hashes
        try manager.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1"])

        // Cache file should exist (save happened)
        XCTAssertTrue(FileManager.default.fileExists(atPath: cachePath.path))

        // Verify content
        let loadedCache = ImageTrackingCache.load(from: cachePath)
        XCTAssertEqual(loadedCache.files["fileA"]?.nodeHashes?["1:1"], "hash1")
    }

    // MARK: - Clear Node Hashes in Batch Mode

    func testClearNodeHashesIsNoOpInBatchMode() throws {
        // Pre-populate cache file with node hashes
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1"])

        let cachePath = tempDirectory.appendingPathComponent("cache.json")
        try cache.save(to: cachePath)

        // Create manager in batch mode
        let manager = ImageTrackingManager(
            client: mockClient,
            cachePath: cachePath.path,
            logger: logger,
            batchMode: true
        )

        // Try to clear node hashes
        try manager.clearNodeHashes(fileId: "fileA")

        // Load cache from disk - hashes should still be there
        // (the in-memory clear doesn't save in batch mode)
        let loadedCache = ImageTrackingCache.load(from: cachePath)
        XCTAssertEqual(loadedCache.files["fileA"]?.nodeHashes?["1:1"], "hash1")
    }

    func testClearNodeHashesSavesToDiskInStandaloneMode() throws {
        // Pre-populate cache file with node hashes
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1"])

        let cachePath = tempDirectory.appendingPathComponent("cache.json")
        try cache.save(to: cachePath)

        // Create manager in standalone mode
        let manager = ImageTrackingManager(
            client: mockClient,
            cachePath: cachePath.path,
            logger: logger,
            batchMode: false
        )

        // Clear node hashes
        try manager.clearNodeHashes(fileId: "fileA")

        // Load cache from disk - hashes should be cleared
        let loadedCache = ImageTrackingCache.load(from: cachePath)
        XCTAssertNil(loadedCache.files["fileA"]?.nodeHashes)
    }

    // MARK: - Batch Mode with TaskLocal Injection

    func testBatchModeWorksWithTaskLocalInjection() {
        // Create shared cache with node hashes
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "icons-file", version: "v5")
        cache.updateNodeHashes(fileId: "icons-file", hashes: [
            "100:1": "hashA",
            "100:2": "hashB",
            "100:3": "hashC",
        ])

        let cachePath = tempDirectory.appendingPathComponent("shared.json")
        let sharedCache = SharedGranularCache(cache: cache, cachePath: cachePath)
        let batchContext = BatchContext(granularCache: sharedCache)

        var managerInBatchMode: ImageTrackingManager?

        BatchSharedState.$current.withValue(BatchSharedState(context: batchContext)) {
            // Create manager inside TaskLocal scope
            managerInBatchMode = ImageTrackingManager(
                client: mockClient,
                cachePath: nil,
                logger: logger,
                batchMode: true
            )

            // Verify it picked up shared cache
            XCTAssertEqual(managerInBatchMode?.currentCachePath, cachePath)
            XCTAssertTrue(managerInBatchMode?.batchMode ?? false)
        }
    }

    // MARK: - Parallel Access in Batch Mode

    func testMultipleManagersShareSameCache() {
        // Create shared cache
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "shared-file", version: "v1")
        cache.updateNodeHashes(fileId: "shared-file", hashes: ["1:1": "original-hash"])

        let cachePath = tempDirectory.appendingPathComponent("shared.json")
        let sharedCache = SharedGranularCache(cache: cache, cachePath: cachePath)
        let batchContext = BatchContext(granularCache: sharedCache)

        BatchSharedState.$current.withValue(BatchSharedState(context: batchContext)) {
            // Create multiple managers (simulating parallel config processing)
            let manager1 = ImageTrackingManager(
                client: mockClient,
                cachePath: nil,
                logger: logger,
                batchMode: true
            )

            let manager2 = ImageTrackingManager(
                client: mockClient,
                cachePath: nil,
                logger: logger,
                batchMode: true
            )

            // Both should use the same cache path
            XCTAssertEqual(manager1.currentCachePath, manager2.currentCachePath)
            XCTAssertEqual(manager1.currentCachePath, cachePath)
        }
    }
}
