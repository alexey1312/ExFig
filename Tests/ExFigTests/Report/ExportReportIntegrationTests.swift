@testable import ExFigCLI
import Foundation
import XCTest

final class ExportReportIntegrationTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ExportReportIntegrationTests-\(UUID().uuidString)")
        // swiftlint:disable:next force_try
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - 6.1 Valid JSON with version, command, stats, timestamps

    func testReportProducesValidJSON() throws {
        let reportPath = tempDirectory.appendingPathComponent("report.json").path
        let ui = TerminalUI(outputMode: .quiet)

        let report = ExportReport(
            version: ExportReport.currentVersion,
            command: "colors",
            config: "exfig.pkl",
            startTime: ISO8601DateFormatter().string(from: Date()),
            endTime: ISO8601DateFormatter().string(from: Date()),
            duration: 1.5,
            success: true,
            error: nil,
            stats: ReportStats(colors: 10, icons: 0, images: 0, typography: 0),
            warnings: [],
            manifest: AssetManifest(files: [])
        )

        writeExportReport(report, to: reportPath, ui: ui)

        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: reportPath))

        // Verify valid JSON
        let data = try Data(contentsOf: URL(fileURLWithPath: reportPath))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json)
        XCTAssertEqual(json?["version"] as? Int, 1)
        XCTAssertEqual(json?["command"] as? String, "colors")
        XCTAssertNotNil(json?["startTime"])
        XCTAssertNotNil(json?["endTime"])
        XCTAssertEqual(json?["duration"] as? Double, 1.5)

        let stats = json?["stats"] as? [String: Any]
        XCTAssertEqual(stats?["colors"] as? Int, 10)
    }

    // MARK: - 6.2 Export failure writes report with success: false

    func testFailedExportStillWritesReport() throws {
        let reportPath = tempDirectory.appendingPathComponent("failure.json").path
        let ui = TerminalUI(outputMode: .quiet)

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
            warnings: ["Token was not set"],
            manifest: nil
        )

        writeExportReport(report, to: reportPath, ui: ui)

        XCTAssertTrue(FileManager.default.fileExists(atPath: reportPath))

        let data = try Data(contentsOf: URL(fileURLWithPath: reportPath))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["success"] as? Bool, false)
        XCTAssertEqual(json?["error"] as? String, "FIGMA_PERSONAL_TOKEN not set")
    }

    // MARK: - 6.3 Report write failure does not fail the export

    func testReportWriteFailureDoesNotThrow() {
        let ui = TerminalUI(outputMode: .quiet)
        let invalidPath = "/nonexistent/directory/report.json"

        let report = ExportReport(
            version: ExportReport.currentVersion,
            command: "colors",
            config: "exfig.pkl",
            startTime: "2024-01-01T00:00:00Z",
            endTime: "2024-01-01T00:00:01Z",
            duration: 1.0,
            success: true,
            error: nil,
            stats: ReportStats(colors: 5, icons: 0, images: 0, typography: 0),
            warnings: [],
            manifest: nil
        )

        // Should NOT throw — writeExportReport catches errors internally
        writeExportReport(report, to: invalidPath, ui: ui)

        // Verify no file was created
        XCTAssertFalse(FileManager.default.fileExists(atPath: invalidPath))
    }

    // MARK: - 6.4 Zero-file export produces report with empty manifest

    func testZeroFileExportEmptyManifest() throws {
        let reportPath = tempDirectory.appendingPathComponent("empty.json").path
        let ui = TerminalUI(outputMode: .quiet)

        let report = ExportReport(
            version: ExportReport.currentVersion,
            command: "images",
            config: "exfig.pkl",
            startTime: "2024-01-01T00:00:00Z",
            endTime: "2024-01-01T00:00:01Z",
            duration: 0.5,
            success: true,
            error: nil,
            stats: ReportStats.zero,
            warnings: [],
            manifest: AssetManifest(files: [])
        )

        writeExportReport(report, to: reportPath, ui: ui)

        let data = try Data(contentsOf: URL(fileURLWithPath: reportPath))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let manifest = json?["manifest"] as? [String: Any]
        let files = manifest?["files"] as? [Any]
        XCTAssertEqual(files?.count, 0)

        XCTAssertEqual(json?["stats"] as? [String: Int], [
            "colors": 0, "icons": 0, "images": 0, "typography": 0,
        ])
    }
}
