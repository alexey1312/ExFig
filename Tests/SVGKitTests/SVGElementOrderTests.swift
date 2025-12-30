import Foundation
@testable import SVGKit
import XCTest

/// Tests for SVG element order preservation in parsing and generation.
/// Ensures paths and groups maintain their document order (z-order).
final class SVGElementOrderTests: XCTestCase {
    var parser: SVGParser!
    let vectorGenerator = VectorDrawableXMLGenerator()

    override func setUp() {
        super.setUp()
        parser = SVGParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Root Level Order

    func testRootElementOrderPreserved() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M0 0h24v24H0z" fill="#FF0000"/>
            <g>
                <path d="M4 4h16v16H4z" fill="#00FF00"/>
            </g>
            <path d="M8 8h8v8H8z" fill="#0000FF"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        XCTAssertEqual(parsed.elements.count, 3, "Should have 3 root elements")

        if case let .path(path1) = parsed.elements[0] {
            XCTAssertEqual(path1.fill?.red, 255, "First element should be red path")
        } else {
            XCTFail("First element should be a path")
        }

        if case .group = parsed.elements[1] {
            // OK
        } else {
            XCTFail("Second element should be a group")
        }

        if case let .path(path3) = parsed.elements[2] {
            XCTAssertEqual(path3.fill?.blue, 255, "Third element should be blue path")
        } else {
            XCTFail("Third element should be a path")
        }
    }

    func testVectorDrawableOutputOrder() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M0 0h24v24H0z" fill="#FF0000"/>
            <g>
                <path d="M4 4h16v16H4z" fill="#00FF00"/>
            </g>
            <path d="M8 8h8v8H8z" fill="#0000FF"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)
        let xml = vectorGenerator.generate(from: parsed)

        let redIndex = xml.range(of: "#FF0000")?.lowerBound
        let groupIndex = xml.range(of: "<group>")?.lowerBound
        let blueIndex = xml.range(of: "#0000FF")?.lowerBound

        XCTAssertNotNil(redIndex)
        XCTAssertNotNil(groupIndex)
        XCTAssertNotNil(blueIndex)
        XCTAssertTrue(redIndex! < groupIndex!, "Red path should come before group")
        XCTAssertTrue(groupIndex! < blueIndex!, "Group should come before blue path")
    }

    // MARK: - Group Level Order

    func testGroupElementsOrderPreserved() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <g>
                <path d="M0 0h12v12H0z" fill="#FF0000"/>
                <g>
                    <path d="M2 2h8v8H2z" fill="#00FF00"/>
                </g>
                <path d="M4 4h4v4H4z" fill="#0000FF"/>
            </g>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        XCTAssertEqual(parsed.groups?.count, 1)
        let group = parsed.groups![0]
        XCTAssertEqual(group.elements.count, 3, "Group should have 3 elements")

        if case let .path(path1) = group.elements[0] {
            XCTAssertEqual(path1.fill?.red, 255)
        } else {
            XCTFail("First group element should be red path")
        }

        if case .group = group.elements[1] {
            // OK - nested group
        } else {
            XCTFail("Second group element should be nested group")
        }

        if case let .path(path3) = group.elements[2] {
            XCTAssertEqual(path3.fill?.blue, 255)
        } else {
            XCTFail("Third group element should be blue path")
        }
    }

    // MARK: - Flag Layer Order

    func testFlagBackgroundBeforeForeground() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <g>
                <path d="M0 4h24v20H0z" fill="#4189DD"/>
            </g>
            <path d="M4 7l2-1 2 1 2-1 2 1" fill="#F9D616"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)
        let xml = vectorGenerator.generate(from: parsed)

        let blueIndex = xml.range(of: "#4189DD")?.lowerBound
        let yellowIndex = xml.range(of: "#F9D616")?.lowerBound

        XCTAssertNotNil(blueIndex, "Blue background should be in output")
        XCTAssertNotNil(yellowIndex, "Yellow foreground should be in output")
        XCTAssertTrue(blueIndex! < yellowIndex!, "Background should come before foreground")
    }

    func testElementsInDocumentOrder() throws {
        // Two groups should maintain their order
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <g>
                <path d="M4 7l2-1 2 1" fill="#D21034"/>
            </g>
            <g>
                <path d="M0 4h24v20H0z" fill="#4189DD"/>
            </g>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)
        let xml = vectorGenerator.generate(from: parsed)

        let redIndex = xml.range(of: "#D21034")?.lowerBound
        let blueIndex = xml.range(of: "#4189DD")?.lowerBound

        XCTAssertNotNil(redIndex)
        XCTAssertNotNil(blueIndex)
        XCTAssertTrue(redIndex! < blueIndex!, "Elements should maintain SVG document order")
    }
}
