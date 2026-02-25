@testable import ExFigCLI
import Foundation
import XCTest

final class DeletedFileDetectionTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DeletedFileDetectionTests-\(UUID().uuidString)")
        // swiftlint:disable:next force_try
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Deleted Detection

    func testDeletedFileDetectedFromPreviousReport() throws {
        // Use absolute paths in previous report that match what ManifestTracker would generate.
        // ManifestTracker.makeRelativePath() strips CWD prefix, so use paths
        // that don't match CWD to get predictable absolute paths in entries.
        let colorsPath = tempDirectory.appendingPathComponent("Colors.swift").path
        let oldColorsPath = tempDirectory.appendingPathComponent("OldColors.swift").path

        // Create a previous report with two files
        let previousReport: [String: Any] = [
            "version": 1,
            "command": "colors",
            "config": "exfig.pkl",
            "startTime": "2024-01-01T00:00:00Z",
            "endTime": "2024-01-01T00:00:01Z",
            "duration": 1.0,
            "success": true,
            "stats": ["colors": 2, "icons": 0, "images": 0, "typography": 0],
            "warnings": [] as [String],
            "manifest": [
                "files": [
                    ["path": colorsPath, "action": "created", "checksum": "abc123", "assetType": "color"],
                    ["path": oldColorsPath, "action": "created", "checksum": "def456", "assetType": "color"],
                ],
            ] as [String: Any],
        ]

        let previousReportPath = tempDirectory.appendingPathComponent("report.json").path
        let previousData = try JSONSerialization.data(withJSONObject: previousReport)
        try previousData.write(to: URL(fileURLWithPath: previousReportPath))

        // New export only generates Colors.swift (OldColors.swift was removed from Figma)
        let tracker = ManifestTracker(assetType: "color")
        let preState = tracker.capturePreState(for: colorsPath)
        tracker.recordWrite(path: colorsPath, data: Data("new colors".utf8), preState: preState)

        let manifest = tracker.buildManifest(previousReportPath: previousReportPath)

        // Should have 2 entries: Colors.swift (created) + OldColors.swift (deleted)
        XCTAssertEqual(manifest.files.count, 2)

        let deletedEntry = manifest.files.first { $0.path.hasSuffix("OldColors.swift") }
        XCTAssertNotNil(deletedEntry)
        XCTAssertEqual(deletedEntry?.action, .deleted)
        XCTAssertNil(deletedEntry?.checksum)
        XCTAssertEqual(deletedEntry?.assetType, "color")
    }

    // MARK: - No Previous Report

    func testNoPreviousReportNoDeletedFiles() {
        let tracker = ManifestTracker(assetType: "icon")
        let filePath = tempDirectory.appendingPathComponent("Icons.swift").path
        let preState = tracker.capturePreState(for: filePath)
        tracker.recordWrite(path: filePath, data: Data("icons".utf8), preState: preState)

        let manifest = tracker.buildManifest(previousReportPath: nil)
        XCTAssertEqual(manifest.files.count, 1)
        XCTAssertTrue(manifest.files.allSatisfy { $0.action != .deleted })
    }

    // MARK: - Non-existent Previous Report Path

    func testNonExistentPreviousReportPath() {
        let tracker = ManifestTracker(assetType: "color")
        let filePath = tempDirectory.appendingPathComponent("Colors.swift").path
        let preState = tracker.capturePreState(for: filePath)
        tracker.recordWrite(path: filePath, data: Data("colors".utf8), preState: preState)

        let manifest = tracker.buildManifest(previousReportPath: "/nonexistent/report.json")
        XCTAssertEqual(manifest.files.count, 1)
        XCTAssertTrue(manifest.files.allSatisfy { $0.action != .deleted })
    }

    // MARK: - All Files Still Present

    func testAllFilesPresentNoDeletedEntries() throws {
        // Use absolute paths matching what ManifestTracker produces for temp directory paths.
        let colorsPath = tempDirectory.appendingPathComponent("Colors.swift").path

        let previousReport: [String: Any] = [
            "version": 1,
            "command": "colors",
            "config": "exfig.pkl",
            "startTime": "2024-01-01T00:00:00Z",
            "endTime": "2024-01-01T00:00:01Z",
            "duration": 1.0,
            "success": true,
            "stats": ["colors": 1, "icons": 0, "images": 0, "typography": 0],
            "warnings": [] as [String],
            "manifest": [
                "files": [
                    ["path": colorsPath, "action": "created", "checksum": "abc123", "assetType": "color"],
                ],
            ] as [String: Any],
        ]

        let previousReportPath = tempDirectory.appendingPathComponent("report.json").path
        let previousData = try JSONSerialization.data(withJSONObject: previousReport)
        try previousData.write(to: URL(fileURLWithPath: previousReportPath))

        // New export generates the same file path
        let tracker = ManifestTracker(assetType: "color")
        let preState = tracker.capturePreState(for: colorsPath)
        tracker.recordWrite(path: colorsPath, data: Data("colors".utf8), preState: preState)

        let manifest = tracker.buildManifest(previousReportPath: previousReportPath)

        // Paths match — no deleted entries
        let deletedFiles = manifest.files.filter { $0.action == .deleted }
        XCTAssertTrue(deletedFiles.isEmpty, "Expected no deleted entries when all files are still present")
    }

    // MARK: - Previous Report Without Manifest

    func testPreviousReportWithoutManifest() throws {
        let previousReport: [String: Any] = [
            "version": 1,
            "command": "colors",
            "config": "exfig.pkl",
            "startTime": "2024-01-01T00:00:00Z",
            "endTime": "2024-01-01T00:00:01Z",
            "duration": 1.0,
            "success": true,
            "stats": ["colors": 1, "icons": 0, "images": 0, "typography": 0],
            "warnings": [] as [String],
        ]

        let previousReportPath = tempDirectory.appendingPathComponent("report.json").path
        let previousData = try JSONSerialization.data(withJSONObject: previousReport)
        try previousData.write(to: URL(fileURLWithPath: previousReportPath))

        let tracker = ManifestTracker(assetType: "color")
        let filePath = tempDirectory.appendingPathComponent("Colors.swift").path
        let preState = tracker.capturePreState(for: filePath)
        tracker.recordWrite(path: filePath, data: Data("colors".utf8), preState: preState)

        let manifest = tracker.buildManifest(previousReportPath: previousReportPath)
        // No deleted entries when previous report has no manifest
        XCTAssertTrue(manifest.files.allSatisfy { $0.action != .deleted })
    }
}
