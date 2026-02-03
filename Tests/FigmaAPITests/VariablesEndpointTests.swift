import CustomDump
import ExFigCore
@testable import FigmaAPI
import XCTest

final class VariablesEndpointTests: XCTestCase {
    // MARK: - URL Construction

    func testMakeRequestConstructsCorrectURL() {
        let endpoint = VariablesEndpoint(fileId: "abc123")
        let baseURL = URL(string: "https://api.figma.com/v1/")!

        let request = endpoint.makeRequest(baseURL: baseURL)

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://api.figma.com/v1/files/abc123/variables/local"
        )
    }

    // MARK: - Response Parsing

    func testContentParsesVariablesResponse() throws {
        let response: VariablesResponse = try FixtureLoader.load("VariablesResponse")

        let endpoint = VariablesEndpoint(fileId: "test")
        let meta = endpoint.content(from: response)

        // Check collections
        XCTAssertEqual(meta.variableCollections.count, 1)

        let collection = meta.variableCollections["VariableCollectionId:1:1"]
        XCTAssertNotNil(collection)
        XCTAssertEqual(collection?.name, "Colors")
        XCTAssertEqual(collection?.modes.count, 2)
        XCTAssertEqual(collection?.modes[0].name, "Light")
        XCTAssertEqual(collection?.modes[1].name, "Dark")

        // Check variables
        XCTAssertEqual(meta.variables.count, 2)

        let bgVariable = meta.variables["VariableID:1:2"]
        XCTAssertNotNil(bgVariable)
        XCTAssertEqual(bgVariable?.name, "primary/background")
        XCTAssertEqual(bgVariable?.description, "Main background color")
    }

    func testContentParsesColorValuesByMode() throws {
        let response: VariablesResponse = try FixtureLoader.load("VariablesResponse")

        let endpoint = VariablesEndpoint(fileId: "test")
        let meta = endpoint.content(from: response)

        let bgVariable = meta.variables["VariableID:1:2"]

        // Check light mode color (white)
        if case let .color(lightColor) = bgVariable?.valuesByMode["1:0"] {
            XCTAssertEqual(lightColor.r, 1.0)
            XCTAssertEqual(lightColor.g, 1.0)
            XCTAssertEqual(lightColor.b, 1.0)
        } else {
            XCTFail("Expected color value for light mode")
        }

        // Check dark mode color (dark gray)
        if case let .color(darkColor) = bgVariable?.valuesByMode["1:1"] {
            XCTAssertEqual(darkColor.r, 0.1)
            XCTAssertEqual(darkColor.g, 0.1)
            XCTAssertEqual(darkColor.b, 0.1)
        } else {
            XCTFail("Expected color value for dark mode")
        }
    }

    func testContentFromResponseWithBody() throws {
        let data = try FixtureLoader.loadData("VariablesResponse")

        let endpoint = VariablesEndpoint(fileId: "test")
        let meta = try endpoint.content(from: nil, with: data)

        XCTAssertEqual(meta.variableCollections.count, 1)
        XCTAssertEqual(meta.variables.count, 2)
    }

    // MARK: - Mode Parsing

    func testModesParsing() throws {
        let response: VariablesResponse = try FixtureLoader.load("VariablesResponse")

        let endpoint = VariablesEndpoint(fileId: "test")
        let meta = endpoint.content(from: response)

        let collection = meta.variableCollections.values.first
        let lightMode = collection?.modes.first { $0.name == "Light" }
        let darkMode = collection?.modes.first { $0.name == "Dark" }

        XCTAssertNotNil(lightMode)
        XCTAssertNotNil(darkMode)
        XCTAssertEqual(lightMode?.modeId, "1:0")
        XCTAssertEqual(darkMode?.modeId, "1:1")
    }

    // MARK: - Error Handling

    func testContentThrowsOnInvalidJSON() {
        let invalidData = Data("invalid".utf8)
        let endpoint = VariablesEndpoint(fileId: "test")

        XCTAssertThrowsError(try endpoint.content(from: nil, with: invalidData))
    }

    func testJSONCodecDirectDecode() throws {
        // Test decoding VariableCollectionValue - API uses camelCase
        let collectionJson = """
        {
            "defaultModeId": "1:0",
            "id": "VariableCollectionId:1:1",
            "name": "Colors",
            "modes": [
              { "modeId": "1:0", "name": "Light" }
            ],
            "variableIds": ["id1"]
        }
        """
        let collectionData = Data(collectionJson.utf8)

        let collection = try JSONCodec.decode(VariableCollectionValue.self, from: collectionData)
        XCTAssertEqual(collection.name, "Colors")
    }

    func testFoundationDecoderDirectDecode() throws {
        // Test Foundation decoder with camelCase JSON (matching Figma API)
        let json = """
        {
          "meta": {
            "variableCollections": {
              "VariableCollectionId:1:1": {
                "defaultModeId": "1:0",
                "id": "VariableCollectionId:1:1",
                "name": "Colors",
                "modes": [
                  { "modeId": "1:0", "name": "Light" }
                ],
                "variableIds": ["id1"]
              }
            },
            "variables": {
              "VariableID:1:2": {
                "id": "VariableID:1:2",
                "name": "test",
                "variableCollectionId": "VariableCollectionId:1:1",
                "valuesByMode": {
                  "1:0": { "r": 1.0, "g": 1.0, "b": 1.0, "a": 1.0 }
                },
                "description": "Test"
              }
            }
          }
        }
        """
        let data = Data(json.utf8)
        let decoder = JSONDecoder()

        let response = try decoder.decode(VariablesResponse.self, from: data)
        XCTAssertEqual(response.meta.variableCollections.count, 1)
    }
}
