@testable import ExFigCLI
import Foundation
import XCTest

final class ExportReportTests: XCTestCase {
    // MARK: - Success Case

    func testSuccessReportJSON() throws {
        let report = ExportReport(
            version: ExportReport.currentVersion,
            command: "colors",
            config: "exfig.pkl",
            startTime: "2024-01-01T00:00:00Z",
            endTime: "2024-01-01T00:00:05Z",
            duration: 5.0,
            success: true,
            error: nil,
            stats: ReportStats(colors: 42, icons: 0, images: 0, typography: 0),
            warnings: [],
            manifest: nil
        )

        let data = try report.jsonData()
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // swiftlint:disable:next force_unwrapping
        XCTAssertEqual(json?["version"] as? Int, 1)
        XCTAssertEqual(json?["command"] as? String, "colors")
        XCTAssertEqual(json?["config"] as? String, "exfig.pkl")
        XCTAssertEqual(json?["startTime"] as? String, "2024-01-01T00:00:00Z")
        XCTAssertEqual(json?["endTime"] as? String, "2024-01-01T00:00:05Z")
        XCTAssertEqual(json?["duration"] as? Double, 5.0)
        XCTAssertEqual(json?["success"] as? Bool, true)
        XCTAssertNil(json?["error"] as? String)

        let stats = json?["stats"] as? [String: Any]
        XCTAssertEqual(stats?["colors"] as? Int, 42)
        XCTAssertEqual(stats?["icons"] as? Int, 0)
        XCTAssertEqual(stats?["images"] as? Int, 0)
        XCTAssertEqual(stats?["typography"] as? Int, 0)
    }

    // MARK: - Failure Case

    func testFailureReportJSON() throws {
        let report = ExportReport(
            version: ExportReport.currentVersion,
            command: "icons",
            config: "exfig.pkl",
            startTime: "2024-01-01T00:00:00Z",
            endTime: "2024-01-01T00:00:01Z",
            duration: 1.0,
            success: false,
            error: "FIGMA_PERSONAL_TOKEN not set",
            stats: ReportStats.zero,
            warnings: [],
            manifest: nil
        )

        let data = try report.jsonData()
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["success"] as? Bool, false)
        XCTAssertEqual(json?["error"] as? String, "FIGMA_PERSONAL_TOKEN not set")
    }

    // MARK: - Empty Warnings

    func testEmptyWarningsArray() throws {
        let report = ExportReport(
            version: ExportReport.currentVersion,
            command: "images",
            config: "exfig.pkl",
            startTime: "2024-01-01T00:00:00Z",
            endTime: "2024-01-01T00:00:02Z",
            duration: 2.0,
            success: true,
            error: nil,
            stats: ReportStats.zero,
            warnings: [],
            manifest: nil
        )

        let data = try report.jsonData()
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let warnings = json?["warnings"] as? [String]
        XCTAssertEqual(warnings, [])
    }

    // MARK: - Warnings Populated

    func testWarningsPopulated() throws {
        let report = ExportReport(
            version: ExportReport.currentVersion,
            command: "colors",
            config: "exfig.pkl",
            startTime: "2024-01-01T00:00:00Z",
            endTime: "2024-01-01T00:00:03Z",
            duration: 3.0,
            success: true,
            error: nil,
            stats: ReportStats(colors: 10, icons: 0, images: 0, typography: 0),
            warnings: ["Warning 1", "Warning 2"],
            manifest: nil
        )

        let data = try report.jsonData()
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let warnings = json?["warnings"] as? [String]
        XCTAssertEqual(warnings, ["Warning 1", "Warning 2"])
    }

    // MARK: - Version Field

    func testVersionField() throws {
        XCTAssertEqual(ExportReport.currentVersion, 1)

        let report = ExportReport(
            version: ExportReport.currentVersion,
            command: "typography",
            config: "exfig.pkl",
            startTime: "2024-01-01T00:00:00Z",
            endTime: "2024-01-01T00:00:01Z",
            duration: 1.0,
            success: true,
            error: nil,
            stats: ReportStats.zero,
            warnings: [],
            manifest: nil
        )

        let data = try report.jsonData()
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["version"] as? Int, 1)
    }

    // MARK: - ReportStats Zero

    func testReportStatsZero() {
        let stats = ReportStats.zero
        XCTAssertEqual(stats.colors, 0)
        XCTAssertEqual(stats.icons, 0)
        XCTAssertEqual(stats.images, 0)
        XCTAssertEqual(stats.typography, 0)
    }

    // MARK: - Report with Manifest

    func testReportWithManifest() throws {
        let manifest = AssetManifest(files: [
            ManifestEntry(path: "Colors.swift", action: .created, checksum: "abc123", assetType: "color"),
            ManifestEntry(path: "OldFile.swift", action: .deleted, checksum: nil, assetType: "color"),
        ])

        let report = ExportReport(
            version: ExportReport.currentVersion,
            command: "colors",
            config: "exfig.pkl",
            startTime: "2024-01-01T00:00:00Z",
            endTime: "2024-01-01T00:00:01Z",
            duration: 1.0,
            success: true,
            error: nil,
            stats: ReportStats(colors: 1, icons: 0, images: 0, typography: 0),
            warnings: [],
            manifest: manifest
        )

        let data = try report.jsonData()
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let manifestJSON = json?["manifest"] as? [String: Any]
        let files = manifestJSON?["files"] as? [[String: Any]]
        XCTAssertEqual(files?.count, 2)

        let createdFile = files?.first
        XCTAssertEqual(createdFile?["path"] as? String, "Colors.swift")
        XCTAssertEqual(createdFile?["action"] as? String, "created")
        XCTAssertEqual(createdFile?["checksum"] as? String, "abc123")
        XCTAssertEqual(createdFile?["assetType"] as? String, "color")

        let deletedFile = files?.last
        XCTAssertEqual(deletedFile?["action"] as? String, "deleted")
        XCTAssertNil(deletedFile?["checksum"] as? String)
    }

    // MARK: - Null Manifest

    func testNullManifest() throws {
        let report = ExportReport(
            version: ExportReport.currentVersion,
            command: "icons",
            config: "exfig.pkl",
            startTime: "2024-01-01T00:00:00Z",
            endTime: "2024-01-01T00:00:01Z",
            duration: 1.0,
            success: true,
            error: nil,
            stats: ReportStats.zero,
            warnings: [],
            manifest: nil
        )

        let data = try report.jsonData()
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // When manifest is nil, key is either absent or null — both valid
        let hasManifestKey = json?.keys.contains("manifest") ?? false
        if hasManifestKey {
            XCTAssertTrue(json?["manifest"] is NSNull)
        }
        // No manifest entry in files either way
        XCTAssertNil(json?["manifest"] as? [String: Any])
    }
}
