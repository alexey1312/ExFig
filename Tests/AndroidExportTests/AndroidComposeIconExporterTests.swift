import AndroidExport
import CustomDump
import ExFigCore
import XCTest

final class AndroidComposeIconExporterTests: XCTestCase {
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

    private let iconName1 = "test_icon_1"
    private let iconName2 = "test_icon_2"

    // MARK: - Tests

    func testExport() throws {
        let exporter = AndroidComposeIconExporter(output: output)

        let result = try XCTUnwrap(exporter.exportIcons(iconNames: [iconName1, iconName2]))

        XCTAssertEqual(result.destination.directory.lastPathComponent, AndroidComposeIconExporterTests.packageName)
        XCTAssertEqual(result.destination.file.absoluteString, "Icons.kt")
        let generatedComposedCode = try String(data: XCTUnwrap(result.data), encoding: .utf8)
        let referenceComposeCode = """
        /*
        \(header)
        */
        package \(AndroidComposeIconExporterTests.packageName)

        import androidx.compose.material.Icon
        import androidx.compose.material.LocalContentAlpha
        import androidx.compose.material.LocalContentColor
        import androidx.compose.runtime.Composable
        import androidx.compose.ui.Modifier
        import androidx.compose.ui.graphics.Color
        import androidx.compose.ui.res.painterResource
        import \(AndroidComposeIconExporterTests.resourcePackage).R

        object Icons

        @Composable
        fun Icons.TestIcon1(
            contentDescription: String? = null,
            modifier: Modifier = Modifier,
            tint: Color = Color.Unspecified
        ) {
            Icon(
                painter = painterResource(id = R.drawable.test_icon_1),
                contentDescription = contentDescription,
                modifier = modifier,
                tint = tint
            )
        }

        @Composable
        fun Icons.TestIcon2(
            contentDescription: String? = null,
            modifier: Modifier = Modifier,
            tint: Color = Color.Unspecified
        ) {
            Icon(
                painter = painterResource(id = R.drawable.test_icon_2),
                contentDescription = contentDescription,
                modifier = modifier,
                tint = tint
            )
        }

        """
        expectNoDifference(generatedComposedCode, referenceComposeCode)
    }

    // MARK: - Tests for allIconNames (granular cache support)

    /// Tests that when allIconNames is provided, the Kotlin file contains all icons
    /// even when only a subset is exported (simulating granular cache behavior).
    func testExportWithAllIconNames_generatesFileWithAllNames() throws {
        let exporter = AndroidComposeIconExporter(output: output)

        // Export with only iconName1, but provide allIconNames with both
        let result = try XCTUnwrap(exporter.exportIcons(
            iconNames: [iconName1],
            allIconNames: [iconName1, iconName2, "test_icon_3"]
        ))

        let generatedComposedCode = try String(data: XCTUnwrap(result.data), encoding: .utf8)

        // Verify all 3 icons are in the generated file
        XCTAssertTrue(generatedComposedCode?.contains("fun Icons.TestIcon1(") == true)
        XCTAssertTrue(generatedComposedCode?.contains("fun Icons.TestIcon2(") == true)
        XCTAssertTrue(generatedComposedCode?.contains("fun Icons.TestIcon3(") == true)
    }

    /// Tests that when allIconNames is nil, the Kotlin file is generated from iconNames.
    func testExportWithoutAllIconNames_generatesFileFromIconNames() throws {
        let exporter = AndroidComposeIconExporter(output: output)

        let result = try XCTUnwrap(exporter.exportIcons(
            iconNames: [iconName1],
            allIconNames: nil
        ))

        let generatedComposedCode = try String(data: XCTUnwrap(result.data), encoding: .utf8)

        // Verify only iconName1 is in the generated file
        XCTAssertTrue(generatedComposedCode?.contains("fun Icons.TestIcon1(") == true)
        XCTAssertFalse(generatedComposedCode?.contains("fun Icons.TestIcon2(") == true)
    }
}
