// swiftlint:disable force_unwrapping
import CustomDump
import ExFigCore
import FlutterExport
import XCTest

final class FlutterColorExporterTests: XCTestCase {
    // MARK: - Properties

    private let output = FlutterOutput(
        outputDirectory: URL(string: "~/lib/generated/")!,
        templatesPath: nil,
        colorsClassName: "AppColors"
    )

    private let colorPair1 = AssetPair<Color>(
        light: Color(name: "colorPair1", red: 119.0 / 255.0, green: 3.0 / 255.0, blue: 1.0, alpha: 0.5),
        dark: nil
    )

    private let colorPair2 = AssetPair<Color>(
        light: Color(name: "colorPair2", red: 1, green: 1, blue: 1, alpha: 1),
        dark: Color(name: "colorPair2", red: 0, green: 0, blue: 0, alpha: 1)
    )

    // MARK: - Tests

    func testExport() throws {
        let exporter = FlutterColorExporter(output: output, outputFileName: nil)

        let result = try exporter.export(colorPairs: [colorPair1, colorPair2])
        XCTAssertEqual(result.count, 1)

        XCTAssertEqual(result[0].destination.directory.absoluteString, "~/lib/generated/")
        XCTAssertEqual(result[0].destination.file.absoluteString, "colors.dart")

        let fileContent = try XCTUnwrap(result[0].data)
        let generatedCode = String(data: fileContent, encoding: .utf8)

        // Build reference with explicit newlines to match generated output exactly
        // Note: Template produces NO blank lines after import, but 2 blank lines at end
        let referenceCode = [
            "// \(header)",
            "",
            "import 'package:flutter/material.dart';",
            "class AppColors {",
            "  AppColors._();",
            "  static const Color colorPair1 = Color(0x807703FF);",
            "  static const Color colorPair2 = Color(0xFFFFFFFF);",
            "}",
            "class AppColorsDark {",
            "  AppColorsDark._();",
            "  static const Color colorPair2 = Color(0xFF000000);",
            "}",
            "",
            "",
        ].joined(separator: "\n") + "\n"

        expectNoDifference(generatedCode, referenceCode)
    }

    func testExportLightOnly() throws {
        let exporter = FlutterColorExporter(output: output, outputFileName: nil)

        let result = try exporter.export(colorPairs: [colorPair1])
        XCTAssertEqual(result.count, 1)

        let fileContent = try XCTUnwrap(result[0].data)
        let generatedCode = String(data: fileContent, encoding: .utf8)

        // Build reference with explicit newlines to match generated output exactly
        // Note: Template produces NO blank lines after import, but 2 blank lines at end
        let referenceCode = [
            "// \(header)",
            "",
            "import 'package:flutter/material.dart';",
            "class AppColors {",
            "  AppColors._();",
            "  static const Color colorPair1 = Color(0x807703FF);",
            "}",
            "",
            "",
        ].joined(separator: "\n") + "\n"

        expectNoDifference(generatedCode, referenceCode)
    }

    func testExportCustomFileName() throws {
        let exporter = FlutterColorExporter(output: output, outputFileName: "app_colors.dart")

        let result = try exporter.export(colorPairs: [colorPair1])
        XCTAssertEqual(result.count, 1)

        XCTAssertEqual(result[0].destination.file.absoluteString, "app_colors.dart")
    }

    func testExportCustomClassName() throws {
        let customOutput = try FlutterOutput(
            outputDirectory: XCTUnwrap(URL(string: "~/lib/generated/")),
            templatesPath: nil,
            colorsClassName: "MyColors"
        )
        let exporter = FlutterColorExporter(output: customOutput, outputFileName: nil)

        let result = try exporter.export(colorPairs: [colorPair1])
        let fileContent = try XCTUnwrap(result[0].data)
        let generatedCode = String(data: fileContent, encoding: .utf8)

        XCTAssertTrue(generatedCode?.contains("class MyColors") == true)
    }

    // MARK: - 4-Mode High Contrast Tests

    func testExportWithHighContrast() throws {
        let colorPairWithHC = AssetPair<Color>(
            light: Color(name: "background", red: 1, green: 1, blue: 1, alpha: 1),
            dark: Color(name: "background", red: 0.08, green: 0.08, blue: 0.08, alpha: 1),
            lightHC: Color(name: "background", red: 1, green: 1, blue: 1, alpha: 1),
            darkHC: Color(name: "background", red: 0, green: 0, blue: 0, alpha: 1)
        )

        let exporter = FlutterColorExporter(output: output, outputFileName: nil)
        let result = try exporter.export(colorPairs: [colorPairWithHC])

        XCTAssertEqual(result.count, 1)

        let fileContent = try XCTUnwrap(result[0].data)
        let generatedCode = try XCTUnwrap(String(data: fileContent, encoding: .utf8))

        // Verify unified mode class structure
        XCTAssertTrue(generatedCode.contains("final Color light;"))
        XCTAssertTrue(generatedCode.contains("final Color dark;"))
        XCTAssertTrue(generatedCode.contains("final Color lightHighContrast;"))
        XCTAssertTrue(generatedCode.contains("final Color darkHighContrast;"))

        // Verify constructor
        XCTAssertTrue(generatedCode.contains("const AppColors({"))
        XCTAssertTrue(generatedCode.contains("required this.light,"))
        XCTAssertTrue(generatedCode.contains("required this.lightHighContrast,"))

        // Verify static constant
        XCTAssertTrue(generatedCode.contains("static const background = AppColors("))
        XCTAssertTrue(generatedCode.contains("light: Color(0xFFFFFFFF),"))
        XCTAssertTrue(generatedCode.contains("dark: Color(0xFF141414),"))
        XCTAssertTrue(generatedCode.contains("lightHighContrast: Color(0xFFFFFFFF),"))
        XCTAssertTrue(generatedCode.contains("darkHighContrast: Color(0xFF000000),"))

        // Verify legacy classes are NOT present
        XCTAssertFalse(generatedCode.contains("AppColors._()"))
        XCTAssertFalse(generatedCode.contains("class AppColorsDark"))
    }

