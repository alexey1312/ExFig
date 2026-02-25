@testable import ExFigCLI
import XCTest

final class TokensInfoTests: XCTestCase {
    // MARK: - TokensFileSource Filtering & Statistics

    func testTokenCountsByType() throws {
        let json = """
        {
            "Brand": {
                "$type": "color",
                "Primary": {
                    "$value": { "colorSpace": "srgb", "components": [1, 0, 0] }
                },
                "Secondary": {
                    "$value": { "colorSpace": "srgb", "components": [0, 1, 0] }
                }
            },
            "Spacing": {
                "$type": "dimension",
                "Small": {
                    "$value": { "value": 4, "unit": "px" }
                }
            },
            "Opacity": {
                "$type": "number",
                "$value": 0.5
            }
        }
        """.utf8

        var source = try TokensFileSource.parse(data: Data(json))
        try source.resolveAliases()

        let counts = source.tokenCountsByType()
        XCTAssertEqual(counts.count, 3)

        let colorCount = counts.first(where: { $0.type == "color" })?.count
        XCTAssertEqual(colorCount, 2)

        let dimensionCount = counts.first(where: { $0.type == "dimension" })?.count
        XCTAssertEqual(dimensionCount, 1)

        let numberCount = counts.first(where: { $0.type == "number" })?.count
        XCTAssertEqual(numberCount, 1)
    }

    func testTopLevelGroups() throws {
        let json = """
        {
            "Brand": {
                "$type": "color",
                "Primary": {
                    "$value": { "colorSpace": "srgb", "components": [1, 0, 0] }
                },
                "Secondary": {
                    "$value": { "colorSpace": "srgb", "components": [0, 1, 0] }
                }
            },
            "Spacing": {
                "$type": "dimension",
                "Small": {
                    "$value": { "value": 4, "unit": "px" }
                },
                "Medium": {
                    "$value": { "value": 8, "unit": "px" }
                },
                "Large": {
                    "$value": { "value": 16, "unit": "px" }
                }
            }
        }
        """.utf8

        let source = try TokensFileSource.parse(data: Data(json))
        let groups = source.topLevelGroups()

        XCTAssertEqual(groups.count, 2)
        // Sorted by count descending
        XCTAssertEqual(groups[0].name, "Spacing")
        XCTAssertEqual(groups[0].count, 3)
        XCTAssertEqual(groups[1].name, "Brand")
        XCTAssertEqual(groups[1].count, 2)
    }

    func testFilteredByGroup() throws {
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

        let source = try TokensFileSource.parse(data: Data(json))
        let filtered = source.filteredByGroup("Brand")

        XCTAssertEqual(filtered.tokens.count, 1)
        XCTAssertNotNil(filtered.tokens["Brand.Primary"])
        XCTAssertNil(filtered.tokens["System.Error"])
    }

    func testFilteredByTypes() throws {
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

        let source = try TokensFileSource.parse(data: Data(json))

        let colorOnly = source.filteredByTypes(["color"])
        XCTAssertEqual(colorOnly.tokens.count, 1)
        XCTAssertNotNil(colorOnly.tokens["Primary"])

        let multiType = source.filteredByTypes(["color", "dimension"])
        XCTAssertEqual(multiType.tokens.count, 2)
    }

    func testResolvedAliasCount() throws {
        let json = """
        {
            "Primitives": {
                "Blue": {
                    "$type": "color",
                    "$value": { "colorSpace": "srgb", "components": [0, 0, 1] }
                }
            },
            "Semantic": {
                "Primary": {
                    "$type": "color",
                    "$value": "{Primitives.Blue}"
                },
                "Secondary": {
                    "$type": "color",
                    "$value": "{Primitives.Blue}"
                }
            }
        }
        """.utf8

        var source = try TokensFileSource.parse(data: Data(json))
        XCTAssertEqual(source.aliasCount, 0) // not resolved yet
        try source.resolveAliases()
        XCTAssertEqual(source.aliasCount, 2)
    }

    func testEmptyFile() throws {
        let json = "{}".utf8
        var source = try TokensFileSource.parse(data: Data(json))
        try source.resolveAliases()

        XCTAssertEqual(source.tokens.count, 0)
        XCTAssertEqual(source.tokenCountsByType().count, 0)
        XCTAssertEqual(source.topLevelGroups().count, 0)
    }

    func testFileNotFound() {
        XCTAssertThrowsError(try TokensFileSource.parse(fileAt: "/nonexistent/tokens.json")) { error in
            guard case TokensFileError.fileNotFound = error else {
                XCTFail("Expected fileNotFound error, got \(error)")
                return
            }
        }
    }
}
