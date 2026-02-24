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

    func testRecordWriteCreatedAction() async {
        let tracker = ManifestTracker(assetType: "color")
        let filePath = tempDirectory.appendingPathComponent("new_file.swift").path
        let data = Data("let colors = []".utf8)

        // File does not exist yet
        XCTAssertFalse(FileManager.default.fileExists(atPath: filePath))

        await tracker.recordWrite(path: filePath, data: data)
        let entries = await tracker.getAll()

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].action, .created)
        XCTAssertEqual(entries[0].assetType, "color")
        XCTAssertNotNil(entries[0].checksum)
        XCTAssertEqual(entries[0].checksum?.count, 16) // FNV-1a 16-char hex
    }

    // MARK: - Modified Detection

    func testRecordWriteModifiedAction() async throws {
        let tracker = ManifestTracker(assetType: "icon")
        let filePath = tempDirectory.appendingPathComponent("existing.swift").path

        // Create existing file with different content
        try Data("old content".utf8).write(to: URL(fileURLWithPath: filePath))

        let newData = Data("new content".utf8)
        await tracker.recordWrite(path: filePath, data: newData)
        let entries = await tracker.getAll()

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].action, .modified)
    }

    // MARK: - Unchanged Detection

    func testRecordWriteUnchangedAction() async throws {
        let tracker = ManifestTracker(assetType: "image")
        let filePath = tempDirectory.appendingPathComponent("same.swift").path
        let content = Data("same content".utf8)

        // Create existing file with same content
        try content.write(to: URL(fileURLWithPath: filePath))

        await tracker.recordWrite(path: filePath, data: content)
        let entries = await tracker.getAll()

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].action, .unchanged)
    }

    // MARK: - Default Asset Type

    func testDefaultAssetType() async {
        let tracker = ManifestTracker(assetType: "typography")
        let filePath = tempDirectory.appendingPathComponent("fonts.swift").path
        let data = Data("fonts".utf8)

        await tracker.recordWrite(path: filePath, data: data)
        let entries = await tracker.getAll()

        XCTAssertEqual(entries[0].assetType, "typography")
    }

    // MARK: - Build Manifest

    func testBuildManifest() async {
        let tracker = ManifestTracker(assetType: "color")
        let filePath = tempDirectory.appendingPathComponent("colors.swift").path
        let data = Data("colors".utf8)

        await tracker.recordWrite(path: filePath, data: data)
        let manifest = await tracker.buildManifest()

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

    func testChecksumConsistency() async {
        let tracker = ManifestTracker(assetType: "color")
        let data = Data("consistent content".utf8)

        let path1 = tempDirectory.appendingPathComponent("file1.swift").path
        let path2 = tempDirectory.appendingPathComponent("file2.swift").path

        await tracker.recordWrite(path: path1, data: data)
        await tracker.recordWrite(path: path2, data: data)

        let entries = await tracker.getAll()
        XCTAssertEqual(entries[0].checksum, entries[1].checksum)
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

        let data = try JSONEncoder().encode(manifest)
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
        let data = try JSONEncoder().encode(manifest)
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
