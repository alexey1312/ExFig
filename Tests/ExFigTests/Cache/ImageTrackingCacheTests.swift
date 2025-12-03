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
}