    func testExportWithoutHighContrast_UsesLegacyMode() throws {
        // colorPair1 and colorPair2 have no HC colors
        let exporter = FlutterColorExporter(output: output, outputFileName: nil)
        let result = try exporter.export(colorPairs: [colorPair1, colorPair2])

        let fileContent = try XCTUnwrap(result[0].data)
        let generatedCode = try XCTUnwrap(String(data: fileContent, encoding: .utf8))

        // Verify legacy 2-class format
        XCTAssertTrue(generatedCode.contains("class AppColors {"))
        XCTAssertTrue(generatedCode.contains("AppColors._();"))
        XCTAssertTrue(generatedCode.contains("static const Color colorPair1 = Color("))
        XCTAssertTrue(generatedCode.contains("class AppColorsDark {"))

        // Verify unified mode elements are NOT present
        XCTAssertFalse(generatedCode.contains("final Color light;"))
        XCTAssertFalse(generatedCode.contains("lightHighContrast"))
        XCTAssertFalse(generatedCode.contains("darkHighContrast"))
    }

    func testExportWithPartialHighContrast_LightHCOnly() throws {
        let colorPairPartialHC = AssetPair<Color>(
            light: Color(name: "accent", red: 1, green: 0, blue: 0, alpha: 1),
            dark: Color(name: "accent", red: 0.8, green: 0, blue: 0, alpha: 1),
            lightHC: Color(name: "accent", red: 1, green: 0, blue: 0, alpha: 1),
            darkHC: nil // Should fallback to dark color
        )

        let exporter = FlutterColorExporter(output: output, outputFileName: nil)
        let result = try exporter.export(colorPairs: [colorPairPartialHC])

        let fileContent = try XCTUnwrap(result[0].data)
        let generatedCode = try XCTUnwrap(String(data: fileContent, encoding: .utf8))

        // Should use unified mode since lightHC is present
        XCTAssertTrue(generatedCode.contains("final Color lightHighContrast;"))
        XCTAssertTrue(generatedCode.contains("final Color darkHighContrast;"))

        // Verify dark and darkHC have same value (fallback)
        XCTAssertTrue(generatedCode.contains("dark: Color(0xFFCC0000),"))
        XCTAssertTrue(generatedCode.contains("darkHighContrast: Color(0xFFCC0000),"))
    }

    func testExportWithPartialHighContrast_DarkHCOnly() throws {
        let colorPairPartialHC = AssetPair<Color>(
            light: Color(name: "primary", red: 0, green: 0.5, blue: 1, alpha: 1),
            dark: Color(name: "primary", red: 0, green: 0.3, blue: 0.8, alpha: 1),
            lightHC: nil, // Should fallback to light color
            darkHC: Color(name: "primary", red: 0, green: 0, blue: 0, alpha: 1)
        )

        let exporter = FlutterColorExporter(output: output, outputFileName: nil)
        let result = try exporter.export(colorPairs: [colorPairPartialHC])

        let fileContent = try XCTUnwrap(result[0].data)
        let generatedCode = try XCTUnwrap(String(data: fileContent, encoding: .utf8))

        // Should use unified mode since darkHC is present
        XCTAssertTrue(generatedCode.contains("final Color lightHighContrast;"))

        // Verify light and lightHC have same value (fallback)
        XCTAssertTrue(generatedCode.contains("light: Color(0xFF0080FF),"))
        XCTAssertTrue(generatedCode.contains("lightHighContrast: Color(0xFF0080FF),"))
    }

    func testExportMixedColors_SomeWithHC_SomeWithout() throws {
        let colorWithHC = AssetPair<Color>(
            light: Color(name: "background", red: 1, green: 1, blue: 1, alpha: 1),
            dark: Color(name: "background", red: 0.1, green: 0.1, blue: 0.1, alpha: 1),
            lightHC: Color(name: "background", red: 1, green: 1, blue: 1, alpha: 1),
            darkHC: Color(name: "background", red: 0, green: 0, blue: 0, alpha: 1)
        )

        let colorWithoutHC = AssetPair<Color>(
            light: Color(name: "accent", red: 1, green: 0, blue: 0, alpha: 1),
            dark: Color(name: "accent", red: 0.8, green: 0, blue: 0, alpha: 1),
            lightHC: nil,
            darkHC: nil
        )

        let exporter = FlutterColorExporter(output: output, outputFileName: nil)
        let result = try exporter.export(colorPairs: [colorWithHC, colorWithoutHC])

        let fileContent = try XCTUnwrap(result[0].data)
        let generatedCode = try XCTUnwrap(String(data: fileContent, encoding: .utf8))

        // Should use unified mode since at least one color has HC
        XCTAssertTrue(generatedCode.contains("final Color lightHighContrast;"))
        XCTAssertTrue(generatedCode.contains("final Color darkHighContrast;"))

        // Verify both colors are exported
        XCTAssertTrue(generatedCode.contains("static const background = AppColors("))
        XCTAssertTrue(generatedCode.contains("static const accent = AppColors("))

        // Verify accent uses fallback for HC values
        // accent light = 0xFFFF0000, should appear twice (light and lightHC)
        let accentLightPattern = "light: Color(0xFFFF0000),"
        let accentLightHCPattern = "lightHighContrast: Color(0xFFFF0000),"
        XCTAssertTrue(generatedCode.contains(accentLightPattern))
        XCTAssertTrue(generatedCode.contains(accentLightHCPattern))
    }
}
