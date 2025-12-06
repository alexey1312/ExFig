// swiftlint:disable file_length
import CustomDump
import Foundation
@testable import SVGKit
import XCTest

final class SVGParserTests: XCTestCase {
    var parser: SVGParser!

    override func setUp() {
        super.setUp()
        parser = SVGParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Basic SVG Parsing

    func testParseSimpleSVG() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12,4 L12,20" fill="none" stroke="#000000"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.width, 24)
        XCTAssertEqual(parsed.height, 24)
        XCTAssertEqual(parsed.viewportWidth, 24)
        XCTAssertEqual(parsed.viewportHeight, 24)
        XCTAssertEqual(parsed.paths.count, 1)
    }

    func testParseSVGWithViewBoxOnly() throws {
        let svg = """
        <svg viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
            <path d="M24,12 L24,36"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.width, 48)
        XCTAssertEqual(parsed.height, 48)
        XCTAssertEqual(parsed.viewportWidth, 48)
        XCTAssertEqual(parsed.viewportHeight, 48)
    }

    func testParseSVGWithDimensionsNoViewBox() throws {
        let svg = """
        <svg width="32" height="32" xmlns="http://www.w3.org/2000/svg">
            <path d="M16,8 L16,24"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.width, 32)
        XCTAssertEqual(parsed.height, 32)
        XCTAssertEqual(parsed.viewportWidth, 32)
        XCTAssertEqual(parsed.viewportHeight, 32)
    }

    func testParseSVGWithPixelUnits() throws {
        let svg = """
        <svg width="24px" height="24px" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12,4 L12,20"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.width, 24)
        XCTAssertEqual(parsed.height, 24)
    }

    // MARK: - Path Attributes

    func testParsePathWithFill() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12,4 L12,20" fill="#FF0000"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertNotNil(parsed.paths[0].fill)
        XCTAssertEqual(parsed.paths[0].fill?.red, 255)
        XCTAssertEqual(parsed.paths[0].fill?.green, 0)
        XCTAssertEqual(parsed.paths[0].fill?.blue, 0)
    }

    func testParsePathWithStroke() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12,4 L12,20" fill="none" stroke="#00FF00" stroke-width="2"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertNil(parsed.paths[0].fill)
        XCTAssertNotNil(parsed.paths[0].stroke)
        XCTAssertEqual(parsed.paths[0].stroke?.red, 0)
        XCTAssertEqual(parsed.paths[0].stroke?.green, 255)
        XCTAssertEqual(parsed.paths[0].stroke?.blue, 0)
        XCTAssertEqual(parsed.paths[0].strokeWidth, 2)
    }

    func testParsePathWithStrokeLineCap() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12,4 L12,20" stroke="#000000" stroke-linecap="round"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.paths[0].strokeLineCap, .round)
    }

    func testParsePathWithStrokeLineJoin() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12,4 L20,12 L12,20" stroke="#000000" stroke-linejoin="bevel"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.paths[0].strokeLineJoin, .bevel)
    }

    func testParsePathWithFillRule() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12,4 L12,20" fill="#000000" fill-rule="evenodd"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.paths[0].fillRule, .evenOdd)
    }

    func testParsePathWithOpacity() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12,4 L12,20" fill="#000000" opacity="0.5"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.paths[0].opacity, 0.5)
    }

    // MARK: - Style Attribute

    func testParsePathWithStyleAttribute() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12,4 L12,20" style="fill:#FF0000;stroke:#00FF00;stroke-width:2"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.paths[0].fill?.red, 255)
        XCTAssertEqual(parsed.paths[0].stroke?.green, 255)
        XCTAssertEqual(parsed.paths[0].strokeWidth, 2)
    }

    // MARK: - Shape Conversion

    func testParseRectElement() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <rect x="4" y="4" width="16" height="16" fill="#000000"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertFalse(parsed.paths[0].pathData.isEmpty)
    }

    func testParseCircleElement() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <circle cx="12" cy="12" r="8" fill="#000000"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertFalse(parsed.paths[0].pathData.isEmpty)
    }

    func testParseEllipseElement() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <ellipse cx="12" cy="12" rx="8" ry="4" fill="#000000"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertFalse(parsed.paths[0].pathData.isEmpty)
    }

    func testParseLineElement() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <line x1="4" y1="4" x2="20" y2="20" stroke="#000000"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertTrue(parsed.paths[0].pathData.contains("M4.0,4.0"))
        XCTAssertTrue(parsed.paths[0].pathData.contains("L20.0,20.0"))
    }

    func testParsePolygonElement() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <polygon points="12,4 20,20 4,20" fill="#000000"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertTrue(parsed.paths[0].pathData.hasSuffix("Z"))
    }

    func testParsePolylineElement() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <polyline points="4,4 12,12 20,4" stroke="#000000" fill="none"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertFalse(parsed.paths[0].pathData.hasSuffix("Z"))
    }

    // MARK: - Nested Groups

    func testParseNestedGroups() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <g fill="#FF0000">
                <g stroke="#00FF00">
                    <path d="M12,4 L12,20"/>
                </g>
            </g>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].fill?.red, 255)
        XCTAssertEqual(parsed.paths[0].stroke?.green, 255)
    }

    func testParseMultiplePaths() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12,4 L12,20" fill="#FF0000"/>
            <path d="M4,12 L20,12" fill="#00FF00"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.paths.count, 2)
        XCTAssertEqual(parsed.paths[0].fill?.red, 255)
        XCTAssertEqual(parsed.paths[1].fill?.green, 255)
    }

    // MARK: - Error Cases

    func testParseInvalidSVGRoot() throws {
        let svg = """
        <html><body>Not an SVG</body></html>
        """
        let data = Data(svg.utf8)

        XCTAssertThrowsError(try parser.parse(data)) { error in
            XCTAssertEqual(error as? SVGParserError, .invalidSVGRoot)
        }
    }

    // MARK: - Real-World Icon

    func testParseRealWorldIcon() throws {
        // A Material Design-style checkmark icon
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41L9 16.17z" fill="#000000"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data)

        XCTAssertEqual(parsed.width, 24)
        XCTAssertEqual(parsed.height, 24)
        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertFalse(parsed.paths[0].commands.isEmpty)
    }
}

// MARK: - SVGColor Tests

final class SVGColorTests: XCTestCase {
    // MARK: - Hex Color Parsing

    func testParseHex6() {
        let color = SVGColor.parse("#FF0000")
        XCTAssertEqual(color?.red, 255)
        XCTAssertEqual(color?.green, 0)
        XCTAssertEqual(color?.blue, 0)
        XCTAssertEqual(color?.alpha, 1.0)
    }

    func testParseHex3() {
        let color = SVGColor.parse("#F00")
        XCTAssertEqual(color?.red, 255)
        XCTAssertEqual(color?.green, 0)
        XCTAssertEqual(color?.blue, 0)
    }

    func testParseHex8() {
        let color = SVGColor.parse("#FF000080")
        XCTAssertEqual(color?.red, 255)
        XCTAssertEqual(color?.green, 0)
        XCTAssertEqual(color?.blue, 0)
        XCTAssertEqual(color!.alpha, 128.0 / 255.0, accuracy: 0.01)
    }

    // MARK: - RGB Color Parsing

    func testParseRGB() {
        let color = SVGColor.parse("rgb(255, 128, 0)")
        XCTAssertEqual(color?.red, 255)
        XCTAssertEqual(color?.green, 128)
        XCTAssertEqual(color?.blue, 0)
        XCTAssertEqual(color?.alpha, 1.0)
    }

    func testParseRGBA() {
        let color = SVGColor.parse("rgba(255, 128, 0, 0.5)")
        XCTAssertEqual(color?.red, 255)
        XCTAssertEqual(color?.green, 128)
        XCTAssertEqual(color?.blue, 0)
        XCTAssertEqual(color?.alpha, 0.5)
    }

    // MARK: - Named Colors

    func testParseNamedColorBlack() {
        let color = SVGColor.parse("black")
        XCTAssertEqual(color?.red, 0)
        XCTAssertEqual(color?.green, 0)
        XCTAssertEqual(color?.blue, 0)
    }

    func testParseNamedColorWhite() {
        let color = SVGColor.parse("white")
        XCTAssertEqual(color?.red, 255)
        XCTAssertEqual(color?.green, 255)
        XCTAssertEqual(color?.blue, 255)
    }

    func testParseNamedColorTransparent() {
        let color = SVGColor.parse("transparent")
        XCTAssertEqual(color?.alpha, 0.0)
    }

    // MARK: - Special Values

    func testParseNone() {
        let color = SVGColor.parse("none")
        XCTAssertNil(color)
    }

    func testParseEmpty() {
        let color = SVGColor.parse("")
        XCTAssertNil(color)
    }

    func testParseCurrentColor() {
        let color = SVGColor.parse("currentColor")
        XCTAssertEqual(color?.red, 0)
        XCTAssertEqual(color?.green, 0)
        XCTAssertEqual(color?.blue, 0)
    }

    // MARK: - Compose Hex Output

    func testComposeHexOutput() {
        let color = SVGColor(red: 255, green: 128, blue: 0, alpha: 1.0)
        XCTAssertEqual(color.composeHex, "0xFFFF8000")
    }

    func testComposeHexOutputWithAlpha() {
        let color = SVGColor(red: 255, green: 0, blue: 0, alpha: 0.5)
        // 0.5 * 255 = 127.5 → UInt8 truncates to 127 → 0x7F
        XCTAssertEqual(color.composeHex, "0x7FFF0000")
    }
}
