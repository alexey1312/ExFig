// swiftlint:disable type_name

@testable import ExFig_iOS
import ExFigCore
import XCTest

/// Tests for iOSIconsExporter conformance to AssetExporter and IconsExporter protocols.
final class iOSIconsExporterTests: XCTestCase {
    // MARK: - Asset Type

    func testAssetTypeIsIcons() {
        let exporter = iOSIconsExporter()

        XCTAssertEqual(exporter.assetType, .icons)
    }

    // MARK: - Sendable

    func testExporterIsSendable() async {
        let exporter = iOSIconsExporter()

        let assetType = await Task {
            exporter.assetType
        }.value

        XCTAssertEqual(assetType, .icons)
    }

    // MARK: - IconsExporter Protocol

    func testConformsToIconsExporter() {
        // Verify type conformance at compile time
        let exporter: any IconsExporter = iOSIconsExporter()

        XCTAssertEqual(exporter.assetType, .icons)
    }

    func testExportMethodExists() async throws {
        // This test verifies the export method signature exists
        // Full integration test would require mock context
        let exporter = iOSIconsExporter()

        // Type signature verification
        let _: (
            [iOSIconsEntry],
            iOSPlatformConfig,
            MockIconsExportContext
        ) async throws -> Int = exporter.exportIcons
    }
}

// MARK: - Mock Context

/// Mock IconsExportContext for testing.
struct MockIconsExportContext: IconsExportContext {
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
        try await operation(MockProgressReporter())
    }
}

/// Mock ProgressReporter for testing.
struct MockProgressReporter: ProgressReporter {
    func update(current: Int) {}
    func increment() {}
}

// swiftlint:enable type_name
