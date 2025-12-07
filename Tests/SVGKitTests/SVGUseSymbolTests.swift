import Foundation
@testable import SVGKit
import XCTest

/// Tests for `<use>` and `<symbol>` SVG element support
final class SVGUseSymbolTests: XCTestCase {
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

    // MARK: - Basic <use> Resolution

    func testBasicUseHrefResolvesToReferencedPath() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <defs>
                <path id="myPath" d="M0,0 L10,10" fill="#FF0000"/>
            </defs>
            <use href="#myPath"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1, "Should resolve <use> to the referenced path")
        XCTAssertEqual(parsed.paths[0].pathData, "M0,0 L10,10")
        XCTAssertEqual(parsed.paths[0].fill?.red, 255)
    }

    func testSymbolInDefsIsResolved() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <defs>
                <symbol id="icon">
                    <path d="M5,5 L15,15" fill="#00FF00"/>
                </symbol>
            </defs>
            <use href="#icon"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1, "Should resolve <use> referencing <symbol>")
        XCTAssertEqual(parsed.paths[0].pathData, "M5,5 L15,15")
        XCTAssertEqual(parsed.paths[0].fill?.green, 255)
    }

    // MARK: - <use> with Position Offset

    func testUseWithXYAppliesTranslateOffset() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
            <defs>
                <rect id="box" x="0" y="0" width="10" height="10" fill="#0000FF"/>
            </defs>
            <use href="#box" x="10" y="20"/>
        </svg>
        """

        let parsed = try parse(svg)

        // The <use> with x/y should create a group with translate transform
        XCTAssertNotNil(parsed.groups, "Should have groups when <use> has x/y offset")
        XCTAssertEqual(parsed.groups?.count, 1)

        let group = parsed.groups?[0]
        XCTAssertEqual(group?.transform?.translateX, 10)
        XCTAssertEqual(group?.transform?.translateY, 20)
    }

    // MARK: - Nested <use> References

    func testNestedUseReferencesWithDepthLimit() throws {
        // Create SVG with nested <use> references
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <defs>
                <path id="base" d="M0,0 L5,5" fill="#000000"/>
                <g id="level1"><use href="#base"/></g>
                <g id="level2"><use href="#level1"/></g>
            </defs>
            <use href="#level2"/>
        </svg>
        """

        let parsed = try parse(svg)

        // Should resolve nested references up to depth limit
        XCTAssertGreaterThanOrEqual(parsed.paths.count, 1, "Should resolve nested <use> references")
    }

    func testDeeplyNestedUseStopsAtDepthLimit() throws {
        // Create SVG with very deep nesting that should be limited
        // This tests that we don't infinite loop or crash
        var defsContent = "<path id=\"p0\" d=\"M0,0 L1,1\" fill=\"#000\"/>"
        for i in 1 ... 15 {
            defsContent += "<g id=\"g\(i)\"><use href=\"#\(i == 1 ? "p0" : "g\(i - 1)")\"/></g>"
        }

        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <defs>\(defsContent)</defs>
            <use href="#g15"/>
        </svg>
        """

        // Should not crash and should return something (possibly empty due to depth limit)
        let parsed = try parse(svg)
        // Just verify it doesn't crash - the exact behavior depends on depth limit
        XCTAssertNotNil(parsed)
    }

    // MARK: - Missing Reference Handling

    func testMissingReferenceSkipsGracefully() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <use href="#nonexistent"/>
            <path d="M0,0 L10,10" fill="#FF0000"/>
        </svg>
        """

        let parsed = try parse(svg)

        // Should skip the missing reference but still parse other elements
        XCTAssertEqual(parsed.paths.count, 1, "Should skip missing reference and parse other paths")
        XCTAssertEqual(parsed.paths[0].pathData, "M0,0 L10,10")
    }

    func testEmptyHrefSkipsGracefully() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <use href=""/>
            <path d="M5,5 L15,15" fill="#00FF00"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1, "Should skip empty href and parse other paths")
    }

    // MARK: - Legacy xlink:href Support

    func testXlinkHrefLegacySyntax() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
             width="24" height="24" viewBox="0 0 24 24">
            <defs>
                <circle id="dot" cx="5" cy="5" r="3" fill="#FF00FF"/>
            </defs>
            <use xlink:href="#dot"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1, "Should support xlink:href legacy syntax")
    }

    // MARK: - <use> with Transform

    func testUseWithTransformAttribute() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <defs>
                <path id="arrow" d="M0,0 L10,5 L0,10" fill="#000000"/>
            </defs>
            <use href="#arrow" transform="rotate(90)"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertNotNil(parsed.groups, "Should create group for <use> with transform")
        XCTAssertEqual(parsed.groups?[0].transform?.rotation, 90)
    }

    // MARK: - Multiple <use> of Same Element

    func testMultipleUsesOfSameElement() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="48" height="24" viewBox="0 0 48 24">
            <defs>
                <rect id="block" width="10" height="10" fill="#0000FF"/>
            </defs>
            <use href="#block" x="0" y="0"/>
            <use href="#block" x="15" y="0"/>
            <use href="#block" x="30" y="0"/>
        </svg>
        """

        let parsed = try parse(svg)

        // Each <use> should create its own copy
        XCTAssertEqual(parsed.groups?.count, 3, "Should create 3 instances from 3 <use> elements")
    }

    // MARK: - <symbol> with viewBox

    func testSymbolWithViewBox() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
            <defs>
                <symbol id="scaledIcon" viewBox="0 0 24 24">
                    <path d="M0,0 L24,24" fill="#FF0000"/>
                </symbol>
            </defs>
            <use href="#scaledIcon" width="48" height="48"/>
        </svg>
        """

        let parsed = try parse(svg)

        // Should parse the symbol content
        XCTAssertGreaterThanOrEqual(parsed.paths.count, 1, "Should parse <symbol> content")
    }

    // MARK: - <use> Outside <defs>

    func testUseReferencingElementOutsideDefs() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path id="original" d="M0,0 L12,12" fill="#AABBCC"/>
            <use href="#original" x="12" y="0"/>
        </svg>
        """

        let parsed = try parse(svg)

        // Should have original path + use copy
        XCTAssertGreaterThanOrEqual(parsed.paths.count, 1, "Should find original path")
        // The <use> should also create something (either path or group)
    }

    // MARK: - Style Inheritance

    func testUseInheritsStyleFromReferencedElement() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <defs>
                <path id="styled" d="M0,0 L10,10" fill="#123456" stroke="#654321" stroke-width="2"/>
            </defs>
            <use href="#styled"/>
        </svg>
        """

        let parsed = try parse(svg)

        XCTAssertEqual(parsed.paths.count, 1)
        let path = parsed.paths[0]
        XCTAssertEqual(path.fill?.red, 0x12)
        XCTAssertEqual(path.fill?.green, 0x34)
        XCTAssertEqual(path.fill?.blue, 0x56)
        XCTAssertEqual(path.stroke?.red, 0x65)
        XCTAssertEqual(path.strokeWidth, 2)
    }
}
