import Foundation
@testable import SVGKit
import XCTest

/// Tests for ImageVector (Jetpack Compose) group generation.
final class ImageVectorGroupTests: XCTestCase {
    // MARK: - Group with Rotation

    func testImageVectorGeneratesGroupWithRotation() throws {
        let transform = SVGTransform(rotation: 45, pivotX: 12, pivotY: 12)
        let path = SVGPath(
            pathData: "M0 0h24v24H0z",
            commands: [.moveTo(x: 0, y: 0, relative: false), .closePath],
            fill: SVGColor(red: 255, green: 0, blue: 0),
            fillType: .solid(SVGColor(red: 255, green: 0, blue: 0)),
            stroke: nil, strokeWidth: nil, strokeLineCap: nil, strokeLineJoin: nil,
            fillRule: nil, opacity: nil
        )
        let group = SVGGroup(
            transform: transform,
            clipPath: nil,
            paths: [path],
            children: [],
            opacity: nil,
            elements: [.path(path)]
        )
        let svg = ParsedSVG(
            width: 24, height: 24,
            viewportWidth: 24, viewportHeight: 24,
            paths: [],
            groups: [group],
            elements: [.group(group)]
        )

        let config = ImageVectorGenerator.Config(packageName: "com.test")
        let generator = ImageVectorGenerator(config: config)
        let kotlin = generator.generate(name: "TestIcon", svg: svg)

        XCTAssertTrue(kotlin.contains("import androidx.compose.ui.graphics.vector.group"))
        XCTAssertTrue(kotlin.contains("group("), "Should generate group call:\n\(kotlin)")
        XCTAssertTrue(kotlin.contains("rotate = 45f"), "Should have rotation:\n\(kotlin)")
        XCTAssertTrue(kotlin.contains("pivotX = 12f"), "Should have pivotX:\n\(kotlin)")
        XCTAssertTrue(kotlin.contains("pivotY = 12f"), "Should have pivotY:\n\(kotlin)")
    }

    // MARK: - Group with Translation

    func testImageVectorGeneratesGroupWithTranslation() throws {
        let transform = SVGTransform(translateX: 5, translateY: 10)
        let path = SVGPath(
            pathData: "M0 0h10v10H0z",
            commands: [.moveTo(x: 0, y: 0, relative: false), .closePath],
            fill: SVGColor(red: 0, green: 0, blue: 0),
            fillType: .solid(SVGColor(red: 0, green: 0, blue: 0)),
            stroke: nil, strokeWidth: nil, strokeLineCap: nil, strokeLineJoin: nil,
            fillRule: nil, opacity: nil
        )
        let group = SVGGroup(
            transform: transform,
            clipPath: nil,
            paths: [path],
            children: [],
            opacity: nil,
            elements: [.path(path)]
        )
        let svg = ParsedSVG(
            width: 24, height: 24,
            viewportWidth: 24, viewportHeight: 24,
            paths: [],
            groups: [group],
            elements: [.group(group)]
        )

        let config = ImageVectorGenerator.Config(packageName: "com.test")
        let generator = ImageVectorGenerator(config: config)
        let kotlin = generator.generate(name: "TestIcon", svg: svg)

        XCTAssertTrue(kotlin.contains("translationX = 5f"), "Should have translationX:\n\(kotlin)")
        XCTAssertTrue(kotlin.contains("translationY = 10f"), "Should have translationY:\n\(kotlin)")
    }

    // MARK: - Group with Scale

    func testImageVectorGeneratesGroupWithScale() throws {
        let transform = SVGTransform(scaleX: 2, scaleY: 0.5)
        let path = SVGPath(
            pathData: "M0 0h10v10H0z",
            commands: [.moveTo(x: 0, y: 0, relative: false), .closePath],
            fill: SVGColor(red: 0, green: 0, blue: 0),
            fillType: .solid(SVGColor(red: 0, green: 0, blue: 0)),
            stroke: nil, strokeWidth: nil, strokeLineCap: nil, strokeLineJoin: nil,
            fillRule: nil, opacity: nil
        )
        let group = SVGGroup(
            transform: transform,
            clipPath: nil,
            paths: [path],
            children: [],
            opacity: nil,
            elements: [.path(path)]
        )
        let svg = ParsedSVG(
            width: 24, height: 24,
            viewportWidth: 24, viewportHeight: 24,
            paths: [],
            groups: [group],
            elements: [.group(group)]
        )

        let config = ImageVectorGenerator.Config(packageName: "com.test")
        let generator = ImageVectorGenerator(config: config)
        let kotlin = generator.generate(name: "TestIcon", svg: svg)

        XCTAssertTrue(kotlin.contains("scaleX = 2f"), "Should have scaleX:\n\(kotlin)")
        XCTAssertTrue(kotlin.contains("scaleY = 0.5f"), "Should have scaleY:\n\(kotlin)")
    }

    // MARK: - No Import Without Groups

    func testNoGroupImportWithoutGroups() throws {
        let path = SVGPath(
            pathData: "M0 0h24v24H0z",
            commands: [.moveTo(x: 0, y: 0, relative: false), .closePath],
            fill: SVGColor(red: 255, green: 0, blue: 0),
            fillType: .solid(SVGColor(red: 255, green: 0, blue: 0)),
            stroke: nil, strokeWidth: nil, strokeLineCap: nil, strokeLineJoin: nil,
            fillRule: nil, opacity: nil
        )
        let svg = ParsedSVG(
            width: 24, height: 24,
            viewportWidth: 24, viewportHeight: 24,
            paths: [path]
        )

        let config = ImageVectorGenerator.Config(packageName: "com.test")
        let generator = ImageVectorGenerator(config: config)
        let kotlin = generator.generate(name: "TestIcon", svg: svg)

        XCTAssertFalse(kotlin.contains("import androidx.compose.ui.graphics.vector.group"))
        XCTAssertFalse(kotlin.contains("group("))
    }
}
