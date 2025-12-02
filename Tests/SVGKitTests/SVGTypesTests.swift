import CustomDump
@testable import SVGKit
import XCTest

// MARK: - SVGTransform Tests

final class SVGTransformTests: XCTestCase {
    // MARK: - Initialization

    func testInitWithAllProperties() {
        let transform = SVGTransform(
            translateX: 10,
            translateY: 20,
            scaleX: 1.5,
            scaleY: 2.0,
            rotation: 45,
            pivotX: 12,
            pivotY: 12
        )

        XCTAssertEqual(transform.translateX, 10)
        XCTAssertEqual(transform.translateY, 20)
        XCTAssertEqual(transform.scaleX, 1.5)
        XCTAssertEqual(transform.scaleY, 2.0)
        XCTAssertEqual(transform.rotation, 45)
        XCTAssertEqual(transform.pivotX, 12)
        XCTAssertEqual(transform.pivotY, 12)
    }

    func testInitWithNilProperties() {
        let transform = SVGTransform(
            translateX: nil,
            translateY: nil,
            scaleX: nil,
            scaleY: nil,
            rotation: nil,
            pivotX: nil,
            pivotY: nil
        )

        XCTAssertNil(transform.translateX)
        XCTAssertNil(transform.translateY)
        XCTAssertNil(transform.scaleX)
        XCTAssertNil(transform.scaleY)
        XCTAssertNil(transform.rotation)
        XCTAssertNil(transform.pivotX)
        XCTAssertNil(transform.pivotY)
    }

    func testTransformEquality() {
        let transform1 = SVGTransform(translateX: 10, translateY: 20)
        let transform2 = SVGTransform(translateX: 10, translateY: 20)
        let transform3 = SVGTransform(translateX: 10, translateY: 30)

        XCTAssertEqual(transform1, transform2)
        XCTAssertNotEqual(transform1, transform3)
    }

