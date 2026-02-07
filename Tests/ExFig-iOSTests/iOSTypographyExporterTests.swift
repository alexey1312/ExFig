// swiftlint:disable type_name

@testable import ExFig_iOS
import ExFigConfig
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

    func testExportMethodExists() {
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
        let entry = iOSTypographyEntry(
            fontSwift: nil,
            labelStyleSwift: nil,
            swiftUIFontSwift: nil,
            generateLabels: false,
            labelsDirectory: nil,
            nameStyle: .camelCase
        )

        XCTAssertNil(entry.fontSwift)
        XCTAssertNil(entry.swiftUIFontSwift)
        XCTAssertFalse(entry.generateLabels)
        XCTAssertNil(entry.labelsDirectory)
        XCTAssertNil(entry.labelStyleSwift)
        XCTAssertEqual(entry.nameStyle, .camelCase)
    }

    func testTypographyEntryWithValues() {
        let entry = iOSTypographyEntry(
            fontSwift: "/path/to/UIFont+Extension.swift",
            labelStyleSwift: nil,
            swiftUIFontSwift: nil,
            generateLabels: true,
            labelsDirectory: "/path/to/Labels",
            nameStyle: .snake_case
        )

        XCTAssertEqual(entry.fontSwift, "/path/to/UIFont+Extension.swift")
        XCTAssertEqual(entry.nameStyle, .snake_case)
        XCTAssertTrue(entry.generateLabels)
        XCTAssertEqual(entry.labelsDirectory, "/path/to/Labels")
    }

    // MARK: - Source Input

    func testTypographySourceInput() {
        let entry = iOSTypographyEntry(
            fontSwift: nil,
            labelStyleSwift: nil,
            swiftUIFontSwift: nil,
            generateLabels: false,
            labelsDirectory: nil,
            nameStyle: .camelCase
        )
        let sourceInput = entry.typographySourceInput(fileId: "default-file-id", timeout: 30.0)

        XCTAssertEqual(sourceInput.fileId, "default-file-id")
        XCTAssertEqual(sourceInput.timeout, 30.0)
    }

    func testTypographySourceInputNilTimeout() {
        let entry = iOSTypographyEntry(
            fontSwift: nil,
            labelStyleSwift: nil,
            swiftUIFontSwift: nil,
            generateLabels: false,
            labelsDirectory: nil,
            nameStyle: .camelCase
        )
        let sourceInput = entry.typographySourceInput(fileId: "default-file-id", timeout: nil)

        XCTAssertEqual(sourceInput.fileId, "default-file-id")
        XCTAssertNil(sourceInput.timeout)
    }

    // MARK: - URL Convenience

    func testFontSwiftURL() {
        let entry = iOSTypographyEntry(
            fontSwift: "/path/to/Font.swift",
            labelStyleSwift: nil,
            swiftUIFontSwift: nil,
            generateLabels: false,
            labelsDirectory: nil,
            nameStyle: .camelCase
        )

        XCTAssertEqual(entry.fontSwiftURL, URL(fileURLWithPath: "/path/to/Font.swift"))
    }

    func testCoreNameStyle() {
        let entry = iOSTypographyEntry(
            fontSwift: nil,
            labelStyleSwift: nil,
            swiftUIFontSwift: nil,
            generateLabels: false,
            labelsDirectory: nil,
            nameStyle: .snake_case
        )

        XCTAssertEqual(entry.coreNameStyle, .snakeCase) // ExFigCore.NameStyle.snakeCase
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
