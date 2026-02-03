@testable import ExFig
import ExFigCore
import FigmaAPI
import XCTest

final class CodeSyntaxSyncerTests: XCTestCase {
    var client: MockClient!
    var syncer: CodeSyntaxSyncer!

    override func setUp() {
        super.setUp()
        client = MockClient()
        syncer = CodeSyntaxSyncer(client: client)
    }

    override func tearDown() {
        client = nil
        syncer = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func makeVariablesMeta(
        collectionName: String = "Colors",
        variableNames: [String] = ["primary/background", "primary/foreground"]
    ) throws -> VariablesMeta {
        let modeId = "1:0"
        let collectionId = "VariableCollectionId:1:1"

        var variablesJson: [String: Any] = [:]
        var variableIds: [String] = []

        for (index, name) in variableNames.enumerated() {
            let varId = "VariableID:1:\(index)"
            variableIds.append(varId)
            variablesJson[varId] = [
                "id": varId,
                "name": name,
                "variableCollectionId": collectionId,
                "valuesByMode": [
                    modeId: ["r": 1.0, "g": 1.0, "b": 1.0, "a": 1.0],
                ],
                "description": "",
            ] as [String: Any]
        }

        let json: [String: Any] = [
            "meta": [
                "variableCollections": [
                    collectionId: [
                        "defaultModeId": modeId,
                        "id": collectionId,
                        "name": collectionName,
                        "modes": [
                            ["modeId": modeId, "name": "Light"],
                        ],
                        "variableIds": variableIds,
                    ],
                ],
                "variables": variablesJson,
            ],
        ]

        // JSON uses camelCase keys matching real Figma API responses
        let data = try JSONSerialization.data(withJSONObject: json)
        let response = try JSONCodec.decode(VariablesResponse.self, from: data)
        return response.meta
    }

    // MARK: - Basic Sync Tests

    func testSyncReturnsCorrectCount() async throws {
        let meta = try makeVariablesMeta(variableNames: ["primary", "secondary", "accent"])
        client.setResponse(meta, for: VariablesEndpoint.self)
        client.setResponse(UpdateVariablesResponse(status: 200, error: false), for: UpdateVariablesEndpoint.self)

        let count = try await syncer.sync(
            fileId: "test-file",
            collectionName: "Colors",
            template: "Color.{name}",
            nameStyle: .camelCase
        )

        XCTAssertEqual(count, 3)
    }

    func testSyncMakesTwoRequests() async throws {
        let meta = try makeVariablesMeta()
        client.setResponse(meta, for: VariablesEndpoint.self)
        client.setResponse(UpdateVariablesResponse(status: 200, error: false), for: UpdateVariablesEndpoint.self)

        _ = try await syncer.sync(
            fileId: "test-file",
            collectionName: "Colors",
            template: "Color.{name}",
            nameStyle: .camelCase
        )

        XCTAssertEqual(client.requestCount, 2)
        XCTAssertEqual(client.requests(containing: "variables/local").count, 1) // GET variables
        XCTAssertEqual(client.requests(containing: "variables").count, 2) // GET + POST
    }

    func testSyncReturnsZeroForEmptyCollection() async throws {
        let meta = try makeVariablesMeta(variableNames: [])
        client.setResponse(meta, for: VariablesEndpoint.self)

        let count = try await syncer.sync(
            fileId: "test-file",
            collectionName: "Colors",
            template: "Color.{name}",
            nameStyle: .camelCase
        )

        XCTAssertEqual(count, 0)
        // Should only make GET request, not POST
        XCTAssertEqual(client.requestCount, 1)
    }

    // MARK: - Collection Not Found

    func testSyncThrowsWhenCollectionNotFound() async throws {
        let meta = try makeVariablesMeta(collectionName: "DifferentCollection")
        client.setResponse(meta, for: VariablesEndpoint.self)

        do {
            _ = try await syncer.sync(
                fileId: "test-file",
                collectionName: "Colors",
                template: "Color.{name}",
                nameStyle: .camelCase
            )
            XCTFail("Expected error for missing collection")
        } catch let error as CodeSyntaxSyncerError {
            if case let .collectionNotFound(name) = error {
                XCTAssertEqual(name, "Colors")
            } else {
                XCTFail("Unexpected error type")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Name Processing Tests

    func testProcessNameNormalizesSlash() async throws {
        let meta = try makeVariablesMeta(variableNames: ["background/primary"])
        client.setResponse(meta, for: VariablesEndpoint.self)
        client.setResponse(UpdateVariablesResponse(status: 200, error: false), for: UpdateVariablesEndpoint.self)

        _ = try await syncer.sync(
            fileId: "test-file",
            collectionName: "Colors",
            template: "Color.{name}",
            nameStyle: .camelCase
        )

        // Check the POST request body
        let postRequests = client.requests(containing: "variables")
            .filter { $0.httpMethod == "POST" }
        XCTAssertEqual(postRequests.count, 1)

        if let body = postRequests.first?.httpBody {
            let request = try JSONCodec.decode(VariablesUpdateRequest.self, from: body)
            XCTAssertEqual(request.variables.first?.codeSyntax?.iOS, "Color.backgroundPrimary")
        }
    }

    func testProcessNameRemovesDuplication() async throws {
        let meta = try makeVariablesMeta(variableNames: ["color/color"])
        client.setResponse(meta, for: VariablesEndpoint.self)
        client.setResponse(UpdateVariablesResponse(status: 200, error: false), for: UpdateVariablesEndpoint.self)

        _ = try await syncer.sync(
            fileId: "test-file",
            collectionName: "Colors",
            template: "Color.{name}",
            nameStyle: .camelCase
        )

        let postRequests = client.requests(containing: "variables")
            .filter { $0.httpMethod == "POST" }

        if let body = postRequests.first?.httpBody {
            let request = try JSONCodec.decode(VariablesUpdateRequest.self, from: body)
            XCTAssertEqual(request.variables.first?.codeSyntax?.iOS, "Color.color")
        }
    }

    func testProcessNameAppliesCamelCase() async throws {
        let meta = try makeVariablesMeta(variableNames: ["background-accent"])
        client.setResponse(meta, for: VariablesEndpoint.self)
        client.setResponse(UpdateVariablesResponse(status: 200, error: false), for: UpdateVariablesEndpoint.self)

        _ = try await syncer.sync(
            fileId: "test-file",
            collectionName: "Colors",
            template: "Color.{name}",
            nameStyle: .camelCase
        )

        let postRequests = client.requests(containing: "variables")
            .filter { $0.httpMethod == "POST" }

        if let body = postRequests.first?.httpBody {
            let request = try JSONCodec.decode(VariablesUpdateRequest.self, from: body)
            XCTAssertEqual(request.variables.first?.codeSyntax?.iOS, "Color.backgroundAccent")
        }
    }

    func testProcessNameAppliesSnakeCase() async throws {
        let meta = try makeVariablesMeta(variableNames: ["backgroundAccent"])
        client.setResponse(meta, for: VariablesEndpoint.self)
        client.setResponse(UpdateVariablesResponse(status: 200, error: false), for: UpdateVariablesEndpoint.self)

        _ = try await syncer.sync(
            fileId: "test-file",
            collectionName: "Colors",
            template: "Color.{name}",
            nameStyle: .snakeCase
        )

        let postRequests = client.requests(containing: "variables")
            .filter { $0.httpMethod == "POST" }

        if let body = postRequests.first?.httpBody {
            let request = try JSONCodec.decode(VariablesUpdateRequest.self, from: body)
            XCTAssertEqual(request.variables.first?.codeSyntax?.iOS, "Color.background_accent")
        }
    }

    // MARK: - Template Tests

    func testTemplateReplacesPlaceholder() async throws {
        let meta = try makeVariablesMeta(variableNames: ["primary"])
        client.setResponse(meta, for: VariablesEndpoint.self)
        client.setResponse(UpdateVariablesResponse(status: 200, error: false), for: UpdateVariablesEndpoint.self)

        _ = try await syncer.sync(
            fileId: "test-file",
            collectionName: "Colors",
            template: "ThemeCompatable.colors.{name}",
            nameStyle: .camelCase
        )

        let postRequests = client.requests(containing: "variables")
            .filter { $0.httpMethod == "POST" }

        if let body = postRequests.first?.httpBody {
            let request = try JSONCodec.decode(VariablesUpdateRequest.self, from: body)
            XCTAssertEqual(request.variables.first?.codeSyntax?.iOS, "ThemeCompatable.colors.primary")
        }
    }

    func testTemplateWithUIColorPrefix() async throws {
        let meta = try makeVariablesMeta(variableNames: ["accent"])
        client.setResponse(meta, for: VariablesEndpoint.self)
        client.setResponse(UpdateVariablesResponse(status: 200, error: false), for: UpdateVariablesEndpoint.self)

        _ = try await syncer.sync(
            fileId: "test-file",
            collectionName: "Colors",
            template: "UIColor.{name}",
            nameStyle: .camelCase
        )

        let postRequests = client.requests(containing: "variables")
            .filter { $0.httpMethod == "POST" }

        if let body = postRequests.first?.httpBody {
            let request = try JSONCodec.decode(VariablesUpdateRequest.self, from: body)
            XCTAssertEqual(request.variables.first?.codeSyntax?.iOS, "UIColor.accent")
        }
    }

    // MARK: - Regex Replacement Tests

    func testNameValidateAndReplaceRegexp() async throws {
        // Simulate a name like "ds3-background-primary" that should become "backgroundPrimary"
        let meta = try makeVariablesMeta(variableNames: ["ds3-background-primary"])
        client.setResponse(meta, for: VariablesEndpoint.self)
        client.setResponse(UpdateVariablesResponse(status: 200, error: false), for: UpdateVariablesEndpoint.self)

        _ = try await syncer.sync(
            fileId: "test-file",
            collectionName: "Colors",
            template: "Color.{name}",
            nameStyle: .camelCase,
            nameValidateRegexp: "ds3-(.+)",
            nameReplaceRegexp: "$1"
        )

        let postRequests = client.requests(containing: "variables")
            .filter { $0.httpMethod == "POST" }

        if let body = postRequests.first?.httpBody {
            let request = try JSONCodec.decode(VariablesUpdateRequest.self, from: body)
            XCTAssertEqual(request.variables.first?.codeSyntax?.iOS, "Color.backgroundPrimary")
        }
    }

    // MARK: - Error Description Tests

    func testCollectionNotFoundErrorDescription() {
        let error = CodeSyntaxSyncerError.collectionNotFound("TestCollection")

        XCTAssertEqual(error.errorDescription, "Variable collection 'TestCollection' not found")
        XCTAssertEqual(error.recoverySuggestion, "Check the tokensCollectionName in your config")
    }

    func testTemplateMissingPlaceholderErrorDescription() {
        let error = CodeSyntaxSyncerError.templateMissingPlaceholder

        XCTAssertEqual(error.errorDescription, "Template must contain {name} placeholder")
        XCTAssertEqual(error.recoverySuggestion, "Use a template like \"Color.{name}\" or \"UIColor.{name}\"")
    }
}
