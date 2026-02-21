@testable import FigmaAPI
import Foundation
#if os(Linux)
    import FoundationNetworking
#endif
import XCTest

/// Tests that endpoint `makeRequest` properly throws instead of crashing
/// when URLComponents cannot produce a valid URL.
final class EndpointMakeRequestTests: XCTestCase {
    // MARK: - Valid Base URL (happy path)

    func testImageEndpointMakeRequestSucceeds() throws {
        // swiftlint:disable:next force_unwrapping
        let baseURL = try XCTUnwrap(URL(string: "https://api.figma.com/v1"))
        let endpoint = ImageEndpoint(fileId: "abc123", nodeIds: ["1:2"], params: SVGParams())

        let request = try endpoint.makeRequest(baseURL: baseURL)

        XCTAssertNotNil(request.url)
        XCTAssertTrue(request.url?.absoluteString.contains("abc123") ?? false)
    }

    func testNodesEndpointMakeRequestSucceeds() throws {
        // swiftlint:disable:next force_unwrapping
        let baseURL = try XCTUnwrap(URL(string: "https://api.figma.com/v1"))
        let endpoint = NodesEndpoint(fileId: "abc123", nodeIds: ["1:2", "3:4"])

        let request = try endpoint.makeRequest(baseURL: baseURL)

        XCTAssertNotNil(request.url)
        XCTAssertTrue(request.url?.absoluteString.contains("nodes") ?? false)
    }

    func testFileMetadataEndpointMakeRequestSucceeds() throws {
        // swiftlint:disable:next force_unwrapping
        let baseURL = try XCTUnwrap(URL(string: "https://api.figma.com/v1"))
        let endpoint = FileMetadataEndpoint(fileId: "abc123")

        let request = try endpoint.makeRequest(baseURL: baseURL)

        XCTAssertNotNil(request.url)
        XCTAssertTrue(request.url?.absoluteString.contains("depth=1") ?? false)
    }
}
