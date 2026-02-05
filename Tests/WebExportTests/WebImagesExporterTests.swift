// swiftlint:disable force_unwrapping
import CustomDump
import ExFigCore
import WebExport
import XCTest

final class WebImagesExporterTests: XCTestCase {
    // MARK: - Properties

    private let output = WebOutput(
        outputDirectory: URL(string: "~/src/images/")!,
        imagesAssetsDirectory: URL(string: "assets/images")!,
        templatesPath: nil
    )

    private lazy var lightImage = Image(
        name: "hero_banner",
        url: URL(string: "https://example.com/hero.svg")!,
        format: "svg"
    )

    private lazy var darkImage = Image(
        name: "hero_banner",
        url: URL(string: "https://example.com/hero_dark.svg")!,
        format: "svg"
    )

    private lazy var validLightPack = ImagePack(
        name: "hero_banner",
        images: [lightImage]
    )

    private lazy var validDarkPack = ImagePack(
        name: "hero_banner",
        images: [darkImage]
    )

    private lazy var imagePair1 = AssetPair<ImagePack>(
        light: validLightPack,
        dark: validDarkPack
    )

    private lazy var imagePairLightOnly = AssetPair<ImagePack>(
        light: validLightPack,
        dark: nil
    )

    // MARK: - Tests

    func testExportImages() throws {
        let exporter = WebImagesExporter(output: output, generateReactComponents: true)

        let result = try exporter.export(images: [imagePair1])

        // Check barrel file
        XCTAssertNotNil(result.barrelFile)
        XCTAssertEqual(result.barrelFile?.destination.file.absoluteString, "index.ts")

        // Check asset files - should have light and dark
        XCTAssertEqual(result.assetFiles.count, 2)

        // Check TSX components
        XCTAssertEqual(result.componentFiles.count, 1)
    }

    func testExportImagesLightOnly() throws {
        let exporter = WebImagesExporter(output: output, generateReactComponents: true)

        let result = try exporter.export(images: [imagePairLightOnly])

        // Check asset files - should have only light
        XCTAssertEqual(result.assetFiles.count, 1)

        // Check TSX components
        XCTAssertEqual(result.componentFiles.count, 1)
    }

    func testExportImagesWithoutReactComponents() throws {
        let exporter = WebImagesExporter(output: output, generateReactComponents: false)

        let result = try exporter.export(images: [imagePairLightOnly])

        // Check that no React components are generated
        XCTAssertEqual(result.componentFiles.count, 0)

        // But asset files should still be there
        XCTAssertEqual(result.assetFiles.count, 1)
    }

    func testExportBarrelFile() throws {
        let exporter = WebImagesExporter(output: output, generateReactComponents: true)

        // Create multiple images
        let image2Light = try ImagePack(
            name: "promo_card",
            images: [Image(
                name: "promo_card",
                url: XCTUnwrap(URL(string: "https://example.com/promo.svg")),
                format: "svg"
            )]
        )
        let imagePair2 = AssetPair<ImagePack>(light: image2Light, dark: nil)

        let result = try exporter.export(images: [imagePairLightOnly, imagePair2])

        // Check barrel file has exports
        let fileContent = try XCTUnwrap(result.barrelFile?.data)
        let generatedCode = try XCTUnwrap(String(data: fileContent, encoding: .utf8))

        XCTAssertTrue(generatedCode.contains("export"))
    }
}
