// swiftlint:disable force_unwrapping function_body_length
@testable import AndroidExport
import CustomDump
import ExFigCore
import XCTest

final class AndroidColorExporterTests: XCTestCase {
    // MARK: - Properties

    private static let packageName = "test"
    private static let resourcePackage = "resourceTest"
    private let output = AndroidOutput(
        xmlOutputDirectory: URL(string: "~/")!,
        xmlResourcePackage: resourcePackage,
        srcDirectory: URL(string: "~/"),
        packageName: packageName,
        colorKotlinURL: nil,
        templatesPath: nil
    )

    private let colorPair1 = AssetPair<Color>(
        light: Color(name: "color_pair_1", red: 119.0 / 255.0, green: 3.0 / 255.0, blue: 1.0, alpha: 0.5),
        dark: nil
    )

    private let colorPair2 = AssetPair<Color>(
        light: Color(name: "color_pair_2", red: 1, green: 1, blue: 1, alpha: 1),
        dark: Color(name: "color_pair_2", red: 0, green: 0, blue: 0, alpha: 1)
    )

    // MARK: - Setup

    func testExport() throws {
        let exporter = AndroidColorExporter(output: output, xmlOutputFileName: nil)

        let result = try exporter.export(colorPairs: [colorPair1, colorPair2])
        XCTAssertEqual(result.count, 3)

        XCTAssertEqual(result[0].destination.directory.lastPathComponent, "values")
        XCTAssertEqual(result[0].destination.file.absoluteString, "colors.xml")

        XCTAssertEqual(result[1].destination.directory.lastPathComponent, "values-night")
        XCTAssertEqual(result[1].destination.file.absoluteString, "colors.xml")

        let fileContentLight = try XCTUnwrap(result[0].data)
        let fileContentDark = try XCTUnwrap(result[1].data)

        let generatedCodeLight = String(data: fileContentLight, encoding: .utf8)
        let generatedCodeDark = String(data: fileContentDark, encoding: .utf8)

        let referenceCodeLight = """
        <?xml version="1.0" encoding="utf-8"?>
        <!--
        \(header)
        -->
        <resources>
            <color name="color_pair_1">#807703FF</color>
            <color name="color_pair_2">#FFFFFF</color>
        </resources>

        """

        let referenceCodeDark = """
        <?xml version="1.0" encoding="utf-8"?>
        <!--
        \(header)
        -->
        <resources>
            <color name="color_pair_1">#807703FF</color>
            <color name="color_pair_2">#000000</color>
        </resources>

        """

        expectNoDifference(generatedCodeLight, referenceCodeLight)
        expectNoDifference(generatedCodeDark, referenceCodeDark)

        XCTAssertEqual(result[2].destination.directory.lastPathComponent, AndroidColorExporterTests.packageName)
        XCTAssertEqual(result[2].destination.file.absoluteString, "Colors.kt")
        let generatedComposedCode = try String(data: XCTUnwrap(result[2].data), encoding: .utf8)
        let referenceComposeCode = """
        /*
        \(header)
        */
        package \(AndroidColorExporterTests.packageName)

        import androidx.compose.runtime.Composable
        import androidx.compose.runtime.ReadOnlyComposable
        import androidx.compose.ui.graphics.Color
        import androidx.compose.ui.res.colorResource
        import \(AndroidColorExporterTests.resourcePackage).R

        object Colors

        @Composable
        @ReadOnlyComposable
        fun Colors.colorPair1(): Color = colorResource(id = R.color.color_pair_1)

        @Composable
        @ReadOnlyComposable
        fun Colors.colorPair2(): Color = colorResource(id = R.color.color_pair_2)

        """
        expectNoDifference(generatedComposedCode, referenceComposeCode)
    }

    // MARK: - Kotlin Hex Tests

    func testKotlinHex_opaqueColor() {
        let color = Color(name: "white", red: 1, green: 1, blue: 1, alpha: 1)
        XCTAssertEqual(color.kotlinHex, "0xFFFFFFFF")
    }

    func testKotlinHex_opaqueColorWithComponents() {
        // RGB: 119, 3, 255 = #7703FF
        let color = Color(name: "purple", red: 119.0 / 255.0, green: 3.0 / 255.0, blue: 1.0, alpha: 1)
        XCTAssertEqual(color.kotlinHex, "0xFF7703FF")
    }

    func testKotlinHex_colorWithAlpha() {
        // RGB: 119, 3, 255 with 50% alpha
        let color = Color(name: "purple_50", red: 119.0 / 255.0, green: 3.0 / 255.0, blue: 1.0, alpha: 0.5)
        XCTAssertEqual(color.kotlinHex, "0x807703FF")
    }

    func testKotlinHex_blackColor() {
        let color = Color(name: "black", red: 0, green: 0, blue: 0, alpha: 1)
        XCTAssertEqual(color.kotlinHex, "0xFF000000")
    }

    // MARK: - Custom Color Kotlin Path Tests

    func testExportWithCustomColorKotlinPath() throws {
        let customURL = URL(string: "./custom/path/Ds3Colors.kt")!
        let outputWithCustomPath = AndroidOutput(
            xmlOutputDirectory: URL(string: "~/")!,
            xmlResourcePackage: AndroidColorExporterTests.resourcePackage,
            srcDirectory: nil,
            packageName: AndroidColorExporterTests.packageName,
            colorKotlinURL: customURL,
            templatesPath: nil
        )

        let exporter = AndroidColorExporter(output: outputWithCustomPath, xmlOutputFileName: nil)
        let result = try exporter.export(colorPairs: [colorPair1])

        // Should have 2 XML files + 1 Kotlin file
        XCTAssertEqual(result.count, 2) // Only light XML + Kotlin (no dark since colorPair1 has no dark)

        // Last file should be the Kotlin file with custom name
        let kotlinFile = result.last!
        XCTAssertEqual(kotlinFile.destination.directory.lastPathComponent, "path")
        XCTAssertEqual(kotlinFile.destination.file.absoluteString, "Ds3Colors.kt")
    }

    func testExportWithCustomColorKotlinPath_overridesPackageDirectory() throws {
        let customURL = URL(string: "./app/src/main/java/com/example/ui/theme/CustomColors.kt")!
        let outputWithCustomPath = AndroidOutput(
            xmlOutputDirectory: URL(string: "~/")!,
            xmlResourcePackage: AndroidColorExporterTests.resourcePackage,
            srcDirectory: URL(string: "~/src"),
            packageName: "com.different.package",
            colorKotlinURL: customURL,
            templatesPath: nil
        )

        let exporter = AndroidColorExporter(output: outputWithCustomPath, xmlOutputFileName: nil)
        let result = try exporter.export(colorPairs: [colorPair1])

        // Last file should use custom path, not computed from package
        let kotlinFile = result.last!
        XCTAssertEqual(kotlinFile.destination.directory.lastPathComponent, "theme")
        XCTAssertEqual(kotlinFile.destination.file.absoluteString, "CustomColors.kt")
    }
}
