// swiftlint:disable force_unwrapping
import CustomDump
import ExFigCore
import WebExport
import XCTest

final class WebColorExporterTests: XCTestCase {
    // MARK: - Properties

    private let output = WebOutput(
        outputDirectory: URL(string: "~/src/tokens/")!,
        templatesPath: nil
    )

    private let colorPair1 = AssetPair<Color>(
        light: Color(name: "background/primary", red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
        dark: nil
    )

    private let colorPair2 = AssetPair<Color>(
        light: Color(name: "text/default", red: 0, green: 0, blue: 0, alpha: 1),
        dark: Color(name: "text/default", red: 1, green: 1, blue: 1, alpha: 1)
    )

    // MARK: - CSS Tests

    func testExportCSS() throws {
        let exporter = WebColorExporter(output: output, cssFileName: nil, tsFileName: nil, jsonFileName: nil)

        let result = try exporter.export(colorPairs: [colorPair1, colorPair2])
        XCTAssertGreaterThanOrEqual(result.count, 1)

        let cssFile = result.first { $0.destination.file.absoluteString == "theme.css" }
        XCTAssertNotNil(cssFile)

        let fileContent = try XCTUnwrap(cssFile?.data)
        let generatedCode = String(data: fileContent, encoding: .utf8)

        let referenceCode = """
        /* \(header) */

        .theme-light {
          --background-primary: #FFFFFF;
          --text-default: #000000;
        }

        .theme-dark {
          --text-default: #FFFFFF;
        }

        """

        let expected = referenceCode.trimmingCharacters(in: .newlines)
        expectNoDifference(generatedCode?.trimmingCharacters(in: .newlines), expected)
    }

    func testExportCSSLightOnly() throws {
        let exporter = WebColorExporter(output: output, cssFileName: nil, tsFileName: nil, jsonFileName: nil)

        let result = try exporter.export(colorPairs: [colorPair1])

        let cssFile = result.first { $0.destination.file.absoluteString == "theme.css" }
        let fileContent = try XCTUnwrap(cssFile?.data)
        let generatedCode = String(data: fileContent, encoding: .utf8)

        let referenceCode = """
        /* \(header) */

        .theme-light {
          --background-primary: #FFFFFF;
        }

        """

        let expected = referenceCode.trimmingCharacters(in: .newlines)
        expectNoDifference(generatedCode?.trimmingCharacters(in: .newlines), expected)
    }

    // MARK: - TypeScript Tests

    func testExportTypeScript() throws {
        let exporter = WebColorExporter(output: output, cssFileName: nil, tsFileName: nil, jsonFileName: nil)

        let result = try exporter.export(colorPairs: [colorPair1, colorPair2])

        let tsFile = result.first { $0.destination.file.absoluteString == "variables.ts" }
        XCTAssertNotNil(tsFile)

        let fileContent = try XCTUnwrap(tsFile?.data)
        let generatedCode = String(data: fileContent, encoding: .utf8)

        let referenceCode = """
        // \(header)

        export const variables = {
          backgroundPrimary: 'var(--background-primary)',
          textDefault: 'var(--text-default)',
        } as const;

        export type ColorVariable = keyof typeof variables;

        """

        expectNoDifference(generatedCode, referenceCode)
    }

    // MARK: - JSON Tests

    func testExportJSON() throws {
        let exporter = WebColorExporter(output: output, cssFileName: nil, tsFileName: nil, jsonFileName: "tokens.json")

        let result = try exporter.export(colorPairs: [colorPair1, colorPair2])

        let jsonFile = result.first { $0.destination.file.absoluteString == "tokens.json" }
        XCTAssertNotNil(jsonFile)

        let fileContent = try XCTUnwrap(jsonFile?.data)
        let generatedCode = try XCTUnwrap(String(data: fileContent, encoding: .utf8))

        // Verify generated output is valid JSON (catches loop.last comma issues)
        let jsonObject = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(generatedCode.utf8)) as? [String: Any]
        )

        // Verify light colors structure
        let light = try XCTUnwrap(jsonObject["light"] as? [String: String])
        XCTAssertEqual(light["background-primary"], "#FFFFFF")
        XCTAssertEqual(light["text-default"], "#000000")

        // Verify dark colors structure
        let dark = try XCTUnwrap(jsonObject["dark"] as? [String: String])
        XCTAssertEqual(dark["text-default"], "#FFFFFF")
    }

    func testExportJSONLightOnly() throws {
        let exporter = WebColorExporter(output: output, cssFileName: nil, tsFileName: nil, jsonFileName: "tokens.json")

        let result = try exporter.export(colorPairs: [colorPair1])

        let jsonFile = result.first { $0.destination.file.absoluteString == "tokens.json" }
        let fileContent = try XCTUnwrap(jsonFile?.data)
        let generatedCode = try XCTUnwrap(String(data: fileContent, encoding: .utf8))

        // Verify valid JSON without dark section
        let jsonObject = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(generatedCode.utf8)) as? [String: Any]
        )

        let light = try XCTUnwrap(jsonObject["light"] as? [String: String])
        XCTAssertEqual(light["background-primary"], "#FFFFFF")
        XCTAssertNil(jsonObject["dark"])
    }

    // MARK: - Custom File Names Tests

    func testExportCustomCSSFileName() throws {
        let exporter = WebColorExporter(
            output: output,
            cssFileName: "colors.css",
            tsFileName: nil,
            jsonFileName: nil
        )

        let result = try exporter.export(colorPairs: [colorPair1])

        let cssFile = result.first { $0.destination.file.absoluteString == "colors.css" }
        XCTAssertNotNil(cssFile)
    }

    func testExportCustomTSFileName() throws {
        let exporter = WebColorExporter(
            output: output,
            cssFileName: nil,
            tsFileName: "colors.ts",
            jsonFileName: nil
        )

        let result = try exporter.export(colorPairs: [colorPair1])

        let tsFile = result.first { $0.destination.file.absoluteString == "colors.ts" }
        XCTAssertNotNil(tsFile)
    }

    // MARK: - Color with Alpha Tests

    func testExportColorWithAlpha() throws {
        let colorWithAlpha = AssetPair<Color>(
            light: Color(name: "overlay", red: 0, green: 0, blue: 0, alpha: 0.5),
            dark: nil
        )

        let exporter = WebColorExporter(output: output, cssFileName: nil, tsFileName: nil, jsonFileName: nil)
        let result = try exporter.export(colorPairs: [colorWithAlpha])

        let cssFile = result.first { $0.destination.file.absoluteString == "theme.css" }
        let fileContent = try XCTUnwrap(cssFile?.data)
        let generatedCode = try XCTUnwrap(String(data: fileContent, encoding: .utf8))

        // Should use rgba format for colors with alpha
        XCTAssertTrue(generatedCode.contains("rgba(0, 0, 0, 0.5)"))
    }
}
