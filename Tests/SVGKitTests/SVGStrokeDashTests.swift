import Foundation
@testable import SVGKit
import XCTest

/// Tests for `stroke-dasharray` and `stroke-dashoffset` support
final class SVGStrokeDashTests: XCTestCase {
    var parser: SVGParser!

    override func setUp() {
        super.setUp()
        parser = SVGParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Helper

    private func parse(_ svg: String) throws -> ParsedSVG {
        try parser.parse(Data(svg.utf8), normalize: false)
    }

    // MARK: - stroke-dasharray Parsing Tests

    func testStrokeDashArrayCommaSeparated() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path d="M0,0 L10,10" stroke="#000000" stroke-dasharray="5,3" fill="none"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].strokeDashArray, [5.0, 3.0])
    }

    func testStrokeDashArraySpaceSeparated() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path d="M0,0 L10,10" stroke="#000000" stroke-dasharray="5 3 2" fill="none"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].strokeDashArray, [5.0, 3.0, 2.0])
    }

    func testStrokeDashArrayMixedSeparators() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path d="M0,0 L10,10" stroke="#000000" stroke-dasharray="10, 5, 2" fill="none"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].strokeDashArray, [10.0, 5.0, 2.0])
    }

    func testStrokeDashArraySingleValue() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path d="M0,0 L10,10" stroke="#000000" stroke-dasharray="5" fill="none"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].strokeDashArray, [5.0])
    }

    func testStrokeDashArrayDecimalValues() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path d="M0,0 L10,10" stroke="#000000" stroke-dasharray="5.5,3.2,1.8" fill="none"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].strokeDashArray, [5.5, 3.2, 1.8])
    }

    // MARK: - stroke-dashoffset Parsing Tests

    func testStrokeDashOffset() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path d="M0,0 L10,10" stroke="#000000" stroke-dasharray="5,3" stroke-dashoffset="2" fill="none"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].strokeDashOffset, 2.0)
    }

    func testStrokeDashOffsetDecimal() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path d="M0,0 L10,10" stroke="#000000" stroke-dasharray="5,3" stroke-dashoffset="1.5" fill="none"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].strokeDashOffset, 1.5)
    }

    func testStrokeDashOffsetNegative() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path d="M0,0 L10,10" stroke="#000000" stroke-dasharray="5,3" stroke-dashoffset="-2" fill="none"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].strokeDashOffset, -2.0)
    }

    // MARK: - Edge Cases

    func testEmptyStrokeDashArray() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path d="M0,0 L10,10" stroke="#000000" stroke-dasharray="" fill="none"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertNil(parsed.paths[0].strokeDashArray)
    }

    func testNoneStrokeDashArray() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path d="M0,0 L10,10" stroke="#000000" stroke-dasharray="none" fill="none"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertNil(parsed.paths[0].strokeDashArray)
    }

    func testNoStrokeDashArray() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path d="M0,0 L10,10" stroke="#000000" fill="none"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertNil(parsed.paths[0].strokeDashArray)
        XCTAssertNil(parsed.paths[0].strokeDashOffset)
    }

    // MARK: - CSS Style Tests

    func testStrokeDashArrayFromCSS() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <style>
                .dashed { stroke-dasharray: 4,2; stroke-dashoffset: 1; }
            </style>
            <path class="dashed" d="M0,0 L10,10" stroke="#000000" fill="none"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].strokeDashArray, [4.0, 2.0])
        XCTAssertEqual(parsed.paths[0].strokeDashOffset, 1.0)
    }

    func testStrokeDashArrayFromInlineStyle() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path d="M0,0 L10,10" stroke="#000000" style="stroke-dasharray: 6,3; stroke-dashoffset: 2" fill="none"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].strokeDashArray, [6.0, 3.0])
        XCTAssertEqual(parsed.paths[0].strokeDashOffset, 2.0)
    }

    // MARK: - Inheritance Tests

    func testStrokeDashArrayInheritedFromGroup() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <g stroke-dasharray="3,1" stroke-dashoffset="0.5">
                <path d="M0,0 L10,10" stroke="#000000" fill="none"/>
            </g>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].strokeDashArray, [3.0, 1.0])
        XCTAssertEqual(parsed.paths[0].strokeDashOffset, 0.5)
    }

    // MARK: - Shape Element Tests

    func testStrokeDashArrayOnRect() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <rect x="2" y="2" width="20" height="20" stroke="#000000" stroke-dasharray="5,5" fill="none"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].strokeDashArray, [5.0, 5.0])
    }

    func testStrokeDashArrayOnCircle() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <circle cx="12" cy="12" r="10" stroke="#000000" stroke-dasharray="3,2" fill="none"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].strokeDashArray, [3.0, 2.0])
    }
}
