@testable import ExFigCLI
import ExFigCore
import Foundation
import XCTest

final class TokensConvertTests: XCTestCase {
    // MARK: - Full Re-Export

    func testFullReExportProducesValidW3CJSON() throws {
        let json = """
        {
            "Brand": {
                "$type": "color",
                "Primary": {
                    "$value": { "colorSpace": "srgb", "components": [0.2, 0.4, 0.8], "alpha": 1.0 }
                }
            },
            "Spacing": {
                "$type": "dimension",
                "Small": { "$value": { "value": 4, "unit": "px" } }
            },
            "Opacity": { "$type": "number", "$value": 0.5 },
            "Heading": {
                "$type": "typography",
                "$value": { "fontFamily": ["Inter"], "fontSize": { "value": 32, "unit": "px" } }
            }
        }
        """.utf8

        var source = try TokensFileSource.parse(data: Data(json))
        try source.resolveAliases()

        let allTokens = W3CTokensExporter(version: .v2025).exportAll(from: source)
        let exporter = W3CTokensExporter(version: .v2025)
        let jsonData = try exporter.serializeToJSON(allTokens, compact: false)
        let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]

        XCTAssertNotNil(parsed)
        XCTAssertNotNil(parsed?["Brand"])
        XCTAssertNotNil(parsed?["Spacing"])
        XCTAssertNotNil(parsed?["Opacity"])
        XCTAssertNotNil(parsed?["Heading"])
    }

    // MARK: - Group Filter

    func testGroupFilterOnlyIncludesMatchingTokens() throws {
        let json = """
        {
            "Brand": {
                "$type": "color",
                "Primary": {
                    "$value": { "colorSpace": "srgb", "components": [1, 0, 0] }
                }
            },
            "System": {
                "$type": "color",
                "Error": {
                    "$value": { "colorSpace": "srgb", "components": [0.8, 0, 0] }
                }
            }
        }
        """.utf8

        var source = try TokensFileSource.parse(data: Data(json))
        try source.resolveAliases()

        let filtered = source.filteredByGroup("Brand")
        let colors = filtered.toColors()

        XCTAssertEqual(colors.count, 1)
        XCTAssertEqual(colors[0].name, "Brand/Primary")
    }

    // MARK: - Type Filter

    func testTypeFilterColorOnly() throws {
        let json = """
        {
            "Primary": {
                "$type": "color",
                "$value": { "colorSpace": "srgb", "components": [1, 0, 0] }
            },
            "Small": {
                "$type": "dimension",
                "$value": { "value": 4, "unit": "px" }
            }
        }
        """.utf8

        var source = try TokensFileSource.parse(data: Data(json))
        try source.resolveAliases()

        let colorOnly = source.filteredByTypes(["color"])
        XCTAssertEqual(colorOnly.tokens.count, 1)
        XCTAssertEqual(colorOnly.toColors().count, 1)
        XCTAssertEqual(colorOnly.toDimensionTokens().count, 0)
    }

    func testTypeFilterMultipleTypes() throws {
        let json = """
        {
            "Primary": {
                "$type": "color",
                "$value": { "colorSpace": "srgb", "components": [1, 0, 0] }
            },
            "Small": {
                "$type": "dimension",
                "$value": { "value": 4, "unit": "px" }
            },
            "Weight": {
                "$type": "number",
                "$value": 700
            }
        }
        """.utf8

        var source = try TokensFileSource.parse(data: Data(json))
        try source.resolveAliases()

        let filtered = source.filteredByTypes(["color", "dimension"])
        XCTAssertEqual(filtered.tokens.count, 2)
        XCTAssertNotNil(filtered.tokens["Primary"])
        XCTAssertNotNil(filtered.tokens["Small"])
        XCTAssertNil(filtered.tokens["Weight"])
    }

    // MARK: - Combined Filters

    func testGroupAndTypeFilterCombined() throws {
        let json = """
        {
            "Brand": {
                "Primary": {
                    "$type": "color",
                    "$value": { "colorSpace": "srgb", "components": [1, 0, 0] }
                },
                "Radius": {
                    "$type": "dimension",
                    "$value": { "value": 8, "unit": "px" }
                }
            },
            "System": {
                "Error": {
                    "$type": "color",
                    "$value": { "colorSpace": "srgb", "components": [0.8, 0, 0] }
                }
            }
        }
        """.utf8

        var source = try TokensFileSource.parse(data: Data(json))
        try source.resolveAliases()

        // Group filter first, then type filter — should only get Brand colors
        let filtered = source.filteredByGroup("Brand").filteredByTypes(["color"])
        XCTAssertEqual(filtered.tokens.count, 1)
        XCTAssertNotNil(filtered.tokens["Brand.Primary"])
        XCTAssertNil(filtered.tokens["Brand.Radius"])
        XCTAssertNil(filtered.tokens["System.Error"])
    }

    // MARK: - W3C Version

    func testV1ExportUsesHexStrings() throws {
        let json = """
        {
            "Primary": {
                "$type": "color",
                "$value": { "colorSpace": "srgb", "components": [1, 0, 0] }
            }
        }
        """.utf8

        var source = try TokensFileSource.parse(data: Data(json))
        try source.resolveAliases()

        let exporter = W3CTokensExporter(version: .v1)
        let colors = source.toColors()
        let tokens = exporter.exportColors(colorsByMode: ["Default": colors])
        let jsonData = try exporter.serializeToJSON(tokens, compact: false)
        let jsonString = String(data: jsonData, encoding: .utf8)

        // v1 uses hex strings, not color objects
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("#ff0000") == true)
    }

    // MARK: - Compact Output

    func testCompactOutputIsMinified() throws {
        let json = """
        {
            "Primary": {
                "$type": "color",
                "$value": { "colorSpace": "srgb", "components": [1, 0, 0] }
            }
        }
        """.utf8

        var source = try TokensFileSource.parse(data: Data(json))
        try source.resolveAliases()

        let exporter = W3CTokensExporter(version: .v2025)
        let colors = source.toColors()
        let tokens = exporter.exportColors(colorsByMode: ["Default": colors])

        let compactData = try exporter.serializeToJSON(tokens, compact: true)
        let prettyData = try exporter.serializeToJSON(tokens, compact: false)

        // Compact should be shorter (no indentation or newlines)
        XCTAssertLessThan(compactData.count, prettyData.count)
    }

    // MARK: - Merge Tokens

    func testMergeTokensDeepMerge() {
        var target: [String: Any] = [
            "Brand": [
                "Primary": ["$type": "color", "$value": "red"],
            ] as [String: Any],
        ]

        let source: [String: Any] = [
            "Brand": [
                "Secondary": ["$type": "color", "$value": "blue"],
            ] as [String: Any],
        ]

        W3CTokensExporter.mergeTokens(from: source, into: &target)

        let brand = target["Brand"] as? [String: Any]
        XCTAssertNotNil(brand?["Primary"])
        XCTAssertNotNil(brand?["Secondary"])
    }
}
