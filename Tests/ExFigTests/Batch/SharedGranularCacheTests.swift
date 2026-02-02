@testable import ExFig
import XCTest

final class SharedGranularCacheTests: XCTestCase {
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

    // MARK: - Basic Operations

    func testNodeHashesReturnsNilForUnknownFile() {
        let cache = ImageTrackingCache()
        let cachePath = tempDirectory.appendingPathComponent("test-cache.json")
        let sharedCache = SharedGranularCache(cache: cache, cachePath: cachePath)

        XCTAssertNil(sharedCache.nodeHashes(for: "unknown-file"))
    }

    func testNodeHashesReturnsHashesForKnownFile() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1", "1:2": "hash2"])

        let cachePath = tempDirectory.appendingPathComponent("test-cache.json")
        let sharedCache = SharedGranularCache(cache: cache, cachePath: cachePath)

        let hashes = sharedCache.nodeHashes(for: "fileA")

        XCTAssertNotNil(hashes)
        XCTAssertEqual(hashes?["1:1"], "hash1")
        XCTAssertEqual(hashes?["1:2"], "hash2")
    }

    func testNodeHashesReturnsNilForFileWithoutNodeHashes() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        // No nodeHashes set

        let cachePath = tempDirectory.appendingPathComponent("test-cache.json")
        let sharedCache = SharedGranularCache(cache: cache, cachePath: cachePath)

        XCTAssertNil(sharedCache.nodeHashes(for: "fileA"))
    }

    // MARK: - hasNodeHashes

    func testHasNodeHashesReturnsFalseForUnknownFile() {
        let cache = ImageTrackingCache()
        let cachePath = tempDirectory.appendingPathComponent("test-cache.json")
        let sharedCache = SharedGranularCache(cache: cache, cachePath: cachePath)

        XCTAssertFalse(sharedCache.hasNodeHashes(for: "unknown-file"))
    }

    func testHasNodeHashesReturnsTrueForFileWithNodeHashes() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1"])

        let cachePath = tempDirectory.appendingPathComponent("test-cache.json")
        let sharedCache = SharedGranularCache(cache: cache, cachePath: cachePath)

        XCTAssertTrue(sharedCache.hasNodeHashes(for: "fileA"))
    }

    func testHasNodeHashesReturnsFalseForFileWithoutNodeHashes() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        // No nodeHashes set

        let cachePath = tempDirectory.appendingPathComponent("test-cache.json")
        let sharedCache = SharedGranularCache(cache: cache, cachePath: cachePath)

        XCTAssertFalse(sharedCache.hasNodeHashes(for: "fileA"))
    }

    // MARK: - Multiple Files

    func testHandlesMultipleFiles() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hashA1"])
        cache.updateFileVersion(fileId: "fileB", version: "v2")
        cache.updateNodeHashes(fileId: "fileB", hashes: ["2:1": "hashB1", "2:2": "hashB2"])

        let cachePath = tempDirectory.appendingPathComponent("test-cache.json")
        let sharedCache = SharedGranularCache(cache: cache, cachePath: cachePath)

        XCTAssertEqual(sharedCache.nodeHashes(for: "fileA")?["1:1"], "hashA1")
        XCTAssertEqual(sharedCache.nodeHashes(for: "fileB")?["2:1"], "hashB1")
        XCTAssertEqual(sharedCache.nodeHashes(for: "fileB")?["2:2"], "hashB2")
        XCTAssertNil(sharedCache.nodeHashes(for: "fileC"))
    }

    // MARK: - Sendable

    func testSharedGranularCacheIsSendable() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1"])

        let cachePath = tempDirectory.appendingPathComponent("test-cache.json")
        let sharedCache = SharedGranularCache(cache: cache, cachePath: cachePath)

        // Verify it can be passed across concurrency boundaries
        Task.detached {
            _ = sharedCache.nodeHashes(for: "fileA")
        }

        XCTAssertTrue(true) // Compiles means it's Sendable
    }

    // MARK: - Cache Path

    func testCachePathIsStored() {
        let cache = ImageTrackingCache()
        let cachePath = tempDirectory.appendingPathComponent("custom-cache.json")
        let sharedCache = SharedGranularCache(cache: cache, cachePath: cachePath)

        XCTAssertEqual(sharedCache.cachePath.lastPathComponent, "custom-cache.json")
    }
}

// MARK: - BatchContext Storage Tests

final class BatchContextStorageTests: XCTestCase {
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

    func testStorageIsNilByDefault() {
        XCTAssertNil(BatchContextStorage.context)
    }

    func testStorageCanBeSetViaTaskLocal() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1"])

        let cachePath = tempDirectory.appendingPathComponent("test-cache.json")
        let sharedCache = SharedGranularCache(cache: cache, cachePath: cachePath)
        let context = BatchContext(granularCache: sharedCache)

        var capturedHashes: [String: String]?

        BatchContextStorage.$context.withValue(context) {
            capturedHashes = BatchContextStorage.context?.granularCache?.nodeHashes(for: "fileA")
        }

        XCTAssertEqual(capturedHashes?["1:1"], "hash1")
    }

    func testStorageIsIsolatedBetweenTasks() {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1"])

        let cachePath = tempDirectory.appendingPathComponent("test-cache.json")
        let sharedCache = SharedGranularCache(cache: cache, cachePath: cachePath)
        let context = BatchContext(granularCache: sharedCache)

        var insideValue: BatchContext?
        var outsideValue: BatchContext?

        BatchContextStorage.$context.withValue(context) {
            insideValue = BatchContextStorage.context
        }

        outsideValue = BatchContextStorage.context

        XCTAssertNotNil(insideValue)
        XCTAssertNil(outsideValue)
    }

    func testStorageIsAccessibleFromNestedTasks() async {
        var cache = ImageTrackingCache()
        cache.updateFileVersion(fileId: "fileA", version: "v1")
        cache.updateNodeHashes(fileId: "fileA", hashes: ["1:1": "hash1"])

        let cachePath = tempDirectory.appendingPathComponent("test-cache.json")
        let sharedCache = SharedGranularCache(cache: cache, cachePath: cachePath)
        let context = BatchContext(granularCache: sharedCache)

        var capturedFromNestedTask: [String: String]?

        await BatchContextStorage.$context.withValue(context) {
            await withTaskGroup(of: [String: String]?.self) { group in
                group.addTask {
                    BatchContextStorage.context?.granularCache?.nodeHashes(for: "fileA")
                }

                for await result in group {
                    capturedFromNestedTask = result
                }
            }
        }

        XCTAssertEqual(capturedFromNestedTask?["1:1"], "hash1")
    }

    func testIsBatchModeReturnsTrueWithAnyContext() {
        let context = BatchContext(versions: PreFetchedFileVersions(versions: [:]))

        BatchContextStorage.$context.withValue(context) {
            XCTAssertTrue(BatchContextStorage.context?.isBatchMode ?? false)
        }
    }

    func testIsBatchModeReturnsFalseWithEmptyContext() {
        let context = BatchContext()

        BatchContextStorage.$context.withValue(context) {
            XCTAssertFalse(BatchContextStorage.context?.isBatchMode ?? true)
        }
    }
}
