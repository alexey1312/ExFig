import CustomDump
import Foundation
@testable import SVGKit
import XCTest

final class SVGGroupParsingTests: XCTestCase {
    var parser: SVGParser!

    override func setUp() {
        super.setUp()
        parser = SVGParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Basic Group Parsing

    func testParseGroupElement() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <g>
                <path d="M12,4 L12,20" fill="#000000"/>
            </g>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        XCTAssertEqual(parsed.groups?.count, 1)
        XCTAssertEqual(parsed.groups?[0].paths.count, 1)
    }

    func testParseGroupWithTransform() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <g transform="translate(10, 20)">
                <path d="M0,0 L10,10" fill="#000000"/>
            </g>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        XCTAssertEqual(parsed.groups?.count, 1)
        XCTAssertEqual(parsed.groups?[0].transform?.translateX, 10)
        XCTAssertEqual(parsed.groups?[0].transform?.translateY, 20)
    }

    func testParseGroupWithScaleTransform() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <g transform="scale(2, 3)">
                <path d="M0,0 L10,10" fill="#000000"/>
            </g>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        XCTAssertEqual(parsed.groups?[0].transform?.scaleX, 2)
        XCTAssertEqual(parsed.groups?[0].transform?.scaleY, 3)
    }

    func testParseGroupWithRotateTransform() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <g transform="rotate(45, 12, 12)">
                <path d="M0,0 L10,10" fill="#000000"/>
            </g>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        XCTAssertEqual(parsed.groups?[0].transform?.rotation, 45)
        XCTAssertEqual(parsed.groups?[0].transform?.pivotX, 12)
        XCTAssertEqual(parsed.groups?[0].transform?.pivotY, 12)
    }

    // MARK: - Clip Path Parsing

    func testParseGroupWithClipPath() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <defs>
                <clipPath id="clip0">
                    <path d="M0,0 L24,0 L24,24 L0,24 Z"/>
                </clipPath>
            </defs>
            <g clip-path="url(#clip0)">
                <path d="M12,4 L12,20" fill="#000000"/>
            </g>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        XCTAssertEqual(parsed.groups?.count, 1)
        XCTAssertEqual(parsed.groups?[0].clipPath, "M0,0 L24,0 L24,24 L0,24 Z")
    }

    // MARK: - Nested Groups

    func testParseNestedGroups() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <g transform="translate(5, 5)">
                <g transform="scale(2)">
                    <path d="M0,0 L10,10" fill="#000000"/>
                </g>
            </g>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        XCTAssertEqual(parsed.groups?.count, 1)
        XCTAssertEqual(parsed.groups?[0].transform?.translateX, 5)
        XCTAssertEqual(parsed.groups?[0].children.count, 1)
        XCTAssertEqual(parsed.groups?[0].children[0].transform?.scaleX, 2)
    }

    func testParseMultipleGroupsAtSameLevel() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <g transform="translate(0, 0)">
                <path d="M0,0 L10,10" fill="#FF0000"/>
            </g>
            <g transform="translate(10, 10)">
                <path d="M0,0 L10,10" fill="#00FF00"/>
            </g>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        XCTAssertEqual(parsed.groups?.count, 2)
        XCTAssertEqual(parsed.groups?[0].transform?.translateX, 0)
        XCTAssertEqual(parsed.groups?[1].transform?.translateX, 10)
    }

    // MARK: - Group Opacity

    func testParseGroupWithOpacity() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <g opacity="0.5">
                <path d="M0,0 L10,10" fill="#000000"/>
            </g>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        XCTAssertEqual(parsed.groups?[0].opacity, 0.5)
    }

    // MARK: - Combined Transforms

    func testParseGroupWithMultipleTransforms() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <g transform="translate(10, 10) rotate(45) scale(2)">
                <path d="M0,0 L10,10" fill="#000000"/>
            </g>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        let transform = parsed.groups?[0].transform
        XCTAssertEqual(transform?.translateX, 10)
        XCTAssertEqual(transform?.translateY, 10)
        XCTAssertEqual(transform?.rotation, 45)
        XCTAssertEqual(transform?.scaleX, 2)
    }

    // MARK: - Backward Compatibility

    func testFlattenedPathsStillWork() throws {
        // The paths property should still contain all paths flattened
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <g>
                <path d="M12,4 L12,20" fill="#000000"/>
            </g>
            <path d="M4,12 L20,12" fill="#000000"/>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        // Flattened paths should include all paths
        XCTAssertEqual(parsed.paths.count, 2)
    }

    // MARK: - Real-World Icon

    func testParseRealWorldIconWithGroups() throws {
        // A Material Design-style icon with groups
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <g transform="translate(2, 2)">
                <g transform="scale(0.833)">
                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2z" fill="#000000"/>
                </g>
            </g>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        XCTAssertEqual(parsed.width, 24)
        XCTAssertEqual(parsed.height, 24)
        XCTAssertEqual(parsed.groups?.count, 1)
        XCTAssertEqual(parsed.groups?[0].children.count, 1)
    }
}
