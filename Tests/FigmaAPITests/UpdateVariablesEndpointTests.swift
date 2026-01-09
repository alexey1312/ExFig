@testable import FigmaAPI
import XCTest

final class UpdateVariablesEndpointTests: XCTestCase {
    // MARK: - URL Construction

    func testMakeRequestConstructsCorrectURL() {
        let body = VariablesUpdateRequest(variables: [])
        let endpoint = UpdateVariablesEndpoint(fileId: "abc123", body: body)
        // swiftlint:disable:next force_unwrapping
        let baseURL = URL(string: "https://api.figma.com/v1/")!

        let request = endpoint.makeRequest(baseURL: baseURL)

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://api.figma.com/v1/files/abc123/variables"
        )
    }

    func testMakeRequestUsesPOSTMethod() {
        let body = VariablesUpdateRequest(variables: [])
        let endpoint = UpdateVariablesEndpoint(fileId: "test", body: body)
        // swiftlint:disable:next force_unwrapping
        let baseURL = URL(string: "https://api.figma.com/v1/")!

        let request = endpoint.makeRequest(baseURL: baseURL)

        XCTAssertEqual(request.httpMethod, "POST")
    }

    func testMakeRequestSetsContentTypeHeader() {
        let body = VariablesUpdateRequest(variables: [])
        let endpoint = UpdateVariablesEndpoint(fileId: "test", body: body)
        // swiftlint:disable:next force_unwrapping
        let baseURL = URL(string: "https://api.figma.com/v1/")!

        let request = endpoint.makeRequest(baseURL: baseURL)

        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testMakeRequestIncludesBody() throws {
        let update = VariableUpdate(
            id: "VariableID:123:456",
            codeSyntax: VariableCodeSyntax(iOS: "Color.primary")
        )
        let body = VariablesUpdateRequest(variables: [update])
        let endpoint = UpdateVariablesEndpoint(fileId: "test", body: body)
        // swiftlint:disable:next force_unwrapping
        let baseURL = URL(string: "https://api.figma.com/v1/")!

        let request = endpoint.makeRequest(baseURL: baseURL)

        XCTAssertNotNil(request.httpBody)

        let decoded = try JSONDecoder().decode(VariablesUpdateRequest.self, from: request.httpBody!)
        XCTAssertEqual(decoded.variables.count, 1)
        XCTAssertEqual(decoded.variables[0].id, "VariableID:123:456")
        XCTAssertEqual(decoded.variables[0].action, "UPDATE")
        XCTAssertEqual(decoded.variables[0].codeSyntax?.iOS, "Color.primary")
    }

    // MARK: - Response Parsing

    func testContentParsesSuccessResponse() throws {
        let json = """
        {
            "status": 200,
            "error": false
        }
        """
        let data = Data(json.utf8)

        let body = VariablesUpdateRequest(variables: [])
        let endpoint = UpdateVariablesEndpoint(fileId: "test", body: body)
        let response = try endpoint.content(from: nil, with: data)

        XCTAssertEqual(response.status, 200)
        XCTAssertEqual(response.error, false)
    }

    func testContentParsesErrorResponse() throws {
        let json = """
        {
            "status": 403,
            "error": true
        }
        """
        let data = Data(json.utf8)

        let body = VariablesUpdateRequest(variables: [])
        let endpoint = UpdateVariablesEndpoint(fileId: "test", body: body)
        let response = try endpoint.content(from: nil, with: data)

        XCTAssertEqual(response.status, 403)
        XCTAssertEqual(response.error, true)
    }
}
