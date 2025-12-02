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

        let referenceCode = """
        // \(header)

        import 'package:flutter/material.dart';

        class AppColors {
          AppColors._();
          static const Color colorPair1 = Color(0x807703FF);
          static const Color colorPair2 = Color(0xFFFFFFFF);
        }
        class AppColorsDark {
          AppColorsDark._();
          static const Color colorPair2 = Color(0xFF000000);
        }

        """ + "\n"

        expectNoDifference(generatedCode, referenceCode)
    }

    func testExportLightOnly() throws {
        let exporter = FlutterColorExporter(output: output, outputFileName: nil)

        let result = try exporter.export(colorPairs: [colorPair1])
        XCTAssertEqual(result.count, 1)

        let fileContent = try XCTUnwrap(result[0].data)
        let generatedCode = String(data: fileContent, encoding: .utf8)

        let referenceCode = """
        // \(header)

        import 'package:flutter/material.dart';

        class AppColors {
          AppColors._();
          static const Color colorPair1 = Color(0x807703FF);
        }

        """ + "\n"

        expectNoDifference(generatedCode, referenceCode)
    }

    func testExportCustomFileName() throws {
        let exporter = FlutterColorExporter(output: output, outputFileName: "app_colors.dart")

        let result = try exporter.export(colorPairs: [colorPair1])
        XCTAssertEqual(result.count, 1)

        XCTAssertEqual(result[0].destination.file.absoluteString, "app_colors.dart")
    }

    func testExportCustomClassName() throws {
        let customOutput = FlutterOutput(
            outputDirectory: URL(string: "~/lib/generated/")!,
            templatesPath: nil,
            colorsClassName: "MyColors"
        )
        let exporter = FlutterColorExporter(output: customOutput, outputFileName: nil)

        let result = try exporter.export(colorPairs: [colorPair1])
        let fileContent = try XCTUnwrap(result[0].data)
        let generatedCode = String(data: fileContent, encoding: .utf8)

        XCTAssertTrue(generatedCode?.contains("class MyColors") == true)
    }
}
