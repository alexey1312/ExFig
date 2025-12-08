// swiftlint:disable force_unwrapping
import CustomDump
import ExFigCore
import FlutterExport
import XCTest

final class FlutterIconsExporterTests: XCTestCase {
    // MARK: - Properties

    private let output = FlutterOutput(
        outputDirectory: URL(string: "~/lib/generated/")!,
        iconsAssetsDirectory: URL(string: "assets/icons")!,
        templatesPath: nil,
        iconsClassName: "AppIcons"
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
        let exporter = FlutterIconsExporter(output: output, outputFileName: nil)

        let result = try exporter.export(icons: [iconPair1])

        // Check dart file
        XCTAssertEqual(result.dartFile.destination.directory.absoluteString, "~/lib/generated/")
        XCTAssertEqual(result.dartFile.destination.file.absoluteString, "icons.dart")

        // Check asset files - should have light and dark
        XCTAssertEqual(result.assetFiles.count, 2)

        let fileContent = try XCTUnwrap(result.dartFile.data)
        let generatedCode = String(data: fileContent, encoding: .utf8)

        let referenceCode = """
        // \(header)

        class AppIcons {
          AppIcons._();
          static const String icAddLight = 'assets/icons/ic_add.svg';
          static const String icAddDark = 'assets/icons/ic_add_dark.svg';
        }

        """ + "\n"

        expectNoDifference(generatedCode, referenceCode)
    }

    func testExportIconsLightOnly() throws {
        let exporter = FlutterIconsExporter(output: output, outputFileName: nil)

        let result = try exporter.export(icons: [iconPairLightOnly])

        // Check asset files - should have only light
        XCTAssertEqual(result.assetFiles.count, 1)

        let fileContent = try XCTUnwrap(result.dartFile.data)
        let generatedCode = String(data: fileContent, encoding: .utf8)

        let referenceCode = """
        // \(header)

        class AppIcons {
          AppIcons._();
          static const String icAdd = 'assets/icons/ic_add.svg';
        }

        """ + "\n"

        expectNoDifference(generatedCode, referenceCode)
    }

    func testExportIconsCustomFileName() throws {
        let exporter = FlutterIconsExporter(output: output, outputFileName: "app_icons.dart")

        let result = try exporter.export(icons: [iconPairLightOnly])

        XCTAssertEqual(result.dartFile.destination.file.absoluteString, "app_icons.dart")
    }

    func testExportIconsCustomClassName() throws {
        let customOutput = FlutterOutput(
            outputDirectory: URL(string: "~/lib/generated/")!,
            iconsAssetsDirectory: URL(string: "assets/icons")!,
            templatesPath: nil,
            iconsClassName: "MyIcons"
        )
        let exporter = FlutterIconsExporter(output: customOutput, outputFileName: nil)

        let result = try exporter.export(icons: [iconPairLightOnly])

        let fileContent = try XCTUnwrap(result.dartFile.data)
        let generatedCode = String(data: fileContent, encoding: .utf8)

        XCTAssertTrue(generatedCode?.contains("class MyIcons") == true)
    }

    // MARK: - Tests for allIconNames (granular cache support)

    /// Tests that when allIconNames is provided, the Dart file contains all icons
    /// even when only a subset is exported (simulating granular cache behavior).
    func testExportWithAllIconNames_generatesDartFileWithAllNames() throws {
        let exporter = FlutterIconsExporter(output: output, outputFileName: nil)

        // Export only one icon, but provide allIconNames with multiple names
        let result = try exporter.export(
            icons: [iconPairLightOnly],
            allIconNames: ["ic_add", "ic_remove", "ic_edit"]
        )

        let fileContent = try XCTUnwrap(result.dartFile.data)
        let generatedCode = String(data: fileContent, encoding: .utf8)

        // Verify all 3 icons are in the Dart file
        XCTAssertTrue(generatedCode?.contains("static const String icAdd = ") == true)
        XCTAssertTrue(generatedCode?.contains("static const String icRemove = ") == true)
        XCTAssertTrue(generatedCode?.contains("static const String icEdit = ") == true)

        // But only 1 asset file is created
        XCTAssertEqual(result.assetFiles.count, 1)
    }

    /// Tests that when allIconNames is nil, the Dart file is derived from exported icons.
    func testExportWithoutAllIconNames_generatesDartFileFromExportedIcons() throws {
        let exporter = FlutterIconsExporter(output: output, outputFileName: nil)

        let result = try exporter.export(
            icons: [iconPairLightOnly],
            allIconNames: nil
        )

        let fileContent = try XCTUnwrap(result.dartFile.data)
        let generatedCode = String(data: fileContent, encoding: .utf8)

        // Verify only the exported icon is in the Dart file
        XCTAssertTrue(generatedCode?.contains("static const String icAdd = ") == true)
        XCTAssertFalse(generatedCode?.contains("static const String icRemove = ") == true)
    }
}
