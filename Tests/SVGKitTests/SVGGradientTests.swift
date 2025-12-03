@testable import SVGKit
import XCTest

final class SVGGradientTests: XCTestCase {
    // MARK: - SVGGradientStop Tests

    func testGradientStopCreation() {
        let color = SVGColor(red: 255, green: 0, blue: 0)
        let stop = SVGGradientStop(offset: 0.5, color: color, opacity: 0.8)

        XCTAssertEqual(stop.offset, 0.5)
        XCTAssertEqual(stop.color.red, 255)
        XCTAssertEqual(stop.color.green, 0)
        XCTAssertEqual(stop.color.blue, 0)
        XCTAssertEqual(stop.opacity, 0.8)
    }

    func testGradientStopDefaultOpacity() {
        let color = SVGColor(red: 0, green: 0, blue: 0)
        let stop = SVGGradientStop(offset: 0, color: color)

        XCTAssertEqual(stop.opacity, 1.0)
    }

    func testGradientStopEquatable() {
        let color1 = SVGColor(red: 255, green: 0, blue: 0)
        let color2 = SVGColor(red: 255, green: 0, blue: 0)
        let color3 = SVGColor(red: 0, green: 0, blue: 255)

        let stop1 = SVGGradientStop(offset: 0.5, color: color1)
        let stop2 = SVGGradientStop(offset: 0.5, color: color2)
        let stop3 = SVGGradientStop(offset: 0.7, color: color1)
        let stop4 = SVGGradientStop(offset: 0.5, color: color3)

        XCTAssertEqual(stop1, stop2)
        XCTAssertNotEqual(stop1, stop3) // Different offset
        XCTAssertNotEqual(stop1, stop4) // Different color
    }

    func testGradientStopSendable() {
        let color = SVGColor(red: 255, green: 0, blue: 0)
        let stop = SVGGradientStop(offset: 0.5, color: color)

        // Verify Sendable conformance compiles
        Task {
            _ = stop // Should compile without warnings
        }
    }

    // MARK: - SVGLinearGradient Tests

    func testLinearGradientCreation() {
        let stops = [
            SVGGradientStop(offset: 0, color: SVGColor(red: 255, green: 0, blue: 0)),
            SVGGradientStop(offset: 1, color: SVGColor(red: 0, green: 0, blue: 255)),
        ]
        let gradient = SVGLinearGradient(
            id: "grad1",
            x1: 0, y1: 0,
            x2: 24, y2: 24,
            stops: stops
        )

        XCTAssertEqual(gradient.id, "grad1")
        XCTAssertEqual(gradient.x1, 0)
        XCTAssertEqual(gradient.y1, 0)
        XCTAssertEqual(gradient.x2, 24)
        XCTAssertEqual(gradient.y2, 24)
        XCTAssertEqual(gradient.stops.count, 2)
        XCTAssertEqual(gradient.spreadMethod, .pad) // Default
    }

    func testLinearGradientWithSpreadMethod() {
        let stops = [
            SVGGradientStop(offset: 0, color: SVGColor(red: 0, green: 0, blue: 0)),
        ]
        let gradient = SVGLinearGradient(
            id: "grad",
            x1: 0, y1: 0,
            x2: 1, y2: 1,
            stops: stops,
            spreadMethod: .reflect
        )

        XCTAssertEqual(gradient.spreadMethod, .reflect)
    }

    func testLinearGradientSendable() {
        let gradient = SVGLinearGradient(
            id: "g",
            x1: 0, y1: 0,
            x2: 1, y2: 1,
            stops: []
        )

        // Verify Sendable conformance compiles
        Task {
            _ = gradient
        }
    }

    func testLinearGradientEquatable() {
        let stops = [
            SVGGradientStop(offset: 0, color: SVGColor(red: 0, green: 0, blue: 0)),
        ]
        let gradient1 = SVGLinearGradient(id: "g1", x1: 0, y1: 0, x2: 1, y2: 1, stops: stops)
        let gradient2 = SVGLinearGradient(id: "g1", x1: 0, y1: 0, x2: 1, y2: 1, stops: stops)
        let gradient3 = SVGLinearGradient(id: "g2", x1: 0, y1: 0, x2: 1, y2: 1, stops: stops)

        XCTAssertEqual(gradient1, gradient2)
        XCTAssertNotEqual(gradient1, gradient3)
    }

    // MARK: - SVGRadialGradient Tests

