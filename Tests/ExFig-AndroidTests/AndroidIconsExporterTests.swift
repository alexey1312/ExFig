@testable import ExFig_Android
import ExFigCore
import XCTest

/// Tests for AndroidIconsExporter conformance to AssetExporter and IconsExporter protocols.
final class AndroidIconsExporterTests: XCTestCase {
    // MARK: - Asset Type

    func testAssetTypeIsIcons() {
        let exporter = AndroidIconsExporter()

        XCTAssertEqual(exporter.assetType, .icons)
    }

    // MARK: - Sendable

    func testExporterIsSendable() async {
        let exporter = AndroidIconsExporter()

        let assetType = await Task {
            exporter.assetType
        }.value

        XCTAssertEqual(assetType, .icons)
    }

    // MARK: - IconsExporter Protocol

    func testConformsToIconsExporter() {
        let exporter: any IconsExporter = AndroidIconsExporter()

        XCTAssertEqual(exporter.assetType, .icons)
    }

    func testExportMethodExists() async throws {
        let exporter = AndroidIconsExporter()

        // Type signature verification
        let _: (
            [AndroidIconsEntry],
            AndroidPlatformConfig,
            MockAndroidIconsExportContext
        ) async throws -> Int = exporter.exportIcons
    }
}

// MARK: - Mock Context

/// Mock IconsExportContext for testing.
struct MockAndroidIconsExportContext: IconsExportContext {
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
        try await operation(MockAndroidIconsProgressReporter())
    }
}

/// Mock ProgressReporter for testing.
struct MockAndroidIconsProgressReporter: ProgressReporter {
    func update(current: Int) {}
    func increment() {}
}
