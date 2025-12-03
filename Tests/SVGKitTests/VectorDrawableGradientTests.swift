@testable import SVGKit
import XCTest

final class VectorDrawableGradientTests: XCTestCase {
    private let generator = VectorDrawableXMLGenerator()

    // MARK: - Helper Methods

    private func createSVGWithLinearGradient() -> ParsedSVG {
        let stops = [
            SVGGradientStop(offset: 0, color: SVGColor(red: 255, green: 0, blue: 0)),
            SVGGradientStop(offset: 1, color: SVGColor(red: 0, green: 0, blue: 255)),
        ]
        let gradient = SVGLinearGradient(id: "grad1", x1: 0, y1: 0, x2: 24, y2: 24, stops: stops)
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
        return ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [path],
            linearGradients: ["grad1": gradient]
        )
    }

    private func createSVGWithRadialGradient() -> ParsedSVG {
        let stops = [
            SVGGradientStop(offset: 0, color: SVGColor(red: 255, green: 255, blue: 255)),
            SVGGradientStop(offset: 1, color: SVGColor(red: 0, green: 0, blue: 0)),
        ]
        let gradient = SVGRadialGradient(id: "grad1", cx: 12, cy: 12, r: 12, stops: stops)
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
        return ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [path],
            radialGradients: ["grad1": gradient]
        )
    }

    private func createSVGWithSolidFill() -> ParsedSVG {
        let color = SVGColor(red: 255, green: 0, blue: 0)
        let path = SVGPath(
            pathData: "M0 0h24v24H0z",
            commands: [],
            fill: color,
            fillType: .solid(color),
            stroke: nil,
            strokeWidth: nil,
            strokeLineCap: nil,
            strokeLineJoin: nil,
            fillRule: nil,
            opacity: nil
        )
        return ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [path]
        )
    }

    // MARK: - Namespace Tests

    func testVectorDrawableWithGradientHasAaptNamespace() {
        let svg = createSVGWithLinearGradient()
        let xml = generator.generate(from: svg)

        XCTAssertTrue(
            xml.contains("xmlns:aapt=\"http://schemas.android.com/aapt\""),
            "Expected aapt namespace in XML:\n\(xml)"
        )
    }

    func testVectorDrawableWithRadialGradientHasAaptNamespace() {
        let svg = createSVGWithRadialGradient()
        let xml = generator.generate(from: svg)

        XCTAssertTrue(
            xml.contains("xmlns:aapt=\"http://schemas.android.com/aapt\""),
            "Expected aapt namespace in XML:\n\(xml)"
        )
    }

    func testVectorDrawableWithoutGradientNoAaptNamespace() {
        let svg = createSVGWithSolidFill()
        let xml = generator.generate(from: svg)

        XCTAssertFalse(
            xml.contains("xmlns:aapt"),
            "Should not have aapt namespace for solid fill:\n\(xml)"
        )
    }

    // MARK: - Linear Gradient XML Tests

    func testGenerateLinearGradientFill() {
        let svg = createSVGWithLinearGradient()
        let xml = generator.generate(from: svg)

        XCTAssertTrue(xml.contains("<aapt:attr name=\"android:fillColor\">"), "Missing aapt:attr:\n\(xml)")
        XCTAssertTrue(xml.contains("android:type=\"linear\""), "Missing type=linear:\n\(xml)")
        XCTAssertTrue(xml.contains("android:startX=\"0\""), "Missing startX:\n\(xml)")
        XCTAssertTrue(xml.contains("android:startY=\"0\""), "Missing startY:\n\(xml)")
        XCTAssertTrue(xml.contains("android:endX=\"24\""), "Missing endX:\n\(xml)")
        XCTAssertTrue(xml.contains("android:endY=\"24\""), "Missing endY:\n\(xml)")
        XCTAssertTrue(xml.contains("<item android:offset=\"0\""), "Missing first stop:\n\(xml)")
        XCTAssertTrue(xml.contains("<item android:offset=\"1\""), "Missing second stop:\n\(xml)")
        XCTAssertTrue(xml.contains("android:color=\"#FFFF0000\""), "Missing red color:\n\(xml)")
        XCTAssertTrue(xml.contains("android:color=\"#FF0000FF\""), "Missing blue color:\n\(xml)")
    }

    func testGenerateLinearGradientClosesCorrectly() {
        let svg = createSVGWithLinearGradient()
        let xml = generator.generate(from: svg)

        XCTAssertTrue(xml.contains("</gradient>"), "Missing gradient close tag:\n\(xml)")
        XCTAssertTrue(xml.contains("</aapt:attr>"), "Missing aapt:attr close tag:\n\(xml)")
    }

    // MARK: - Radial Gradient XML Tests

    func testGenerateRadialGradientFill() {
        let svg = createSVGWithRadialGradient()
        let xml = generator.generate(from: svg)

        XCTAssertTrue(xml.contains("<aapt:attr name=\"android:fillColor\">"), "Missing aapt:attr:\n\(xml)")
        XCTAssertTrue(xml.contains("android:type=\"radial\""), "Missing type=radial:\n\(xml)")
        XCTAssertTrue(xml.contains("android:centerX=\"12\""), "Missing centerX:\n\(xml)")
        XCTAssertTrue(xml.contains("android:centerY=\"12\""), "Missing centerY:\n\(xml)")
        XCTAssertTrue(xml.contains("android:gradientRadius=\"12\""), "Missing gradientRadius:\n\(xml)")
    }

    // MARK: - Gradient Stop Opacity Tests

    func testGradientStopWithOpacity() {
        let stops = [
            SVGGradientStop(offset: 0, color: SVGColor(red: 255, green: 0, blue: 0), opacity: 0.5),
            SVGGradientStop(offset: 1, color: SVGColor(red: 0, green: 0, blue: 255), opacity: 1.0),
        ]
        let gradient = SVGLinearGradient(id: "grad1", x1: 0, y1: 0, x2: 24, y2: 24, stops: stops)
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
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [path],
            linearGradients: ["grad1": gradient]
        )

        let xml = generator.generate(from: svg)

        // 0.5 opacity = 0x80 (128) alpha
        XCTAssertTrue(xml.contains("android:color=\"#80FF0000\""), "Expected 50% alpha red (#80FF0000):\n\(xml)")
        XCTAssertTrue(xml.contains("android:color=\"#FF0000FF\""), "Expected full alpha blue (#FF0000FF):\n\(xml)")
    }

    func testGradientStopWithZeroOpacity() {
        let stops = [
            SVGGradientStop(offset: 0, color: SVGColor(red: 255, green: 0, blue: 0), opacity: 0.0),
            SVGGradientStop(offset: 1, color: SVGColor(red: 0, green: 0, blue: 255), opacity: 1.0),
        ]
        let gradient = SVGLinearGradient(id: "grad1", x1: 0, y1: 0, x2: 24, y2: 24, stops: stops)
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
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [path],
            linearGradients: ["grad1": gradient]
        )

        let xml = generator.generate(from: svg)

        // 0.0 opacity = 0x00 alpha
        XCTAssertTrue(xml.contains("android:color=\"#00FF0000\""), "Expected 0% alpha red (#00FF0000):\n\(xml)")
    }

    // MARK: - Backward Compatibility Tests

    func testSolidFillStillWorks() {
        let svg = createSVGWithSolidFill()
        let xml = generator.generate(from: svg)

        XCTAssertTrue(xml.contains("android:fillColor=\"#FF0000\""), "Expected solid fill color:\n\(xml)")
        XCTAssertFalse(xml.contains("<aapt:attr"), "Should not have aapt:attr for solid fill:\n\(xml)")
        XCTAssertFalse(xml.contains("<gradient"), "Should not have gradient for solid fill:\n\(xml)")
    }

    // MARK: - Multiple Stops Tests

    func testGradientWithThreeStops() {
        let stops = [
            SVGGradientStop(offset: 0, color: SVGColor(red: 255, green: 0, blue: 0)),
            SVGGradientStop(offset: 0.5, color: SVGColor(red: 0, green: 255, blue: 0)),
            SVGGradientStop(offset: 1, color: SVGColor(red: 0, green: 0, blue: 255)),
        ]
        let gradient = SVGLinearGradient(id: "grad1", x1: 0, y1: 0, x2: 24, y2: 0, stops: stops)
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
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [path],
            linearGradients: ["grad1": gradient]
        )

        let xml = generator.generate(from: svg)

        XCTAssertTrue(xml.contains("<item android:offset=\"0\""), "Missing first stop:\n\(xml)")
        XCTAssertTrue(xml.contains("<item android:offset=\"0.5\""), "Missing middle stop:\n\(xml)")
        XCTAssertTrue(xml.contains("<item android:offset=\"1\""), "Missing last stop:\n\(xml)")
        XCTAssertTrue(xml.contains("android:color=\"#FFFF0000\""), "Missing red:\n\(xml)")
        XCTAssertTrue(xml.contains("android:color=\"#FF00FF00\""), "Missing green:\n\(xml)")
        XCTAssertTrue(xml.contains("android:color=\"#FF0000FF\""), "Missing blue:\n\(xml)")
    }

    // MARK: - XML Validity Tests

    func testGeneratedXMLIsWellFormed() {
        let svg = createSVGWithLinearGradient()
        let xml = generator.generate(from: svg)

        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            XCTAssertNoThrow(try XMLDocument(xmlString: xml, options: []))
        #else
            // Fallback validation for Linux
            XCTAssertTrue(xml.hasPrefix("<?xml"), "Should start with XML declaration")
            XCTAssertTrue(xml.contains("<vector"), "Should have vector element")
            XCTAssertTrue(xml.contains("</vector>"), "Should close vector element")
        #endif
    }
}
