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

    // MARK: - Mask Parsing (Figma uses mask instead of clip-path)

    func testParseGroupWithMask() throws {
        // Figma exports flags with mask instead of clipPath
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <mask id="mask0" style="mask-type:luminance">
                <path d="M0,0 L24,0 L24,24 L0,24 Z"/>
            </mask>
            <g mask="url(#mask0)">
                <path d="M12,4 L12,20" fill="#000000"/>
            </g>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        XCTAssertEqual(parsed.groups?.count, 1)
        XCTAssertEqual(parsed.groups?[0].clipPath, "M0,0 L24,0 L24,24 L0,24 Z")
    }

    func testParseGroupWithMaskContainingRect() throws {
        // Figma often uses rect inside mask for rounded corners
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <mask id="mask0" style="mask-type:luminance">
                <rect x="0.25" y="4.25" width="23.5" height="15.5" rx="1.75" fill="white"/>
            </mask>
            <g mask="url(#mask0)">
                <path d="M0,4 L24,4 L24,20 L0,20 Z" fill="#E34F4F"/>
            </g>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        XCTAssertEqual(parsed.groups?.count, 1)
        // Rect should be converted to rounded rectangle path
        let clipPath = parsed.groups?[0].clipPath
        XCTAssertNotNil(clipPath)
        XCTAssertTrue(clipPath?.contains("M2.0,4.25") == true, "Should start at x + rx")
        XCTAssertTrue(clipPath?.hasPrefix("M") == true)
        XCTAssertTrue(clipPath?.hasSuffix("Z") == true)
    }

    func testParseGroupWithMaskInDefs() throws {
        // Mask can also be inside defs
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <defs>
                <mask id="maskInDefs">
                    <path d="M2,2 L22,2 L22,22 L2,22 Z"/>
                </mask>
            </defs>
            <g mask="url(#maskInDefs)">
                <path d="M12,4 L12,20" fill="#000000"/>
            </g>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        XCTAssertEqual(parsed.groups?.count, 1)
        XCTAssertEqual(parsed.groups?[0].clipPath, "M2,2 L22,2 L22,22 L2,22 Z")
    }

    func testClipPathTakesPrecedenceOverMask() throws {
        // If both clip-path and mask are present, clip-path wins
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <defs>
                <clipPath id="clip0">
                    <path d="M0,0 L24,0 L24,24 L0,24 Z"/>
                </clipPath>
            </defs>
            <mask id="mask0">
                <path d="M5,5 L19,5 L19,19 L5,19 Z"/>
            </mask>
            <g clip-path="url(#clip0)" mask="url(#mask0)">
                <path d="M12,4 L12,20" fill="#000000"/>
            </g>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        XCTAssertEqual(parsed.groups?.count, 1)
        // clip-path takes precedence over mask
        XCTAssertEqual(parsed.groups?[0].clipPath, "M0,0 L24,0 L24,24 L0,24 Z")
    }

    func testParseFigmaFlagStyleSVG() throws {
        // Real-world Figma flag SVG structure
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <rect x="0.25" y="4.25" width="23.5" height="15.5" rx="1.75"
                  fill="white" stroke="#D0D0D0" stroke-width="0.5"/>
            <mask id="mask0_2241_2924" style="mask-type:luminance"
                  maskUnits="userSpaceOnUse" x="0" y="4" width="24" height="16">
                <rect x="0.25" y="4.25" width="23.5" height="15.5" rx="1.75"
                      fill="white" stroke="white" stroke-width="0.5"/>
            </mask>
            <g mask="url(#mask0_2241_2924)">
                <path d="M0 14.6667H24V20H0V14.6667Z" fill="#E34F4F"/>
                <path d="M0 4H24V9.33333H0V4Z" fill="#EEEEEE"/>
            </g>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        // Should have groups (the masked group)
        XCTAssertNotNil(parsed.groups)
        XCTAssertGreaterThanOrEqual(parsed.groups?.count ?? 0, 1)

        // Find the masked group
        let maskedGroup = parsed.groups?.first { $0.clipPath != nil }
        XCTAssertNotNil(maskedGroup, "Should have a group with clip-path from mask")

        // Clip path should be a rounded rectangle
        let clipPath = maskedGroup?.clipPath
        XCTAssertNotNil(clipPath)
        XCTAssertTrue(clipPath?.contains("a") == true, "Should contain arc commands for rounded corners")
    }

    func testParseGroupWithMaskRectMissingXAttribute() throws {
        // US flag style: mask rect has no explicit x attribute (defaults to 0 per SVG spec)
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <mask id="mask0" style="mask-type:luminance" maskUnits="userSpaceOnUse">
                <rect y="4" width="24" height="16" rx="2" fill="white"/>
            </mask>
            <g mask="url(#mask0)">
                <path d="M0 4H24V20H0V4Z" fill="#E34F4F"/>
            </g>
        </svg>
        """
        let data = Data(svg.utf8)
        let parsed = try parser.parse(data, normalize: false)

        // Should have a group with clip-path from mask
        XCTAssertEqual(parsed.groups?.count, 1)
        let clipPath = parsed.groups?[0].clipPath
        XCTAssertNotNil(clipPath, "Should parse mask rect even without explicit x attribute")
        XCTAssertTrue(clipPath?.hasPrefix("M2.0,4") == true, "Should start at x=0+rx, y=4")
        XCTAssertTrue(clipPath?.contains("a") == true, "Should contain arc commands for rounded corners")
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
