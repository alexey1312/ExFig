import Foundation
@testable import SVGKit
import XCTest

/// Tests for `matrix()`, `skewX()`, and `skewY()` transform support
final class SVGMatrixTransformTests: XCTestCase {
    // MARK: - matrix() Transform Tests

    func testMatrixTranslateOnly() {
        // matrix(1,0,0,1,10,20) = translate(10,20)
        let transform = SVGTransform.parse("matrix(1,0,0,1,10,20)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.translateX, 10)
        XCTAssertEqual(transform?.translateY, 20)
        // Scale should be 1 (identity)
        XCTAssertEqual(transform?.scaleX ?? 0, 1, accuracy: 0.001)
        XCTAssertEqual(transform?.scaleY ?? 0, 1, accuracy: 0.001)
    }

    func testMatrixScaleOnly() {
        // matrix(2,0,0,3,0,0) = scale(2,3)
        let transform = SVGTransform.parse("matrix(2,0,0,3,0,0)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.scaleX ?? 0, 2, accuracy: 0.001)
        XCTAssertEqual(transform?.scaleY ?? 0, 3, accuracy: 0.001)
        XCTAssertEqual(transform?.translateX, 0)
        XCTAssertEqual(transform?.translateY, 0)
    }

    func testMatrixUniformScale() {
        // matrix(2,0,0,2,0,0) = scale(2)
        let transform = SVGTransform.parse("matrix(2,0,0,2,0,0)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.scaleX ?? 0, 2, accuracy: 0.001)
        XCTAssertEqual(transform?.scaleY ?? 0, 2, accuracy: 0.001)
    }

    func testMatrixRotation90() {
        // matrix(0,1,-1,0,0,0) = rotate(90)
        // cos(90°) = 0, sin(90°) = 1
        let transform = SVGTransform.parse("matrix(0,1,-1,0,0,0)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.rotation ?? 0, 90, accuracy: 0.1)
    }

    func testMatrixRotation45() {
        // matrix(0.707,0.707,-0.707,0.707,0,0) ≈ rotate(45)
        let cos45 = cos(45 * Double.pi / 180)
        let sin45 = sin(45 * Double.pi / 180)
        let transform = SVGTransform.parse("matrix(\(cos45),\(sin45),\(-sin45),\(cos45),0,0)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.rotation ?? 0, 45, accuracy: 0.1)
    }

    func testMatrixCombinedScaleAndTranslate() {
        // matrix(2,0,0,2,100,50) = scale(2) + translate(100,50)
        let transform = SVGTransform.parse("matrix(2,0,0,2,100,50)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.scaleX ?? 0, 2, accuracy: 0.001)
        XCTAssertEqual(transform?.scaleY ?? 0, 2, accuracy: 0.001)
        XCTAssertEqual(transform?.translateX, 100)
        XCTAssertEqual(transform?.translateY, 50)
    }

    func testMatrixIdentity() {
        // matrix(1,0,0,1,0,0) = identity (no transform)
        let transform = SVGTransform.parse("matrix(1,0,0,1,0,0)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.scaleX ?? 0, 1, accuracy: 0.001)
        XCTAssertEqual(transform?.scaleY ?? 0, 1, accuracy: 0.001)
        XCTAssertEqual(transform?.translateX, 0)
        XCTAssertEqual(transform?.translateY, 0)
    }

    func testMatrixInvalidArgCount() {
        // matrix with wrong number of arguments should be ignored
        let transform = SVGTransform.parse("matrix(1,0,0,1,0)")
        XCTAssertNil(transform)

        // Extra args are ignored, implementation parses first 6 values
        _ = SVGTransform.parse("matrix(1,0,0,1,0,0,0)")
    }

    // MARK: - skewX() Transform Tests

    func testSkewX30() {
        let transform = SVGTransform.parse("skewX(30)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.skewX, 30)
        XCTAssertNil(transform?.skewY)
    }

    func testSkewX45() {
        let transform = SVGTransform.parse("skewX(45)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.skewX, 45)
    }

    func testSkewXNegative() {
        let transform = SVGTransform.parse("skewX(-15)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.skewX, -15)
    }

    func testSkewXZero() {
        let transform = SVGTransform.parse("skewX(0)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.skewX, 0)
    }

    // MARK: - skewY() Transform Tests

    func testSkewY45() {
        let transform = SVGTransform.parse("skewY(45)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.skewY, 45)
        XCTAssertNil(transform?.skewX)
    }

    func testSkewY30() {
        let transform = SVGTransform.parse("skewY(30)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.skewY, 30)
    }

    func testSkewYNegative() {
        let transform = SVGTransform.parse("skewY(-20)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.skewY, -20)
    }

    // MARK: - Combined Transform Tests

    func testTranslateAndSkewX() {
        let transform = SVGTransform.parse("translate(10,20) skewX(30)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.translateX, 10)
        XCTAssertEqual(transform?.translateY, 20)
        XCTAssertEqual(transform?.skewX, 30)
    }

    func testScaleAndSkewY() {
        let transform = SVGTransform.parse("scale(2) skewY(15)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.scaleX, 2)
        XCTAssertEqual(transform?.skewY, 15)
    }

    func testSkewXAndSkewY() {
        let transform = SVGTransform.parse("skewX(10) skewY(20)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.skewX, 10)
        XCTAssertEqual(transform?.skewY, 20)
    }

    func testRotateAndSkew() {
        let transform = SVGTransform.parse("rotate(45) skewX(10)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.rotation, 45)
        XCTAssertEqual(transform?.skewX, 10)
    }

    // MARK: - SVG Integration Tests

    func testSkewXInSVGGroup() throws {
        let parser = SVGParser()
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <g transform="skewX(15)">
                <path d="M0,0 L10,10" fill="#000000"/>
            </g>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: false)

        XCTAssertNotNil(parsed.groups)
        XCTAssertEqual(parsed.groups?.count, 1)
        XCTAssertEqual(parsed.groups?[0].transform?.skewX, 15)
    }

    func testSkewYInSVGGroup() throws {
        let parser = SVGParser()
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <g transform="skewY(20)">
                <rect width="10" height="10" fill="#FF0000"/>
            </g>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: false)

        XCTAssertNotNil(parsed.groups)
        XCTAssertEqual(parsed.groups?[0].transform?.skewY, 20)
    }

    func testMatrixTransformInSVG() throws {
        let parser = SVGParser()
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <g transform="matrix(2,0,0,2,10,10)">
                <path d="M0,0 L12,12" fill="#000000"/>
            </g>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: false)

        XCTAssertNotNil(parsed.groups)
        let transform = parsed.groups?[0].transform
        XCTAssertEqual(transform?.scaleX ?? 0, 2, accuracy: 0.001)
        XCTAssertEqual(transform?.scaleY ?? 0, 2, accuracy: 0.001)
        XCTAssertEqual(transform?.translateX, 10)
        XCTAssertEqual(transform?.translateY, 10)
    }

    // MARK: - Edge Cases

    func testSkewWithDecimalValue() {
        let transform = SVGTransform.parse("skewX(15.5)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.skewX, 15.5)
    }

    func testMatrixWithSpaces() {
        let transform = SVGTransform.parse("matrix(1, 0, 0, 1, 10, 20)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.translateX, 10)
        XCTAssertEqual(transform?.translateY, 20)
    }

    func testMatrixWithNoSpaces() {
        let transform = SVGTransform.parse("matrix(1,0,0,1,5,10)")

        XCTAssertNotNil(transform)
        XCTAssertEqual(transform?.translateX, 5)
        XCTAssertEqual(transform?.translateY, 10)
    }
}
