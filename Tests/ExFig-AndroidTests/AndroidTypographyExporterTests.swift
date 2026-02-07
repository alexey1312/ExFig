@testable import ExFig_Android
import ExFigConfig
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

    func testExportMethodExists() {
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
        let entry = AndroidTypographyEntry(
            nameStyle: .snake_case,
            composePackageName: nil
        )

        XCTAssertEqual(entry.nameStyle, .snake_case)
        XCTAssertNil(entry.composePackageName)
    }

    func testTypographyEntryWithValues() {
        let entry = AndroidTypographyEntry(
            nameStyle: .camelCase,
            composePackageName: "com.example.app.ui"
        )

        XCTAssertEqual(entry.nameStyle, .camelCase)
        XCTAssertEqual(entry.composePackageName, "com.example.app.ui")
    }

    // MARK: - Source Input

    func testTypographySourceInput() {
        let entry = AndroidTypographyEntry(
            nameStyle: .snake_case,
            composePackageName: nil
        )
        let sourceInput = entry.typographySourceInput(fileId: "default-file-id", timeout: 30.0)

        XCTAssertEqual(sourceInput.fileId, "default-file-id")
        XCTAssertEqual(sourceInput.timeout, 30.0)
    }

    func testTypographySourceInputNilTimeout() {
        let entry = AndroidTypographyEntry(
            nameStyle: .snake_case,
            composePackageName: nil
        )
        let sourceInput = entry.typographySourceInput(fileId: "default-file-id", timeout: nil)

        XCTAssertEqual(sourceInput.fileId, "default-file-id")
        XCTAssertNil(sourceInput.timeout)
    }

    // MARK: - Core Name Style

    func testCoreNameStyle() {
        let entry = AndroidTypographyEntry(
            nameStyle: .camelCase,
            composePackageName: nil
        )

        XCTAssertEqual(entry.coreNameStyle, .camelCase)
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
