import CustomDump
@testable import ExFig
import ExFigCore
@testable import FigmaAPI
import XCTest

final class ColorsVariablesLoaderTests: XCTestCase {
    var mockClient: MockClient!

    override func setUp() {
        super.setUp()
        mockClient = MockClient()
    }

    override func tearDown() {
        mockClient = nil
        super.tearDown()
    }

    // MARK: - Basic Loading

    func testLoadVariablesColorsBasic() async throws {
        let variablesMeta = VariablesMeta.make(
            collectionName: "Colors",
            modes: [("1:0", "Light"), ("1:1", "Dark")],
            variables: [
                (
                    id: "1:2",
                    name: "primary/background",
                    valuesByMode: [
                        "1:0": (r: 1.0, g: 1.0, b: 1.0, a: 1.0),
                        "1:1": (r: 0.1, g: 0.1, b: 0.1, a: 1.0),
                    ]
                ),
            ]
        )

        mockClient.setResponse(variablesMeta, for: VariablesEndpoint.self)

        let variablesParams = Params.Common.VariablesColors.make(
            tokensFileId: "test-file",
            tokensCollectionName: "Colors",
            lightModeName: "Light",
            darkModeName: "Dark"
        )

        let loader = ColorsVariablesLoader(
            client: mockClient,
            figmaParams: .make(lightFileId: "test-file"),
            variableParams: variablesParams,
            filter: nil
        )

        let result = try await loader.load()

        XCTAssertEqual(result.light.count, 1)
        XCTAssertEqual(result.light.first?.name, "primary/background")
        XCTAssertEqual(result.light.first?.red, 1.0)

        XCTAssertEqual(result.dark?.count, 1)
        XCTAssertEqual(result.dark?.first?.red, 0.1)
    }

    func testLoadVariablesColorsWithMultipleColors() async throws {
        let variablesMeta = VariablesMeta.make(
            collectionName: "Colors",
            modes: [("1:0", "Light"), ("1:1", "Dark")],
            variables: [
                (
                    id: "1:2",
                    name: "primary/background",
                    valuesByMode: [
                        "1:0": (r: 1.0, g: 1.0, b: 1.0, a: 1.0),
                        "1:1": (r: 0.0, g: 0.0, b: 0.0, a: 1.0),
                    ]
                ),
                (
                    id: "1:3",
                    name: "primary/text",
                    valuesByMode: [
                        "1:0": (r: 0.0, g: 0.0, b: 0.0, a: 1.0),
                        "1:1": (r: 1.0, g: 1.0, b: 1.0, a: 1.0),
                    ]
                ),
            ]
        )

        mockClient.setResponse(variablesMeta, for: VariablesEndpoint.self)

        let variablesParams = Params.Common.VariablesColors.make(
            tokensFileId: "test-file",
            tokensCollectionName: "Colors"
        )

        let loader = ColorsVariablesLoader(
            client: mockClient,
            figmaParams: .make(lightFileId: "test-file"),
            variableParams: variablesParams,
            filter: nil
        )

        let result = try await loader.load()

        XCTAssertEqual(result.light.count, 2)
        XCTAssertEqual(result.dark?.count, 2)

        let bgLight = result.light.first { $0.name == "primary/background" }
        let textLight = result.light.first { $0.name == "primary/text" }

        XCTAssertEqual(bgLight?.red, 1.0)
        XCTAssertEqual(textLight?.red, 0.0)
    }

    // MARK: - Filtering

    func testLoadVariablesColorsWithFilter() async throws {
        let variablesMeta = VariablesMeta.make(
            collectionName: "Colors",
            modes: [("1:0", "Light"), ("1:1", "Dark")],
            variables: [
                (
                    id: "1:2",
                    name: "button/primary",
                    valuesByMode: [
                        "1:0": (r: 1.0, g: 0.0, b: 0.0, a: 1.0),
                        "1:1": (r: 0.8, g: 0.0, b: 0.0, a: 1.0),
                    ]
                ),
                (
                    id: "1:3",
                    name: "text/primary",
                    valuesByMode: [
                        "1:0": (r: 0.0, g: 0.0, b: 0.0, a: 1.0),
                        "1:1": (r: 1.0, g: 1.0, b: 1.0, a: 1.0),
                    ]
                ),
            ]
        )

        mockClient.setResponse(variablesMeta, for: VariablesEndpoint.self)

        let variablesParams = Params.Common.VariablesColors.make(
            tokensFileId: "test-file",
            tokensCollectionName: "Colors"
        )

        let loader = ColorsVariablesLoader(
            client: mockClient,
            figmaParams: .make(lightFileId: "test-file"),
            variableParams: variablesParams,
            filter: "button/*"
        )

        let result = try await loader.load()

        XCTAssertEqual(result.light.count, 1)
        XCTAssertEqual(result.light.first?.name, "button/primary")
    }

