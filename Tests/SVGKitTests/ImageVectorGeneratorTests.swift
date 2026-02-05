// swiftlint:disable file_length type_body_length
import CustomDump
import Foundation
@testable import SVGKit
import XCTest

final class ImageVectorGeneratorTests: XCTestCase {
    // MARK: - Basic Generation

    func testGenerateSimpleIcon() {
        let config = ImageVectorGenerator.Config(
            packageName: "com.example.icons",
            extensionTarget: nil,
            generatePreview: false
        )
        let generator = ImageVectorGenerator(config: config)

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [
                SVGPath(
                    pathData: "M12,4 L12,20",
                    commands: [
                        .moveTo(x: 12, y: 4, relative: false),
                        .lineTo(x: 12, y: 20, relative: false),
                    ],
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

        let code = generator.generate(name: "arrow_down", svg: svg)

        XCTAssertTrue(code.contains("package com.example.icons"))
        XCTAssertTrue(code.contains("public val ArrowDown: ImageVector"))
        XCTAssertTrue(code.contains("moveTo(12f, 4f)"))
        XCTAssertTrue(code.contains("lineTo(12f, 20f)"))
        XCTAssertFalse(code.contains("@Preview"))
    }

    func testGenerateWithPreview() {
        let config = ImageVectorGenerator.Config(
            packageName: "com.example.icons",
            extensionTarget: nil,
            generatePreview: true
        )
        let generator = ImageVectorGenerator(config: config)

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: []
        )

        let code = generator.generate(name: "icon", svg: svg)

        XCTAssertTrue(code.contains("@Preview(showBackground = true)"))
        XCTAssertTrue(code.contains("@Composable"))
        XCTAssertTrue(code.contains("private fun IconPreview()"))
        XCTAssertTrue(code.contains("import androidx.compose.ui.tooling.preview.Preview"))
    }

    func testGenerateWithExtensionTarget() {
        let config = ImageVectorGenerator.Config(
            packageName: "com.example.icons",
            extensionTarget: "com.example.AppIcons",
            generatePreview: false
        )
        let generator = ImageVectorGenerator(config: config)

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: []
        )

        let code = generator.generate(name: "star", svg: svg)

        XCTAssertTrue(code.contains("public val AppIcons.Star: ImageVector"))
        XCTAssertTrue(code.contains("import com.example.AppIcons"))
    }

    // MARK: - Path Commands Generation

    func testGenerateMoveToAbsolute() {
        let config = ImageVectorGenerator.Config(packageName: "com.example", generatePreview: false)
        let generator = ImageVectorGenerator(config: config)

        let svg = createSVGWithCommands([.moveTo(x: 10.5, y: 20.5, relative: false)])
        let code = generator.generate(name: "test", svg: svg)

        XCTAssertTrue(code.contains("moveTo(10.5f, 20.5f)"))
    }

    func testGenerateMoveToRelative() {
        let config = ImageVectorGenerator.Config(packageName: "com.example", generatePreview: false)
        let generator = ImageVectorGenerator(config: config)

        let svg = createSVGWithCommands([.moveTo(x: 5, y: 10, relative: true)])
        let code = generator.generate(name: "test", svg: svg)

        XCTAssertTrue(code.contains("moveToRelative(5f, 10f)"))
    }

    func testGenerateLineToAbsolute() {
        let config = ImageVectorGenerator.Config(packageName: "com.example", generatePreview: false)
        let generator = ImageVectorGenerator(config: config)

        let svg = createSVGWithCommands([.lineTo(x: 100, y: 200, relative: false)])
        let code = generator.generate(name: "test", svg: svg)

        XCTAssertTrue(code.contains("lineTo(100f, 200f)"))
    }

    func testGenerateLineToRelative() {
        let config = ImageVectorGenerator.Config(packageName: "com.example", generatePreview: false)
        let generator = ImageVectorGenerator(config: config)

        let svg = createSVGWithCommands([.lineTo(x: 10, y: 20, relative: true)])
        let code = generator.generate(name: "test", svg: svg)

        XCTAssertTrue(code.contains("lineToRelative(10f, 20f)"))
    }

    func testGenerateHorizontalLineTo() {
        let config = ImageVectorGenerator.Config(packageName: "com.example", generatePreview: false)
        let generator = ImageVectorGenerator(config: config)

        let svg = createSVGWithCommands([.horizontalLineTo(x: 50, relative: false)])
        let code = generator.generate(name: "test", svg: svg)

        XCTAssertTrue(code.contains("horizontalLineTo(50f)"))
    }

    func testGenerateVerticalLineTo() {
        let config = ImageVectorGenerator.Config(packageName: "com.example", generatePreview: false)
        let generator = ImageVectorGenerator(config: config)

        let svg = createSVGWithCommands([.verticalLineTo(y: 75, relative: false)])
        let code = generator.generate(name: "test", svg: svg)

        XCTAssertTrue(code.contains("verticalLineTo(75f)"))
    }

