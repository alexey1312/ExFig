@testable import FigmaAPI
import XCTest

final class VariableUpdateTests: XCTestCase {
    // MARK: - VariableUpdate

    func testVariableUpdateInitSetsActionToUpdate() {
        let update = VariableUpdate(
            id: "VariableID:123:456",
            codeSyntax: VariableCodeSyntax(iOS: "Color.primary")
        )

        XCTAssertEqual(update.action, "UPDATE")
        XCTAssertEqual(update.id, "VariableID:123:456")
    }

    func testVariableUpdateEncodesToJSON() throws {
        let update = VariableUpdate(
            id: "VariableID:123:456",
            codeSyntax: VariableCodeSyntax(iOS: "Color.primary")
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(update)
        let json = String(data: data, encoding: .utf8)

        XCTAssertNotNil(json)
        XCTAssertTrue(try XCTUnwrap(json?.contains("\"action\":\"UPDATE\"")))
        XCTAssertTrue(try XCTUnwrap(json?.contains("\"id\":\"VariableID:123:456\"")))
        XCTAssertTrue(try XCTUnwrap(json?.contains("\"iOS\":\"Color.primary\"")))
    }

    func testVariableUpdateDecodesFromJSON() throws {
        let json = """
        {
            "action": "UPDATE",
            "id": "VariableID:123:456",
            "codeSyntax": {
                "iOS": "Color.primary"
            }
        }
        """
        let data = Data(json.utf8)

        let update = try JSONDecoder().decode(VariableUpdate.self, from: data)

        XCTAssertEqual(update.action, "UPDATE")
        XCTAssertEqual(update.id, "VariableID:123:456")
        XCTAssertEqual(update.codeSyntax?.iOS, "Color.primary")
    }

    // MARK: - VariableCodeSyntax

    func testVariableCodeSyntaxInitWithiOSOnly() {
        let syntax = VariableCodeSyntax(iOS: "Color.primary")

        XCTAssertEqual(syntax.iOS, "Color.primary")
        XCTAssertNil(syntax.ANDROID)
        XCTAssertNil(syntax.WEB)
    }

    func testVariableCodeSyntaxInitWithAllPlatforms() {
        let syntax = VariableCodeSyntax(
            iOS: "Color.primary",
            android: "R.color.primary",
            web: "var(--primary)"
        )

        XCTAssertEqual(syntax.iOS, "Color.primary")
        XCTAssertEqual(syntax.ANDROID, "R.color.primary")
        XCTAssertEqual(syntax.WEB, "var(--primary)")
    }

    func testVariableCodeSyntaxEncodesToJSON() throws {
        let syntax = VariableCodeSyntax(
            iOS: "Color.primary",
            android: "R.color.primary"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(syntax)
        let json = String(data: data, encoding: .utf8)

        XCTAssertNotNil(json)
        XCTAssertTrue(try XCTUnwrap(json?.contains("\"iOS\":\"Color.primary\"")))
        XCTAssertTrue(try XCTUnwrap(json?.contains("\"ANDROID\":\"R.color.primary\"")))
    }

    func testVariableCodeSyntaxDecodesFromJSON() throws {
        let json = """
        {
            "iOS": "Color.accent",
            "ANDROID": "R.color.accent",
            "WEB": "var(--accent)"
        }
        """
        let data = Data(json.utf8)

        let syntax = try JSONDecoder().decode(VariableCodeSyntax.self, from: data)

        XCTAssertEqual(syntax.iOS, "Color.accent")
        XCTAssertEqual(syntax.ANDROID, "R.color.accent")
        XCTAssertEqual(syntax.WEB, "var(--accent)")
    }

    // MARK: - VariablesUpdateRequest

    func testVariablesUpdateRequestEncodesToJSON() throws {
        let updates = [
            VariableUpdate(
                id: "VariableID:1:1",
                codeSyntax: VariableCodeSyntax(iOS: "Color.primary")
            ),
            VariableUpdate(
                id: "VariableID:1:2",
                codeSyntax: VariableCodeSyntax(iOS: "Color.secondary")
            ),
        ]
        let request = VariablesUpdateRequest(variables: updates)

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(VariablesUpdateRequest.self, from: data)

        XCTAssertEqual(decoded.variables.count, 2)
        XCTAssertEqual(decoded.variables[0].id, "VariableID:1:1")
        XCTAssertEqual(decoded.variables[1].id, "VariableID:1:2")
    }

    // MARK: - UpdateVariablesResponse

    func testUpdateVariablesResponseDecodesFromJSON() throws {
        let json = """
        {
            "status": 200,
            "error": false
        }
        """
        let data = Data(json.utf8)

        let response = try JSONDecoder().decode(UpdateVariablesResponse.self, from: data)

        XCTAssertEqual(response.status, 200)
        XCTAssertEqual(response.error, false)
    }

    func testUpdateVariablesResponseHandlesNilFields() throws {
        let json = "{}"
        let data = Data(json.utf8)

        let response = try JSONDecoder().decode(UpdateVariablesResponse.self, from: data)

        XCTAssertNil(response.status)
        XCTAssertNil(response.error)
    }
}
