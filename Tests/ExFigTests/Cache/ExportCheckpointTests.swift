@testable import ExFigCLI
import Foundation
import XCTest

final class ExportCheckpointTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        // swiftlint:disable:next force_try
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Initialization

    func testInit_createsCheckpointWithUniqueID() {
        let checkpoint1 = ExportCheckpoint(configPath: "/path/to/config.pkl", configHash: "abc123")
        let checkpoint2 = ExportCheckpoint(configPath: "/path/to/config.pkl", configHash: "abc123")

        XCTAssertNotEqual(checkpoint1.exportID, checkpoint2.exportID)
    }

    func testInit_setsStartedAtToNow() {
        let before = Date()
        let checkpoint = ExportCheckpoint(configPath: "/path/to/config.pkl", configHash: "abc123")
        let after = Date()

        XCTAssertGreaterThanOrEqual(checkpoint.startedAt, before)
        XCTAssertLessThanOrEqual(checkpoint.startedAt, after)
    }

    func testInit_storesConfigPathAndHash() {
        let checkpoint = ExportCheckpoint(configPath: "/path/to/config.pkl", configHash: "abc123")

        XCTAssertEqual(checkpoint.configPath, "/path/to/config.pkl")
        XCTAssertEqual(checkpoint.configHash, "abc123")
    }

    // MARK: - Expiration

    func testIsExpired_returnsFalseForFreshCheckpoint() {
        let checkpoint = ExportCheckpoint(configPath: "/path", configHash: "hash")

        XCTAssertFalse(checkpoint.isExpired())
    }

    func testIsExpired_returnsTrueForOldCheckpoint() throws {
        var checkpoint = ExportCheckpoint(configPath: "/path", configHash: "hash")

        // Manually set startedAt to 25 hours ago
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        // swiftlint:disable:next force_try
        var data = try encoder.encode(checkpoint)
        // swiftlint:disable:next force_try force_cast
        var json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let oldDate = Date().addingTimeInterval(-25 * 60 * 60)
        let formatter = ISO8601DateFormatter()
        json["startedAt"] = formatter.string(from: oldDate)
        // swiftlint:disable:next force_try
        data = try JSONSerialization.data(withJSONObject: json)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        // swiftlint:disable:next force_try
        checkpoint = try decoder.decode(ExportCheckpoint.self, from: data)

        XCTAssertTrue(checkpoint.isExpired())
    }

    func testIsExpired_respectsCustomExpiration() {
        let checkpoint = ExportCheckpoint(configPath: "/path", configHash: "hash")

        // Very short expiration should not expire immediately
        XCTAssertFalse(checkpoint.isExpired(expiration: 1))
    }

    // MARK: - Config Matching

    func testMatchesConfig_returnsTrueForMatchingHash() {
        let checkpoint = ExportCheckpoint(configPath: "/path", configHash: "abc123")

        XCTAssertTrue(checkpoint.matchesConfig(hash: "abc123"))
    }

    func testMatchesConfig_returnsFalseForDifferentHash() {
        let checkpoint = ExportCheckpoint(configPath: "/path", configHash: "abc123")

        XCTAssertFalse(checkpoint.matchesConfig(hash: "xyz789"))
    }

    // MARK: - Progress Tracking

    func testMarkColorsCompleted_updatesState() {
        var checkpoint = ExportCheckpoint(
            configPath: "/path",
            configHash: "hash",
            pending: ExportCheckpoint.PendingItems(colors: true)
        )

        checkpoint.markColorsCompleted()

        XCTAssertTrue(checkpoint.completed.colors)
        XCTAssertFalse(checkpoint.pending.colors)
    }

    func testMarkTypographyCompleted_updatesState() {
        var checkpoint = ExportCheckpoint(
            configPath: "/path",
            configHash: "hash",
            pending: ExportCheckpoint.PendingItems(typography: true)
        )

        checkpoint.markTypographyCompleted()

        XCTAssertTrue(checkpoint.completed.typography)
        XCTAssertFalse(checkpoint.pending.typography)
    }

    func testMarkIconCompleted_updatesState() {
        var checkpoint = ExportCheckpoint(
            configPath: "/path",
            configHash: "hash",
            pending: ExportCheckpoint.PendingItems(icons: ["icon1", "icon2"])
        )

        checkpoint.markIconCompleted("icon1")

        XCTAssertTrue(checkpoint.completed.icons.contains("icon1"))
        XCTAssertFalse(checkpoint.pending.icons.contains("icon1"))
        XCTAssertTrue(checkpoint.pending.icons.contains("icon2"))
    }

    func testMarkImageCompleted_updatesState() {
        var checkpoint = ExportCheckpoint(
            configPath: "/path",
            configHash: "hash",
            pending: ExportCheckpoint.PendingItems(images: ["img1", "img2"])
        )

        checkpoint.markImageCompleted("img1")

        XCTAssertTrue(checkpoint.completed.images.contains("img1"))
        XCTAssertFalse(checkpoint.pending.images.contains("img1"))
        XCTAssertTrue(checkpoint.pending.images.contains("img2"))
    }

    // MARK: - Completion Check

    func testIsComplete_returnsTrueWhenAllDone() {
        var checkpoint = ExportCheckpoint(
            configPath: "/path",
            configHash: "hash",
            pending: ExportCheckpoint.PendingItems(colors: true, icons: ["icon1"])
        )

        checkpoint.markColorsCompleted()
        checkpoint.markIconCompleted("icon1")

        XCTAssertTrue(checkpoint.isComplete)
    }

    func testIsComplete_returnsFalseWhenPending() {
        let checkpoint = ExportCheckpoint(
            configPath: "/path",
            configHash: "hash",
            pending: ExportCheckpoint.PendingItems(colors: true)
        )

        XCTAssertFalse(checkpoint.isComplete)
    }

    func testIsComplete_returnsTrueWhenNoPending() {
        let checkpoint = ExportCheckpoint(configPath: "/path", configHash: "hash")

        XCTAssertTrue(checkpoint.isComplete)
    }

    // MARK: - Persistence

    func testSaveAndLoad_roundTrips() throws {
        var original = ExportCheckpoint(
            configPath: "/path/to/config.pkl",
            configHash: "abc123",
            pending: ExportCheckpoint.PendingItems(
                colors: true,
                typography: true,
                icons: ["icon1", "icon2"],
                images: ["img1"]
            )
        )
        original.markColorsCompleted()
        original.markIconCompleted("icon1")

        try original.save(to: tempDirectory)
        let loaded = try ExportCheckpoint.load(from: tempDirectory)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.exportID, original.exportID)
        XCTAssertEqual(loaded?.configPath, original.configPath)
        XCTAssertEqual(loaded?.configHash, original.configHash)
        XCTAssertEqual(loaded?.completed.colors, true)
        XCTAssertEqual(loaded?.completed.icons, ["icon1"])
        XCTAssertEqual(loaded?.pending.icons, ["icon2"])
    }

    func testLoad_returnsNilWhenNoFile() throws {
        let loaded = try ExportCheckpoint.load(from: tempDirectory)

        XCTAssertNil(loaded)
    }

    func testDelete_removesFile() throws {
        let checkpoint = ExportCheckpoint(configPath: "/path", configHash: "hash")
        try checkpoint.save(to: tempDirectory)

        let fileURL = tempDirectory.appendingPathComponent(ExportCheckpoint.fileName)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        try ExportCheckpoint.delete(from: tempDirectory)

        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testDelete_succeedsWhenNoFile() throws {
        // Should not throw
        try ExportCheckpoint.delete(from: tempDirectory)
    }

    // MARK: - Config Hash

    func testComputeConfigHash_returnsDeterministicHash() throws {
        let configContent = "figma:\n  fileKey: abc123\n"
        let fileURL = tempDirectory.appendingPathComponent("config.pkl")
        try configContent.write(to: fileURL, atomically: true, encoding: .utf8)

        let hash1 = try ExportCheckpoint.computeConfigHash(from: fileURL)
        let hash2 = try ExportCheckpoint.computeConfigHash(from: fileURL)

        XCTAssertEqual(hash1, hash2)
    }

    func testComputeConfigHash_differentForDifferentContent() throws {
        let file1 = tempDirectory.appendingPathComponent("config1.pkl")
        let file2 = tempDirectory.appendingPathComponent("config2.pkl")

        try "content1".write(to: file1, atomically: true, encoding: .utf8)
        try "content2".write(to: file2, atomically: true, encoding: .utf8)

        let hash1 = try ExportCheckpoint.computeConfigHash(from: file1)
        let hash2 = try ExportCheckpoint.computeConfigHash(from: file2)

        XCTAssertNotEqual(hash1, hash2)
    }
}
