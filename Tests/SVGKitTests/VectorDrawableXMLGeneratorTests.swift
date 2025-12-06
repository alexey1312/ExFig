// swiftlint:disable file_length type_body_length
import CustomDump
import Foundation
@testable import SVGKit
import XCTest

final class VectorDrawableXMLGeneratorTests: XCTestCase {
    // MARK: - Root Element Tests

    func testGenerateRootElement() {
        let generator = VectorDrawableXMLGenerator()

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: []
        )

        let xml = generator.generate(from: svg)

        XCTAssertTrue(xml.contains("<?xml version=\"1.0\" encoding=\"utf-8\"?>"))
        XCTAssertTrue(xml.contains("<vector"))
        XCTAssertTrue(xml.contains("xmlns:android=\"http://schemas.android.com/apk/res/android\""))
        XCTAssertTrue(xml.contains("android:width=\"24dp\""))
        XCTAssertTrue(xml.contains("android:height=\"24dp\""))
        XCTAssertTrue(xml.contains("android:viewportWidth=\"24\""))
        XCTAssertTrue(xml.contains("android:viewportHeight=\"24\""))
    }

    func testGenerateWithDifferentDimensions() {
        let generator = VectorDrawableXMLGenerator()

        let svg = ParsedSVG(
            width: 48,
            height: 32,
            viewportWidth: 96,
            viewportHeight: 64,
            paths: []
        )

        let xml = generator.generate(from: svg)

        XCTAssertTrue(xml.contains("android:width=\"48dp\""))
        XCTAssertTrue(xml.contains("android:height=\"32dp\""))
        XCTAssertTrue(xml.contains("android:viewportWidth=\"96\""))
        XCTAssertTrue(xml.contains("android:viewportHeight=\"64\""))
    }

    // MARK: - Path Element Tests

    func testGeneratePathWithFill() {
        let generator = VectorDrawableXMLGenerator()

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [
                SVGPath(
                    pathData: "M12,4 L12,20",
                    commands: [],
                    fill: SVGColor(red: 255, green: 0, blue: 0),
                    stroke: nil,
                    strokeWidth: nil,
                    strokeLineCap: nil,
                    strokeLineJoin: nil,
                    fillRule: nil,
                    opacity: nil
                ),
            ]
        )

        let xml = generator.generate(from: svg)

        XCTAssertTrue(xml.contains("<path"))
        XCTAssertTrue(xml.contains("android:pathData=\"M12,4 L12,20\""))
        XCTAssertTrue(xml.contains("android:fillColor=\"#FF0000\""))
    }

    func testGeneratePathWithStroke() {
        let generator = VectorDrawableXMLGenerator()

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [
                SVGPath(
                    pathData: "M4,4 L20,20",
                    commands: [],
                    fill: nil,
                    stroke: SVGColor(red: 0, green: 255, blue: 0),
                    strokeWidth: 2.5,
                    strokeLineCap: .round,
                    strokeLineJoin: .bevel,
                    fillRule: nil,
                    opacity: nil
                ),
            ]
        )

        let xml = generator.generate(from: svg)

        XCTAssertTrue(xml.contains("android:strokeColor=\"#00FF00\""))
        XCTAssertTrue(xml.contains("android:strokeWidth=\"2.5\""))
        XCTAssertTrue(xml.contains("android:strokeLineCap=\"round\""))
        XCTAssertTrue(xml.contains("android:strokeLineJoin=\"bevel\""))
    }

    func testGeneratePathWithFillType() {
        let generator = VectorDrawableXMLGenerator()

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [
                SVGPath(
                    pathData: "M0,0 L24,0 L24,24 L0,24 Z",
                    commands: [],
                    fill: SVGColor(red: 0, green: 0, blue: 0),
                    stroke: nil,
                    strokeWidth: nil,
                    strokeLineCap: nil,
                    strokeLineJoin: nil,
                    fillRule: .evenOdd,
                    opacity: nil
                ),
            ]
        )

        let xml = generator.generate(from: svg)

        XCTAssertTrue(xml.contains("android:fillType=\"evenOdd\""))
    }

    func testGeneratePathWithOpacity() {
        let generator = VectorDrawableXMLGenerator()

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [
                SVGPath(
                    pathData: "M0,0 L24,24",
                    commands: [],
                    fill: SVGColor(red: 0, green: 0, blue: 0),
                    stroke: nil,
                    strokeWidth: nil,
                    strokeLineCap: nil,
                    strokeLineJoin: nil,
                    fillRule: nil,
                    opacity: 0.5
                ),
            ]
        )

        let xml = generator.generate(from: svg)

        XCTAssertTrue(xml.contains("android:fillAlpha=\"0.5\""))
    }

    // MARK: - Group Element Tests

    func testGenerateGroupWithTranslate() {
        let generator = VectorDrawableXMLGenerator()

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [],
            groups: [
                SVGGroup(
                    transform: SVGTransform(translateX: 10, translateY: 20),
                    clipPath: nil,
                    paths: [
                        SVGPath(
                            pathData: "M0,0 L10,10",
                            commands: [],
                            fill: SVGColor(red: 0, green: 0, blue: 0),
                            stroke: nil,
                            strokeWidth: nil,
                            strokeLineCap: nil,
                            strokeLineJoin: nil,
                            fillRule: nil,
                            opacity: nil
                        ),
                    ],
                    children: [],
                    opacity: nil
                ),
            ]
        )

        let xml = generator.generate(from: svg)

        XCTAssertTrue(xml.contains("<group"))
        XCTAssertTrue(xml.contains("android:translateX=\"10\""))
        XCTAssertTrue(xml.contains("android:translateY=\"20\""))
        XCTAssertTrue(xml.contains("</group>"))
    }

    func testGenerateGroupWithScale() {
        let generator = VectorDrawableXMLGenerator()

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [],
            groups: [
                SVGGroup(
                    transform: SVGTransform(scaleX: 2, scaleY: 3),
                    clipPath: nil,
                    paths: [],
                    children: [],
                    opacity: nil
                ),
            ]
        )

        let xml = generator.generate(from: svg)

        XCTAssertTrue(xml.contains("android:scaleX=\"2\""))
        XCTAssertTrue(xml.contains("android:scaleY=\"3\""))
    }

    func testGenerateGroupWithRotation() {
        let generator = VectorDrawableXMLGenerator()

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [],
            groups: [
                SVGGroup(
                    transform: SVGTransform(rotation: 45, pivotX: 12, pivotY: 12),
                    clipPath: nil,
                    paths: [],
                    children: [],
                    opacity: nil
                ),
            ]
        )

        let xml = generator.generate(from: svg)

        XCTAssertTrue(xml.contains("android:rotation=\"45\""))
        XCTAssertTrue(xml.contains("android:pivotX=\"12\""))
        XCTAssertTrue(xml.contains("android:pivotY=\"12\""))
    }

    // MARK: - Clip Path Tests

    func testGenerateGroupWithClipPath() {
        let generator = VectorDrawableXMLGenerator()

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [],
            groups: [
                SVGGroup(
                    transform: nil,
                    clipPath: "M0,0 L24,0 L24,24 L0,24 Z",
                    paths: [
                        SVGPath(
                            pathData: "M12,4 L12,20",
                            commands: [],
                            fill: SVGColor(red: 0, green: 0, blue: 0),
                            stroke: nil,
                            strokeWidth: nil,
                            strokeLineCap: nil,
                            strokeLineJoin: nil,
                            fillRule: nil,
                            opacity: nil
                        ),
                    ],
                    children: [],
                    opacity: nil
                ),
            ]
        )

        let xml = generator.generate(from: svg)

        XCTAssertTrue(xml.contains("<clip-path"))
        XCTAssertTrue(xml.contains("android:pathData=\"M0,0 L24,0 L24,24 L0,24 Z\""))
    }

    // MARK: - AutoMirrored Tests

    func testGenerateWithAutoMirrored() {
        let generator = VectorDrawableXMLGenerator(autoMirrored: true)

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: []
        )

        let xml = generator.generate(from: svg)

        XCTAssertTrue(xml.contains("android:autoMirrored=\"true\""))
    }

    func testGenerateWithoutAutoMirrored() {
        let generator = VectorDrawableXMLGenerator(autoMirrored: false)

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: []
        )

        let xml = generator.generate(from: svg)

        XCTAssertFalse(xml.contains("android:autoMirrored"))
    }

    // MARK: - Nested Groups Tests

    func testGenerateNestedGroups() {
        let generator = VectorDrawableXMLGenerator()

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [],
            groups: [
                SVGGroup(
                    transform: SVGTransform(translateX: 5, translateY: 5),
                    clipPath: nil,
                    paths: [],
                    children: [
                        SVGGroup(
                            transform: SVGTransform(scaleX: 2, scaleY: 2),
                            clipPath: nil,
                            paths: [
                                SVGPath(
                                    pathData: "M0,0 L10,10",
                                    commands: [],
                                    fill: SVGColor(red: 0, green: 0, blue: 0),
                                    stroke: nil,
                                    strokeWidth: nil,
                                    strokeLineCap: nil,
                                    strokeLineJoin: nil,
                                    fillRule: nil,
                                    opacity: nil
                                ),
                            ],
                            children: [],
                            opacity: nil
                        ),
                    ],
                    opacity: nil
                ),
            ]
        )

        let xml = generator.generate(from: svg)

        // Count group tags
        let groupOpenCount = xml.components(separatedBy: "<group").count - 1
        let groupCloseCount = xml.components(separatedBy: "</group>").count - 1

        XCTAssertEqual(groupOpenCount, 2)
        XCTAssertEqual(groupCloseCount, 2)
    }

    // MARK: - Color Formatting Tests

    func testColorFormattingWithFullAlpha() {
        let generator = VectorDrawableXMLGenerator()

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [
                SVGPath(
                    pathData: "M0,0",
                    commands: [],
                    fill: SVGColor(red: 255, green: 128, blue: 64, alpha: 1.0),
                    stroke: nil,
                    strokeWidth: nil,
                    strokeLineCap: nil,
                    strokeLineJoin: nil,
                    fillRule: nil,
                    opacity: nil
                ),
            ]
        )

        let xml = generator.generate(from: svg)

        XCTAssertTrue(xml.contains("android:fillColor=\"#FF8040\""))
    }

    func testColorFormattingWithAlpha() {
        let generator = VectorDrawableXMLGenerator()

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [
                SVGPath(
                    pathData: "M0,0",
                    commands: [],
                    fill: SVGColor(red: 255, green: 0, blue: 0, alpha: 0.5),
                    stroke: nil,
                    strokeWidth: nil,
                    strokeLineCap: nil,
                    strokeLineJoin: nil,
                    fillRule: nil,
                    opacity: nil
                ),
            ]
        )

        let xml = generator.generate(from: svg)

        // 0.5 alpha = 0x7F, so #7FFF0000
        XCTAssertTrue(xml.contains("android:fillColor=\"#7FFF0000\""))
    }

    // MARK: - Real-World Icon Test

    func testGenerateRealWorldIcon() {
        let generator = VectorDrawableXMLGenerator()

        // Material Design checkmark icon
        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [
                SVGPath(
                    pathData: "M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41L9 16.17z",
                    commands: [],
                    fill: SVGColor(red: 0, green: 0, blue: 0),
                    stroke: nil,
                    strokeWidth: nil,
                    strokeLineCap: nil,
                    strokeLineJoin: nil,
                    fillRule: nil,
                    opacity: nil
                ),
            ]
        )

        let xml = generator.generate(from: svg)

        XCTAssertTrue(xml.hasPrefix("<?xml version=\"1.0\" encoding=\"utf-8\"?>"))
        XCTAssertTrue(xml.contains("<vector"))
        XCTAssertTrue(xml.contains("<path"))
        XCTAssertTrue(xml.contains("</vector>"))
        XCTAssertTrue(xml.contains("M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41L9 16.17z"))
    }

    // MARK: - Multiple Paths Tests

    func testGenerateMultiplePaths() {
        let generator = VectorDrawableXMLGenerator()

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [
                SVGPath(
                    pathData: "M12,4 L12,20",
                    commands: [],
                    fill: SVGColor(red: 255, green: 0, blue: 0),
                    stroke: nil,
                    strokeWidth: nil,
                    strokeLineCap: nil,
                    strokeLineJoin: nil,
                    fillRule: nil,
                    opacity: nil
                ),
                SVGPath(
                    pathData: "M4,12 L20,12",
                    commands: [],
                    fill: SVGColor(red: 0, green: 255, blue: 0),
                    stroke: nil,
                    strokeWidth: nil,
                    strokeLineCap: nil,
                    strokeLineJoin: nil,
                    fillRule: nil,
                    opacity: nil
                ),
            ]
        )

        let xml = generator.generate(from: svg)

        let pathCount = xml.components(separatedBy: "<path").count - 1
        XCTAssertEqual(pathCount, 2)
        XCTAssertTrue(xml.contains("M12,4 L12,20"))
        XCTAssertTrue(xml.contains("M4,12 L20,12"))
    }
}
