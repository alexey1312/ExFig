// swiftlint:disable file_length type_body_length

import CustomDump
@testable import ExFig
import ExFigCore
import FigmaAPI
import XCTest

final class W3CTokensExporterTests: XCTestCase {
    // MARK: - Color Hex Conversion

    func testColorToHexRGB() {
        // Given: A fully opaque red color
        let exporter = W3CTokensExporter()

        // When: Converting to hex
        let hex = exporter.colorToHex(r: 1.0, g: 0.0, b: 0.0, a: 1.0)

        // Then: Should output #RRGGBB format
        XCTAssertEqual(hex, "#ff0000")
    }

    func testColorToHexRGBA() {
        // Given: A semi-transparent green color
        let exporter = W3CTokensExporter()

        // When: Converting to hex
        let hex = exporter.colorToHex(r: 0.0, g: 1.0, b: 0.0, a: 0.5)

        // Then: Should output #RRGGBBAA format
        XCTAssertEqual(hex, "#00ff0080")
    }

    func testColorToHexRoundsCorrectly() {
        // Given: A color with fractional components
        let exporter = W3CTokensExporter()

        // When: Converting 127.5/255 (which should round to 128)
        let hex = exporter.colorToHex(r: 0.5, g: 0.5, b: 0.5, a: 1.0)

        // Then: Should round correctly
        XCTAssertEqual(hex, "#808080")
    }

    func testColorToHexWhite() {
        let exporter = W3CTokensExporter()
        let hex = exporter.colorToHex(r: 1.0, g: 1.0, b: 1.0, a: 1.0)
        XCTAssertEqual(hex, "#ffffff")
    }

    func testColorToHexBlack() {
        let exporter = W3CTokensExporter()
        let hex = exporter.colorToHex(r: 0.0, g: 0.0, b: 0.0, a: 1.0)
        XCTAssertEqual(hex, "#000000")
    }

    // MARK: - Variable Name to Hierarchy

    func testNameToHierarchySimple() {
        let exporter = W3CTokensExporter()

        let path = exporter.nameToHierarchy("Background/Primary")

        XCTAssertEqual(path, ["Background", "Primary"])
    }

    func testNameToHierarchyNested() {
        let exporter = W3CTokensExporter()

        let path = exporter.nameToHierarchy("Statement/Background/PrimaryPressed")

        XCTAssertEqual(path, ["Statement", "Background", "PrimaryPressed"])
    }

    func testNameToHierarchySingleLevel() {
        let exporter = W3CTokensExporter()

        let path = exporter.nameToHierarchy("primary")

        XCTAssertEqual(path, ["primary"])
    }

    // MARK: - W3C Token Structure

