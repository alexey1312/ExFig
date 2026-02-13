// swiftlint:disable file_length type_body_length

import CustomDump
@testable import ExFigCLI
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

        let variablesParams = PKLConfig.Common.VariablesColors.make(
            tokensFileId: "test-file",
            tokensCollectionName: "Colors",
            lightModeName: "Light",
            darkModeName: "Dark"
        )

        let loader = ColorsVariablesLoader(
            client: mockClient,
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

        let variablesParams = PKLConfig.Common.VariablesColors.make(
            tokensFileId: "test-file",
            tokensCollectionName: "Colors"
        )

        let loader = ColorsVariablesLoader(
            client: mockClient,
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

        let variablesParams = PKLConfig.Common.VariablesColors.make(
            tokensFileId: "test-file",
            tokensCollectionName: "Colors"
        )

        let loader = ColorsVariablesLoader(
            client: mockClient,
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

        let variablesParams = PKLConfig.Common.VariablesColors.make(
            tokensFileId: "test-file",
            tokensCollectionName: "Tokens",
            lightModeName: "Light",
            darkModeName: "Dark",
            lightHCModeName: "LightHC",
            darkHCModeName: "DarkHC"
        )

        let loader = ColorsVariablesLoader(
            client: mockClient,
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

        let variablesParams = PKLConfig.Common.VariablesColors.make(
            tokensFileId: "test-file",
            tokensCollectionName: "NonExistentCollection"
        )

        let loader = ColorsVariablesLoader(
            client: mockClient,
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

    // MARK: - Variable Alias Resolution

    func testResolvesVariableAliasToColor() async throws {
        // Given: A token variable that references a primitive color via alias
        let variablesMeta = VariablesMeta.makeWithAliases(
            collectionName: "Tokens",
            modes: [("1:0", "Light")],
            variables: [
                // Token that aliases a primitive
                (
                    id: "token:1",
                    name: "background/primary",
                    collectionId: nil,
                    valuesByMode: ["1:0": .alias("prim:red")]
                ),
                // Primitive color
                (
                    id: "prim:red",
                    name: "red/500",
                    collectionId: "VariableCollectionId:primitives",
                    valuesByMode: ["2:0": .color(r: 1.0, g: 0.0, b: 0.0, a: 1.0)]
                ),
            ],
            primitiveCollections: [
                (
                    id: "VariableCollectionId:primitives",
                    name: "Primitives",
                    defaultModeId: "2:0",
                    modes: [("2:0", "Value")],
                    variableIds: ["prim:red"]
                ),
            ]
        )

        mockClient.setResponse(variablesMeta, for: VariablesEndpoint.self)

        let variablesParams = PKLConfig.Common.VariablesColors.make(
            tokensFileId: "test-file",
            tokensCollectionName: "Tokens",
            lightModeName: "Light"
        )

        let loader = ColorsVariablesLoader(
            client: mockClient,
            variableParams: variablesParams,
            filter: nil
        )

        // When: Loading colors
        let result = try await loader.load()

        // Then: Alias should be resolved to the primitive color value
        XCTAssertEqual(result.light.count, 1)
        XCTAssertEqual(result.light.first?.name, "background/primary")
        XCTAssertEqual(result.light.first?.red, 1.0)
        XCTAssertEqual(result.light.first?.green, 0.0)
        XCTAssertEqual(result.light.first?.blue, 0.0)
    }

    func testResolvesNestedVariableAliases() async throws {
        // Given: A chain of aliases: token -> alias -> primitive
        let variablesMeta = VariablesMeta.makeWithAliases(
            collectionName: "Tokens",
            modes: [("1:0", "Light")],
            variables: [
                // Token aliases another alias
                (
                    id: "token:1",
                    name: "button/primary",
                    collectionId: nil,
                    valuesByMode: ["1:0": .alias("semantic:brand")]
                ),
                // Semantic color that aliases primitive
                (
                    id: "semantic:brand",
                    name: "brand/primary",
                    collectionId: "VariableCollectionId:semantic",
                    valuesByMode: ["2:0": .alias("prim:blue")]
                ),
                // Primitive color
                (
                    id: "prim:blue",
                    name: "blue/600",
                    collectionId: "VariableCollectionId:primitives",
                    valuesByMode: ["3:0": .color(r: 0.0, g: 0.0, b: 1.0, a: 1.0)]
                ),
            ],
            primitiveCollections: [
                (
                    id: "VariableCollectionId:semantic",
                    name: "Semantic",
                    defaultModeId: "2:0",
                    modes: [("2:0", "Value")],
                    variableIds: ["semantic:brand"]
                ),
                (
                    id: "VariableCollectionId:primitives",
                    name: "Primitives",
                    defaultModeId: "3:0",
                    modes: [("3:0", "Value")],
                    variableIds: ["prim:blue"]
                ),
            ]
        )

        mockClient.setResponse(variablesMeta, for: VariablesEndpoint.self)

        let variablesParams = PKLConfig.Common.VariablesColors.make(
            tokensFileId: "test-file",
            tokensCollectionName: "Tokens",
            lightModeName: "Light"
        )

        let loader = ColorsVariablesLoader(
            client: mockClient,
            variableParams: variablesParams,
            filter: nil
        )

        // When: Loading colors
        let result = try await loader.load()

        // Then: Nested aliases should be fully resolved
        XCTAssertEqual(result.light.count, 1)
        XCTAssertEqual(result.light.first?.name, "button/primary")
        XCTAssertEqual(result.light.first?.blue, 1.0)
    }

    func testResolvesAliasWithCustomPrimitivesModeName() async throws {
        // Given: A primitive collection with a custom mode name
        let variablesMeta = VariablesMeta.makeWithAliases(
            collectionName: "Tokens",
            modes: [("1:0", "Light")],
            variables: [
                (
                    id: "token:1",
                    name: "accent",
                    collectionId: nil,
                    valuesByMode: ["1:0": .alias("prim:green")]
                ),
                (
                    id: "prim:green",
                    name: "green/500",
                    collectionId: "VariableCollectionId:primitives",
                    valuesByMode: [
                        "2:0": .color(r: 0.0, g: 0.8, b: 0.0, a: 1.0),
                        "2:1": .color(r: 0.0, g: 1.0, b: 0.0, a: 1.0),
                    ]
                ),
            ],
            primitiveCollections: [
                (
                    id: "VariableCollectionId:primitives",
                    name: "Primitives",
                    defaultModeId: "2:0",
                    modes: [("2:0", "Default"), ("2:1", "Brand")],
                    variableIds: ["prim:green"]
                ),
            ]
        )

        mockClient.setResponse(variablesMeta, for: VariablesEndpoint.self)

        let variablesParams = PKLConfig.Common.VariablesColors.make(
            tokensFileId: "test-file",
            tokensCollectionName: "Tokens",
            lightModeName: "Light",
            primitivesModeName: "Brand" // Use Brand mode instead of default
        )

        let loader = ColorsVariablesLoader(
            client: mockClient,
            variableParams: variablesParams,
            filter: nil
        )

        // When: Loading colors
        let result = try await loader.load()

        // Then: Should use the specified primitives mode
        XCTAssertEqual(result.light.count, 1)
        XCTAssertEqual(result.light.first?.green, 1.0) // Brand mode has green=1.0
    }

    func testResolvesAliasesAcrossMultipleModes() async throws {
        // Given: A token with aliases for both Light and Dark modes
        let variablesMeta = VariablesMeta.makeWithAliases(
            collectionName: "Tokens",
            modes: [("1:0", "Light"), ("1:1", "Dark")],
            variables: [
                (
                    id: "token:1",
                    name: "surface",
                    collectionId: nil,
                    valuesByMode: [
                        "1:0": .alias("prim:white"),
                        "1:1": .alias("prim:black"),
                    ]
                ),
                (
                    id: "prim:white",
                    name: "white",
                    collectionId: "VariableCollectionId:primitives",
                    valuesByMode: ["2:0": .color(r: 1.0, g: 1.0, b: 1.0, a: 1.0)]
                ),
                (
                    id: "prim:black",
                    name: "black",
                    collectionId: "VariableCollectionId:primitives",
                    valuesByMode: ["2:0": .color(r: 0.0, g: 0.0, b: 0.0, a: 1.0)]
                ),
            ],
            primitiveCollections: [
                (
                    id: "VariableCollectionId:primitives",
                    name: "Primitives",
                    defaultModeId: "2:0",
                    modes: [("2:0", "Value")],
                    variableIds: ["prim:white", "prim:black"]
                ),
            ]
        )

        mockClient.setResponse(variablesMeta, for: VariablesEndpoint.self)

        let variablesParams = PKLConfig.Common.VariablesColors.make(
            tokensFileId: "test-file",
            tokensCollectionName: "Tokens",
            lightModeName: "Light",
            darkModeName: "Dark"
        )

        let loader = ColorsVariablesLoader(
            client: mockClient,
            variableParams: variablesParams,
            filter: nil
        )

        // When: Loading colors
        let result = try await loader.load()

        // Then: Each mode should resolve to correct primitive
        XCTAssertEqual(result.light.first?.red, 1.0) // White
        XCTAssertEqual(result.dark?.first?.red, 0.0) // Black
    }

    // MARK: - Deleted Variables

    func testSkipsDeletedButReferencedVariables() async throws {
        // Given: One active color and one deleted-but-referenced color
        let variablesMeta = VariablesMeta.makeWithAliases(
            collectionName: "Colors",
            modes: [("1:0", "Light"), ("1:1", "Dark")],
            variables: [
                (
                    id: "1:2",
                    name: "primary/background",
                    collectionId: nil,
                    valuesByMode: [
                        "1:0": .color(r: 1.0, g: 1.0, b: 1.0, a: 1.0),
                        "1:1": .color(r: 0.1, g: 0.1, b: 0.1, a: 1.0),
                    ]
                ),
                (
                    id: "1:3",
                    name: "Background/(!!!DEPRICATED)Float",
                    collectionId: nil,
                    valuesByMode: [
                        "1:0": .color(r: 0.5, g: 0.5, b: 0.5, a: 1.0),
                        "1:1": .color(r: 0.3, g: 0.3, b: 0.3, a: 1.0),
                    ]
                ),
            ],
            deletedVariableIds: ["1:3"]
        )

        mockClient.setResponse(variablesMeta, for: VariablesEndpoint.self)

        let variablesParams = PKLConfig.Common.VariablesColors.make(
            tokensFileId: "test-file",
            tokensCollectionName: "Colors",
            lightModeName: "Light",
            darkModeName: "Dark"
        )

        let loader = ColorsVariablesLoader(
            client: mockClient,
            variableParams: variablesParams,
            filter: nil
        )

        // When: Loading colors
        let result = try await loader.load()

        // Then: Only active variable should be included
        XCTAssertEqual(result.light.count, 1)
        XCTAssertEqual(result.light.first?.name, "primary/background")
        XCTAssertEqual(result.dark?.count, 1)
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

        let variablesParams = PKLConfig.Common.VariablesColors.make(
            tokensFileId: "test-file",
            tokensCollectionName: "Colors"
        )

        let loader = ColorsVariablesLoader(
            client: mockClient,
            variableParams: variablesParams,
            filter: nil
        )

        _ = try await loader.load()

        // ColorsVariablesLoader should only make 1 API call
        // (all modes come in single response, no parallelization needed)
        XCTAssertEqual(mockClient.requestCount, 1)
    }
}
