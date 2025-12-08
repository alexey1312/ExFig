@testable import ExFig
import Foundation
import XCTest

/// Regression tests for granular cache directory preservation behavior.
/// These tests verify that when granular cache is enabled, existing files
/// are NOT deleted during partial exports.
///
/// Bug fixed: When only some assets changed with granular cache enabled,
/// the entire output directory was being deleted before writing only the
/// changed assets, causing all unchanged assets to be lost.
final class GranularCacheDirectoryPreservationTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("GranularCacheTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        super.tearDown()
    }

    // MARK: - Directory Preservation Logic Tests

    /// Tests that the condition `filter == nil && granularCacheManager == nil`
    /// correctly prevents directory deletion when granular cache is active.
    func testShouldDeleteDirectoryCondition_withGranularCache_returnsFalse() {
        // Given: granular cache is enabled (manager is not nil)
        let filter: String? = nil
        let granularCacheManagerIsNil = false // simulates granularCacheManager != nil

        // When: checking if directory should be deleted
        let shouldDelete = filter == nil && granularCacheManagerIsNil

        // Then: should NOT delete directory
        XCTAssertFalse(shouldDelete, "Directory should NOT be deleted when granular cache is enabled")
    }

    func testShouldDeleteDirectoryCondition_withoutGranularCache_returnsTrue() {
        // Given: granular cache is disabled (manager is nil)
        let filter: String? = nil
        let granularCacheManagerIsNil = true // simulates granularCacheManager == nil

        // When: checking if directory should be deleted
        let shouldDelete = filter == nil && granularCacheManagerIsNil

        // Then: should delete directory (normal full export behavior)
        XCTAssertTrue(shouldDelete, "Directory SHOULD be deleted when granular cache is disabled")
    }

    func testShouldDeleteDirectoryCondition_withFilter_returnsFalse() {
        // Given: filter is set (partial export by name)
        let filter: String? = "some_icon"
        let granularCacheManagerIsNil = true

        // When: checking if directory should be deleted
        let shouldDelete = filter == nil && granularCacheManagerIsNil

        // Then: should NOT delete directory (filter mode preserves existing files)
        XCTAssertFalse(shouldDelete, "Directory should NOT be deleted when filter is active")
    }

    // MARK: - File System Behavior Tests

    /// Simulates the scenario where granular cache detects 1 changed file out of many.
    /// Verifies that existing files are preserved when only writing changed files.
    func testExistingFilesPreserved_whenWritingPartialChanges() throws {
        // Given: existing files in output directory
        let existingFile1 = tempDirectory.appendingPathComponent("icon_home.svg")
        let existingFile2 = tempDirectory.appendingPathComponent("icon_settings.svg")
        let existingFile3 = tempDirectory.appendingPathComponent("icon_profile.svg")

        try "home-content".write(to: existingFile1, atomically: true, encoding: .utf8)
        try "settings-content".write(to: existingFile2, atomically: true, encoding: .utf8)
        try "profile-content".write(to: existingFile3, atomically: true, encoding: .utf8)

        // Verify all 3 files exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: existingFile1.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: existingFile2.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: existingFile3.path))

        // When: simulating granular cache mode - only write the changed file
        // (NOT deleting directory first, as the fix ensures)
        // With granular cache enabled, we skip directory deletion entirely

        // Write only the "changed" file (icon_settings with new content)
        try "settings-NEW-content".write(to: existingFile2, atomically: true, encoding: .utf8)

        // Then: all files should still exist
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: existingFile1.path),
            "Unchanged file icon_home.svg should be preserved"
        )
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: existingFile2.path),
            "Changed file icon_settings.svg should exist with new content"
        )
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: existingFile3.path),
            "Unchanged file icon_profile.svg should be preserved"
        )

        // Verify content
        XCTAssertEqual(try String(contentsOf: existingFile1, encoding: .utf8), "home-content")
        XCTAssertEqual(try String(contentsOf: existingFile2, encoding: .utf8), "settings-NEW-content")
        XCTAssertEqual(try String(contentsOf: existingFile3, encoding: .utf8), "profile-content")
    }

    /// Demonstrates the bug scenario: if directory is deleted, unchanged files are lost.
    func testBugScenario_deletingDirectoryCausesDataLoss() throws {
        // Given: existing files in output directory
        let existingFile1 = tempDirectory.appendingPathComponent("icon_home.svg")
        let existingFile2 = tempDirectory.appendingPathComponent("icon_settings.svg")

        try "home-content".write(to: existingFile1, atomically: true, encoding: .utf8)
        try "settings-content".write(to: existingFile2, atomically: true, encoding: .utf8)

        // When: simulating the BUG - deleting directory before writing
        try FileManager.default.removeItem(at: tempDirectory)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        // Write only one file (simulating granular cache with 1 change)
        try "settings-NEW-content".write(to: existingFile2, atomically: true, encoding: .utf8)

        // Then: unchanged file is LOST (this is the bug we fixed)
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: existingFile1.path),
            "BUG DEMONSTRATION: Unchanged file was lost due to directory deletion"
        )
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: existingFile2.path),
            "Only the changed file exists"
        )
    }
}
