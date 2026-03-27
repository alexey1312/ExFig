@testable import ExFigCLI
import XCTest

final class SVGColorReplacerTests: XCTestCase {
    // MARK: - Basic Replacement

    func testReplacesHexInFillAttribute() {
        let svg = "<rect fill=\"#ff0000\" />"
        let result = SVGColorReplacer.replaceColors(in: svg, colorMap: ["ff0000": "00ff00"])
        XCTAssertEqual(result, "<rect fill=\"#00ff00\" />")
    }

    func testReplacesHexInStrokeAttribute() {
        let svg = "<path stroke=\"#aabbcc\" />"
        let result = SVGColorReplacer.replaceColors(in: svg, colorMap: ["aabbcc": "112233"])
        XCTAssertEqual(result, "<path stroke=\"#112233\" />")
    }

    func testReplacesHexInStopColorAttribute() {
        let svg = "<stop stop-color=\"#ff00ff\" />"
        let result = SVGColorReplacer.replaceColors(in: svg, colorMap: ["ff00ff": "00ffff"])
        XCTAssertEqual(result, "<stop stop-color=\"#00ffff\" />")
    }

    // MARK: - Case Insensitive

    func testCaseInsensitiveMatch() {
        let svg = "<rect fill=\"#AABBCC\" />"
        let result = SVGColorReplacer.replaceColors(in: svg, colorMap: ["aabbcc": "112233"])
        XCTAssertEqual(result, "<rect fill=\"#112233\" />")
    }

    // MARK: - CSS Style Properties

    func testReplacesCSSFillProperty() {
        let svg = "<rect style=\"fill:#ff0000;stroke:#00ff00\" />"
        let result = SVGColorReplacer.replaceColors(
            in: svg,
            colorMap: ["ff0000": "111111", "00ff00": "222222"]
        )
        XCTAssertTrue(result.contains("fill:#111111"))
        XCTAssertTrue(result.contains("stroke:#222222"))
    }

    // MARK: - Multiple Colors

    func testReplacesMultipleColors() {
        let svg = """
        <svg>
          <rect fill="#ff0000" />
          <circle fill="#00ff00" />
          <path stroke="#0000ff" />
        </svg>
        """
        let result = SVGColorReplacer.replaceColors(
            in: svg,
            colorMap: ["ff0000": "111111", "00ff00": "222222", "0000ff": "333333"]
        )
        XCTAssertTrue(result.contains("#111111"))
        XCTAssertTrue(result.contains("#222222"))
        XCTAssertTrue(result.contains("#333333"))
        XCTAssertFalse(result.contains("#ff0000"))
        XCTAssertFalse(result.contains("#00ff00"))
        XCTAssertFalse(result.contains("#0000ff"))
    }

    // MARK: - No Match

    func testEmptyColorMapReturnsOriginal() {
        let svg = "<rect fill=\"#ff0000\" />"
        let result = SVGColorReplacer.replaceColors(in: svg, colorMap: [:])
        XCTAssertEqual(result, svg)
    }

    func testNoMatchingColorsReturnsOriginal() {
        let svg = "<rect fill=\"#ff0000\" />"
        let result = SVGColorReplacer.replaceColors(in: svg, colorMap: ["aabbcc": "112233"])
        XCTAssertEqual(result, svg)
    }

    // MARK: - Color Normalization

    func testNormalizeColorFromRGBA() {
        XCTAssertEqual(SVGColorReplacer.normalizeColor(r: 1.0, g: 0.0, b: 0.0), "ff0000")
        XCTAssertEqual(SVGColorReplacer.normalizeColor(r: 0.0, g: 1.0, b: 0.0), "00ff00")
        XCTAssertEqual(SVGColorReplacer.normalizeColor(r: 0.0, g: 0.0, b: 1.0), "0000ff")
        XCTAssertEqual(SVGColorReplacer.normalizeColor(r: 0.0, g: 0.0, b: 0.0), "000000")
        XCTAssertEqual(SVGColorReplacer.normalizeColor(r: 1.0, g: 1.0, b: 1.0), "ffffff")
    }

    func testNormalizeColorClampsValues() {
        XCTAssertEqual(SVGColorReplacer.normalizeColor(r: 1.5, g: -0.1, b: 0.5), "ff0080")
    }

    func testNormalizeColorFractionalValues() {
        // 0.2 * 255 = 51 = 0x33
        XCTAssertEqual(SVGColorReplacer.normalizeColor(r: 0.2, g: 0.2, b: 0.2), "333333")
    }
}
