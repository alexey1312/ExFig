import Foundation
import Resvg
@testable import SVGKit
import XCTest

final class ResvgPathConverterTests: XCTestCase {
    // MARK: - Path Segment Conversion Tests

    func testConvertMoveToSegment() throws {
        // MoveTo without other commands creates a degenerate path
        // So we test MoveTo as part of a valid path with LineTo
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M10,20 L20,30"/>
        </svg>
        """
        let tree = try SvgTree(data: Data(svg.utf8))
        let paths = collectPaths(from: tree.root)

        XCTAssertEqual(paths.count, 1)
        let pathString = ResvgPathConverter.toPathString(paths[0])
        // Path should contain MoveTo command
        XCTAssertTrue(pathString.hasPrefix("M"), "Path should start with MoveTo")
    }

    func testConvertLineToSegment() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M0,0 L10,20"/>
        </svg>
        """
        let tree = try SvgTree(data: Data(svg.utf8))
        let paths = collectPaths(from: tree.root)

        XCTAssertEqual(paths.count, 1)
        let pathString = ResvgPathConverter.toPathString(paths[0])
        XCTAssertTrue(pathString.contains("L"))
    }

    func testConvertCubicBezierSegment() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M0,0 C10,0 20,10 20,20"/>
        </svg>
        """
        let tree = try SvgTree(data: Data(svg.utf8))
        let paths = collectPaths(from: tree.root)

        XCTAssertEqual(paths.count, 1)
        let pathString = ResvgPathConverter.toPathString(paths[0])
        XCTAssertTrue(pathString.contains("C"))
    }

    func testConvertCloseSegment() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M0,0 L10,0 L10,10 Z"/>
        </svg>
        """
        let tree = try SvgTree(data: Data(svg.utf8))
        let paths = collectPaths(from: tree.root)

        XCTAssertEqual(paths.count, 1)
        let pathString = ResvgPathConverter.toPathString(paths[0])
        XCTAssertTrue(pathString.contains("Z"))
    }

    // MARK: - Tree Traversal Tests

    func testTreeRootAccess() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M12,4 L12,20"/>
        </svg>
        """
        let tree = try SvgTree(data: Data(svg.utf8))
        let root = tree.root

        XCTAssertGreaterThan(root.childCount, 0)
    }

    func testTreeSize() throws {
        let svg = """
        <svg width="100" height="50" viewBox="0 0 100 50" xmlns="http://www.w3.org/2000/svg">
            <path d="M0,0 L100,50"/>
        </svg>
        """
        let tree = try SvgTree(data: Data(svg.utf8))

        XCTAssertEqual(tree.size.width, 100)
        XCTAssertEqual(tree.size.height, 50)
    }

    func testGroupChildrenTraversal() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <g>
                <path d="M0,0 L10,10"/>
                <path d="M10,10 L20,20"/>
            </g>
        </svg>
        """
        let tree = try SvgTree(data: Data(svg.utf8))
        let paths = collectPaths(from: tree.root)

        XCTAssertEqual(paths.count, 2)
    }

    // MARK: - Mask Extraction Tests

    func testExtractPathFromMask() throws {
        // SVG with mask containing a rectangle (Figma flag pattern)
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <defs>
                <mask id="mask0">
                    <rect x="0" y="0" width="24" height="24" rx="4" fill="white"/>
                </mask>
            </defs>
            <g mask="url(#mask0)">
                <path d="M0,0 L24,0 L24,24 L0,24 Z" fill="#FF0000"/>
            </g>
        </svg>
        """
        let tree = try SvgTree(data: Data(svg.utf8))

        // Find the group with mask
        let maskPath = findMaskPath(in: tree.root)
        XCTAssertNotNil(maskPath, "Should find mask path in SVG")

        if let pathData = maskPath {
            XCTAssertFalse(pathData.isEmpty)
            XCTAssertTrue(pathData.contains("M") || pathData.contains("L") || pathData.contains("C"))
        }
    }

    func testExtractPathFromClipPath() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <defs>
                <clipPath id="clip0">
                    <rect x="0" y="0" width="24" height="24"/>
                </clipPath>
            </defs>
            <g clip-path="url(#clip0)">
                <path d="M0,0 L24,24"/>
            </g>
        </svg>
        """
        let tree = try SvgTree(data: Data(svg.utf8))

        let clipPath = findClipPath(in: tree.root)
        XCTAssertNotNil(clipPath, "Should find clip-path in SVG")

        if let pathData = clipPath {
            XCTAssertFalse(pathData.isEmpty)
        }
    }

    // MARK: - Path Properties Tests

    func testPathFillColor() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M0,0 L24,24" fill="#FF0000"/>
        </svg>
        """
        let tree = try SvgTree(data: Data(svg.utf8))
        let paths = collectPaths(from: tree.root)

        XCTAssertEqual(paths.count, 1)
        XCTAssertTrue(paths[0].hasFill)

        if let fill = paths[0].fill {
            XCTAssertEqual(fill.paintType, .color)
            XCTAssertEqual(fill.color.r, 255)
            XCTAssertEqual(fill.color.g, 0)
            XCTAssertEqual(fill.color.b, 0)
        }
    }

    func testPathStrokeProperties() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M0,0 L24,24" stroke="#0000FF" stroke-width="2" fill="none"/>
        </svg>
        """
        let tree = try SvgTree(data: Data(svg.utf8))
        let paths = collectPaths(from: tree.root)

        XCTAssertEqual(paths.count, 1)
        XCTAssertTrue(paths[0].hasStroke)

        if let stroke = paths[0].stroke {
            XCTAssertEqual(stroke.paintType, .color)
            XCTAssertEqual(stroke.color.r, 0)
            XCTAssertEqual(stroke.color.g, 0)
            XCTAssertEqual(stroke.color.b, 255)
            XCTAssertEqual(stroke.width, 2.0)
        }
    }

    // MARK: - Transform Tests

    func testGroupTransform() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <g transform="translate(10, 20)">
                <path d="M0,0 L10,10"/>
            </g>
        </svg>
        """
        let tree = try SvgTree(data: Data(svg.utf8))

        // Find the group with transform
        for child in tree.root.children {
            if let group = child.asGroup() {
                let transform = group.transform
                XCTAssertEqual(transform.e, 10.0, "translateX should be 10")
                XCTAssertEqual(transform.f, 20.0, "translateY should be 20")
            }
        }
    }

    // MARK: - Helper Methods

    private func collectPaths(from group: Group) -> [Resvg.Path] {
        var paths: [Resvg.Path] = []
        for child in group.children {
            if let path = child.asPath() {
                paths.append(path)
            } else if let childGroup = child.asGroup() {
                paths.append(contentsOf: collectPaths(from: childGroup))
            }
        }
        return paths
    }

    private func findMaskPath(in group: Group) -> String? {
        // Check if this group has a mask
        if let mask = group.mask {
            return ResvgPathConverter.extractPathFromMask(mask)
        }

        // Recurse into children
        for child in group.children {
            if let childGroup = child.asGroup() {
                if let maskPath = findMaskPath(in: childGroup) {
                    return maskPath
                }
            }
        }
        return nil
    }

    private func findClipPath(in group: Group) -> String? {
        // Check if this group has a clip-path
        if let clipPath = group.clipPath {
            return ResvgPathConverter.extractPathFromClipPath(clipPath)
        }

        // Recurse into children
        for child in group.children {
            if let childGroup = child.asGroup() {
                if let path = findClipPath(in: childGroup) {
                    return path
                }
            }
        }
        return nil
    }
}
