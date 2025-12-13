// swiftlint:disable force_unwrapping
import WebExport
import XCTest

final class SVGToJSXConverterTests: XCTestCase {
    // MARK: - Basic Conversion Tests

    func testConvertSimpleSVG() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
          <path d="M12 2L2 22h20L12 2z" fill="#000"/>
        </svg>
        """
        let data = Data(svg.utf8)

        let result = try SVGToJSXConverter.convert(svgData: data)

        XCTAssertEqual(result.viewBox, "0 0 24 24")
        XCTAssertTrue(result.jsxContent.contains("M12 2L2 22h20L12 2z"))
    }

    func testConvertSVGWithoutViewBoxUsesWidthHeight() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32">
          <circle cx="16" cy="16" r="8" fill="red"/>
        </svg>
        """
        let data = Data(svg.utf8)

        let result = try SVGToJSXConverter.convert(svgData: data)

        XCTAssertEqual(result.viewBox, "0 0 32 32")
    }

    func testConvertSVGWithFractionalDimensions() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24.5" height="24.5">
          <rect x="0" y="0" width="24" height="24"/>
        </svg>
        """
        let data = Data(svg.utf8)

        let result = try SVGToJSXConverter.convert(svgData: data)

        XCTAssertEqual(result.viewBox, "0 0 24.5 24.5")
    }

    // MARK: - HTML to JSX Attribute Conversion Tests

    func testConvertFillRuleAttribute() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
          <path d="M0 0" fill-rule="evenodd"/>
        </svg>
        """
        let data = Data(svg.utf8)

        let result = try SVGToJSXConverter.convert(svgData: data)

        XCTAssertTrue(result.jsxContent.contains("fillRule=\"evenodd\""))
        XCTAssertFalse(result.jsxContent.contains("fill-rule"))
    }

    func testConvertStrokeAttributes() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
          <path d="M0 0" stroke-width="2" stroke-linecap="round" stroke-linejoin="bevel"/>
        </svg>
        """
        let data = Data(svg.utf8)

        let result = try SVGToJSXConverter.convert(svgData: data)

        XCTAssertTrue(result.jsxContent.contains("strokeWidth=\"2\""))
        XCTAssertTrue(result.jsxContent.contains("strokeLinecap=\"round\""))
        XCTAssertTrue(result.jsxContent.contains("strokeLinejoin=\"bevel\""))
    }

    func testConvertClipAttributes() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
          <g clip-path="url(#clip)" clip-rule="nonzero">
            <rect x="0" y="0" width="24" height="24"/>
          </g>
        </svg>
        """
        let data = Data(svg.utf8)

        let result = try SVGToJSXConverter.convert(svgData: data)

        XCTAssertTrue(result.jsxContent.contains("clipPath=\"url(#clip)\""))
        XCTAssertTrue(result.jsxContent.contains("clipRule=\"nonzero\""))
    }

    func testConvertClassToClassName() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
          <path d="M0 0" class="icon-path"/>
        </svg>
        """
        let data = Data(svg.utf8)

        let result = try SVGToJSXConverter.convert(svgData: data)

        XCTAssertTrue(result.jsxContent.contains("className=\"icon-path\""))
        XCTAssertFalse(result.jsxContent.contains("class="))
    }

    func testConvertMultipleAttributes() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
          <path d="M0 0" fill-rule="evenodd" fill-opacity="0.5" stroke-width="1"/>
        </svg>
        """
        let data = Data(svg.utf8)

        let result = try SVGToJSXConverter.convert(svgData: data)

        XCTAssertTrue(result.jsxContent.contains("fillRule=\"evenodd\""))
        XCTAssertTrue(result.jsxContent.contains("fillOpacity=\"0.5\""))
        XCTAssertTrue(result.jsxContent.contains("strokeWidth=\"1\""))
    }

    // MARK: - Complex SVG Tests

    func testConvertSVGWithNestedGroups() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
          <g fill-rule="evenodd">
            <g stroke-width="2">
              <path d="M0 0"/>
            </g>
          </g>
        </svg>
        """
        let data = Data(svg.utf8)

        let result = try SVGToJSXConverter.convert(svgData: data)

        XCTAssertTrue(result.jsxContent.contains("<g fillRule=\"evenodd\">"))
        XCTAssertTrue(result.jsxContent.contains("<g strokeWidth=\"2\">"))
    }

    func testConvertSVGWithDefs() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
          <defs>
            <linearGradient id="grad" stop-color="#fff" stop-opacity="1">
              <stop offset="0%"/>
            </linearGradient>
          </defs>
          <rect fill="url(#grad)"/>
        </svg>
        """
        let data = Data(svg.utf8)

        let result = try SVGToJSXConverter.convert(svgData: data)

        XCTAssertTrue(result.jsxContent.contains("stopColor=\"#fff\""))
        XCTAssertTrue(result.jsxContent.contains("stopOpacity=\"1\""))
    }

    func testConvertXlinkHref() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
          <defs>
            <symbol id="icon-base"/>
          </defs>
          <use xlink:href="#icon-base"/>
        </svg>
        """
        let data = Data(svg.utf8)

        let result = try SVGToJSXConverter.convert(svgData: data)

        XCTAssertTrue(result.jsxContent.contains("xlinkHref=\"#icon-base\""))
        XCTAssertFalse(result.jsxContent.contains("xlink:href"))
    }

    func testConvertXmlSpace() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
          <text xml:space="preserve">Hello</text>
        </svg>
        """
        let data = Data(svg.utf8)

        let result = try SVGToJSXConverter.convert(svgData: data)

        XCTAssertTrue(result.jsxContent.contains("xmlSpace=\"preserve\""))
        XCTAssertFalse(result.jsxContent.contains("xml:space"))
    }

    // MARK: - Error Cases

    func testInvalidUTF8ThrowsError() {
        let invalidData = Data([0xFF, 0xFE]) // Invalid UTF-8 sequence

        XCTAssertThrowsError(try SVGToJSXConverter.convert(svgData: invalidData)) { error in
            guard let svgError = error as? SVGToJSXError else {
                XCTFail("Expected SVGToJSXError")
                return
            }
            XCTAssertEqual(svgError, .invalidEncoding)
        }
    }

    func testMalformedSVGWithoutOpeningTag() {
        let svg = "<rect x=\"0\" y=\"0\"/>"
        let data = Data(svg.utf8)

        // Without <svg> tag, viewBox extraction fails first
        XCTAssertThrowsError(try SVGToJSXConverter.convert(svgData: data)) { error in
            guard let svgError = error as? SVGToJSXError else {
                XCTFail("Expected SVGToJSXError")
                return
            }
            XCTAssertEqual(svgError, .missingViewBox)
        }
    }

    func testMalformedSVGWithoutClosingTag() {
        let svg = "<svg viewBox=\"0 0 24 24\"><path d=\"M0 0\"/>"
        let data = Data(svg.utf8)

        XCTAssertThrowsError(try SVGToJSXConverter.convert(svgData: data)) { error in
            guard let svgError = error as? SVGToJSXError else {
                XCTFail("Expected SVGToJSXError")
                return
            }
            XCTAssertEqual(svgError, .malformedSVG)
        }
    }

    func testSVGWithoutViewBoxOrDimensions() {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg">
          <path d="M0 0"/>
        </svg>
        """
        let data = Data(svg.utf8)

        XCTAssertThrowsError(try SVGToJSXConverter.convert(svgData: data)) { error in
            guard let svgError = error as? SVGToJSXError else {
                XCTFail("Expected SVGToJSXError")
                return
            }
            XCTAssertEqual(svgError, .missingViewBox)
        }
    }

    // MARK: - Edge Cases

    func testEmptySVGContent() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
        </svg>
        """
        let data = Data(svg.utf8)

        let result = try SVGToJSXConverter.convert(svgData: data)

        XCTAssertEqual(result.viewBox, "0 0 24 24")
        XCTAssertEqual(result.jsxContent, "")
    }

    func testSVGWithWhitespaceOnly() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">

        </svg>
        """
        let data = Data(svg.utf8)

        let result = try SVGToJSXConverter.convert(svgData: data)

        XCTAssertEqual(result.jsxContent, "")
    }

    func testViewBoxWithDifferentQuotes() throws {
        let svg = """
        <svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'>
          <path d="M0 0"/>
        </svg>
        """
        let data = Data(svg.utf8)

        let result = try SVGToJSXConverter.convert(svgData: data)

        XCTAssertEqual(result.viewBox, "0 0 16 16")
    }
}
