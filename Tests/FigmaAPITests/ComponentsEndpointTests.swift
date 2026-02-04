import CustomDump
@testable import FigmaAPI
import XCTest

final class ComponentsEndpointTests: XCTestCase {
    // MARK: - URL Construction

    func testMakeRequestConstructsCorrectURL() {
        let endpoint = ComponentsEndpoint(fileId: "abc123")
        let baseURL = URL(string: "https://api.figma.com/v1/")!

        let request = endpoint.makeRequest(baseURL: baseURL)

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://api.figma.com/v1/files/abc123/components"
        )
    }

    // MARK: - Response Parsing

    func testContentParsesComponentsResponse() throws {
        let response: ComponentsResponse = try FixtureLoader.load("ComponentsResponse")

        let endpoint = ComponentsEndpoint(fileId: "test")
        let components = endpoint.content(from: response)

        XCTAssertEqual(components.count, 4)

        // Check first icon component
        let arrowRight = components[0]
        XCTAssertEqual(arrowRight.name, "Icons/24/arrow_right")
        XCTAssertEqual(arrowRight.nodeId, "10:1")
        XCTAssertEqual(arrowRight.description, "Arrow pointing right")
        XCTAssertEqual(arrowRight.containingFrame.pageName, Optional("Components"))
        XCTAssertEqual(arrowRight.containingFrame.name, "Icons")
    }

    func testContentParsesComponentWithEmptyDescription() throws {
        let response: ComponentsResponse = try FixtureLoader.load("ComponentsResponse")

        let endpoint = ComponentsEndpoint(fileId: "test")
        let components = endpoint.content(from: response)

        let arrowLeft = components[1]
        XCTAssertEqual(arrowLeft.name, "Icons/24/arrow_left")
        XCTAssertEqual(arrowLeft.description, "")
    }

    func testContentParsesImageComponent() throws {
        let response: ComponentsResponse = try FixtureLoader.load("ComponentsResponse")

        let endpoint = ComponentsEndpoint(fileId: "test")
        let components = endpoint.content(from: response)

        let heroBanner = components[3]
        XCTAssertEqual(heroBanner.name, "Images/hero_banner")
        XCTAssertEqual(heroBanner.containingFrame.pageName, Optional("Assets"))
    }

    func testContentFromResponseWithBody() throws {
        let data = try FixtureLoader.loadData("ComponentsResponse")

        let endpoint = ComponentsEndpoint(fileId: "test")
        let components = try endpoint.content(from: nil, with: data)

        XCTAssertEqual(components.count, 4)
    }

    // MARK: - Error Handling

    func testContentThrowsOnInvalidJSON() {
        let invalidData = Data("invalid".utf8)
        let endpoint = ComponentsEndpoint(fileId: "test")

        XCTAssertThrowsError(try endpoint.content(from: nil, with: invalidData))
    }
}
