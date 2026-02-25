// swiftlint:disable file_length type_body_length

import CustomDump
@testable import ExFigCLI
import ExFigCore
import FigmaAPI
import XCTest

final class W3CTokensExporterTests: XCTestCase {
    // MARK: - Color Hex Conversion

    func testColorToHexRGB() {
        let exporter = W3CTokensExporter(version: .v2025)
        let hex = exporter.colorToHex(r: 1.0, g: 0.0, b: 0.0)
        XCTAssertEqual(hex, "#ff0000")
    }

    func testColorToHexWhite() {
        let exporter = W3CTokensExporter(version: .v2025)
        let hex = exporter.colorToHex(r: 1.0, g: 1.0, b: 1.0)
        XCTAssertEqual(hex, "#ffffff")
    }

    func testColorToHexBlack() {
        let exporter = W3CTokensExporter(version: .v2025)
        let hex = exporter.colorToHex(r: 0.0, g: 0.0, b: 0.0)
        XCTAssertEqual(hex, "#000000")
    }

    func testColorToHexRoundsCorrectly() {
        let exporter = W3CTokensExporter(version: .v2025)
        let hex = exporter.colorToHex(r: 0.5, g: 0.5, b: 0.5)
        XCTAssertEqual(hex, "#808080")
    }

    // MARK: - Legacy Color Hex (v1)

    func testColorToHexLegacyOpaque() {
        let exporter = W3CTokensExporter(version: .v1)
        let hex = exporter.colorToHexLegacy(r: 1.0, g: 0.0, b: 0.0, a: 1.0)
        XCTAssertEqual(hex, "#ff0000")
    }

    func testColorToHexLegacyWithAlpha() {
        let exporter = W3CTokensExporter(version: .v1)
        let hex = exporter.colorToHexLegacy(r: 0.0, g: 1.0, b: 0.0, a: 0.5)
        XCTAssertEqual(hex, "#00ff0080")
    }

    // MARK: - Color Object (v2025)

    func testColorToObjectOpaque() {
        let exporter = W3CTokensExporter(version: .v2025)
        let obj = exporter.colorToObject(r: 1.0, g: 1.0, b: 1.0, a: 1.0)

        XCTAssertEqual(obj["colorSpace"] as? String, "srgb")
        XCTAssertEqual(obj["components"] as? [Double], [1.0, 1.0, 1.0])
        XCTAssertEqual(obj["hex"] as? String, "#ffffff")
        XCTAssertNil(obj["alpha"], "Alpha should be omitted when 1.0")
    }

