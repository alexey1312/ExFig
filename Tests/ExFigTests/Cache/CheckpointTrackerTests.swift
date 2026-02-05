@testable import ExFig
import ExFigCore
import Foundation
import XCTest

final class CheckpointTrackerTests: XCTestCase {
    private var tempDirectory: URL!
    private var configFile: URL!

    override func setUp() async throws {
        try await super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        // Create a test config file
        configFile = tempDirectory.appendingPathComponent("config.yaml")
        try "figma:\n  fileKey: test123\n".write(to: configFile, atomically: true, encoding: .utf8)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        try await super.tearDown()
    }

    // MARK: - Initialization

    func testInit_createsTrackerWithAssetNames() async throws {
        let tracker = try CheckpointTracker(
            configPath: configFile.path,
            directory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1", "icon2", "icon3"]
        )

        let completed = await tracker.completedNames
        let pending = await tracker.pendingNames

        XCTAssertTrue(completed.isEmpty)
        XCTAssertEqual(pending, ["icon1", "icon2", "icon3"])
    }

    func testInit_differentAssetTypes() async throws {
        let iconsTracker = try CheckpointTracker(
            configPath: configFile.path,
            directory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1"]
        )

        // Create separate directory for images checkpoint
        let imagesDir = tempDirectory.appendingPathComponent("images")
        try FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)

        let imagesConfigFile = imagesDir.appendingPathComponent("config.yaml")
        try "figma:\n  fileKey: test456\n".write(to: imagesConfigFile, atomically: true, encoding: .utf8)

        let imagesTracker = try CheckpointTracker(
            configPath: imagesConfigFile.path,
            directory: imagesDir,
            assetType: .images,
            assetNames: ["img1"]
        )

        let iconsPending = await iconsTracker.pendingNames
        let imagesPending = await imagesTracker.pendingNames

        XCTAssertEqual(iconsPending, ["icon1"])
        XCTAssertEqual(imagesPending, ["img1"])
    }

    // MARK: - Mark Completed

    func testMarkCompleted_updatesPendingAndCompleted() async throws {
        let tracker = try CheckpointTracker(
            configPath: configFile.path,
            directory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1", "icon2", "icon3"]
        )

        await tracker.markCompleted("icon1")

        let completed = await tracker.completedNames
        let pending = await tracker.pendingNames

        XCTAssertEqual(completed, ["icon1"])
        XCTAssertEqual(pending, ["icon2", "icon3"])
    }

    func testMarkCompleted_batchUpdate() async throws {
        let tracker = try CheckpointTracker(
            configPath: configFile.path,
            directory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1", "icon2", "icon3"]
        )

        await tracker.markCompleted(["icon1", "icon2"])

        let completed = await tracker.completedNames
        let pending = await tracker.pendingNames

        XCTAssertEqual(completed, ["icon1", "icon2"])
        XCTAssertEqual(pending, ["icon3"])
    }

    // MARK: - Is Complete

    func testIsComplete_returnsFalseWhenPending() async throws {
        let tracker = try CheckpointTracker(
            configPath: configFile.path,
            directory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1"]
        )

        let isComplete = await tracker.isComplete
        XCTAssertFalse(isComplete)
    }

    func testIsComplete_returnsTrueWhenAllDone() async throws {
        let tracker = try CheckpointTracker(
            configPath: configFile.path,
            directory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1"]
        )

        await tracker.markCompleted("icon1")

        let isComplete = await tracker.isComplete
        XCTAssertTrue(isComplete)
    }

    // MARK: - Save and Load

    func testSaveAndLoadIfValid_roundTrips() async throws {
        let tracker = try CheckpointTracker(
            configPath: configFile.path,
            directory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1", "icon2", "icon3"]
        )

        await tracker.markCompleted("icon1")
        try await tracker.save()

        let loaded = try CheckpointTracker.loadIfValid(
            configPath: configFile.path,
            directory: tempDirectory,
            assetType: .icons
        )

        XCTAssertNotNil(loaded)
        let completed = try await XCTUnwrap(loaded?.completedNames)
        let pending = try await XCTUnwrap(loaded?.pendingNames)

        XCTAssertEqual(completed, ["icon1"])
        XCTAssertEqual(pending, ["icon2", "icon3"])
    }

    func testLoadIfValid_returnsNilWhenNoCheckpoint() throws {
        let emptyDir = tempDirectory.appendingPathComponent("empty")
        // swiftlint:disable:next force_try
        try FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)

        let configInEmptyDir = emptyDir.appendingPathComponent("config.yaml")
        // swiftlint:disable:next force_try
        try "figma:\n  fileKey: test\n".write(to: configInEmptyDir, atomically: true, encoding: .utf8)

        let loaded = try CheckpointTracker.loadIfValid(
            configPath: configInEmptyDir.path,
            directory: emptyDir,
            assetType: .icons
        )

        XCTAssertNil(loaded)
    }

    func testLoadIfValid_returnsNilWhenConfigHashMismatch() async throws {
        let tracker = try CheckpointTracker(
            configPath: configFile.path,
            directory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1"]
        )
        try await tracker.save()

        // Modify config to change hash
        try "figma:\n  fileKey: differentKey\n".write(to: configFile, atomically: true, encoding: .utf8)

        let loaded = try CheckpointTracker.loadIfValid(
            configPath: configFile.path,
            directory: tempDirectory,
            assetType: .icons
        )

        XCTAssertNil(loaded)
    }

    // MARK: - Delete

    func testDelete_removesCheckpointFile() async throws {
        let tracker = try CheckpointTracker(
            configPath: configFile.path,
            directory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1"]
        )
        try await tracker.save()

        let checkpointPath = tempDirectory.appendingPathComponent(ExportCheckpoint.fileName)
        XCTAssertTrue(FileManager.default.fileExists(atPath: checkpointPath.path))

        try await tracker.delete()

        XCTAssertFalse(FileManager.default.fileExists(atPath: checkpointPath.path))
    }

    // MARK: - Filter Pending Files

    func testFilterPending_excludesCompletedFiles() async throws {
        let tracker = try CheckpointTracker(
            configPath: configFile.path,
            directory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1", "icon2", "icon3"]
        )

        await tracker.markCompleted("icon1")

        let files = [
            makeFileContents(name: "icon1"),
            makeFileContents(name: "icon2"),
            makeFileContents(name: "icon3"),
        ]

        let pending = await tracker.filterPending(files)

        XCTAssertEqual(pending.count, 2)
        let pendingNames = Set(pending.map { $0.destination.file.deletingPathExtension().lastPathComponent })
        XCTAssertEqual(pendingNames, ["icon2", "icon3"])
    }

    func testFilterPending_returnsAllWhenNoneCompleted() async throws {
        let tracker = try CheckpointTracker(
            configPath: configFile.path,
            directory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1", "icon2"]
        )

        let files = [
            makeFileContents(name: "icon1"),
            makeFileContents(name: "icon2"),
        ]

        let pending = await tracker.filterPending(files)

        XCTAssertEqual(pending.count, 2)
    }

    // MARK: - Helper Methods

    private func makeFileContents(name: String) -> FileContents {
        let fileURL = URL(fileURLWithPath: "\(name).svg")
        let dest = Destination(directory: tempDirectory, file: fileURL)
        return FileContents(destination: dest, data: Data("test".utf8))
    }
}
