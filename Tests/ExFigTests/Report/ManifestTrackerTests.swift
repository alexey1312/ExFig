@testable import ExFigCLI
@testable import ExFigCore
import Foundation
import XCTest

final class ManifestTrackerTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ManifestTrackerTests-\(UUID().uuidString)")
        // swiftlint:disable:next force_try
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        ManifestTrackerStorage.current = nil
    }

    override func tearDown() {
        ManifestTrackerStorage.current = nil
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Created Detection

    func testRecordWriteCreatedAction() throws {
        let tracker = ManifestTracker(assetType: "color")
        let filePath = tempDirectory.appendingPathComponent("new_file.swift").path
        let data = Data("let colors = []".utf8)

        // File does not exist yet
        XCTAssertFalse(FileManager.default.fileExists(atPath: filePath))

        let preState = tracker.capturePreState(for: filePath)
        // Simulate write
        // swiftlint:disable:next force_try
        try data.write(to: URL(fileURLWithPath: filePath))
        tracker.recordWrite(path: filePath, data: data, preState: preState)

        let entries = tracker.getAll()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].action, .created)
        XCTAssertEqual(entries[0].assetType, "color")
        XCTAssertNotNil(entries[0].checksum)
        XCTAssertEqual(entries[0].checksum?.count, 16) // FNV-1a 16-char hex
    }

    // MARK: - Modified Detection

    func testRecordWriteModifiedAction() throws {
        let tracker = ManifestTracker(assetType: "icon")
        let filePath = tempDirectory.appendingPathComponent("existing.swift").path

        // Create existing file with different content
        try Data("old content".utf8).write(to: URL(fileURLWithPath: filePath))

        let preState = tracker.capturePreState(for: filePath)
        let newData = Data("new content".utf8)
        try newData.write(to: URL(fileURLWithPath: filePath))
        tracker.recordWrite(path: filePath, data: newData, preState: preState)

        let entries = tracker.getAll()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].action, .modified)
    }

    // MARK: - Unchanged Detection

    func testRecordWriteUnchangedAction() throws {
        let tracker = ManifestTracker(assetType: "image")
        let filePath = tempDirectory.appendingPathComponent("same.swift").path
        let content = Data("same content".utf8)

        // Create existing file with same content
        try content.write(to: URL(fileURLWithPath: filePath))

        let preState = tracker.capturePreState(for: filePath)
        try content.write(to: URL(fileURLWithPath: filePath))
        tracker.recordWrite(path: filePath, data: content, preState: preState)

        let entries = tracker.getAll()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].action, .unchanged)
    }

    // MARK: - Default Asset Type

    func testDefaultAssetType() {
        let tracker = ManifestTracker(assetType: "typography")
        let filePath = tempDirectory.appendingPathComponent("fonts.swift").path
        let data = Data("fonts".utf8)

        let preState = tracker.capturePreState(for: filePath)
        tracker.recordWrite(path: filePath, data: data, preState: preState)

        let entries = tracker.getAll()
        XCTAssertEqual(entries[0].assetType, "typography")
    }

    // MARK: - Asset Type Override

    func testAssetTypeOverride() {
        let tracker = ManifestTracker(assetType: "color")
        let filePath = tempDirectory.appendingPathComponent("icon.svg").path
        let data = Data("<svg/>".utf8)

        let preState = tracker.capturePreState(for: filePath)
        tracker.recordWrite(path: filePath, data: data, preState: preState, assetType: "icon")

        let entries = tracker.getAll()
        XCTAssertEqual(entries[0].assetType, "icon")
    }

    // MARK: - Build Manifest

    func testBuildManifest() {
        let tracker = ManifestTracker(assetType: "color")
        let filePath = tempDirectory.appendingPathComponent("colors.swift").path
        let data = Data("colors".utf8)

        let preState = tracker.capturePreState(for: filePath)
        tracker.recordWrite(path: filePath, data: data, preState: preState)

        let manifest = tracker.buildManifest()
        XCTAssertEqual(manifest.files.count, 1)
    }

    // MARK: - Storage

    func testManifestTrackerStorage() {
        XCTAssertNil(ManifestTrackerStorage.current)

        let tracker = ManifestTracker(assetType: "icon")
        ManifestTrackerStorage.current = tracker
        XCTAssertNotNil(ManifestTrackerStorage.current)

        ManifestTrackerStorage.current = nil
        XCTAssertNil(ManifestTrackerStorage.current)
    }

    // MARK: - Checksum Consistency

    func testChecksumConsistency() {
        let tracker = ManifestTracker(assetType: "color")
        let data = Data("consistent content".utf8)

        let path1 = tempDirectory.appendingPathComponent("file1.swift").path
        let path2 = tempDirectory.appendingPathComponent("file2.swift").path

        let preState1 = tracker.capturePreState(for: path1)
        tracker.recordWrite(path: path1, data: data, preState: preState1)

        let preState2 = tracker.capturePreState(for: path2)
        tracker.recordWrite(path: path2, data: data, preState: preState2)

        let entries = tracker.getAll()
        XCTAssertEqual(entries[0].checksum, entries[1].checksum)
    }

    // MARK: - RecordCopy Tests

    func testRecordCopyCreated() throws {
        let tracker = ManifestTracker(assetType: "image")
        let sourceURL = tempDirectory.appendingPathComponent("source.png")
        let destPath = tempDirectory.appendingPathComponent("dest.png").path
        let content = Data("image data".utf8)

        try content.write(to: sourceURL)

        let preState = tracker.capturePreState(for: destPath)
        XCTAssertFalse(preState.fileExisted)

        // Simulate copy
        try FileManager.default.copyItem(at: sourceURL, to: URL(fileURLWithPath: destPath))
        tracker.recordCopy(path: destPath, sourceURL: sourceURL, preState: preState)

        let entries = tracker.getAll()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].action, .created)
        XCTAssertNotNil(entries[0].checksum)
    }

    func testRecordCopyModified() throws {
        let tracker = ManifestTracker(assetType: "image")
        let sourceURL = tempDirectory.appendingPathComponent("source.png")
        let destPath = tempDirectory.appendingPathComponent("dest.png").path

        // Create existing destination with different content
        try Data("old image".utf8).write(to: URL(fileURLWithPath: destPath))

        let preState = tracker.capturePreState(for: destPath)
        XCTAssertTrue(preState.fileExisted)

        // Write new source and copy
        let newContent = Data("new image".utf8)
        try newContent.write(to: sourceURL)
        try FileManager.default.removeItem(atPath: destPath)
        try FileManager.default.copyItem(at: sourceURL, to: URL(fileURLWithPath: destPath))
        tracker.recordCopy(path: destPath, sourceURL: sourceURL, preState: preState)

        let entries = tracker.getAll()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].action, .modified)
    }

    func testRecordCopyUnchanged() throws {
        let tracker = ManifestTracker(assetType: "image")
        let sourceURL = tempDirectory.appendingPathComponent("source.png")
        let destPath = tempDirectory.appendingPathComponent("dest.png").path
        let content = Data("same image".utf8)

        // Create both with same content
        try content.write(to: sourceURL)
        try content.write(to: URL(fileURLWithPath: destPath))

        let preState = tracker.capturePreState(for: destPath)
        XCTAssertTrue(preState.fileExisted)

        // Re-copy same content
        try FileManager.default.removeItem(atPath: destPath)
        try FileManager.default.copyItem(at: sourceURL, to: URL(fileURLWithPath: destPath))
        tracker.recordCopy(path: destPath, sourceURL: sourceURL, preState: preState)

        let entries = tracker.getAll()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].action, .unchanged)
    }

    func testRecordCopyWithUnreadableSource() {
        let tracker = ManifestTracker(assetType: "image")
        let sourceURL = URL(fileURLWithPath: "/nonexistent/source.png")
        let destPath = tempDirectory.appendingPathComponent("dest.png").path

        let preState = tracker.capturePreState(for: destPath)

        // Destination doesn't exist, source is unreadable — still records entry
        tracker.recordCopy(path: destPath, sourceURL: sourceURL, preState: preState)

        let entries = tracker.getAll()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].action, .created)
        // Checksum is nil when both source and destination are unreadable
        XCTAssertNil(entries[0].checksum)
    }

    // MARK: - Two-Phase Prevents Phantom Entries

    func testNoEntryRecordedOnFailedWrite() {
        let tracker = ManifestTracker(assetType: "color")
        let filePath = tempDirectory.appendingPathComponent("colors.swift").path
        let data = Data("colors".utf8)

        // Capture pre-state
        let preState = tracker.capturePreState(for: filePath)

        // Simulate failed write — don't call recordWrite
        // Entries should be empty
        let entries = tracker.getAll()
        XCTAssertTrue(entries.isEmpty)

        // Now use preState to verify it captured correctly
        XCTAssertFalse(preState.fileExisted)
        XCTAssertNil(preState.existingChecksum)

        // If write eventually succeeds, we can still record
        tracker.recordWrite(path: filePath, data: data, preState: preState)
        XCTAssertEqual(tracker.getAll().count, 1)
    }
}