    func testColorToObjectWithAlpha() {
        let exporter = W3CTokensExporter(version: .v2025)
        let obj = exporter.colorToObject(r: 0.231, g: 0.541, b: 0.8, a: 0.502)

        XCTAssertEqual(obj["colorSpace"] as? String, "srgb")
        XCTAssertEqual(obj["components"] as? [Double], [0.231, 0.541, 0.8])
        XCTAssertEqual(obj["alpha"] as? Double, 0.502)
        XCTAssertEqual(obj["hex"] as? String, "#3b8acc")
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

    // MARK: - V2025 Color Export

    func testExportColorsSingleModeV2025() {
        let exporter = W3CTokensExporter(version: .v2025)
        let colorsByMode: [String: [ExFigCore.Color]] = [
            "Light": [
                Color(name: "Background/Primary", red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            ],
        ]

        let tokens = exporter.exportColors(colorsByMode: colorsByMode)

        guard let background = tokens["Background"] as? [String: Any],
              let primary = background["Primary"] as? [String: Any]
        else {
            XCTFail("Expected nested structure Background/Primary")
            return
        }

        XCTAssertEqual(primary["$type"] as? String, "color")

        // $value should be a color object (not mode dict)
        guard let value = primary["$value"] as? [String: Any] else {
            XCTFail("Expected $value to be a color object")
            return
        }
        XCTAssertEqual(value["colorSpace"] as? String, "srgb")
        XCTAssertEqual(value["components"] as? [Double], [1.0, 1.0, 1.0])
        XCTAssertEqual(value["hex"] as? String, "#ffffff")

        // No modes extension for single mode
        XCTAssertNil(primary["$extensions"], "Single mode should not have $extensions.com.exfig.modes")
    }

    func testExportColorsMultiModeV2025() {
        let exporter = W3CTokensExporter(version: .v2025)
        let colorsByMode: [String: [ExFigCore.Color]] = [
            "Light": [
                Color(name: "Background/Primary", red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            ],
            "Dark": [
                Color(name: "Background/Primary", red: 0.102, green: 0.102, blue: 0.102, alpha: 1.0),
            ],
        ]

        let tokens = exporter.exportColors(colorsByMode: colorsByMode)

        guard let background = tokens["Background"] as? [String: Any],
              let primary = background["Primary"] as? [String: Any]
        else {
            XCTFail("Expected nested structure Background/Primary")
            return
        }

        // $value is the default (first) mode
        guard let value = primary["$value"] as? [String: Any] else {
            XCTFail("Expected $value to be a color object")
            return
        }
        XCTAssertEqual(value["colorSpace"] as? String, "srgb")
        XCTAssertNotNil(value["hex"])

        // $extensions.com.exfig.modes should exist
        guard let extensions = primary["$extensions"] as? [String: Any],
              let comExfig = extensions["com.exfig"] as? [String: Any],
              let modes = comExfig["modes"] as? [String: Any]
        else {
            XCTFail("Expected $extensions.com.exfig.modes")
            return
        }

        XCTAssertNotNil(modes["Light"])
        XCTAssertNotNil(modes["Dark"])

        // Each mode value should be a color object
        guard let darkMode = modes["Dark"] as? [String: Any] else {
            XCTFail("Expected Dark mode to be a color object")
            return
        }
        XCTAssertEqual(darkMode["colorSpace"] as? String, "srgb")
        XCTAssertEqual(darkMode["hex"] as? String, "#1a1a1a")
    }

    func testExportColorsWithAlphaV2025() {
        let exporter = W3CTokensExporter(version: .v2025)
        let colorsByMode: [String: [ExFigCore.Color]] = [
            "Light": [
                Color(name: "overlay", red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5),
            ],
        ]

        let tokens = exporter.exportColors(colorsByMode: colorsByMode)

        guard let overlay = tokens["overlay"] as? [String: Any],
              let value = overlay["$value"] as? [String: Any]
        else {
            XCTFail("Expected overlay token with color object $value")
            return
        }

        XCTAssertEqual(value["alpha"] as? Double, 0.5)
        // hex should be 6-digit (no alpha in hex per spec)
        XCTAssertEqual(value["hex"] as? String, "#000000")
    }

    func testExportColorsWithDescriptionV2025() {
        let exporter = W3CTokensExporter(version: .v2025)
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

    func testExportColorsEmptyDescriptionOmittedV2025() {
        let exporter = W3CTokensExporter(version: .v2025)
        let colorsByMode: [String: [ExFigCore.Color]] = [
            "Light": [
                Color(name: "primary", red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),
            ],
        ]
        let descriptions = ["primary": "  "]

        let tokens = exporter.exportColors(colorsByMode: colorsByMode, descriptions: descriptions)

        guard let primary = tokens["primary"] as? [String: Any] else {
            XCTFail("Expected primary token")
            return
        }
        XCTAssertNil(primary["$description"], "Whitespace-only description should be omitted")
    }

    func testExportColorsWithMetadataV2025() {
        let exporter = W3CTokensExporter(version: .v2025)
        let colorsByMode: [String: [ExFigCore.Color]] = [
            "Light": [
                Color(name: "primary", red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),
            ],
        ]
        let metadata = ["primary": ColorTokenMetadata(variableId: "VariableID:123:456", fileId: "abc123")]

        let tokens = exporter.exportColors(colorsByMode: colorsByMode, metadata: metadata)

        guard let primary = tokens["primary"] as? [String: Any],
              let extensions = primary["$extensions"] as? [String: Any],
              let comExfig = extensions["com.exfig"] as? [String: Any]
        else {
            XCTFail("Expected $extensions.com.exfig")
            return
        }

        XCTAssertEqual(comExfig["variableId"] as? String, "VariableID:123:456")
        XCTAssertEqual(comExfig["fileId"] as? String, "abc123")
    }

    func testExportColorsMetadataMergesWithModesV2025() {
        let exporter = W3CTokensExporter(version: .v2025)
        let colorsByMode: [String: [ExFigCore.Color]] = [
            "Light": [
                Color(name: "primary", red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            ],
            "Dark": [
                Color(name: "primary", red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0),
            ],
        ]
        let metadata = ["primary": ColorTokenMetadata(variableId: "VariableID:123:456", fileId: "abc123")]

        let tokens = exporter.exportColors(colorsByMode: colorsByMode, metadata: metadata)

        guard let primary = tokens["primary"] as? [String: Any],
              let extensions = primary["$extensions"] as? [String: Any],
              let comExfig = extensions["com.exfig"] as? [String: Any]
        else {
            XCTFail("Expected $extensions.com.exfig")
            return
        }

        XCTAssertNotNil(comExfig["modes"], "Modes should be present")
        XCTAssertNotNil(comExfig["variableId"], "Metadata should merge with modes")
        XCTAssertNotNil(comExfig["fileId"], "FileId should merge with modes")
    }

    // MARK: - V1 Color Export (Legacy)

    func testExportColorsV1Format() {
        let exporter = W3CTokensExporter(version: .v1)
        let colorsByMode: [String: [ExFigCore.Color]] = [
            "Light": [
                Color(name: "Background/Primary", red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            ],
            "Dark": [
                Color(name: "Background/Primary", red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0),
            ],
        ]

        let tokens = exporter.exportColors(colorsByMode: colorsByMode)

        guard let background = tokens["Background"] as? [String: Any],
              let primary = background["Primary"] as? [String: Any]
        else {
            XCTFail("Expected nested structure Background/Primary")
            return
        }

        XCTAssertEqual(primary["$type"] as? String, "color")
        guard let value = primary["$value"] as? [String: String] else {
            XCTFail("Expected $value to be mode→hex dictionary")
            return
        }
        XCTAssertEqual(value["Light"], "#ffffff")
        XCTAssertEqual(value["Dark"], "#1a1a1a")
        XCTAssertNil(primary["$extensions"], "V1 should not have $extensions")
    }

    // MARK: - JSON Serialization

    func testSerializeToJSON() throws {
        let exporter = W3CTokensExporter(version: .v2025)
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
        XCTAssertTrue(jsonString?.contains("\"colorSpace\"") ?? false)
    }

    func testSerializeToJSONCompact() throws {
        let exporter = W3CTokensExporter(version: .v2025)
        let colorsByMode: [String: [ExFigCore.Color]] = [
            "Light": [
                Color(name: "primary", red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),
            ],
        ]

        let tokens = exporter.exportColors(colorsByMode: colorsByMode)
        let jsonData = try exporter.serializeToJSON(tokens, compact: true)
        let jsonString = String(data: jsonData, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertFalse(jsonString?.contains("\n") ?? true)
    }

    // MARK: - Complex Hierarchy

    func testExportDeepNesting() {
        let exporter = W3CTokensExporter(version: .v2025)
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

    // MARK: - Typography V2025

    func testExportTypographyV2025() {
        let exporter = W3CTokensExporter(version: .v2025)
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

        // Composite value
        guard let value = h1["$value"] as? [String: Any] else {
            XCTFail("Expected $value to be a dictionary")
            return
        }
        XCTAssertEqual(value["fontFamily"] as? [String], ["Inter-Bold"])

        // fontSize should be dimension object
        guard let fontSize = value["fontSize"] as? [String: Any] else {
            XCTFail("Expected fontSize to be dimension object")
            return
        }
        XCTAssertEqual(fontSize["value"] as? Double, 32)
        XCTAssertEqual(fontSize["unit"] as? String, "px")

        // lineHeight should be ratio (40/32 = 1.25)
        XCTAssertEqual(value["lineHeight"] as? Double, 1.25)

        // Sub-tokens
        guard let fontFamilySub = h1["fontFamily"] as? [String: Any] else {
            XCTFail("Expected fontFamily sub-token")
            return
        }
        XCTAssertEqual(fontFamilySub["$type"] as? String, "fontFamily")
        XCTAssertEqual(fontFamilySub["$value"] as? [String], ["Inter-Bold"])

        guard let fontSizeSub = h1["fontSize"] as? [String: Any] else {
            XCTFail("Expected fontSize sub-token")
            return
        }
        XCTAssertEqual(fontSizeSub["$type"] as? String, "dimension")

        guard let lineHeightSub = h1["lineHeight"] as? [String: Any] else {
            XCTFail("Expected lineHeight sub-token")
            return
        }
        XCTAssertEqual(lineHeightSub["$type"] as? String, "number")
        XCTAssertEqual(lineHeightSub["$value"] as? Double, 1.25)

        guard let letterSpacingSub = h1["letterSpacing"] as? [String: Any] else {
            XCTFail("Expected letterSpacing sub-token")
            return
        }
        XCTAssertEqual(letterSpacingSub["$type"] as? String, "dimension")
    }

    func testExportTypographyNoLineHeightV2025() {
        let exporter = W3CTokensExporter(version: .v2025)
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

        XCTAssertNil(value["lineHeight"], "lineHeight should be omitted when nil")
        XCTAssertNil(body["lineHeight"], "lineHeight sub-token should not exist when nil")
        XCTAssertNil(body["letterSpacing"], "letterSpacing sub-token should not exist when 0")
    }

    // MARK: - Typography V1 (Legacy)

    func testExportTypographyV1() {
        let exporter = W3CTokensExporter(version: .v1)
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

        guard let value = h1["$value"] as? [String: Any] else {
            XCTFail("Expected $value to be a dictionary")
            return
        }

        // V1: fontFamily is a plain string, fontSize is a number
        XCTAssertEqual(value["fontFamily"] as? String, "Inter-Bold")
        XCTAssertEqual(value["fontSize"] as? Double, 32)
        XCTAssertEqual(value["lineHeight"] as? Double, 40)
        XCTAssertEqual(value["letterSpacing"] as? Double, -0.5)

        // No sub-tokens in v1
        XCTAssertNil(h1["fontFamily"], "V1 should not have sub-tokens")
        XCTAssertNil(h1["fontSize"], "V1 should not have sub-tokens")
    }

    // MARK: - Asset Export V2025

    func testExportAssetsV2025() {
        let exporter = W3CTokensExporter(version: .v2025)
        let assets: [AssetToken] = [
            AssetToken(
                name: "Icons/Navigation/ArrowLeft",
                url: "https://figma-api.s3.amazonaws.com/images/arrow-left.svg",
                description: "Left arrow icon",
                nodeId: "1:23",
                fileId: "def456"
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

        // No $type for assets in v2025
        XCTAssertNil(arrowLeft["$type"], "V2025 should not have $type: asset")

        XCTAssertEqual(arrowLeft["$description"] as? String, "Left arrow icon")

        // Asset URL in $extensions.com.exfig.assetUrl
        guard let extensions = arrowLeft["$extensions"] as? [String: Any],
              let comExfig = extensions["com.exfig"] as? [String: Any]
        else {
            XCTFail("Expected $extensions.com.exfig")
            return
        }

        XCTAssertEqual(
            comExfig["assetUrl"] as? String,
            "https://figma-api.s3.amazonaws.com/images/arrow-left.svg"
        )
        XCTAssertEqual(comExfig["nodeId"] as? String, "1:23")
        XCTAssertEqual(comExfig["fileId"] as? String, "def456")
    }

    func testExportAssetsNoDescriptionV2025() {
        let exporter = W3CTokensExporter(version: .v2025)
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

    // MARK: - Asset Export V1 (Legacy)

    func testExportAssetsV1() {
        let exporter = W3CTokensExporter(version: .v1)
        let assets: [AssetToken] = [
            AssetToken(
                name: "Icons/Search",
                url: "https://figma.com/images/search.svg",
                description: nil
            ),
        ]

        let tokens = exporter.exportAssets(assets: assets)

        guard let icons = tokens["Icons"] as? [String: Any],
              let search = icons["Search"] as? [String: Any]
        else {
            XCTFail("Expected Icons/Search")
            return
        }

        XCTAssertEqual(search["$type"] as? String, "asset")
        XCTAssertEqual(search["$value"] as? String, "https://figma.com/images/search.svg")
    }

    func testExportAssetsMultiple() {
        let exporter = W3CTokensExporter(version: .v2025)
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
