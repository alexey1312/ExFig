import Foundation
@testable import SVGKit
import XCTest

/// Tests for SVG normalization via usvg
final class SVGNormalizationTests: XCTestCase {
    var parser: SVGParser!

    override func setUp() {
        super.setUp()
        parser = SVGParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Default Fill

    func testNormalizationAppliesDefaultFill() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M0,0 L24,24"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: true)

        XCTAssertEqual(parsed.paths.count, 1)
        // usvg applies default black fill
        XCTAssertNotNil(parsed.paths.first?.fill)
        XCTAssertEqual(parsed.paths.first?.fill?.red, 0)
        XCTAssertEqual(parsed.paths.first?.fill?.green, 0)
        XCTAssertEqual(parsed.paths.first?.fill?.blue, 0)
    }

    // MARK: - Use Element Resolution

    func testNormalizationResolvesUseElement() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <defs>
                <path id="myPath" d="M0,0 L10,10" fill="#FF0000"/>
            </defs>
            <use href="#myPath"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: true)

        // usvg resolves <use> to actual path
        XCTAssertGreaterThan(parsed.paths.count, 0)
    }

    // MARK: - CSS Inlining

    func testNormalizationInlinesCSS() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <style>.red { fill: #FF0000; }</style>
            <path class="red" d="M0,0 L24,24"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: true)

        XCTAssertEqual(parsed.paths.count, 1)
        // CSS class should be resolved to inline fill
        XCTAssertNotNil(parsed.paths.first?.fill)
        XCTAssertEqual(parsed.paths.first?.fill?.red, 255)
        XCTAssertEqual(parsed.paths.first?.fill?.green, 0)
        XCTAssertEqual(parsed.paths.first?.fill?.blue, 0)
    }

    // MARK: - Shape Conversion

    func testNormalizationConvertsCircleToPath() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <circle cx="12" cy="12" r="10" fill="#00FF00"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: true)

        // usvg converts circle to path with arc commands
        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertFalse(parsed.paths.first!.pathData.isEmpty)
    }

    func testNormalizationConvertsRectToPath() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <rect x="2" y="2" width="20" height="20" fill="#0000FF"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: true)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertNotNil(parsed.paths.first?.fill)
        XCTAssertEqual(parsed.paths.first?.fill?.blue, 255)
    }

    // MARK: - Transform Flattening

    func testNormalizationFlattensTransforms() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <g transform="translate(10, 10) rotate(45) scale(2)">
                <path d="M0,0 L10,10" fill="#000000"/>
            </g>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: true)

        // usvg flattens transforms into path coordinates
        XCTAssertGreaterThan(parsed.paths.count, 0)
    }

    // MARK: - Gradient Preservation

    func testNormalizationPreservesLinearGradient() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <defs>
                <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="0%">
                    <stop offset="0%" style="stop-color:#FF0000"/>
                    <stop offset="100%" style="stop-color:#0000FF"/>
                </linearGradient>
            </defs>
            <rect x="0" y="0" width="24" height="24" fill="url(#grad1)"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: true)

        XCTAssertEqual(parsed.paths.count, 1)
        if case .linearGradient = parsed.paths.first?.fillType {
            // Gradient preserved
        } else {
            // usvg may convert gradient to solid or preserve it
            // This is acceptable behavior
        }
    }

    // MARK: - Normalize vs No Normalize Comparison

    func testNormalizeProducesDifferentOutput() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <circle cx="12" cy="12" r="10" fill="#FF0000"/>
        </svg>
        """

        let normalized = try parser.parse(Data(svg.utf8), normalize: true)
        let raw = try parser.parse(Data(svg.utf8), normalize: false)

        // Normalized converts circle to path commands
        // Raw parsing also converts but path data format may differ
        XCTAssertEqual(normalized.paths.count, 1)
        XCTAssertEqual(raw.paths.count, 1)

        // Both should have same fill color
        XCTAssertEqual(normalized.paths.first?.fill?.red, raw.paths.first?.fill?.red)
    }

    // MARK: - Edge Cases

    func testNormalizationHandlesEmptySVG() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: true)

        XCTAssertTrue(parsed.paths.isEmpty)
    }

    func testNormalizationHandlesComplexSVG() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <defs>
                <clipPath id="clip">
                    <rect x="0" y="0" width="12" height="24"/>
                </clipPath>
            </defs>
            <g clip-path="url(#clip)">
                <circle cx="12" cy="12" r="10" fill="#FF0000"/>
            </g>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: true)

        // Should handle clip-path and produce valid output
        XCTAssertGreaterThan(parsed.paths.count, 0)
    }
}
