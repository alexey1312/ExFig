// swiftlint:disable force_unwrapping
import CustomDump
import ExFigCore
import WebExport
import XCTest

final class WebIconsExporterTests: XCTestCase {
    // MARK: - Properties

    private let output = WebOutput(
        outputDirectory: URL(string: "~/src/icons/")!,
        iconsAssetsDirectory: URL(string: "assets/icons")!,
        templatesPath: nil
    )

    private lazy var lightImage = Image(
        name: "ic_add",
        url: URL(string: "https://example.com/light_icon.svg")!,
        format: "svg"
    )

    private lazy var darkImage = Image(
        name: "ic_add",
        url: URL(string: "https://example.com/dark_icon.svg")!,
        format: "svg"
    )

    private lazy var validLightPack = ImagePack(
        name: "ic_add",
        images: [lightImage]
    )

    private lazy var validDarkPack = ImagePack(
        name: "ic_add",
        images: [darkImage]
    )

    private lazy var iconPair1 = AssetPair<ImagePack>(
        light: validLightPack,
        dark: validDarkPack
    )

    private lazy var iconPairLightOnly = AssetPair<ImagePack>(
        light: validLightPack,
        dark: nil
    )

    // MARK: - Tests

    func testExportIcons() throws {
        let exporter = WebIconsExporter(output: output, generateReactComponents: true)

        let result = try exporter.export(icons: [iconPair1])

        // Check barrel file
        XCTAssertNotNil(result.barrelFile)
        XCTAssertEqual(result.barrelFile?.destination.file.absoluteString, "index.ts")

        // Check asset files - should have light and dark
        XCTAssertEqual(result.assetFiles.count, 2)

        // Check TSX components
        XCTAssertEqual(result.componentFiles.count, 1)
    }

    func testExportIconsLightOnly() throws {
        let exporter = WebIconsExporter(output: output, generateReactComponents: true)

        let result = try exporter.export(icons: [iconPairLightOnly])

        // Check asset files - should have only light
        XCTAssertEqual(result.assetFiles.count, 1)

        // Check TSX components
        XCTAssertEqual(result.componentFiles.count, 1)
    }

    func testExportIconsWithoutReactComponents() throws {
        let exporter = WebIconsExporter(output: output, generateReactComponents: false)

        let result = try exporter.export(icons: [iconPairLightOnly])

        // Check that no React components are generated
        XCTAssertEqual(result.componentFiles.count, 0)

        // But asset files should still be there
        XCTAssertEqual(result.assetFiles.count, 1)
    }

    func testExportIconComponentContent() throws {
        let exporter = WebIconsExporter(output: output, generateReactComponents: true)

        let result = try exporter.export(icons: [iconPairLightOnly])

        let component = try XCTUnwrap(result.componentFiles.first)
        let content = try XCTUnwrap(String(data: XCTUnwrap(component.data), encoding: .utf8))

        // Verify component renders with correct structure
        XCTAssertTrue(content.contains("export const IcAdd"), "Expected component name IcAdd")
        XCTAssertTrue(content.contains("IconProps"), "Expected IconProps type import")
        XCTAssertTrue(content.contains("viewBox=\"0 0 24 24\""), "Expected default viewBox")
    }

    func testExportTypesFile() throws {
        let exporter = WebIconsExporter(output: output, generateReactComponents: true)

        let result = try exporter.export(icons: [iconPairLightOnly])

        // Check types file
        XCTAssertNotNil(result.typesFile)
        XCTAssertEqual(result.typesFile?.destination.file.absoluteString, "types.ts")

        let fileContent = try XCTUnwrap(result.typesFile?.data)
        let generatedCode = try XCTUnwrap(String(data: fileContent, encoding: .utf8))

        XCTAssertTrue(generatedCode.contains("SVGAttributes"))
        XCTAssertTrue(generatedCode.contains("IconProps"))
    }

    func testExportBarrelFile() throws {
        let exporter = WebIconsExporter(output: output, generateReactComponents: true)

        // Create multiple icons
        let icon2Light = try ImagePack(
            name: "ic_remove",
            images: [Image(
                name: "ic_remove",
                url: XCTUnwrap(URL(string: "https://example.com/remove.svg")),
                format: "svg"
            )]
        )
        let iconPair2 = AssetPair<ImagePack>(light: icon2Light, dark: nil)

        let result = try exporter.export(icons: [iconPairLightOnly, iconPair2])

        // Check barrel file has exports
        let fileContent = try XCTUnwrap(result.barrelFile?.data)
        let generatedCode = try XCTUnwrap(String(data: fileContent, encoding: .utf8))

        XCTAssertTrue(generatedCode.contains("export"))
    }
}
