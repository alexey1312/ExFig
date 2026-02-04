// swiftlint:disable type_name

@testable import ExFig_iOS
import ExFigCore
import XCTest

/// Tests for iOSTypographyExporter conformance to TypographyExporter protocol.
final class iOSTypographyExporterTests: XCTestCase {
    // MARK: - Asset Type

    func testAssetTypeIsTypography() {
        let exporter = iOSTypographyExporter()

        XCTAssertEqual(exporter.assetType, .typography)
    }

    // MARK: - Sendable

    func testExporterIsSendable() async {
        let exporter = iOSTypographyExporter()

        let assetType = await Task {
            exporter.assetType
        }.value

        XCTAssertEqual(assetType, .typography)
    }

    // MARK: - TypographyExporter Protocol

    func testConformsToTypographyExporter() {
        // Verify type conformance at compile time
        let exporter: any TypographyExporter = iOSTypographyExporter()

        XCTAssertEqual(exporter.assetType, .typography)
    }

    func testExportMethodExists() async throws {
        // This test verifies the export method signature exists
        // Full integration test would require mock context
        let exporter = iOSTypographyExporter()

        // Type signature verification
        let _: (
            iOSTypographyEntry,
            iOSPlatformConfig,
            MockTypographyExportContext
        ) async throws -> Int = exporter.exportTypography
    }

    // MARK: - Entry Configuration

    func testTypographyEntryDefaults() {
        let entry = iOSTypographyEntry()

        XCTAssertNil(entry.fileId)
        XCTAssertNil(entry.nameValidateRegexp)
        XCTAssertNil(entry.nameReplaceRegexp)
        XCTAssertEqual(entry.nameStyle, .camelCase)
        XCTAssertNil(entry.fontSwift)
        XCTAssertNil(entry.swiftUIFontSwift)
        XCTAssertFalse(entry.generateLabels)
        XCTAssertNil(entry.labelsDirectory)
        XCTAssertNil(entry.labelStyleSwift)
    }

    func testTypographyEntryWithValues() {
        let fontSwiftURL = URL(filePath: "/path/to/UIFont+Extension.swift")
        let entry = iOSTypographyEntry(
            fileId: "test-file-id",
            nameValidateRegexp: "^[a-z]+$",
            nameReplaceRegexp: "$1",
            nameStyle: .snakeCase,
            fontSwift: fontSwiftURL,
            swiftUIFontSwift: nil,
            generateLabels: true,
            labelsDirectory: URL(filePath: "/path/to/Labels"),
            labelStyleSwift: nil
        )

        XCTAssertEqual(entry.fileId, "test-file-id")
        XCTAssertEqual(entry.nameValidateRegexp, "^[a-z]+$")
        XCTAssertEqual(entry.nameReplaceRegexp, "$1")
        XCTAssertEqual(entry.nameStyle, .snakeCase)
        XCTAssertEqual(entry.fontSwift, fontSwiftURL)
        XCTAssertTrue(entry.generateLabels)
    }

    // MARK: - Source Input

    func testTypographySourceInput() {
        let entry = iOSTypographyEntry(fileId: "entry-file-id")
        let sourceInput = entry.typographySourceInput(fileId: "default-file-id", timeout: 30.0)

        // Should use entry's fileId over default
        XCTAssertEqual(sourceInput.fileId, "entry-file-id")
        XCTAssertEqual(sourceInput.timeout, 30.0)
    }

    func testTypographySourceInputFallback() {
        let entry = iOSTypographyEntry() // No fileId
        let sourceInput = entry.typographySourceInput(fileId: "default-file-id", timeout: nil)

        // Should fall back to default fileId
        XCTAssertEqual(sourceInput.fileId, "default-file-id")
        XCTAssertNil(sourceInput.timeout)
    }
}

// MARK: - Mock Context

/// Mock TypographyExportContext for testing.
struct MockTypographyExportContext: TypographyExportContext {
    var isBatchMode: Bool = false
    var filter: String?

    func writeFiles(_ files: [FileContents]) throws {
        // No-op for testing
    }

    func info(_ message: String) {
        // No-op for testing
    }

    func warning(_ message: String) {
        // No-op for testing
    }

    func success(_ message: String) {
        // No-op for testing
    }

    func withSpinner<T: Sendable>(
        _ message: String,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await operation()
    }

    func loadTypography(from source: TypographySourceInput) async throws -> TypographyLoadOutput {
        // Return empty text styles for testing
        TypographyLoadOutput(textStyles: [])
    }

    func processTypography(
        _ textStyles: TypographyLoadOutput,
        platform: Platform,
        nameValidateRegexp: String?,
        nameReplaceRegexp: String?,
        nameStyle: NameStyle
    ) throws -> TypographyProcessResult {
        TypographyProcessResult(textStyles: [], warning: nil)
    }
}

// swiftlint:enable type_name
