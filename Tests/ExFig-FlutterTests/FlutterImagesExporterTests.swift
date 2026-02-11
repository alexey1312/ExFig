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

// MARK: - Dark Mode Suffix in makeSVGRemoteFiles

final class FlutterDarkSVGRemoteFilesTests: XCTestCase {
    private let assetsDir = URL(fileURLWithPath: "/project/assets/images")

    func testDarkFilesGetSuffixInSVGRemoteFiles() throws {
        let lightPack = try ImagePack(
            image: Image(name: "icon", url: XCTUnwrap(URL(string: "https://figma.com/light")), format: "svg")
        )
        let darkPack = try ImagePack(
            image: Image(name: "icon", url: XCTUnwrap(URL(string: "https://figma.com/dark")), format: "svg")
        )
        let pairs = [AssetPair(light: lightPack, dark: darkPack)]

        let files = FlutterImagesHelpers.makeSVGRemoteFiles(
            imagePairs: pairs, assetsDirectory: assetsDir, nameStyle: .snakeCase
        )

        XCTAssertEqual(files.count, 2)

        // Light file: normal name, same directory
        XCTAssertEqual(files[0].destination.file.lastPathComponent, "icon.svg")
        XCTAssertEqual(files[0].destination.directory, assetsDir)
        XCTAssertFalse(files[0].dark)

        // Dark file: name with suffix, same directory (not dark/ subdirectory)
        XCTAssertEqual(files[1].destination.file.lastPathComponent, "icon_dark.svg")
        XCTAssertEqual(files[1].destination.directory, assetsDir)
        XCTAssertTrue(files[1].dark)
    }

    func testDarkSVGFilesSuffixVariesByNameStyle() throws {
        let lightPack = try ImagePack(
            image: Image(name: "icon", url: XCTUnwrap(URL(string: "https://figma.com/light")), format: "svg")
        )
        let darkPack = try ImagePack(
            image: Image(name: "icon", url: XCTUnwrap(URL(string: "https://figma.com/dark")), format: "svg")
        )
        let pairs = [AssetPair(light: lightPack, dark: darkPack)]

        let camelFiles = FlutterImagesHelpers.makeSVGRemoteFiles(
            imagePairs: pairs, assetsDirectory: assetsDir, nameStyle: .camelCase
        )
        XCTAssertEqual(camelFiles[1].destination.file.lastPathComponent, "iconDark.svg")

        let kebabFiles = FlutterImagesHelpers.makeSVGRemoteFiles(
            imagePairs: pairs, assetsDirectory: assetsDir, nameStyle: .kebabCase
        )
        XCTAssertEqual(kebabFiles[1].destination.file.lastPathComponent, "icon-dark.svg")
    }
}

// MARK: - Dark Mode Suffix in makeRasterRemoteFiles

final class FlutterDarkRasterRemoteFilesTests: XCTestCase {
    private let tempDir = URL(fileURLWithPath: "/tmp/exfig-test")

    func testDarkFilesGetSuffixInRasterRemoteFiles() throws {
        let lightPack = try ImagePack(
            name: "icon",
            images: [
                Image(
                    name: "icon",
                    scale: .individual(1.0),
                    url: XCTUnwrap(URL(string: "https://figma.com/1x")),
                    format: "png"
                ),
                Image(
                    name: "icon",
                    scale: .individual(2.0),
                    url: XCTUnwrap(URL(string: "https://figma.com/2x")),
                    format: "png"
                ),
            ]
        )
        let darkPack = try ImagePack(
            name: "icon",
            images: [
                Image(
                    name: "icon",
                    scale: .individual(1.0),
                    url: XCTUnwrap(URL(string: "https://figma.com/dark-1x")),
                    format: "png"
                ),
                Image(
                    name: "icon",
                    scale: .individual(2.0),
                    url: XCTUnwrap(URL(string: "https://figma.com/dark-2x")),
                    format: "png"
                ),
            ]
        )
        let pairs = [AssetPair(light: lightPack, dark: darkPack)]

        let files = try FlutterImagesHelpers.makeRasterRemoteFiles(
            imagePairs: pairs, tempDirectory: tempDir, scales: [1.0, 2.0], nameStyle: .snakeCase
        )

        XCTAssertEqual(files.count, 4)

        // Light files: normal name
        let lightFiles = files.filter { !$0.dark }
        XCTAssertEqual(lightFiles.count, 2)
        XCTAssertTrue(lightFiles.allSatisfy { $0.destination.file.lastPathComponent == "icon.png" })

        // Dark files: name with suffix, same scale directories (not dark/ subdirectory)
        let darkFiles = files.filter(\.dark)
        XCTAssertEqual(darkFiles.count, 2)
        XCTAssertTrue(darkFiles.allSatisfy { $0.destination.file.lastPathComponent == "icon_dark.png" })

        // Dark files use same scale directories as light (no dark/ prefix)
        let darkDirs = darkFiles.map(\.destination.directory.lastPathComponent).sorted()
        let lightDirs = lightFiles.map(\.destination.directory.lastPathComponent).sorted()
        XCTAssertEqual(darkDirs, lightDirs)
    }
}

// MARK: - Dark Mode End-to-End (makeSVGRemoteFiles → mapToFlutterScaleDirectories)

final class FlutterDarkModeEndToEndTests: XCTestCase {
    func testDarkFilesPreserveSuffixAfterScaleMapping() {
        let assetsDir = URL(fileURLWithPath: "/project/assets/images")

        // Simulate files after rasterization — dark files already have suffix from makeSVGRemoteFiles
        let files = [
            makeRasterFile(name: "icon.webp", scale: 1.0, dark: false),
            makeRasterFile(name: "icon.webp", scale: 2.0, dark: false),
            makeRasterFile(name: "icon_dark.webp", scale: 1.0, dark: true),
            makeRasterFile(name: "icon_dark.webp", scale: 2.0, dark: true),
        ]

        let result = FlutterImagesHelpers.mapToFlutterScaleDirectories(files, assetsDirectory: assetsDir)

        XCTAssertEqual(result.count, 4)

        let lightResults = result.filter { !$0.dark }
        let darkResults = result.filter(\.dark)

        // Light: icon.webp in root and 2.0x/
        XCTAssertEqual(lightResults[0].destination.file.lastPathComponent, "icon.webp")
        XCTAssertEqual(lightResults[0].destination.directory, assetsDir)
        XCTAssertEqual(lightResults[1].destination.file.lastPathComponent, "icon.webp")
        XCTAssertEqual(lightResults[1].destination.directory, assetsDir.appendingPathComponent("2.0x"))

        // Dark: icon_dark.webp in root and 2.0x/ (suffix preserved, no dark/ subdirectory)
        XCTAssertEqual(darkResults[0].destination.file.lastPathComponent, "icon_dark.webp")
        XCTAssertEqual(darkResults[0].destination.directory, assetsDir)
        XCTAssertEqual(darkResults[1].destination.file.lastPathComponent, "icon_dark.webp")
        XCTAssertEqual(darkResults[1].destination.directory, assetsDir.appendingPathComponent("2.0x"))
    }

    // MARK: - Helpers

    private func makeRasterFile(name: String, scale: Double, dark: Bool) -> FileContents {
        FileContents(
            destination: Destination(directory: URL(fileURLWithPath: "/tmp"), file: URL(fileURLWithPath: name)),
            data: Data("test".utf8),
            scale: scale,
            dark: dark
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