// MARK: - AssetManifest JSON Tests

final class AssetManifestTests: XCTestCase {
    func testAssetManifestJSONSerialization() throws {
        let manifest = AssetManifest(files: [
            ManifestEntry(path: "Colors.swift", action: .created, checksum: "abcdef0123456789", assetType: "color"),
            ManifestEntry(path: "Icons.swift", action: .modified, checksum: "1234567890abcdef", assetType: "icon"),
            ManifestEntry(path: "Old.swift", action: .deleted, checksum: nil, assetType: "color"),
            ManifestEntry(path: "Same.swift", action: .unchanged, checksum: "fedcba9876543210", assetType: "image"),
        ])

        let data = try JSONCodec.encode(manifest)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let files = json?["files"] as? [[String: Any]]

        XCTAssertEqual(files?.count, 4)

        // Verify created
        XCTAssertEqual(files?[0]["action"] as? String, "created")
        XCTAssertEqual(files?[0]["path"] as? String, "Colors.swift")
        XCTAssertEqual(files?[0]["checksum"] as? String, "abcdef0123456789")

        // Verify deleted has null checksum
        XCTAssertEqual(files?[2]["action"] as? String, "deleted")
        XCTAssertNil(files?[2]["checksum"] as? String)
    }

    func testEmptyManifest() throws {
        let manifest = AssetManifest(files: [])
        let data = try JSONCodec.encode(manifest)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let files = json?["files"] as? [Any]

        XCTAssertEqual(files?.count, 0)
    }

    func testFileActionRawValues() {
        XCTAssertEqual(FileAction.created.rawValue, "created")
        XCTAssertEqual(FileAction.modified.rawValue, "modified")
        XCTAssertEqual(FileAction.unchanged.rawValue, "unchanged")
        XCTAssertEqual(FileAction.deleted.rawValue, "deleted")
    }
}