    // MARK: - All Modes

    func testLoadVariablesColorsWithAllModes() async throws {
        let variablesMeta = VariablesMeta.make(
            collectionName: "Tokens",
            modes: [
                ("1:0", "Light"),
                ("1:1", "Dark"),
                ("1:2", "LightHC"),
                ("1:3", "DarkHC"),
            ],
            variables: [
                (
                    id: "1:2",
                    name: "primary",
                    valuesByMode: [
                        "1:0": (r: 1.0, g: 1.0, b: 1.0, a: 1.0),
                        "1:1": (r: 0.1, g: 0.1, b: 0.1, a: 1.0),
                        "1:2": (r: 0.95, g: 0.95, b: 0.95, a: 1.0),
                        "1:3": (r: 0.05, g: 0.05, b: 0.05, a: 1.0),
                    ]
                ),
            ]
        )

        mockClient.setResponse(variablesMeta, for: VariablesEndpoint.self)

        let variablesParams = Params.Common.VariablesColors.make(
            tokensFileId: "test-file",
            tokensCollectionName: "Tokens",
            lightModeName: "Light",
            darkModeName: "Dark",
            lightHCModeName: "LightHC",
            darkHCModeName: "DarkHC"
        )

        let loader = ColorsVariablesLoader(
            client: mockClient,
            figmaParams: .make(lightFileId: "test-file"),
            variableParams: variablesParams,
            filter: nil
        )

        let result = try await loader.load()

        XCTAssertEqual(result.light.count, 1)
        XCTAssertEqual(result.dark?.count, 1)
        XCTAssertEqual(result.lightHC?.count, 1)
        XCTAssertEqual(result.darkHC?.count, 1)

        XCTAssertEqual(result.light.first?.red, 1.0)
        XCTAssertEqual(result.dark?.first?.red, 0.1)
        XCTAssertEqual(result.lightHC?.first?.red, 0.95)
        XCTAssertEqual(result.darkHC?.first?.red, 0.05)
    }

    // MARK: - Error Handling

    func testThrowsWhenTokensFileIdMissing() async {
        let loader = ColorsVariablesLoader(
            client: mockClient,
            figmaParams: .make(lightFileId: "test-file"),
            variableParams: nil,
            filter: nil
        )

        do {
            _ = try await loader.load()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is ExFigError)
        }
    }

    func testThrowsWhenCollectionNotFound() async {
        let variablesMeta = VariablesMeta.make(
            collectionName: "DifferentCollection",
            modes: [("1:0", "Light")],
            variables: [
                (
                    id: "1:2",
                    name: "color",
                    valuesByMode: ["1:0": (r: 1.0, g: 0.0, b: 0.0, a: 1.0)]
                ),
            ]
        )

        mockClient.setResponse(variablesMeta, for: VariablesEndpoint.self)

        let variablesParams = Params.Common.VariablesColors.make(
            tokensFileId: "test-file",
            tokensCollectionName: "NonExistentCollection"
        )

        let loader = ColorsVariablesLoader(
            client: mockClient,
            figmaParams: .make(lightFileId: "test-file"),
            variableParams: variablesParams,
            filter: nil
        )

        do {
            _ = try await loader.load()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is ExFigError)
        }
    }

    // MARK: - Single API Call Verification

    func testUseSingleAPICall() async throws {
        let variablesMeta = VariablesMeta.make(
            collectionName: "Colors",
            modes: [("1:0", "Light"), ("1:1", "Dark")],
            variables: [
                (
                    id: "1:2",
                    name: "color",
                    valuesByMode: [
                        "1:0": (r: 1.0, g: 0.0, b: 0.0, a: 1.0),
                        "1:1": (r: 0.0, g: 1.0, b: 0.0, a: 1.0),
                    ]
                ),
            ]
        )

        mockClient.setResponse(variablesMeta, for: VariablesEndpoint.self)

        let variablesParams = Params.Common.VariablesColors.make(
            tokensFileId: "test-file",
            tokensCollectionName: "Colors"
        )

        let loader = ColorsVariablesLoader(
            client: mockClient,
            figmaParams: .make(lightFileId: "test-file"),
            variableParams: variablesParams,
            filter: nil
        )

        _ = try await loader.load()

        // ColorsVariablesLoader should only make 1 API call
        // (all modes come in single response, no parallelization needed)
        XCTAssertEqual(mockClient.requestCount, 1)
    }
}
