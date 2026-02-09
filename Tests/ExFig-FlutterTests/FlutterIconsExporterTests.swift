@testable import ExFig_Flutter
import ExFigCore
import XCTest

/// Tests for FlutterIconsExporter conformance to AssetExporter and IconsExporter protocols.
final class FlutterIconsExporterTests: XCTestCase {
    // MARK: - Asset Type

    func testAssetTypeIsIcons() {
        let exporter = FlutterIconsExporter()

        XCTAssertEqual(exporter.assetType, .icons)
    }

    // MARK: - Sendable

    func testExporterIsSendable() async {
        let exporter = FlutterIconsExporter()

        let assetType = await Task {
            exporter.assetType
        }.value

        XCTAssertEqual(assetType, .icons)
    }

    // MARK: - IconsExporter Protocol

    func testConformsToIconsExporter() {
        let exporter: any IconsExporter = FlutterIconsExporter()

        XCTAssertEqual(exporter.assetType, .icons)
    }

    func testExportMethodExists() {
        let exporter = FlutterIconsExporter()

        // Type signature verification - exportIcons returns IconsExportResult
        let _: (
            [FlutterIconsEntry],
            FlutterPlatformConfig,
            MockFlutterIconsExportContext
        ) async throws -> IconsExportResult = exporter.exportIcons
    }
}

// MARK: - Mock Context

/// Mock IconsExportContext for testing.
struct MockFlutterIconsExportContext: IconsExportContext {
    var isBatchMode: Bool = false
    var filter: String?

    func writeFiles(_ files: [FileContents]) throws {}
    func info(_ message: String) {}
    func warning(_ message: String) {}
    func success(_ message: String) {}

    func withSpinner<T: Sendable>(
        _ message: String,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await operation()
    }

    func loadIcons(from source: IconsSourceInput) async throws -> IconsLoadOutput {
        IconsLoadOutput(light: [], dark: [])
    }

    func processIcons(
        _ icons: IconsLoadOutput,
        platform: Platform,
        nameValidateRegexp: String?,
        nameReplaceRegexp: String?,
        nameStyle: NameStyle
    ) throws -> IconsProcessResult {
        IconsProcessResult(iconPairs: [], warning: nil)
    }

    func downloadFiles(
        _ files: [FileContents],
        progressTitle: String
    ) async throws -> [FileContents] {
        files
    }

    func withProgress<T: Sendable>(
        _ title: String,
        total: Int,
        operation: @escaping @Sendable (ProgressReporter) async throws -> T
    ) async throws -> T {
        try await operation(MockFlutterIconsProgressReporter())
    }
}

/// Mock ProgressReporter for testing.
struct MockFlutterIconsProgressReporter: ProgressReporter {
    func update(current: Int) {}
    func increment() {}
}
