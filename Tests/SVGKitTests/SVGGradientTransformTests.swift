import Foundation
@testable import SVGKit
import XCTest

/// Tests for gradientTransform parsing and application in SVG gradients.
final class SVGGradientTransformTests: XCTestCase {
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

    // MARK: - Parsing

    func testParseLinearGradientWithTranslateTransform() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <defs>
                <linearGradient id="grad1" x1="0" y1="0" x2="24" y2="0"
                    gradientTransform="translate(5, 10)">
                    <stop offset="0" stop-color="#FF0000"/>
                    <stop offset="1" stop-color="#0000FF"/>
                </linearGradient>
            </defs>
            <path d="M0 0h24v24H0z" fill="url(#grad1)"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        let gradient = parsed.linearGradients["grad1"]
        XCTAssertNotNil(gradient)
        XCTAssertNotNil(gradient?.gradientTransform, "gradientTransform should be parsed")
        XCTAssertEqual(gradient?.gradientTransform?.translateX, 5)
        XCTAssertEqual(gradient?.gradientTransform?.translateY, 10)
    }

    func testParseRadialGradientWithTranslateAndScaleTransform() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <defs>
                <radialGradient id="grad1" cx="12" cy="12" r="6"
                    gradientTransform="translate(2, 3) scale(1.5)">
                    <stop offset="0" stop-color="#FFFFFF"/>
                    <stop offset="1" stop-color="#000000"/>
                </radialGradient>
            </defs>
            <path d="M0 0h24v24H0z" fill="url(#grad1)"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        let gradient = parsed.radialGradients["grad1"]
        XCTAssertNotNil(gradient)
        XCTAssertNotNil(gradient?.gradientTransform, "gradientTransform should be parsed")
        XCTAssertEqual(gradient?.gradientTransform?.translateX, 2)
        XCTAssertEqual(gradient?.gradientTransform?.translateY, 3)
        XCTAssertEqual(gradient?.gradientTransform?.scaleX, 1.5)
    }

    func testParseRadialGradientWithMatrixTransform() throws {
        // Figma often exports matrix transforms for gradients
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <defs>
                <radialGradient id="grad1" cx="0" cy="0" r="1"
                    gradientTransform="matrix(10 0 0 10 12 12)">
                    <stop offset="0" stop-color="#FFFFFF"/>
                    <stop offset="1" stop-color="#000000"/>
                </radialGradient>
            </defs>
            <path d="M0 0h24v24H0z" fill="url(#grad1)"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        let gradient = parsed.radialGradients["grad1"]
        XCTAssertNotNil(gradient)
        XCTAssertNotNil(gradient?.gradientTransform)
        XCTAssertEqual(gradient?.gradientTransform?.translateX, 12)
        XCTAssertEqual(gradient?.gradientTransform?.translateY, 12)
        XCTAssertEqual(gradient?.gradientTransform?.scaleX, 10)
        XCTAssertEqual(gradient?.gradientTransform?.scaleY, 10)
    }

    // MARK: - VectorDrawable Application

    func testVectorDrawableAppliesLinearGradientTransform() {
        let transform = SVGTransform(translateX: 5, translateY: 10)
        let gradient = SVGLinearGradient(
            id: "grad1",
            x1: 0, y1: 0, x2: 10, y2: 0,
            stops: [
                SVGGradientStop(offset: 0, color: SVGColor(red: 255, green: 0, blue: 0)),
                SVGGradientStop(offset: 1, color: SVGColor(red: 0, green: 0, blue: 255)),
            ],
            gradientTransform: transform
        )
        let path = SVGPath(
            pathData: "M0 0h24v24H0z",
            commands: [],
            fill: nil,
            fillType: .linearGradient(gradient),
            stroke: nil,
            strokeWidth: nil,
            strokeLineCap: nil,
            strokeLineJoin: nil,
            fillRule: nil,
            opacity: nil
        )
        let svg = ParsedSVG(
            width: 24, height: 24,
            viewportWidth: 24, viewportHeight: 24,
            paths: [path],
            linearGradients: ["grad1": gradient]
        )

        let xml = vectorGenerator.generate(from: svg)

        // x1=0 + translateX=5 = 5, x2=10 + translateX=5 = 15
        XCTAssertTrue(xml.contains("android:startX=\"5\""), "startX should be transformed:\n\(xml)")
        XCTAssertTrue(xml.contains("android:startY=\"10\""), "startY should be transformed:\n\(xml)")
        XCTAssertTrue(xml.contains("android:endX=\"15\""), "endX should be transformed:\n\(xml)")
        XCTAssertTrue(xml.contains("android:endY=\"10\""), "endY should be transformed:\n\(xml)")
    }

    func testVectorDrawableAppliesRadialGradientTransform() {
        let transform = SVGTransform(translateX: 6, translateY: 6, scaleX: 2, scaleY: 2)
        let gradient = SVGRadialGradient(
            id: "grad1",
            cx: 0, cy: 0, r: 5,
            stops: [
                SVGGradientStop(offset: 0, color: SVGColor(red: 255, green: 255, blue: 255)),
                SVGGradientStop(offset: 1, color: SVGColor(red: 0, green: 0, blue: 0)),
            ],
            gradientTransform: transform
        )
        let path = SVGPath(
            pathData: "M0 0h24v24H0z",
            commands: [],
            fill: nil,
            fillType: .radialGradient(gradient),
            stroke: nil,
            strokeWidth: nil,
            strokeLineCap: nil,
            strokeLineJoin: nil,
            fillRule: nil,
            opacity: nil
        )
        let svg = ParsedSVG(
            width: 24, height: 24,
            viewportWidth: 24, viewportHeight: 24,
            paths: [path],
            radialGradients: ["grad1": gradient]
        )

        let xml = vectorGenerator.generate(from: svg)

        // cx=0*2+6=6, cy=0*2+6=6, r=5*2=10
        XCTAssertTrue(xml.contains("android:centerX=\"6\""), "centerX should be transformed:\n\(xml)")
        XCTAssertTrue(xml.contains("android:centerY=\"6\""), "centerY should be transformed:\n\(xml)")
        XCTAssertTrue(xml.contains("android:gradientRadius=\"10\""), "radius should be scaled:\n\(xml)")
    }

    // MARK: - Integration

    func testEndToEndRadialGradientWithTransform() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <defs>
                <radialGradient id="paint0_radial" cx="0" cy="0" r="1"
                    gradientUnits="userSpaceOnUse"
                    gradientTransform="translate(12 12) scale(10)">
                    <stop stop-color="white"/>
                    <stop offset="1" stop-color="black"/>
                </radialGradient>
            </defs>
            <rect width="24" height="24" fill="url(#paint0_radial)"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        let xml = vectorGenerator.generate(from: parsed)

        // After transform: cx=0*10+12=12, cy=0*10+12=12, r=1*10=10
        XCTAssertTrue(xml.contains("android:centerX=\"12\""), "centerX should be 12:\n\(xml)")
        XCTAssertTrue(xml.contains("android:centerY=\"12\""), "centerY should be 12:\n\(xml)")
        XCTAssertTrue(xml.contains("android:gradientRadius=\"10\""), "radius should be 10:\n\(xml)")
    }
}