    func testRadialGradientCreation() {
        let stops = [
            SVGGradientStop(offset: 0, color: SVGColor(red: 255, green: 255, blue: 255)),
            SVGGradientStop(offset: 1, color: SVGColor(red: 0, green: 0, blue: 0)),
        ]
        let gradient = SVGRadialGradient(
            id: "grad2",
            cx: 12, cy: 12,
            r: 12,
            fx: nil, fy: nil,
            stops: stops
        )

        XCTAssertEqual(gradient.id, "grad2")
        XCTAssertEqual(gradient.cx, 12)
        XCTAssertEqual(gradient.cy, 12)
        XCTAssertEqual(gradient.r, 12)
        XCTAssertNil(gradient.fx)
        XCTAssertNil(gradient.fy)
        XCTAssertEqual(gradient.stops.count, 2)
        XCTAssertEqual(gradient.spreadMethod, .pad)
    }

    func testRadialGradientWithFocalPoint() {
        let gradient = SVGRadialGradient(
            id: "grad3",
            cx: 12, cy: 12,
            r: 12,
            fx: 8, fy: 8,
            stops: []
        )

        XCTAssertEqual(gradient.fx, 8)
        XCTAssertEqual(gradient.fy, 8)
    }

    func testRadialGradientSendable() {
        let gradient = SVGRadialGradient(
            id: "g",
            cx: 12, cy: 12,
            r: 12,
            stops: []
        )

        // Verify Sendable conformance compiles
        Task {
            _ = gradient
        }
    }

    func testRadialGradientEquatable() {
        let stops = [
            SVGGradientStop(offset: 0, color: SVGColor(red: 0, green: 0, blue: 0)),
        ]
        let gradient1 = SVGRadialGradient(id: "g1", cx: 12, cy: 12, r: 12, stops: stops)
        let gradient2 = SVGRadialGradient(id: "g1", cx: 12, cy: 12, r: 12, stops: stops)
        let gradient3 = SVGRadialGradient(id: "g1", cx: 12, cy: 12, r: 24, stops: stops)

        XCTAssertEqual(gradient1, gradient2)
        XCTAssertNotEqual(gradient1, gradient3)
    }

    // MARK: - SVGFill Tests

    func testSVGFillNone() {
        let fill = SVGFill.none
        if case .none = fill {
            // Success
        } else {
            XCTFail("Expected .none")
        }
    }

    func testSVGFillSolid() {
        let color = SVGColor(red: 255, green: 0, blue: 0)
        let fill = SVGFill.solid(color)

        if case let .solid(fillColor) = fill {
            XCTAssertEqual(fillColor.red, 255)
            XCTAssertEqual(fillColor.green, 0)
            XCTAssertEqual(fillColor.blue, 0)
        } else {
            XCTFail("Expected .solid")
        }
    }

    func testSVGFillLinearGradient() {
        let gradient = SVGLinearGradient(id: "g", x1: 0, y1: 0, x2: 1, y2: 1, stops: [])
        let fill = SVGFill.linearGradient(gradient)

        if case let .linearGradient(g) = fill {
            XCTAssertEqual(g.id, "g")
        } else {
            XCTFail("Expected .linearGradient")
        }
    }

    func testSVGFillRadialGradient() {
        let gradient = SVGRadialGradient(id: "rg", cx: 12, cy: 12, r: 12, stops: [])
        let fill = SVGFill.radialGradient(gradient)

        if case let .radialGradient(g) = fill {
            XCTAssertEqual(g.id, "rg")
        } else {
            XCTFail("Expected .radialGradient")
        }
    }

    func testSVGFillEquatable() {
        let color = SVGColor(red: 255, green: 0, blue: 0)
        let fill1 = SVGFill.solid(color)
        let fill2 = SVGFill.solid(color)
        let fill3 = SVGFill.none

        XCTAssertEqual(fill1, fill2)
        XCTAssertNotEqual(fill1, fill3)
    }

    func testSVGFillSendable() {
        let fill = SVGFill.none

        // Verify Sendable conformance compiles
        Task {
            _ = fill
        }
    }

    // MARK: - SpreadMethod Tests

    func testSpreadMethodRawValues() {
        XCTAssertEqual(SVGLinearGradient.SpreadMethod.pad.rawValue, "pad")
        XCTAssertEqual(SVGLinearGradient.SpreadMethod.reflect.rawValue, "reflect")
        XCTAssertEqual(SVGLinearGradient.SpreadMethod.repeating.rawValue, "repeat")
    }
}