    func testTransformIsSendable() {
        let transform = SVGTransform(translateX: 10, translateY: 20)

        // Verify Sendable conformance by passing across task boundaries
        let expectation = expectation(description: "Sendable")
        Task {
            _ = transform.translateX
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Parsing

    func testParseTranslate() {
        let transform = SVGTransform.parse("translate(10, 20)")

        XCTAssertEqual(transform?.translateX, 10)
        XCTAssertEqual(transform?.translateY, 20)
    }

    func testParseTranslateSingleValue() {
        let transform = SVGTransform.parse("translate(10)")

        XCTAssertEqual(transform?.translateX, 10)
        XCTAssertEqual(transform?.translateY, 0)
    }

    func testParseScale() {
        let transform = SVGTransform.parse("scale(2, 3)")

        XCTAssertEqual(transform?.scaleX, 2)
        XCTAssertEqual(transform?.scaleY, 3)
    }

    func testParseScaleSingleValue() {
        let transform = SVGTransform.parse("scale(2)")

        XCTAssertEqual(transform?.scaleX, 2)
        XCTAssertEqual(transform?.scaleY, 2)
    }

    func testParseRotate() {
        let transform = SVGTransform.parse("rotate(45)")

        XCTAssertEqual(transform?.rotation, 45)
        XCTAssertNil(transform?.pivotX)
        XCTAssertNil(transform?.pivotY)
    }

    func testParseRotateWithPivot() {
        let transform = SVGTransform.parse("rotate(45, 12, 12)")

        XCTAssertEqual(transform?.rotation, 45)
        XCTAssertEqual(transform?.pivotX, 12)
        XCTAssertEqual(transform?.pivotY, 12)
    }

    func testParseInvalidTransform() {
        let transform = SVGTransform.parse("invalid()")
        XCTAssertNil(transform)
    }

    func testParseEmptyString() {
        let transform = SVGTransform.parse("")
        XCTAssertNil(transform)
    }

    // MARK: - Combining Transforms

    func testParseMultipleTransforms() {
        let transform = SVGTransform.parse("translate(10, 20) rotate(45)")

        // Combined transform should have both translate and rotate
        XCTAssertEqual(transform?.translateX, 10)
        XCTAssertEqual(transform?.translateY, 20)
        XCTAssertEqual(transform?.rotation, 45)
    }
}

// MARK: - SVGGroup Tests

final class SVGGroupTests: XCTestCase {
    // MARK: - Initialization

    func testInitWithAllProperties() {
        let path = SVGPath(
            pathData: "M0,0 L10,10",
            commands: [.moveTo(x: 0, y: 0, relative: false), .lineTo(x: 10, y: 10, relative: false)],
            fill: SVGColor(red: 0, green: 0, blue: 0),
            stroke: nil,
            strokeWidth: nil,
            strokeLineCap: nil,
            strokeLineJoin: nil,
            fillRule: nil,
            opacity: nil
        )

        let transform = SVGTransform(translateX: 10, translateY: 20)

        let group = SVGGroup(
            transform: transform,
            clipPath: "M0,0 L24,0 L24,24 L0,24 Z",
            paths: [path],
            children: [],
            opacity: 0.5
        )

        XCTAssertEqual(group.transform, transform)
        XCTAssertEqual(group.clipPath, "M0,0 L24,0 L24,24 L0,24 Z")
        XCTAssertEqual(group.paths.count, 1)
        XCTAssertEqual(group.children.count, 0)
        XCTAssertEqual(group.opacity, 0.5)
    }

    func testGroupEquality() {
        let group1 = SVGGroup(
            transform: nil,
            clipPath: nil,
            paths: [],
            children: [],
            opacity: nil
        )
        let group2 = SVGGroup(
            transform: nil,
            clipPath: nil,
            paths: [],
            children: [],
            opacity: nil
        )

        XCTAssertEqual(group1, group2)
    }

    func testGroupIsSendable() {
        let group = SVGGroup(
            transform: nil,
            clipPath: nil,
            paths: [],
            children: [],
            opacity: nil
        )

        let expectation = expectation(description: "Sendable")
        Task {
            _ = group.paths
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Nested Groups

    func testNestedGroups() {
        let innerGroup = SVGGroup(
            transform: SVGTransform(translateX: 5, translateY: 5),
            clipPath: nil,
            paths: [],
            children: [],
            opacity: nil
        )

        let outerGroup = SVGGroup(
            transform: SVGTransform(translateX: 10, translateY: 10),
            clipPath: nil,
            paths: [],
            children: [innerGroup],
            opacity: nil
        )

        XCTAssertEqual(outerGroup.children.count, 1)
        XCTAssertEqual(outerGroup.children[0].transform?.translateX, 5)
    }
}

// MARK: - Extended ParsedSVG Tests

final class ParsedSVGExtendedTests: XCTestCase {
    func testParsedSVGWithGroups() {
        let group = SVGGroup(
            transform: SVGTransform(translateX: 10, translateY: 10),
            clipPath: nil,
            paths: [],
            children: [],
            opacity: nil
        )

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [],
            groups: [group]
        )

        XCTAssertEqual(svg.groups?.count, 1)
        XCTAssertEqual(svg.groups?[0].transform?.translateX, 10)
    }

    func testParsedSVGWithoutGroups() {
        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: []
        )

        XCTAssertNil(svg.groups)
    }

    func testParsedSVGBackwardCompatibility() {
        // Existing code should work without groups
        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [
                SVGPath(
                    pathData: "M0,0",
                    commands: [.moveTo(x: 0, y: 0, relative: false)],
                    fill: nil,
                    stroke: nil,
                    strokeWidth: nil,
                    strokeLineCap: nil,
                    strokeLineJoin: nil,
                    fillRule: nil,
                    opacity: nil
                ),
            ]
        )

        XCTAssertEqual(svg.width, 24)
        XCTAssertEqual(svg.height, 24)
        XCTAssertEqual(svg.paths.count, 1)
    }
}
