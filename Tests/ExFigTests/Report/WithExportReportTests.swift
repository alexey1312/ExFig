@testable import ExFigCLI
import Foundation
import XCTest

final class WithExportReportTests: XCTestCase {
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WithExportReportTests-\(UUID().uuidString)")
        // swiftlint:disable:next force_try
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        WarningCollectorStorage.current = nil
        ManifestTrackerStorage.current = nil
    }

    override func tearDown() {
        WarningCollectorStorage.current = nil
        ManifestTrackerStorage.current = nil
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Nil Report Path Skips Report

    func testNilReportPathSkipsReportGeneration() async throws {
        let ui = TerminalUI(outputMode: .quiet)
        var exportCalled = false

        try await withExportReport(
            command: "colors",
            assetType: "color",
            reportPath: nil,
            configInput: "exfig.pkl",
            ui: ui,
            buildStats: { .colors($0) },
            export: {
                exportCalled = true
                return 5
            }
        )

        XCTAssertTrue(exportCalled)
        // No storage should be set when reportPath is nil
        XCTAssertNil(WarningCollectorStorage.current)
        XCTAssertNil(ManifestTrackerStorage.current)
    }

    // MARK: - Report Written On Success

    func testReportWrittenOnSuccess() async throws {
        let reportPath = tempDirectory.appendingPathComponent("success.json").path
        let ui = TerminalUI(outputMode: .quiet)

        try await withExportReport(
            command: "colors",
            assetType: "color",
            reportPath: reportPath,
            configInput: "test.pkl",
            ui: ui,
            buildStats: { .colors($0) },
            export: { 42 }
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: reportPath))

        let data = try Data(contentsOf: URL(fileURLWithPath: reportPath))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["command"] as? String, "colors")
        XCTAssertEqual(json?["config"] as? String, "test.pkl")
        XCTAssertEqual(json?["success"] as? Bool, true)
        XCTAssertNil(json?["error"] as? String)

        let stats = json?["stats"] as? [String: Any]
        XCTAssertEqual(stats?["colors"] as? Int, 42)
    }

    // MARK: - Export Error Rethrown After Report Write

    func testExportErrorRethrownAfterReportWrite() async throws {
        let reportPath = tempDirectory.appendingPathComponent("error.json").path
        let ui = TerminalUI(outputMode: .quiet)

        struct TestExportError: Error, LocalizedError {
            var errorDescription: String? {
                "Test export failed"
            }
        }

        do {
            try await withExportReport(
                command: "icons",
                assetType: "icon",
                reportPath: reportPath,
                configInput: "exfig.pkl",
                ui: ui,
                buildStats: { .icons($0) },
                export: { throw TestExportError() }
            )
            XCTFail("Expected error to be rethrown")
        } catch {
            XCTAssertTrue(error is TestExportError)
        }

        // Report should still be written
        XCTAssertTrue(FileManager.default.fileExists(atPath: reportPath))

        let data = try Data(contentsOf: URL(fileURLWithPath: reportPath))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["success"] as? Bool, false)
        XCTAssertEqual(json?["error"] as? String, "Test export failed")
    }

    // MARK: - Storage Cleaned Up After Success

    func testStorageCleanedUpAfterSuccess() async throws {
        let reportPath = tempDirectory.appendingPathComponent("cleanup.json").path
        let ui = TerminalUI(outputMode: .quiet)

        try await withExportReport(
            command: "colors",
            assetType: "color",
            reportPath: reportPath,
            configInput: "exfig.pkl",
            ui: ui,
            buildStats: { .colors($0) },
            export: { 1 }
        )

        XCTAssertNil(WarningCollectorStorage.current)
        XCTAssertNil(ManifestTrackerStorage.current)
    }

    // MARK: - Storage Cleaned Up After Failure

    func testStorageCleanedUpAfterFailure() async throws {
        let reportPath = tempDirectory.appendingPathComponent("cleanup_fail.json").path
        let ui = TerminalUI(outputMode: .quiet)

        struct TestError: Error {}

        do {
            try await withExportReport(
                command: "images",
                assetType: "image",
                reportPath: reportPath,
                configInput: "exfig.pkl",
                ui: ui,
                buildStats: { .images($0) },
                export: { throw TestError() }
            )
        } catch {
            // expected
        }

        XCTAssertNil(WarningCollectorStorage.current)
        XCTAssertNil(ManifestTrackerStorage.current)
    }

    // MARK: - Default Config Fallback

    func testDefaultConfigFallback() async throws {
        let reportPath = tempDirectory.appendingPathComponent("default_config.json").path
        let ui = TerminalUI(outputMode: .quiet)

        try await withExportReport(
            command: "typography",
            assetType: "typography",
            reportPath: reportPath,
            configInput: nil,
            ui: ui,
            buildStats: { .typography($0) },
            export: { 3 }
        )

        let data = try Data(contentsOf: URL(fileURLWithPath: reportPath))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["config"] as? String, "exfig.pkl")
    }
}
