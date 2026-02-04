@testable import ExFig_Android
import ExFigCore
import XCTest

/// Tests for AndroidTypographyExporter conformance to TypographyExporter protocol.
final class AndroidTypographyExporterTests: XCTestCase {
    // MARK: - Asset Type

    func testAssetTypeIsTypography() {
        let exporter = AndroidTypographyExporter()

        XCTAssertEqual(exporter.assetType, .typography)
    }

    // MARK: - Sendable

    func testExporterIsSendable() async {
        let exporter = AndroidTypographyExporter()

        let assetType = await Task {
            exporter.assetType
        }.value

        XCTAssertEqual(assetType, .typography)
    }

    // MARK: - TypographyExporter Protocol

    func testConformsToTypographyExporter() {
        // Verify type conformance at compile time
        let exporter: any TypographyExporter = AndroidTypographyExporter()

        XCTAssertEqual(exporter.assetType, .typography)
    }

    func testExportMethodExists() async throws {
        // This test verifies the export method signature exists
        // Full integration test would require mock context
        let exporter = AndroidTypographyExporter()

        // Type signature verification
        let _: (
            AndroidTypographyEntry,
            AndroidPlatformConfig,
            MockTypographyExportContext
        ) async throws -> Int = exporter.exportTypography
    }

    // MARK: - Entry Configuration

    func testTypographyEntryDefaults() {
        let entry = AndroidTypographyEntry()

        XCTAssertNil(entry.fileId)
        XCTAssertNil(entry.nameValidateRegexp)
        XCTAssertNil(entry.nameReplaceRegexp)
        XCTAssertEqual(entry.nameStyle, .snakeCase)
        XCTAssertNil(entry.composePackageName)
    }

    func testTypographyEntryWithValues() {
        let entry = AndroidTypographyEntry(
            fileId: "test-file-id",
            nameValidateRegexp: "^[a-z]+$",
            nameReplaceRegexp: "$1",
            nameStyle: .camelCase,
            composePackageName: "com.example.app.ui"
        )

        XCTAssertEqual(entry.fileId, "test-file-id")
        XCTAssertEqual(entry.nameValidateRegexp, "^[a-z]+$")
        XCTAssertEqual(entry.nameReplaceRegexp, "$1")
        XCTAssertEqual(entry.nameStyle, .camelCase)
        XCTAssertEqual(entry.composePackageName, "com.example.app.ui")
    }

    // MARK: - Source Input

    func testTypographySourceInput() {
        let entry = AndroidTypographyEntry(fileId: "entry-file-id")
        let sourceInput = entry.typographySourceInput(fileId: "default-file-id", timeout: 30.0)

        // Should use entry's fileId over default
        XCTAssertEqual(sourceInput.fileId, "entry-file-id")
        XCTAssertEqual(sourceInput.timeout, 30.0)
    }

    func testTypographySourceInputFallback() {
        let entry = AndroidTypographyEntry() // No fileId
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
