import Foundation
@testable import SVGKit
import XCTest

/// Tests for SVG opacity/alpha parsing and generation.
final class SVGOpacityTests: XCTestCase {
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

    func testParsePathWithOpacity() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M0 0h24v24H0z" fill="#FF0000" opacity="0.5"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].opacity, 0.5)
    }

    func testParsePathWithLowOpacity() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M0 0h24v24H0z" fill="#FF0000" opacity="0.25"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        XCTAssertEqual(parsed.paths.count, 1)
        XCTAssertEqual(parsed.paths[0].opacity, 0.25)
    }

    // MARK: - VectorDrawable Generation

    func testVectorDrawableFillAlpha() throws {
        let path = SVGPath(
            pathData: "M0 0h24v24H0z",
            commands: [],
            fill: SVGColor(red: 255, green: 0, blue: 0),
            fillType: .solid(SVGColor(red: 255, green: 0, blue: 0)),
            stroke: nil, strokeWidth: nil, strokeLineCap: nil, strokeLineJoin: nil,
            fillRule: nil,
            opacity: 0.5
        )
        let svg = ParsedSVG(
            width: 24, height: 24,
            viewportWidth: 24, viewportHeight: 24,
            paths: [path]
        )

        let xml = vectorGenerator.generate(from: svg)

        XCTAssertTrue(xml.contains("android:fillAlpha=\"0.5\""), "Should have fillAlpha:\n\(xml)")
    }

    // MARK: - ImageVector Generation

    func testImageVectorFillAlpha() throws {
        let path = SVGPath(
            pathData: "M0 0h24v24H0z",
            commands: [.moveTo(x: 0, y: 0, relative: false), .closePath],
            fill: SVGColor(red: 255, green: 0, blue: 0),
            fillType: .solid(SVGColor(red: 255, green: 0, blue: 0)),
            stroke: nil, strokeWidth: nil, strokeLineCap: nil, strokeLineJoin: nil,
            fillRule: nil,
            opacity: 0.3
        )
        let svg = ParsedSVG(
            width: 24, height: 24,
            viewportWidth: 24, viewportHeight: 24,
            paths: [path]
        )

        let config = ImageVectorGenerator.Config(packageName: "com.test")
        let generator = ImageVectorGenerator(config: config)
        let kotlin = generator.generate(name: "TestIcon", svg: svg)

        XCTAssertTrue(kotlin.contains("fillAlpha = 0.3f"), "Should have fillAlpha:\n\(kotlin)")
    }

    func testImageVectorOmitsFillAlphaForFullOpacity() throws {
        let path = SVGPath(
            pathData: "M0 0h24v24H0z",
            commands: [.moveTo(x: 0, y: 0, relative: false), .closePath],
            fill: SVGColor(red: 255, green: 0, blue: 0),
            fillType: .solid(SVGColor(red: 255, green: 0, blue: 0)),
            stroke: nil, strokeWidth: nil, strokeLineCap: nil, strokeLineJoin: nil,
            fillRule: nil,
            opacity: 1.0
        )
        let svg = ParsedSVG(
            width: 24, height: 24,
            viewportWidth: 24, viewportHeight: 24,
            paths: [path]
        )

        let config = ImageVectorGenerator.Config(packageName: "com.test")
        let generator = ImageVectorGenerator(config: config)
        let kotlin = generator.generate(name: "TestIcon", svg: svg)

        XCTAssertFalse(kotlin.contains("fillAlpha"), "Should not have fillAlpha for 1.0:\n\(kotlin)")
    }

    func testImageVectorOmitsFillAlphaForNilOpacity() throws {
        let path = SVGPath(
            pathData: "M0 0h24v24H0z",
            commands: [.moveTo(x: 0, y: 0, relative: false), .closePath],
            fill: SVGColor(red: 255, green: 0, blue: 0),
            fillType: .solid(SVGColor(red: 255, green: 0, blue: 0)),
            stroke: nil, strokeWidth: nil, strokeLineCap: nil, strokeLineJoin: nil,
            fillRule: nil,
            opacity: nil
        )
        let svg = ParsedSVG(
            width: 24, height: 24,
            viewportWidth: 24, viewportHeight: 24,
            paths: [path]
        )

        let config = ImageVectorGenerator.Config(packageName: "com.test")
        let generator = ImageVectorGenerator(config: config)
        let kotlin = generator.generate(name: "TestIcon", svg: svg)

        XCTAssertFalse(kotlin.contains("fillAlpha"), "Should not have fillAlpha for nil:\n\(kotlin)")
    }
}
