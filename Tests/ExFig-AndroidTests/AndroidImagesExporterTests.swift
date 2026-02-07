@testable import ExFig_Android
import ExFigCore
import XCTest

/// Tests for AndroidImagesExporter conformance to AssetExporter and ImagesExporter protocols.
final class AndroidImagesExporterTests: XCTestCase {
    // MARK: - Asset Type

    func testAssetTypeIsImages() {
        let exporter = AndroidImagesExporter()

        XCTAssertEqual(exporter.assetType, .images)
    }

    // MARK: - Sendable

    func testExporterIsSendable() async {
        let exporter = AndroidImagesExporter()

        let assetType = await Task {
            exporter.assetType
        }.value

        XCTAssertEqual(assetType, .images)
    }

    // MARK: - ImagesExporter Protocol

    func testConformsToImagesExporter() {
        let exporter: any ImagesExporter = AndroidImagesExporter()

        XCTAssertEqual(exporter.assetType, .images)
    }

    func testExportMethodExists() {
        let exporter = AndroidImagesExporter()

        // Type signature verification
        let _: (
            [AndroidImagesEntry],
            AndroidPlatformConfig,
            MockAndroidImagesExportContext
        ) async throws -> ImagesExportResult = exporter.exportImages
    }
}

// MARK: - Mock Context

/// Mock ImagesExportContext for testing.
struct MockAndroidImagesExportContext: ImagesExportContext {
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
        heicOptions: HeicConverterOptions?,
        webpOptions: WebpConverterOptions?,
        progressTitle: String
    ) async throws -> [FileContents] {
        files
    }

    // swiftlint:disable:next function_parameter_count
    func rasterizeSVGs(
        _ files: [FileContents],
        scales: [Double],
        to outputFormat: ImageOutputFormat,
        heicOptions: HeicConverterOptions?,
        webpOptions: WebpConverterOptions?,
        progressTitle: String
    ) async throws -> [FileContents] {
        []
    }

    func withProgress<T: Sendable>(
        _ title: String,
        total: Int,
        operation: @escaping @Sendable (ProgressReporter) async throws -> T
    ) async throws -> T {
        try await operation(MockAndroidImagesProgressReporter())
    }
}

/// Mock ProgressReporter for images testing.
struct MockAndroidImagesProgressReporter: ProgressReporter {
    func update(current: Int) {}
    func increment() {}
}
