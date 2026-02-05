// swiftlint:disable force_unwrapping
import CustomDump
import ExFigCore
import FlutterExport
import XCTest

final class FlutterImagesExporterTests: XCTestCase {
    // MARK: - Properties

    private let output = FlutterOutput(
        outputDirectory: URL(string: "~/lib/generated/")!,
        imagesAssetsDirectory: URL(string: "assets/images")!,
        templatesPath: nil,
        imagesClassName: "AppImages"
    )

    private lazy var lightImage1x = Image(
        name: "logo",
        scale: .individual(1),
        url: URL(string: "https://example.com/light_1x.png")!,
        format: "png"
    )

    private lazy var lightImage2x = Image(
        name: "logo",
        scale: .individual(2),
        url: URL(string: "https://example.com/light_2x.png")!,
        format: "png"
    )

    private lazy var lightImage3x = Image(
        name: "logo",
        scale: .individual(3),
        url: URL(string: "https://example.com/light_3x.png")!,
        format: "png"
    )

    private lazy var darkImage1x = Image(
        name: "logo",
        scale: .individual(1),
        url: URL(string: "https://example.com/dark_1x.png")!,
        format: "png"
    )

    private lazy var darkImage2x = Image(
        name: "logo",
        scale: .individual(2),
        url: URL(string: "https://example.com/dark_2x.png")!,
        format: "png"
    )

    private lazy var darkImage3x = Image(
        name: "logo",
        scale: .individual(3),
        url: URL(string: "https://example.com/dark_3x.png")!,
        format: "png"
    )

    private lazy var validLightPack = ImagePack(
        name: "logo",
        images: [lightImage1x, lightImage2x, lightImage3x]
    )

    private lazy var validDarkPack = ImagePack(
        name: "logo",
        images: [darkImage1x, darkImage2x, darkImage3x]
    )

    private lazy var imagePairWithDark = AssetPair<ImagePack>(
        light: validLightPack,
        dark: validDarkPack
    )

    private lazy var imagePairLightOnly = AssetPair<ImagePack>(
        light: validLightPack,
        dark: nil
    )

    // MARK: - Tests

    func testExportImages() throws {
        let exporter = FlutterImagesExporter(output: output, outputFileName: nil, scales: nil, format: nil)

        let result = try exporter.export(images: [imagePairLightOnly])

        // Check dart file
        XCTAssertEqual(result.dartFile.destination.directory.absoluteString, "~/lib/generated/")
        XCTAssertEqual(result.dartFile.destination.file.absoluteString, "images.dart")

        // Check asset files - should have 3 scales (1x, 2x, 3x)
        XCTAssertEqual(result.assetFiles.count, 3)

        let fileContent = try XCTUnwrap(result.dartFile.data)
        let generatedCode = String(data: fileContent, encoding: .utf8)

        let referenceCode = """
        // \(header)

        class AppImages {
          AppImages._();
          static const String logo = 'assets/images/logo.png';
        }

        """ + "\n"

        expectNoDifference(generatedCode, referenceCode)
    }

    func testExportImagesWithDarkMode() throws {
        let exporter = FlutterImagesExporter(output: output, outputFileName: nil, scales: nil, format: nil)

        let result = try exporter.export(images: [imagePairWithDark])

        // Check dart file
        XCTAssertEqual(result.dartFile.destination.directory.absoluteString, "~/lib/generated/")
        XCTAssertEqual(result.dartFile.destination.file.absoluteString, "images.dart")

        // Check asset files - should have 6 files (3 scales x 2 variants)
        XCTAssertEqual(result.assetFiles.count, 6)

        let fileContent = try XCTUnwrap(result.dartFile.data)
        let generatedCode = String(data: fileContent, encoding: .utf8)

        let referenceCode = """
        // \(header)

        class AppImages {
          AppImages._();
          static const String logoLight = 'assets/images/logo.png';
          static const String logoDark = 'assets/images/logo_dark.png';
        }

        """ + "\n"

        expectNoDifference(generatedCode, referenceCode)
    }

    func testExportImagesCustomFileName() throws {
        let exporter = FlutterImagesExporter(
            output: output,
            outputFileName: "app_images.dart",
            scales: nil,
            format: nil
        )

        let result = try exporter.export(images: [imagePairLightOnly])

        XCTAssertEqual(result.dartFile.destination.file.absoluteString, "app_images.dart")
    }

    func testExportImagesCustomClassName() throws {
        let customOutput = try FlutterOutput(
            outputDirectory: XCTUnwrap(URL(string: "~/lib/generated/")),
            imagesAssetsDirectory: XCTUnwrap(URL(string: "assets/images")),
            templatesPath: nil,
            imagesClassName: "MyImages"
        )
        let exporter = FlutterImagesExporter(output: customOutput, outputFileName: nil, scales: nil, format: nil)

        let result = try exporter.export(images: [imagePairLightOnly])

        let fileContent = try XCTUnwrap(result.dartFile.data)
        let generatedCode = String(data: fileContent, encoding: .utf8)

        XCTAssertTrue(generatedCode?.contains("class MyImages") == true)
    }

    func testExportImagesCustomScales() throws {
        let exporter = FlutterImagesExporter(output: output, outputFileName: nil, scales: [1, 2], format: nil)

        let result = try exporter.export(images: [imagePairLightOnly])

        // Check asset files - should have 2 scales (1x, 2x)
        XCTAssertEqual(result.assetFiles.count, 2)
    }

    func testExportImagesScaleDirectories() throws {
        let exporter = FlutterImagesExporter(output: output, outputFileName: nil, scales: nil, format: nil)

        let result = try exporter.export(images: [imagePairLightOnly])

        // Verify scale directory structure
        let scale1xFile = result.assetFiles.first { $0.scale == 1 }
        let scale2xFile = result.assetFiles.first { $0.scale == 2 }
        let scale3xFile = result.assetFiles.first { $0.scale == 3 }

        // 1x should be at root (assets/images/)
        XCTAssertEqual(scale1xFile?.destination.directory.absoluteString, "assets/images")

        // 2x should be at 2x/ subdirectory
        XCTAssertEqual(scale2xFile?.destination.directory.absoluteString, "assets/images/2.0x")

        // 3x should be at 3x/ subdirectory
        XCTAssertEqual(scale3xFile?.destination.directory.absoluteString, "assets/images/3.0x")
    }
}
