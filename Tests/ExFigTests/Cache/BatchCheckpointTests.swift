@testable import ExFig
import ExFigKit
import Foundation
import XCTest

final class BatchCheckpointTests: XCTestCase {
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
        let checkpoint1 = BatchCheckpoint(requestedPaths: ["/path1"])
        let checkpoint2 = BatchCheckpoint(requestedPaths: ["/path1"])

        XCTAssertNotEqual(checkpoint1.batchID, checkpoint2.batchID)
    }

    func testInit_storesRequestedPaths() {
        let paths = ["/path1", "/path2", "/path3"]
        let checkpoint = BatchCheckpoint(requestedPaths: paths)

        XCTAssertEqual(checkpoint.requestedPaths, paths)
    }

    func testInit_startsWithEmptyCompletedAndFailed() {
        let checkpoint = BatchCheckpoint(requestedPaths: ["/path1"])

        XCTAssertTrue(checkpoint.completedConfigs.isEmpty)
        XCTAssertTrue(checkpoint.failedConfigs.isEmpty)
    }

    // MARK: - Expiration

    func testIsExpired_returnsFalseForFreshCheckpoint() {
        let checkpoint = BatchCheckpoint(requestedPaths: ["/path1"])

        XCTAssertFalse(checkpoint.isExpired())
    }

    // MARK: - Path Matching

    func testMatchesPaths_returnsTrueForSamePaths() {
        let checkpoint = BatchCheckpoint(requestedPaths: ["/path1", "/path2"])

        XCTAssertTrue(checkpoint.matchesPaths(["/path1", "/path2"]))
        XCTAssertTrue(checkpoint.matchesPaths(["/path2", "/path1"])) // Order doesn't matter
    }

    func testMatchesPaths_returnsFalseForDifferentPaths() {
        let checkpoint = BatchCheckpoint(requestedPaths: ["/path1", "/path2"])

        XCTAssertFalse(checkpoint.matchesPaths(["/path1", "/path3"]))
        XCTAssertFalse(checkpoint.matchesPaths(["/path1"]))
    }

    // MARK: - Progress Tracking

    func testMarkCompleted_addsToCompletedSet() {
        var checkpoint = BatchCheckpoint(requestedPaths: ["/path1", "/path2"])

        checkpoint.markCompleted("/path1")

        XCTAssertTrue(checkpoint.completedConfigs.contains("/path1"))
        XCTAssertTrue(checkpoint.isCompleted("/path1"))
        XCTAssertFalse(checkpoint.isCompleted("/path2"))
    }

    func testMarkCompleted_removesFromFailed() {
        var checkpoint = BatchCheckpoint(requestedPaths: ["/path1"])
        checkpoint.markFailed("/path1")

        checkpoint.markCompleted("/path1")

        XCTAssertFalse(checkpoint.failedConfigs.contains("/path1"))
    }

    func testMarkFailed_addsToFailedSet() {
        var checkpoint = BatchCheckpoint(requestedPaths: ["/path1"])

        checkpoint.markFailed("/path1")

        XCTAssertTrue(checkpoint.failedConfigs.contains("/path1"))
    }

    func testRemainingCount_returnsCorrectValue() {
        var checkpoint = BatchCheckpoint(requestedPaths: ["/path1", "/path2", "/path3"])

        XCTAssertEqual(checkpoint.remainingCount, 3)

        checkpoint.markCompleted("/path1")
        XCTAssertEqual(checkpoint.remainingCount, 2)

        checkpoint.markCompleted("/path2")
        XCTAssertEqual(checkpoint.remainingCount, 1)
    }

    func testPendingPaths_returnsUncompletedPaths() {
        var checkpoint = BatchCheckpoint(requestedPaths: ["/path1", "/path2", "/path3"])
        checkpoint.markCompleted("/path1")

        let pending = checkpoint.pendingPaths(from: ["/path1", "/path2", "/path3"])

        XCTAssertEqual(Set(pending), Set(["/path2", "/path3"]))
    }

    // MARK: - Persistence

    func testSaveAndLoad_roundTrips() throws {
        var original = BatchCheckpoint(requestedPaths: ["/path1", "/path2", "/path3"])
        original.markCompleted("/path1")
        original.markFailed("/path2")

        try original.save(to: tempDirectory)
        let loaded = try BatchCheckpoint.load(from: tempDirectory)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.batchID, original.batchID)
        XCTAssertEqual(loaded?.requestedPaths, original.requestedPaths)
        XCTAssertEqual(loaded?.completedConfigs, original.completedConfigs)
        XCTAssertEqual(loaded?.failedConfigs, original.failedConfigs)
    }

    func testLoad_returnsNilWhenNoFile() throws {
        let loaded = try BatchCheckpoint.load(from: tempDirectory)

        XCTAssertNil(loaded)
    }

    func testDelete_removesFile() throws {
        let checkpoint = BatchCheckpoint(requestedPaths: ["/path1"])
        try checkpoint.save(to: tempDirectory)

        let fileURL = tempDirectory.appendingPathComponent(BatchCheckpoint.fileName)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        try BatchCheckpoint.delete(from: tempDirectory)

        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testDelete_succeedsWhenNoFile() throws {
        // Should not throw
        try BatchCheckpoint.delete(from: tempDirectory)
    }
}
