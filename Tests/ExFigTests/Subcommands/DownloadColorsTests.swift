import CustomDump
@testable import ExFig
import ExFigCore
import FigmaAPI
import XCTest

final class DownloadColorsTests: XCTestCase {
    var mockClient: MockClient!

    override func setUp() {
        super.setUp()
        mockClient = MockClient()
    }

    override func tearDown() {
        mockClient = nil
        super.tearDown()
    }

    // MARK: - JSONExportFormat

    func testJSONExportFormatParsing() {
        XCTAssertEqual(JSONExportFormat(rawValue: "w3c"), .w3c)
        XCTAssertEqual(JSONExportFormat(rawValue: "raw"), .raw)
        XCTAssertNil(JSONExportFormat(rawValue: "invalid"))
    }

    func testJSONExportFormatAllCases() {
        XCTAssertEqual(JSONExportFormat.allCases.count, 2)
        XCTAssertTrue(JSONExportFormat.allCases.contains(.w3c))
        XCTAssertTrue(JSONExportFormat.allCases.contains(.raw))
    }

    // MARK: - W3C Export Integration

    func testExportColorsToW3CFormat() throws {
        let exporter = W3CTokensExporter()

        let colorsByMode: [String: [ExFigCore.Color]] = [
            "Light": [
                Color(name: "Background/Primary", red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            ],
            "Dark": [
                Color(name: "Background/Primary", red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0),
            ],
        ]

        let tokens = exporter.exportColors(colorsByMode: colorsByMode)
        let jsonData = try exporter.serializeToJSON(tokens, compact: false)

        XCTAssertFalse(jsonData.isEmpty)

        // Verify structure
        let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        XCTAssertNotNil(parsed)

        guard let background = parsed?["Background"] as? [String: Any],
              let primary = background["Primary"] as? [String: Any]
        else {
            XCTFail("Expected Background/Primary structure")
            return
        }

        XCTAssertEqual(primary["$type"] as? String, "color")
    }

    // MARK: - Raw Export Integration

    func testExportColorsToRawFormat() throws {
        let metadata = RawExportMetadata(
            name: "Design System",
            fileId: "abc123",
            exfigVersion: ExFigCommand.version
        )

        let variablesMeta = VariablesMeta.make(
            collectionName: "Colors",
            modes: [("1:0", "Light"), ("1:1", "Dark")],
            variables: [
                ("1", "primary", ["1:0": (r: 1.0, g: 0.0, b: 0.0, a: 1.0), "1:1": (r: 0.8, g: 0.0, b: 0.0, a: 1.0)]),
            ]
        )

        let output = RawExportOutput(source: metadata, data: variablesMeta)
        let exporter = RawExporter()
        let jsonData = try exporter.serialize(output, compact: false)

        XCTAssertFalse(jsonData.isEmpty)

        // Verify structure
        let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        XCTAssertNotNil(parsed?["source"])
        XCTAssertNotNil(parsed?["data"])
    }
}
