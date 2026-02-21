import CustomDump
@testable import FigmaAPI
import XCTest

final class FileMetadataEndpointTests: XCTestCase {
    // MARK: - URL Construction

    func testMakeRequestConstructsCorrectURL() throws {
        let endpoint = FileMetadataEndpoint(fileId: "abc123")
        // swiftlint:disable:next force_unwrapping
        let baseURL = try XCTUnwrap(URL(string: "https://api.figma.com/v1/"))

        let request = try endpoint.makeRequest(baseURL: baseURL)

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://api.figma.com/v1/files/abc123?depth=1"
        )
    }

    func testMakeRequestIncludesDepthParameter() throws {
        let endpoint = FileMetadataEndpoint(fileId: "test")
        // swiftlint:disable:next force_unwrapping
        let baseURL = try XCTUnwrap(URL(string: "https://api.figma.com/v1/"))

        let request = try endpoint.makeRequest(baseURL: baseURL)

        XCTAssertTrue(request.url?.query?.contains("depth=1") ?? false)
    }

    // MARK: - Response Parsing

    func testContentParsesFileMetadata() throws {
        let data = try FixtureLoader.loadData("FileMetadataResponse")

        let endpoint = FileMetadataEndpoint(fileId: "test")
        let metadata = try endpoint.content(from: nil, with: data)

        XCTAssertEqual(metadata.name, "Design System")
        XCTAssertEqual(metadata.version, "1234567890")
        XCTAssertEqual(metadata.lastModified, "2024-01-15T10:30:00Z")
        XCTAssertEqual(metadata.editorType, "figma")
        XCTAssertNotNil(metadata.thumbnailUrl)
    }

    func testContentParsesVersionCorrectly() throws {
        let data = try FixtureLoader.loadData("FileMetadataResponse")

        let endpoint = FileMetadataEndpoint(fileId: "test")
        let metadata = try endpoint.content(from: nil, with: data)

        // Version should be a string identifier
        XCTAssertFalse(metadata.version.isEmpty)
        XCTAssertEqual(metadata.version, "1234567890")
    }

    // MARK: - Error Handling

    func testContentThrowsOnInvalidJSON() {
        let invalidData = Data("invalid".utf8)
        let endpoint = FileMetadataEndpoint(fileId: "test")

        XCTAssertThrowsError(try endpoint.content(from: nil, with: invalidData))
    }

    func testContentThrowsFigmaErrorOnAPIError() {
        let errorJSON = """
        {
            "status": 404,
            "err": "Not found"
        }
        """
        let errorData = Data(errorJSON.utf8)
        let endpoint = FileMetadataEndpoint(fileId: "test")

        XCTAssertThrowsError(try endpoint.content(from: nil, with: errorData)) { error in
            XCTAssertTrue(error is FigmaClientError)
            if let figmaError = error as? FigmaClientError {
                XCTAssertEqual(figmaError.status, 404)
            }
        }
    }
}