    func testGenerateCurveTo() {
        let config = ImageVectorGenerator.Config(packageName: "com.example", generatePreview: false)
        let generator = ImageVectorGenerator(config: config)

        let svg = createSVGWithCommands([.curveTo(x1: 1, y1: 2, x2: 3, y2: 4, x: 5, y: 6, relative: false)])
        let code = generator.generate(name: "test", svg: svg)

        XCTAssertTrue(code.contains("curveTo(1f, 2f, 3f, 4f, 5f, 6f)"))
    }

    func testGenerateSmoothCurveTo() {
        let config = ImageVectorGenerator.Config(packageName: "com.example", generatePreview: false)
        let generator = ImageVectorGenerator(config: config)

        let svg = createSVGWithCommands([.smoothCurveTo(x2: 10, y2: 20, x: 30, y: 40, relative: false)])
        let code = generator.generate(name: "test", svg: svg)

        XCTAssertTrue(code.contains("reflectiveCurveTo(10f, 20f, 30f, 40f)"))
    }

    func testGenerateQuadraticBezierCurveTo() {
        let config = ImageVectorGenerator.Config(packageName: "com.example", generatePreview: false)
        let generator = ImageVectorGenerator(config: config)

        let svg = createSVGWithCommands([.quadraticBezierCurveTo(x1: 5, y1: 10, x: 15, y: 20, relative: false)])
        let code = generator.generate(name: "test", svg: svg)

        XCTAssertTrue(code.contains("quadTo(5f, 10f, 15f, 20f)"))
    }

    func testGenerateSmoothQuadraticBezierCurveTo() {
        let config = ImageVectorGenerator.Config(packageName: "com.example", generatePreview: false)
        let generator = ImageVectorGenerator(config: config)

        let svg = createSVGWithCommands([.smoothQuadraticBezierCurveTo(x: 25, y: 35, relative: false)])
        let code = generator.generate(name: "test", svg: svg)

        XCTAssertTrue(code.contains("reflectiveQuadTo(25f, 35f)"))
    }

    func testGenerateArcTo() {
        let config = ImageVectorGenerator.Config(packageName: "com.example", generatePreview: false)
        let generator = ImageVectorGenerator(config: config)

        let svg = createSVGWithCommands([
            .arcTo(
                rx: 10,
                ry: 10,
                xAxisRotation: 0,
                largeArcFlag: true,
                sweepFlag: false,
                x: 50,
                y: 50,
                relative: false
            ),
        ])
        let code = generator.generate(name: "test", svg: svg)

        XCTAssertTrue(code.contains("arcTo(10f, 10f, 0f, true, false, 50f, 50f)"))
    }

    func testGenerateClosePath() {
        let config = ImageVectorGenerator.Config(packageName: "com.example", generatePreview: false)
        let generator = ImageVectorGenerator(config: config)

        let svg = createSVGWithCommands([.closePath])
        let code = generator.generate(name: "test", svg: svg)

        XCTAssertTrue(code.contains("close()"))
    }

    // MARK: - Path Attributes

    func testGeneratePathWithFill() {
        let config = ImageVectorGenerator.Config(packageName: "com.example", generatePreview: false)
        let generator = ImageVectorGenerator(config: config)

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [
                SVGPath(
                    pathData: "M0,0",
                    commands: [.moveTo(x: 0, y: 0, relative: false)],
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

        let code = generator.generate(name: "test", svg: svg)

        XCTAssertTrue(code.contains("fill = SolidColor(Color(0xFFFF0000))"))
    }

    func testGeneratePathWithStroke() {
        let config = ImageVectorGenerator.Config(packageName: "com.example", generatePreview: false)
        let generator = ImageVectorGenerator(config: config)

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
                    stroke: SVGColor(red: 0, green: 255, blue: 0),
                    strokeWidth: 2.5,
                    strokeLineCap: .round,
                    strokeLineJoin: .bevel,
                    fillRule: nil,
                    opacity: nil
                ),
            ]
        )

        let code = generator.generate(name: "test", svg: svg)

