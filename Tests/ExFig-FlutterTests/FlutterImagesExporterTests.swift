@testable import ExFig_Flutter
import ExFigCore
import XCTest

/// Tests for FlutterImagesExporter conformance to AssetExporter and ImagesExporter protocols.
final class FlutterImagesExporterTests: XCTestCase {
    // MARK: - Asset Type

    func testAssetTypeIsImages() {
        let exporter = FlutterImagesExporter()

        XCTAssertEqual(exporter.assetType, .images)
    }

    // MARK: - Sendable

    func testExporterIsSendable() async {
        let exporter = FlutterImagesExporter()

        let assetType = await Task {
            exporter.assetType
        }.value

        XCTAssertEqual(assetType, .images)
    }

    // MARK: - ImagesExporter Protocol

    func testConformsToImagesExporter() {
        let exporter: any ImagesExporter = FlutterImagesExporter()

        XCTAssertEqual(exporter.assetType, .images)
    }

    func testExportMethodExists() {
        let exporter = FlutterImagesExporter()

        // Type signature verification
        let _: (
            [FlutterImagesEntry],
            FlutterPlatformConfig,
            MockFlutterImagesExportContext
        ) async throws -> ImagesExportResult = exporter.exportImages
    }
}

// MARK: - mapToFlutterScaleDirectories

final class FlutterScaleDirectoriesTests: XCTestCase {
    private let assetsDir = URL(fileURLWithPath: "/project/assets/images")

    func testInMemoryFilesAreMappedToScaleDirectories() {
        let files = [
            makeInMemoryFile(name: "icon.webp", scale: 1.0),
            makeInMemoryFile(name: "icon.webp", scale: 2.0),
            makeInMemoryFile(name: "icon.webp", scale: 3.0),
        ]

        let result = FlutterImagesHelpers.mapToFlutterScaleDirectories(files, assetsDirectory: assetsDir)

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].destination.directory, assetsDir)
        XCTAssertEqual(result[1].destination.directory, assetsDir.appendingPathComponent("2.0x"))
        XCTAssertEqual(result[2].destination.directory, assetsDir.appendingPathComponent("3.0x"))
    }

    func testOnDiskFilesAreMappedToScaleDirectories() {
        let files = [
            makeOnDiskFile(name: "icon.webp", scale: 1.0),
            makeOnDiskFile(name: "icon.webp", scale: 2.0),
        ]

        let result = FlutterImagesHelpers.mapToFlutterScaleDirectories(files, assetsDirectory: assetsDir)

        XCTAssertEqual(result.count, 2)
        XCTAssertNotNil(result[0].dataFile)
        XCTAssertNotNil(result[1].dataFile)
    }

    func testScaleSuffixIsStrippedFromFilenames() {
        let files = [
            makeInMemoryFile(name: "icon@2x.png", scale: 2.0),
            makeInMemoryFile(name: "icon@3x.png", scale: 3.0),
        ]

        let result = FlutterImagesHelpers.mapToFlutterScaleDirectories(files, assetsDirectory: assetsDir)

        XCTAssertEqual(result[0].destination.file.lastPathComponent, "icon.png")
        XCTAssertEqual(result[1].destination.file.lastPathComponent, "icon.png")
    }

    func testMetadataIsPreserved() {
        let files = [makeInMemoryFile(name: "icon.png", scale: 2.0, dark: true)]

        let result = FlutterImagesHelpers.mapToFlutterScaleDirectories(files, assetsDirectory: assetsDir)

        XCTAssertEqual(result[0].scale, 2.0)
        XCTAssertTrue(result[0].dark)
    }

    // MARK: - Helpers

    private func makeInMemoryFile(name: String, scale: Double, dark: Bool = false) -> FileContents {
        FileContents(
            destination: Destination(directory: URL(fileURLWithPath: "/tmp"), file: URL(fileURLWithPath: name)),
            data: Data("test".utf8),
            scale: scale,
            dark: dark
        )
    }

    private func makeOnDiskFile(name: String, scale: Double) -> FileContents {
        FileContents(
            destination: Destination(directory: URL(fileURLWithPath: "/tmp"), file: URL(fileURLWithPath: name)),
            dataFile: URL(fileURLWithPath: "/tmp/\(name)"),
            scale: scale
        )
    }
}

// MARK: - Mock Context

/// Mock ImagesExportContext for testing.
struct MockFlutterImagesExportContext: ImagesExportContext {
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
        try await operation(MockFlutterImagesProgressReporter())
    }
}

/// Mock ProgressReporter for images testing.
struct MockFlutterImagesProgressReporter: ProgressReporter {
    func update(current: Int) {}
    func increment() {}
}
