import CustomDump
@testable import FigmaAPI
import XCTest

final class NodesEndpointTests: XCTestCase {
    // MARK: - URL Construction

    func testMakeRequestConstructsCorrectURL() throws {
        let endpoint = NodesEndpoint(fileId: "abc123", nodeIds: ["1:2", "1:3"])
        let baseURL = try XCTUnwrap(URL(string: "https://api.figma.com/v1/"))

        let request = endpoint.makeRequest(baseURL: baseURL)

        XCTAssertTrue(request.url?.absoluteString.contains("files/abc123/nodes") ?? false)
        XCTAssertTrue(request.url?.absoluteString.contains("ids=1:2,1:3") ?? false)
    }

    func testMakeRequestWithSingleNodeId() throws {
        let endpoint = NodesEndpoint(fileId: "file123", nodeIds: ["10:5"])
        let baseURL = try XCTUnwrap(URL(string: "https://api.figma.com/v1/"))

        let request = endpoint.makeRequest(baseURL: baseURL)

        XCTAssertTrue(request.url?.absoluteString.contains("ids=10:5") ?? false)
    }

    func testMakeRequestWithManyNodeIds() throws {
        let nodeIds = (1 ... 100).map { "1:\($0)" }
        let endpoint = NodesEndpoint(fileId: "file123", nodeIds: nodeIds)
        let baseURL = try XCTUnwrap(URL(string: "https://api.figma.com/v1/"))

        let request = endpoint.makeRequest(baseURL: baseURL)

        // All node IDs should be joined with commas
        let url = request.url?.absoluteString ?? ""
        XCTAssertTrue(url.contains("1:1,1:2"))
        XCTAssertTrue(url.contains("1:99,1:100"))
    }

    // MARK: - Response Parsing

    func testContentParsesNodesResponse() throws {
        let response: NodesResponse = try FixtureLoader.load("NodesResponse")

        let endpoint = NodesEndpoint(fileId: "test", nodeIds: [])
        let nodes = endpoint.content(from: response)

        XCTAssertEqual(nodes.count, 5)

        // Check color node
        let colorNode = nodes["1:2"]
        XCTAssertNotNil(colorNode)
        XCTAssertEqual(colorNode?.document.name, "primary/background")
        XCTAssertEqual(colorNode?.document.fills.count, 1)

        let fill = colorNode?.document.fills[0]
        XCTAssertEqual(fill?.type, .solid)
        XCTAssertEqual(fill?.color?.r, 1.0)
        XCTAssertEqual(fill?.color?.g, 1.0)
        XCTAssertEqual(fill?.color?.b, 1.0)
    }

    func testContentParsesTextStyleNode() throws {
        let response: NodesResponse = try FixtureLoader.load("NodesResponse")

        let endpoint = NodesEndpoint(fileId: "test", nodeIds: [])
        let nodes = endpoint.content(from: response)

        let textNode = nodes["2:1"]
        XCTAssertNotNil(textNode)

        let style = textNode?.document.style
        XCTAssertNotNil(style)
        XCTAssertEqual(style?.fontFamily, "Inter")
        XCTAssertEqual(style?.fontWeight, 700)
        XCTAssertEqual(style?.fontSize, 32.0)
        XCTAssertEqual(style?.lineHeightPx, 40.0)
        XCTAssertEqual(style?.letterSpacing, -0.5)
        XCTAssertEqual(style?.lineHeightUnit, .pixels)
    }

    func testContentFromResponseWithBody() throws {
        let data = try FixtureLoader.loadData("NodesResponse")

        let endpoint = NodesEndpoint(fileId: "test", nodeIds: [])
        let nodes = try endpoint.content(from: nil, with: data)

        XCTAssertEqual(nodes.count, 5)
    }

    // MARK: - Paint Parsing

    func testSolidPaintExtraction() throws {
        let response: NodesResponse = try FixtureLoader.load("NodesResponse")

        let endpoint = NodesEndpoint(fileId: "test", nodeIds: [])
        let nodes = endpoint.content(from: response)

        let node = nodes["1:4"]
        let paint = node?.document.fills.first
        let solidPaint = paint?.asSolid

        XCTAssertNotNil(solidPaint)
        XCTAssertEqual(solidPaint?.opacity, 0.8)
        XCTAssertEqual(solidPaint?.color.r, 0.2)
    }

    func testNonSolidPaintReturnsNil() {
        let paint = Paint(type: .gradientLinear, blendMode: nil, opacity: 1.0, color: nil, gradientStops: nil)
        XCTAssertNil(paint.asSolid)
    }

    // MARK: - Error Handling

    func testContentThrowsOnInvalidJSON() {
        let invalidData = Data("not json".utf8)
        let endpoint = NodesEndpoint(fileId: "test", nodeIds: [])

        XCTAssertThrowsError(try endpoint.content(from: nil, with: invalidData))
    }
}