        XCTAssertTrue(code.contains("stroke = SolidColor(Color(0xFF00FF00))"))
        XCTAssertTrue(code.contains("strokeLineWidth = 2.5f"))
        XCTAssertTrue(code.contains("strokeLineCap = StrokeCap.Round"))
        XCTAssertTrue(code.contains("strokeLineJoin = StrokeJoin.Bevel"))
    }

    func testGeneratePathWithEvenOddFillRule() {
        let config = ImageVectorGenerator.Config(packageName: "com.example", generatePreview: false)
        let generator = ImageVectorGenerator(config: config)

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [
                SVGPath(
                    pathData: "M0,0",
                    commands: [.moveTo(x: 0, y: 0, relative: false)],
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

        let code = generator.generate(name: "test", svg: svg)

        XCTAssertTrue(code.contains("pathFillType = PathFillType.EvenOdd"))
        XCTAssertTrue(code.contains("import androidx.compose.ui.graphics.PathFillType"))
    }

    // MARK: - Color Mappings

    func testGenerateWithColorMapping() {
        let config = ImageVectorGenerator.Config(
            packageName: "com.example",
            generatePreview: false,
            colorMappings: ["000000": "MaterialTheme.colorScheme.onSurface"]
        )
        let generator = ImageVectorGenerator(config: config)

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [
                SVGPath(
                    pathData: "M0,0",
                    commands: [.moveTo(x: 0, y: 0, relative: false)],
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

        let code = generator.generate(name: "test", svg: svg)

        XCTAssertTrue(code.contains("fill = SolidColor(MaterialTheme.colorScheme.onSurface)"))
        XCTAssertFalse(code.contains("Color(0xFF000000)"))
    }

    func testGenerateWithWildcardColorMapping() {
        let config = ImageVectorGenerator.Config(
            packageName: "com.example",
            generatePreview: false,
            colorMappings: ["*": "LocalContentColor.current"]
        )
        let generator = ImageVectorGenerator(config: config)

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [
                SVGPath(
                    pathData: "M0,0",
                    commands: [.moveTo(x: 0, y: 0, relative: false)],
                    fill: SVGColor(red: 255, green: 128, blue: 64),
                    stroke: nil,
                    strokeWidth: nil,
                    strokeLineCap: nil,
                    strokeLineJoin: nil,
                    fillRule: nil,
                    opacity: nil
                ),
            ]
        )

        let code = generator.generate(name: "test", svg: svg)

        XCTAssertTrue(code.contains("fill = SolidColor(LocalContentColor.current)"))
    }

    // MARK: - Icon Naming

    func testIconNameConversion() {
        let config = ImageVectorGenerator.Config(packageName: "com.example", generatePreview: false)
        let generator = ImageVectorGenerator(config: config)

        let svg = createSVGWithCommands([])

        // Test snake_case
        var code = generator.generate(name: "arrow_back", svg: svg)
        XCTAssertTrue(code.contains("public val ArrowBack: ImageVector"))
        XCTAssertTrue(code.contains("_arrowBack"))

        // Test kebab-case
        code = generator.generate(name: "arrow-forward", svg: svg)
        XCTAssertTrue(code.contains("public val ArrowForward: ImageVector"))

        // Test single word
        code = generator.generate(name: "home", svg: svg)
        XCTAssertTrue(code.contains("public val Home: ImageVector"))
    }

    // MARK: - Dimensions

    func testGenerateWithDifferentDimensions() {
        let config = ImageVectorGenerator.Config(packageName: "com.example", generatePreview: false)
        let generator = ImageVectorGenerator(config: config)

        let svg = ParsedSVG(
            width: 48,
            height: 32,
            viewportWidth: 96,
            viewportHeight: 64,
            paths: []
        )

        let code = generator.generate(name: "test", svg: svg)

        XCTAssertTrue(code.contains("defaultWidth = 48.dp"))
        XCTAssertTrue(code.contains("defaultHeight = 32.dp"))
        XCTAssertTrue(code.contains("viewportWidth = 96f"))
        XCTAssertTrue(code.contains("viewportHeight = 64f"))
    }

    // MARK: - Imports

    func testGenerateImportsWithStroke() {
        let config = ImageVectorGenerator.Config(packageName: "com.example", generatePreview: false)
        let generator = ImageVectorGenerator(config: config)

        let svg = ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [
                SVGPath(
                    pathData: "M0,0",
                    commands: [],
                    fill: nil,
                    stroke: SVGColor(red: 0, green: 0, blue: 0),
                    strokeWidth: 2,
                    strokeLineCap: nil,
                    strokeLineJoin: nil,
                    fillRule: nil,
                    opacity: nil
                ),
            ]
        )

        let code = generator.generate(name: "test", svg: svg)

        XCTAssertTrue(code.contains("import androidx.compose.ui.graphics.StrokeCap"))
        XCTAssertTrue(code.contains("import androidx.compose.ui.graphics.StrokeJoin"))
    }

    // MARK: - Helper Methods

    private func createSVGWithCommands(_ commands: [SVGPathCommand]) -> ParsedSVG {
        ParsedSVG(
            width: 24,
            height: 24,
            viewportWidth: 24,
            viewportHeight: 24,
            paths: [
                SVGPath(
                    pathData: "",
                    commands: commands,
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
    }
}
