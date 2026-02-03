// swiftlint:disable type_name

@testable import ExFig_iOS
import ExFigCore
import XCTest

/// Tests for iOSImagesExporter conformance to AssetExporter and ImagesExporter protocols.
final class iOSImagesExporterTests: XCTestCase {
    // MARK: - Asset Type

    func testAssetTypeIsImages() {
        let exporter = iOSImagesExporter()

        XCTAssertEqual(exporter.assetType, .images)
    }

    // MARK: - Sendable

    func testExporterIsSendable() async {
        let exporter = iOSImagesExporter()

        let assetType = await Task {
            exporter.assetType
        }.value

        XCTAssertEqual(assetType, .images)
    }

    // MARK: - ImagesExporter Protocol

    func testConformsToImagesExporter() {
        // Verify type conformance at compile time
        let exporter: any ImagesExporter = iOSImagesExporter()

        XCTAssertEqual(exporter.assetType, .images)
    }

    func testExportMethodExists() async throws {
        // This test verifies the export method signature exists
        // Full integration test would require mock context
        let exporter = iOSImagesExporter()

        // Type signature verification
        let _: (
            [iOSImagesEntry],
            iOSPlatformConfig,
            MockImagesExportContext
        ) async throws -> Int = exporter.exportImages
    }
}

// MARK: - Mock Context

/// Mock ImagesExportContext for testing.
struct MockImagesExportContext: ImagesExportContext {
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

    func loadImages(from source: ImagesSourceInput) async throws -> ImagesLoadOutput {
        ImagesLoadOutput(light: [], dark: [])
    }

    func processImages(
        _ images: ImagesLoadOutput,
        platform: Platform,
        nameValidateRegexp: String?,
        nameReplaceRegexp: String?,
        nameStyle: NameStyle
    ) throws -> ImagesProcessResult {
        ImagesProcessResult(imagePairs: [], warning: nil)
    }

    func downloadFiles(
        _ files: [FileContents],
        progressTitle: String
    ) async throws -> [FileContents] {
        files
    }

    func convertFormat(
        _ files: [FileContents],
        to outputFormat: ImageOutputFormat,
        progressTitle: String
    ) async throws -> [FileContents] {
        files
    }

    func rasterizeSVGs(
        _ files: [FileContents],
        scales: [Double],
        to outputFormat: ImageOutputFormat,
        progressTitle: String
    ) async throws -> [FileContents] {
        []
    }

    func withProgress<T: Sendable>(
        _ title: String,
        total: Int,
        operation: @escaping @Sendable (ProgressReporter) async throws -> T
    ) async throws -> T {
        try await operation(MockImagesProgressReporter())
    }
}

/// Mock ProgressReporter for images testing.
struct MockImagesProgressReporter: ProgressReporter {
    func update(current: Int) {}
    func increment() {}
}

// swiftlint:enable type_name