    func testExportColorsToW3CFormat() {
        // Given: Colors with modes
        let exporter = W3CTokensExporter()
        let colorsByMode: [String: [ExFigCore.Color]] = [
            "Light": [
                Color(name: "Background/Primary", red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            ],
            "Dark": [
                Color(name: "Background/Primary", red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0),
            ],
        ]

        // When: Exporting to W3C format
        let tokens = exporter.exportColors(colorsByMode: colorsByMode)

        // Then: Should produce nested W3C structure
        guard let background = tokens["Background"] as? [String: Any],
              let primary = background["Primary"] as? [String: Any]
        else {
            XCTFail("Expected nested structure Background/Primary")
            return
        }

        XCTAssertEqual(primary["$type"] as? String, "color")
        guard let value = primary["$value"] as? [String: String] else {
            XCTFail("Expected $value to be a dictionary")
            return
        }
        XCTAssertEqual(value["Light"], "#ffffff")
        XCTAssertEqual(value["Dark"], "#1a1a1a")
    }

    func testExportColorsWithDescription() {
        let exporter = W3CTokensExporter()
        let colorsByMode: [String: [ExFigCore.Color]] = [
            "Light": [
                Color(name: "primary", red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),
            ],
        ]
        let descriptions = ["primary": "Primary brand color"]

        let tokens = exporter.exportColors(colorsByMode: colorsByMode, descriptions: descriptions)

        guard let primary = tokens["primary"] as? [String: Any] else {
            XCTFail("Expected primary token")
            return
        }
        XCTAssertEqual(primary["$description"] as? String, "Primary brand color")
    }

    func testExportColorsSingleMode() {
        // Given: Colors with only one mode
        let exporter = W3CTokensExporter()
        let colorsByMode: [String: [ExFigCore.Color]] = [
            "Light": [
                Color(name: "accent", red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0),
            ],
        ]

        // When: Exporting
        let tokens = exporter.exportColors(colorsByMode: colorsByMode)

        // Then: $value should be dict format (consistent with multi-mode)
        guard let accent = tokens["accent"] as? [String: Any] else {
            XCTFail("Expected accent token")
            return
        }
        XCTAssertEqual(accent["$type"] as? String, "color")

        // Always use dict format for consistency (mode name -> hex value)
        guard let valueDict = accent["$value"] as? [String: String] else {
            XCTFail("Expected $value to be a dictionary")
            return
        }
        XCTAssertEqual(valueDict["Light"], "#0080ff")
    }

    // MARK: - JSON Serialization

    func testSerializeToJSON() throws {
        let exporter = W3CTokensExporter()
        let colorsByMode: [String: [ExFigCore.Color]] = [
            "Light": [
                Color(name: "primary", red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),
            ],
        ]

        let tokens = exporter.exportColors(colorsByMode: colorsByMode)
        let jsonData = try exporter.serializeToJSON(tokens, compact: false)
        let jsonString = String(data: jsonData, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("\"$type\"") ?? false)
        XCTAssertTrue(jsonString?.contains("\"color\"") ?? false)
    }

    func testSerializeToJSONCompact() throws {
        let exporter = W3CTokensExporter()
        let colorsByMode: [String: [ExFigCore.Color]] = [
            "Light": [
                Color(name: "primary", red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),
            ],
        ]

        let tokens = exporter.exportColors(colorsByMode: colorsByMode)
        let jsonData = try exporter.serializeToJSON(tokens, compact: true)
        let jsonString = String(data: jsonData, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        // Compact JSON should not have newlines
        XCTAssertFalse(jsonString?.contains("\n") ?? true)
    }

    // MARK: - Complex Hierarchy

    func testExportDeepNesting() {
        let exporter = W3CTokensExporter()
        let colorsByMode: [String: [ExFigCore.Color]] = [
            "Light": [
                Color(name: "UI/Button/Primary/Background", red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0),
                Color(name: "UI/Button/Primary/Text", red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            ],
        ]

        let tokens = exporter.exportColors(colorsByMode: colorsByMode)

        guard let ui = tokens["UI"] as? [String: Any],
              let button = ui["Button"] as? [String: Any],
              let primary = button["Primary"] as? [String: Any],
              let background = primary["Background"] as? [String: Any]
        else {
            XCTFail("Expected deep nesting UI/Button/Primary/Background")
            return
        }

        XCTAssertEqual(background["$type"] as? String, "color")
    }

    // MARK: - Typography Export

    func testExportTypographyBasic() {
        let exporter = W3CTokensExporter()
        let textStyles = [
            TextStyle(
                name: "Heading/H1",
                fontName: "Inter-Bold",
                fontSize: 32,
                fontStyle: nil,
                lineHeight: 40,
                letterSpacing: -0.5,
                textCase: .original
            ),
        ]

        let tokens = exporter.exportTypography(textStyles: textStyles)

        guard let heading = tokens["Heading"] as? [String: Any],
              let h1 = heading["H1"] as? [String: Any]
        else {
            XCTFail("Expected nested structure Heading/H1")
            return
        }

        XCTAssertEqual(h1["$type"] as? String, "typography")
        guard let value = h1["$value"] as? [String: Any] else {
            XCTFail("Expected $value to be a dictionary")
            return
        }
        XCTAssertEqual(value["fontFamily"] as? String, "Inter-Bold")
        XCTAssertEqual(value["fontSize"] as? Double, 32)
        XCTAssertEqual(value["lineHeight"] as? Double, 40)
        XCTAssertEqual(value["letterSpacing"] as? Double, -0.5)
    }

    func testExportTypographyWithTextCase() {
        let exporter = W3CTokensExporter()
        let textStyles = [
            TextStyle(
                name: "Label/Uppercase",
                fontName: "Inter-Medium",
                fontSize: 12,
                fontStyle: nil,
                lineHeight: 16,
                letterSpacing: 1.0,
                textCase: .uppercased
            ),
        ]

        let tokens = exporter.exportTypography(textStyles: textStyles)

        guard let label = tokens["Label"] as? [String: Any],
              let uppercase = label["Uppercase"] as? [String: Any],
              let value = uppercase["$value"] as? [String: Any]
        else {
            XCTFail("Expected nested structure Label/Uppercase")
            return
        }

        XCTAssertEqual(value["textTransform"] as? String, "uppercase")
    }

    func testExportTypographyNoLineHeight() {
        let exporter = W3CTokensExporter()
        let textStyles = [
            TextStyle(
                name: "Body",
                fontName: "Inter-Regular",
                fontSize: 16,
                fontStyle: nil,
                lineHeight: nil,
                letterSpacing: 0,
                textCase: .original
            ),
        ]

        let tokens = exporter.exportTypography(textStyles: textStyles)

        guard let body = tokens["Body"] as? [String: Any],
              let value = body["$value"] as? [String: Any]
        else {
            XCTFail("Expected Body token")
            return
        }

        // lineHeight should be omitted when nil
        XCTAssertNil(value["lineHeight"])
    }

    func testExportTypographyMultipleStyles() {
        let exporter = W3CTokensExporter()
        let textStyles = [
            TextStyle(
                name: "Text/Title",
                fontName: "Inter-Bold",
                fontSize: 24,
                fontStyle: nil,
                lineHeight: 32,
                letterSpacing: 0,
                textCase: .original
            ),
            TextStyle(
                name: "Text/Body",
                fontName: "Inter-Regular",
                fontSize: 16,
                fontStyle: nil,
                lineHeight: 24,
                letterSpacing: 0,
                textCase: .original
            ),
        ]

        let tokens = exporter.exportTypography(textStyles: textStyles)

        guard let text = tokens["Text"] as? [String: Any] else {
            XCTFail("Expected Text group")
            return
        }

        XCTAssertNotNil(text["Title"])
        XCTAssertNotNil(text["Body"])
    }

    // MARK: - Asset Export

    func testExportAssetsBasic() {
        let exporter = W3CTokensExporter()
        let assets: [AssetToken] = [
            AssetToken(
                name: "Icons/Navigation/ArrowLeft",
                url: "https://figma-api.s3.amazonaws.com/images/arrow-left.svg",
                description: "Left arrow icon"
            ),
        ]

        let tokens = exporter.exportAssets(assets: assets)

        guard let icons = tokens["Icons"] as? [String: Any],
              let navigation = icons["Navigation"] as? [String: Any],
              let arrowLeft = navigation["ArrowLeft"] as? [String: Any]
        else {
            XCTFail("Expected nested structure Icons/Navigation/ArrowLeft")
            return
        }

        XCTAssertEqual(arrowLeft["$type"] as? String, "asset")
        XCTAssertEqual(
            arrowLeft["$value"] as? String,
            "https://figma-api.s3.amazonaws.com/images/arrow-left.svg"
        )
        XCTAssertEqual(arrowLeft["$description"] as? String, "Left arrow icon")
    }

    func testExportAssetsNoDescription() {
        let exporter = W3CTokensExporter()
        let assets: [AssetToken] = [
            AssetToken(name: "icon", url: "https://example.com/icon.png", description: nil),
        ]

        let tokens = exporter.exportAssets(assets: assets)

        guard let icon = tokens["icon"] as? [String: Any] else {
            XCTFail("Expected icon token")
            return
        }

        XCTAssertNil(icon["$description"])
    }

    func testExportAssetsMultiple() {
        let exporter = W3CTokensExporter()
        let assets: [AssetToken] = [
            AssetToken(name: "UI/Button/Plus", url: "https://example.com/plus.svg", description: nil),
            AssetToken(name: "UI/Button/Minus", url: "https://example.com/minus.svg", description: nil),
        ]

        let tokens = exporter.exportAssets(assets: assets)

        guard let ui = tokens["UI"] as? [String: Any],
              let button = ui["Button"] as? [String: Any]
        else {
            XCTFail("Expected UI/Button structure")
            return
        }

        XCTAssertNotNil(button["Plus"])
        XCTAssertNotNil(button["Minus"])
    }
}
