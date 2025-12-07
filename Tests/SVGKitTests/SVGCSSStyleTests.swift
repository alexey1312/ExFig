import Foundation
@testable import SVGKit
import XCTest

/// Tests for CSS `<style>` block parsing in SVG
final class SVGCSSStyleTests: XCTestCase {
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
        try parser.parse(Data(svg.utf8))
    }

    // MARK: - Class Selector Tests

    func testClassSelectorAppliesFill() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <style>
                .icon { fill: #FF0000; }
            </style>
            <path class="icon" d="M0,0 L10,10"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].fill?.red, 255)
        XCTAssertEqual(parsed.paths[0].fill?.green, 0)
        XCTAssertEqual(parsed.paths[0].fill?.blue, 0)
    }

    func testClassSelectorAppliesStroke() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <style>
                .outline { stroke: #00FF00; stroke-width: 2; }
            </style>
            <path class="outline" d="M0,0 L10,10" fill="none"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].stroke?.green, 255)
        XCTAssertEqual(parsed.paths[0].strokeWidth, 2)
    }

    // MARK: - ID Selector Tests

    func testIdSelectorAppliesFill() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <style>
                #logo { fill: #0000FF; }
            </style>
            <rect id="logo" x="0" y="0" width="10" height="10"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].fill?.blue, 255)
    }

    // MARK: - Multiple Classes Tests

    func testMultipleClassesMergeStyles() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <style>
                .red { fill: #FF0000; }
                .thick { stroke-width: 3; }
            </style>
            <path class="red thick" d="M0,0 L10,10" stroke="#000000"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].fill?.red, 255)
        XCTAssertEqual(parsed.paths[0].strokeWidth, 3)
    }

    // MARK: - Specificity Tests

    func testInlineStyleOverridesCSS() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <style>
                .icon { fill: #FF0000; }
            </style>
            <path class="icon" d="M0,0 L10,10" fill="#00FF00"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        // Inline style should override CSS
        XCTAssertEqual(parsed.paths[0].fill?.green, 255)
        XCTAssertEqual(parsed.paths[0].fill?.red, 0)
    }

    func testInlineStyleAttributeOverridesCSS() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <style>
                .icon { fill: #FF0000; stroke: #0000FF; }
            </style>
            <path class="icon" d="M0,0 L10,10" style="fill: #00FF00"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        // Inline style attribute overrides CSS fill
        XCTAssertEqual(parsed.paths[0].fill?.green, 255)
        // CSS stroke should still apply
        XCTAssertEqual(parsed.paths[0].stroke?.blue, 255)
    }

    // MARK: - Multiple Rules Tests

    func testMultipleSelectorsInOneRule() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <style>
                .a, .b { fill: #FF0000; }
            </style>
            <path class="a" d="M0,0 L5,5"/>
            <path class="b" d="M5,5 L10,10"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 2)
        XCTAssertEqual(parsed.paths[0].fill?.red, 255)
        XCTAssertEqual(parsed.paths[1].fill?.red, 255)
    }

    // MARK: - Edge Cases

    func testEmptyStyleBlockNoError() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <style></style>
            <path d="M0,0 L10,10" fill="#FF0000"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].fill?.red, 255)
    }

    func testStyleInDefsSection() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <defs>
                <style>
                    .icon { fill: #FF0000; }
                </style>
            </defs>
            <path class="icon" d="M0,0 L10,10"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].fill?.red, 255)
    }

    func testCDATAWrappedStyle() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <style><![CDATA[
                .icon { fill: #FF0000; }
            ]]></style>
            <path class="icon" d="M0,0 L10,10"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].fill?.red, 255)
    }

    func testMalformedCSSSkippedGracefully() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <style>
                .icon { fill: #FF0000; stroke: }
                .valid { fill: #00FF00; }
            </style>
            <path class="valid" d="M0,0 L10,10"/>
        </svg>
        """

        let parsed = try parse(svg)

        // Should not crash, valid rule should still apply
        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].fill?.green, 255)
    }

    // MARK: - CSS Property Support Tests

    func testCSSFillOpacity() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <style>
                .semi { fill: #FF0000; opacity: 0.5; }
            </style>
            <path class="semi" d="M0,0 L10,10"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].fill?.red, 255)
        XCTAssertEqual(parsed.paths[0].opacity, 0.5)
    }

    func testCSSStrokeLinecap() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <style>
                .rounded { stroke: #000000; stroke-linecap: round; }
            </style>
            <path class="rounded" d="M0,0 L10,10" fill="none"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].strokeLineCap, .round)
    }

    func testCSSFillRule() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <style>
                .even { fill: #000000; fill-rule: evenodd; }
            </style>
            <path class="even" d="M0,0 L10,10 L0,10 Z"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].fillRule, .evenOdd)
    }

    // MARK: - Group Inheritance Tests

    func testCSSAppliedToGroup() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <style>
                .group-style { fill: #FF0000; }
            </style>
            <g class="group-style">
                <path d="M0,0 L10,10"/>
            </g>
        </svg>
        """

        let parsed = try parse(svg)

        // CSS on group should inherit to children
        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].fill?.red, 255)
    }
}
