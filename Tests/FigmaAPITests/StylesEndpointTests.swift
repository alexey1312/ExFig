import CustomDump
@testable import FigmaAPI
import XCTest

final class StylesEndpointTests: XCTestCase {
    // MARK: - URL Construction

    func testMakeRequestConstructsCorrectURL() {
        let endpoint = StylesEndpoint(fileId: "abc123")
        let baseURL = URL(string: "https://api.figma.com/v1/")!

        let request = endpoint.makeRequest(baseURL: baseURL)

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://api.figma.com/v1/files/abc123/styles"
        )
    }

    func testMakeRequestWithSpecialCharactersInFileId() {
        let endpoint = StylesEndpoint(fileId: "file-with-dashes")
        let baseURL = URL(string: "https://api.figma.com/v1/")!

        let request = endpoint.makeRequest(baseURL: baseURL)

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://api.figma.com/v1/files/file-with-dashes/styles"
        )
    }

    // MARK: - Response Parsing

    func testContentParsesStylesResponse() throws {
        let response: StylesResponse = try FixtureLoader.load("StylesResponse")

        let endpoint = StylesEndpoint(fileId: "test")
        let styles = endpoint.content(from: response)

        XCTAssertEqual(styles.count, 5)

        // Check first fill style
        let firstStyle = styles[0]
        XCTAssertEqual(firstStyle.name, "primary/background")
        XCTAssertEqual(firstStyle.nodeId, "1:2")
        XCTAssertEqual(firstStyle.styleType, .fill)
        XCTAssertEqual(firstStyle.description, "")

        // Check style with description
        let styleWithDescription = styles[1]
        XCTAssertEqual(styleWithDescription.name, "primary/text")
        XCTAssertEqual(styleWithDescription.description, "ios")

        // Check text style
        let textStyle = styles[3]
        XCTAssertEqual(textStyle.name, "heading/large")
        XCTAssertEqual(textStyle.styleType, .text)
    }

    func testContentFromResponseWithBody() throws {
        let data = try FixtureLoader.loadData("StylesResponse")

        let endpoint = StylesEndpoint(fileId: "test")
        let styles = try endpoint.content(from: nil, with: data)

        XCTAssertEqual(styles.count, 5)
        XCTAssertEqual(styles[0].name, "primary/background")
    }

    // MARK: - Error Handling

    func testContentThrowsOnInvalidJSON() {
        let invalidData = Data("invalid json".utf8)
        let endpoint = StylesEndpoint(fileId: "test")

        XCTAssertThrowsError(try endpoint.content(from: nil, with: invalidData))
    }

    func testContentThrowsOnFigmaError() throws {
        let errorJSONString = """
        {
            "status": 404,
            "err": "Not found"
        }
        """
        let errorJSON = Data(errorJSONString.utf8)

        let endpoint = StylesEndpoint(fileId: "test")

        XCTAssertThrowsError(try endpoint.content(from: nil, with: errorJSON)) { error in
            XCTAssertTrue(error is FigmaClientError)
        }
    }
}
