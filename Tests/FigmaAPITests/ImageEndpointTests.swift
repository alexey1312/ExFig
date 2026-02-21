import CustomDump
@testable import FigmaAPI
import XCTest

final class ImageEndpointTests: XCTestCase {
    // MARK: - URL Construction

    func testMakeRequestWithPNGParams() throws {
        let params = PNGParams(scale: 2.0)
        let endpoint = ImageEndpoint(fileId: "abc123", nodeIds: ["1:2", "1:3"], params: params)
        let baseURL = try XCTUnwrap(URL(string: "https://api.figma.com/v1/"))

        let request = try endpoint.makeRequest(baseURL: baseURL)
        let url = request.url?.absoluteString ?? ""

        XCTAssertTrue(url.contains("images/abc123"))
        XCTAssertTrue(url.contains("format=png"))
        XCTAssertTrue(url.contains("scale=2.0"))
        XCTAssertTrue(url.contains("ids=1:2,1:3"))
    }

    func testMakeRequestWithSVGParams() throws {
        let params = SVGParams()
        params.svgIncludeId = true
        params.svgSimplifyStroke = true

        let endpoint = ImageEndpoint(fileId: "file123", nodeIds: ["10:1"], params: params)
        let baseURL = try XCTUnwrap(URL(string: "https://api.figma.com/v1/"))

        let request = try endpoint.makeRequest(baseURL: baseURL)
        let url = request.url?.absoluteString ?? ""

        XCTAssertTrue(url.contains("format=svg"))
        XCTAssertTrue(url.contains("svg_include_id=true"))
        XCTAssertTrue(url.contains("svg_simplify_stroke=true"))
    }

    func testMakeRequestWithPDFParams() throws {
        let params = PDFParams()
        let endpoint = ImageEndpoint(fileId: "file123", nodeIds: ["5:1"], params: params)
        let baseURL = try XCTUnwrap(URL(string: "https://api.figma.com/v1/"))

        let request = try endpoint.makeRequest(baseURL: baseURL)
        let url = request.url?.absoluteString ?? ""

        XCTAssertTrue(url.contains("format=pdf"))
        XCTAssertFalse(url.contains("scale="))
    }

    func testMakeRequestIncludesUseAbsoluteBounds() throws {
        let params = PNGParams(scale: 1.0)
        let endpoint = ImageEndpoint(fileId: "file123", nodeIds: ["1:1"], params: params)
        let baseURL = try XCTUnwrap(URL(string: "https://api.figma.com/v1/"))

        let request = try endpoint.makeRequest(baseURL: baseURL)
        let url = request.url?.absoluteString ?? ""

        XCTAssertTrue(url.contains("use_absolute_bounds=true"))
    }

    // MARK: - Response Parsing

    func testContentParsesImageResponse() throws {
        let response: ImageResponse = try FixtureLoader.load("ImageResponse")

        let endpoint = ImageEndpoint(fileId: "test", nodeIds: [], params: SVGParams())
        let images = endpoint.content(from: response)

        XCTAssertEqual(images.count, 4)
        XCTAssertNotNil(images["10:1"] as Any?)
        XCTAssertTrue(images["10:1"]??.contains("arrow_right.svg") ?? false)
    }

    func testContentFromResponseWithBody() throws {
        let data = try FixtureLoader.loadData("ImageResponse")

        let endpoint = ImageEndpoint(fileId: "test", nodeIds: [], params: SVGParams())
        let images = try endpoint.content(from: nil, with: data)

        XCTAssertEqual(images.count, 4)
    }

    // MARK: - FormatParams

    func testPNGParamsQueryItems() {
        let params = PNGParams(scale: 3.0)
        let items = params.queryItems

        XCTAssertTrue(items.contains { $0.name == "format" && $0.value == "png" })
        XCTAssertTrue(items.contains { $0.name == "scale" && $0.value == "3.0" })
    }

    func testSVGParamsDefaultValues() {
        let params = SVGParams()

        XCTAssertFalse(params.svgIncludeId)
        XCTAssertFalse(params.svgSimplifyStroke)
    }

    func testSVGParamsQueryItems() {
        let params = SVGParams()
        params.svgIncludeId = true
        let items = params.queryItems

        XCTAssertTrue(items.contains { $0.name == "svg_include_id" && $0.value == "true" })
    }

    // MARK: - Error Handling

    func testContentThrowsOnInvalidJSON() {
        let invalidData = Data("bad json".utf8)
        let endpoint = ImageEndpoint(fileId: "test", nodeIds: [], params: SVGParams())

        XCTAssertThrowsError(try endpoint.content(from: nil, with: invalidData))
    }
}
