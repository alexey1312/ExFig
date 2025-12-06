// swiftlint:disable file_length type_body_length
@testable import SVGKit
import XCTest

final class SVGGradientParsingTests: XCTestCase {
    private let parser = SVGParser()

    // MARK: - Linear Gradient Parsing Tests

    func testParseLinearGradientBasic() throws {
        let svg = """
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="grad1" x1="0" y1="0" x2="24" y2="24">
              <stop offset="0" stop-color="#FF0000"/>
              <stop offset="1" stop-color="#0000FF"/>
            </linearGradient>
          </defs>
          <rect fill="url(#grad1)" width="24" height="24"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))

        XCTAssertEqual(parsed.linearGradients.count, 1)

        let gradient = parsed.linearGradients["grad1"]
        XCTAssertNotNil(gradient)
        XCTAssertEqual(gradient?.x1, 0)
        XCTAssertEqual(gradient?.y1, 0)
        XCTAssertEqual(gradient?.x2, 24)
        XCTAssertEqual(gradient?.y2, 24)
        XCTAssertEqual(gradient?.stops.count, 2)
        XCTAssertEqual(gradient?.stops[0].color.red, 255)
        XCTAssertEqual(gradient?.stops[0].color.green, 0)
        XCTAssertEqual(gradient?.stops[0].color.blue, 0)
        XCTAssertEqual(gradient?.stops[1].color.red, 0)
        XCTAssertEqual(gradient?.stops[1].color.green, 0)
        XCTAssertEqual(gradient?.stops[1].color.blue, 255)
    }

    func testParseLinearGradientPercentageCoords() throws {
        let svg = """
        <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stop-color="#000000"/>
              <stop offset="100%" stop-color="#FFFFFF"/>
            </linearGradient>
          </defs>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))
        let gradient = parsed.linearGradients["grad1"]

        // Percentages should be converted to viewport coordinates
        XCTAssertEqual(gradient?.x1, 0)
        XCTAssertEqual(gradient?.y1, 0)
        XCTAssertEqual(gradient?.x2, 100)
        XCTAssertEqual(gradient?.y2, 100)
    }

    func testParseLinearGradientWithSpreadMethod() throws {
        let svg = """
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="grad1" spreadMethod="reflect">
              <stop offset="0" stop-color="#000000"/>
              <stop offset="1" stop-color="#FFFFFF"/>
            </linearGradient>
          </defs>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))
        let gradient = parsed.linearGradients["grad1"]

        XCTAssertEqual(gradient?.spreadMethod, .reflect)
    }

    func testParseLinearGradientWithRepeatSpreadMethod() throws {
        let svg = """
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="grad1" spreadMethod="repeat">
              <stop offset="0" stop-color="#000000"/>
              <stop offset="1" stop-color="#FFFFFF"/>
            </linearGradient>
          </defs>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))
        let gradient = parsed.linearGradients["grad1"]

        XCTAssertEqual(gradient?.spreadMethod, .repeating)
    }

    func testParseLinearGradientDefaultSpreadMethod() throws {
        let svg = """
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="grad1">
              <stop offset="0" stop-color="#000000"/>
              <stop offset="1" stop-color="#FFFFFF"/>
            </linearGradient>
          </defs>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))
        let gradient = parsed.linearGradients["grad1"]

        XCTAssertEqual(gradient?.spreadMethod, .pad)
    }

    // MARK: - Radial Gradient Parsing Tests

    func testParseRadialGradientBasic() throws {
        let svg = """
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <radialGradient id="grad2" cx="12" cy="12" r="12">
              <stop offset="0" stop-color="#FFFFFF"/>
              <stop offset="1" stop-color="#000000"/>
            </radialGradient>
          </defs>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))

        XCTAssertEqual(parsed.radialGradients.count, 1)

        let gradient = parsed.radialGradients["grad2"]
        XCTAssertNotNil(gradient)
        XCTAssertEqual(gradient?.cx, 12)
        XCTAssertEqual(gradient?.cy, 12)
        XCTAssertEqual(gradient?.r, 12)
        XCTAssertNil(gradient?.fx)
        XCTAssertNil(gradient?.fy)
        XCTAssertEqual(gradient?.stops.count, 2)
    }

    func testParseRadialGradientWithFocalPoint() throws {
        let svg = """
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <radialGradient id="grad2" cx="12" cy="12" r="12" fx="8" fy="8">
              <stop offset="0" stop-color="#FFFFFF"/>
              <stop offset="1" stop-color="#000000"/>
            </radialGradient>
          </defs>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))
        let gradient = parsed.radialGradients["grad2"]

        XCTAssertEqual(gradient?.fx, 8)
        XCTAssertEqual(gradient?.fy, 8)
    }

    func testParseRadialGradientPercentageCoords() throws {
        let svg = """
        <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <radialGradient id="grad1" cx="50%" cy="50%" r="50%">
              <stop offset="0" stop-color="#FFFFFF"/>
              <stop offset="1" stop-color="#000000"/>
            </radialGradient>
          </defs>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))
        let gradient = parsed.radialGradients["grad1"]

        XCTAssertEqual(gradient?.cx, 50)
        XCTAssertEqual(gradient?.cy, 50)
        XCTAssertEqual(gradient?.r, 50)
    }

    // MARK: - Stop Element Parsing Tests

    func testParseStopWithOpacity() throws {
        let svg = """
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="grad1">
              <stop offset="0" stop-color="#FF0000" stop-opacity="0.5"/>
              <stop offset="1" stop-color="#0000FF" stop-opacity="1"/>
            </linearGradient>
          </defs>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))
        let gradient = parsed.linearGradients["grad1"]

        XCTAssertEqual(gradient?.stops[0].opacity, 0.5)
        XCTAssertEqual(gradient?.stops[1].opacity, 1.0)
    }

    func testParseStopDefaultOpacity() throws {
        let svg = """
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="grad1">
              <stop offset="0" stop-color="#000000"/>
            </linearGradient>
          </defs>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))
        let gradient = parsed.linearGradients["grad1"]

        XCTAssertEqual(gradient?.stops[0].opacity, 1.0)
    }

    func testParseStopPercentageOffset() throws {
        let svg = """
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="grad1">
              <stop offset="0%" stop-color="#000000"/>
              <stop offset="50%" stop-color="#888888"/>
              <stop offset="100%" stop-color="#FFFFFF"/>
            </linearGradient>
          </defs>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))
        let gradient = parsed.linearGradients["grad1"]

        XCTAssertEqual(gradient?.stops[0].offset, 0.0)
        XCTAssertEqual(gradient?.stops[1].offset, 0.5)
        XCTAssertEqual(gradient?.stops[2].offset, 1.0)
    }

    func testParseStopsAreSortedByOffset() throws {
        let svg = """
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="grad1">
              <stop offset="1" stop-color="#FFFFFF"/>
              <stop offset="0" stop-color="#000000"/>
              <stop offset="0.5" stop-color="#888888"/>
            </linearGradient>
          </defs>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))
        let gradient = parsed.linearGradients["grad1"]

        XCTAssertEqual(gradient?.stops[0].offset, 0.0)
        XCTAssertEqual(gradient?.stops[1].offset, 0.5)
        XCTAssertEqual(gradient?.stops[2].offset, 1.0)
    }

    // MARK: - Fill URL Resolution Tests

    func testResolveFillUrlReferenceToLinearGradient() throws {
        let svg = """
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="myGrad">
              <stop offset="0" stop-color="#FF0000"/>
              <stop offset="1" stop-color="#0000FF"/>
            </linearGradient>
          </defs>
          <rect fill="url(#myGrad)" width="24" height="24"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))

        XCTAssertEqual(parsed.paths.count, 1)

        if case let .linearGradient(gradient) = parsed.paths[0].fillType {
            XCTAssertEqual(gradient.id, "myGrad")
        } else {
            XCTFail("Expected linearGradient fill, got \(String(describing: parsed.paths[0].fillType))")
        }
    }

    func testResolveFillUrlReferenceToRadialGradient() throws {
        let svg = """
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <radialGradient id="myGrad" cx="12" cy="12" r="12">
              <stop offset="0" stop-color="#FFFFFF"/>
              <stop offset="1" stop-color="#000000"/>
            </radialGradient>
          </defs>
          <rect fill="url(#myGrad)" width="24" height="24"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))

        XCTAssertEqual(parsed.paths.count, 1)

        if case let .radialGradient(gradient) = parsed.paths[0].fillType {
            XCTAssertEqual(gradient.id, "myGrad")
        } else {
            XCTFail("Expected radialGradient fill, got \(String(describing: parsed.paths[0].fillType))")
        }
    }

    func testResolveFillUrlNotFound() throws {
        let svg = """
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <rect fill="url(#nonexistent)" width="24" height="24"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))

        // Should fall back to none when gradient not found
        if case .none = parsed.paths[0].fillType {
            // Success
        } else {
            XCTFail("Expected .none fill for missing gradient, got \(String(describing: parsed.paths[0].fillType))")
        }
    }

    // MARK: - Backward Compatibility Tests

    func testParseSVGWithoutGradients() throws {
        let svg = """
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <rect fill="#FF0000" width="24" height="24"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))

        XCTAssertTrue(parsed.linearGradients.isEmpty)
        XCTAssertTrue(parsed.radialGradients.isEmpty)

        if case let .solid(color) = parsed.paths[0].fillType {
            XCTAssertEqual(color.red, 255)
            XCTAssertEqual(color.green, 0)
            XCTAssertEqual(color.blue, 0)
        } else {
            XCTFail("Expected solid fill, got \(String(describing: parsed.paths[0].fillType))")
        }
    }

    func testParseSVGWithEmptyDefs() throws {
        let svg = """
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <defs></defs>
          <rect fill="#FF0000" width="24" height="24"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))

        XCTAssertTrue(parsed.linearGradients.isEmpty)
        XCTAssertTrue(parsed.radialGradients.isEmpty)
    }

    func testParseSVGWithNoDefs() throws {
        let svg = """
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <rect fill="#FF0000" width="24" height="24"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))

        XCTAssertTrue(parsed.linearGradients.isEmpty)
        XCTAssertTrue(parsed.radialGradients.isEmpty)
    }

    // MARK: - Multiple Gradients Tests

    func testParseMultipleGradients() throws {
        let svg = """
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="linear1">
              <stop offset="0" stop-color="#FF0000"/>
              <stop offset="1" stop-color="#0000FF"/>
            </linearGradient>
            <linearGradient id="linear2">
              <stop offset="0" stop-color="#00FF00"/>
              <stop offset="1" stop-color="#FFFF00"/>
            </linearGradient>
            <radialGradient id="radial1" cx="12" cy="12" r="12">
              <stop offset="0" stop-color="#FFFFFF"/>
              <stop offset="1" stop-color="#000000"/>
            </radialGradient>
          </defs>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))

        XCTAssertEqual(parsed.linearGradients.count, 2)
        XCTAssertEqual(parsed.radialGradients.count, 1)
        XCTAssertNotNil(parsed.linearGradients["linear1"])
        XCTAssertNotNil(parsed.linearGradients["linear2"])
        XCTAssertNotNil(parsed.radialGradients["radial1"])
    }

    // MARK: - Shorthand Color Tests

    func testParseStopWithShorthandColor() throws {
        let svg = """
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="grad1">
              <stop offset="0" stop-color="#F00"/>
              <stop offset="1" stop-color="#00F"/>
            </linearGradient>
          </defs>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))
        let gradient = parsed.linearGradients["grad1"]

        XCTAssertEqual(gradient?.stops[0].color.red, 255)
        XCTAssertEqual(gradient?.stops[0].color.green, 0)
        XCTAssertEqual(gradient?.stops[0].color.blue, 0)
        XCTAssertEqual(gradient?.stops[1].color.red, 0)
        XCTAssertEqual(gradient?.stops[1].color.green, 0)
        XCTAssertEqual(gradient?.stops[1].color.blue, 255)
    }

    // MARK: - Path with Gradient Fill

    func testParsePathWithGradientFill() throws {
        let svg = """
        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <linearGradient id="grad1" x1="0" y1="0" x2="24" y2="24">
              <stop offset="0" stop-color="#FF0000"/>
              <stop offset="1" stop-color="#0000FF"/>
            </linearGradient>
          </defs>
          <path d="M0 0h24v24H0z" fill="url(#grad1)"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8))

        XCTAssertEqual(parsed.paths.count, 1)

        if case let .linearGradient(gradient) = parsed.paths[0].fillType {
            XCTAssertEqual(gradient.id, "grad1")
            XCTAssertEqual(gradient.stops.count, 2)
        } else {
            XCTFail("Expected linearGradient fill")
        }
    }
}
