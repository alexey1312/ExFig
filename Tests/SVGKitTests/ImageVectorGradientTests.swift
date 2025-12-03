// swiftlint:disable type_body_length
@testable import SVGKit
import XCTest

final class ImageVectorGradientTests: XCTestCase {
    private let config = ImageVectorGenerator.Config(
        packageName: "com.example.icons",
        extensionTarget: nil,
        generatePreview: false
    )

    private lazy var generator = ImageVectorGenerator(config: config)

    // MARK: - Helper Methods

    private func createSVGWithLinearGradient() -> ParsedSVG {
        let stops = [
            SVGGradientStop(offset: 0, color: SVGColor(red: 255, green: 0, blue: 0)),
            SVGGradientStop(offset: 1, color: SVGColor(red: 0, green: 0, blue: 255)),
        ]
        let gradient = SVGLinearGradient(id: "grad1", x1: 0, y1: 0, x2: 24, y2: 24, stops: stops)
        let path = SVGPath(
            pathData: "M0 0h24v24H0z",
            commands: [
                .moveTo(x: 0, y: 0, relative: false),
                .horizontalLineTo(x: 24, relative: false),
                .verticalLineTo(y: 24, relative: false),
                .horizontalLineTo(x: 0, relative: false),
                .closePath,
            ],
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
            commands: [
                .moveTo(x: 0, y: 0, relative: false),
                .horizontalLineTo(x: 24, relative: false),
                .verticalLineTo(y: 24, relative: false),
                .horizontalLineTo(x: 0, relative: false),
                .closePath,
            ],
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
            commands: [
                .moveTo(x: 0, y: 0, relative: false),
                .horizontalLineTo(x: 24, relative: false),
                .verticalLineTo(y: 24, relative: false),
                .horizontalLineTo(x: 0, relative: false),
                .closePath,
            ],
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

    // MARK: - Import Tests

    func testLinearGradientAddsRequiredImports() {
        let svg = createSVGWithLinearGradient()
        let code = generator.generate(name: "test_icon", svg: svg)

        XCTAssertTrue(
            code.contains("import androidx.compose.ui.graphics.Brush"),
            "Expected Brush import:\n\(code)"
        )
        XCTAssertTrue(
            code.contains("import androidx.compose.ui.geometry.Offset"),
            "Expected Offset import:\n\(code)"
        )
    }

    func testRadialGradientAddsRequiredImports() {
        let svg = createSVGWithRadialGradient()
        let code = generator.generate(name: "test_icon", svg: svg)

        XCTAssertTrue(
            code.contains("import androidx.compose.ui.graphics.Brush"),
            "Expected Brush import:\n\(code)"
        )
        XCTAssertTrue(
            code.contains("import androidx.compose.ui.geometry.Offset"),
            "Expected Offset import:\n\(code)"
        )
    }

    func testSolidFillDoesNotAddBrushImport() {
        let svg = createSVGWithSolidFill()
        let code = generator.generate(name: "test_icon", svg: svg)

        XCTAssertFalse(
            code.contains("import androidx.compose.ui.graphics.Brush"),
            "Should not have Brush import for solid fill:\n\(code)"
        )
    }

    // MARK: - Linear Gradient Generation Tests

    func testGenerateLinearGradientFill() {
        let svg = createSVGWithLinearGradient()
        let code = generator.generate(name: "test_icon", svg: svg)

        XCTAssertTrue(
            code.contains("Brush.linearGradient"),
            "Expected linearGradient brush:\n\(code)"
        )
        XCTAssertTrue(
            code.contains("colorStops = arrayOf("),
            "Expected colorStops array:\n\(code)"
        )
        XCTAssertTrue(
            code.contains("start = Offset(0f, 0f)"),
            "Expected start offset:\n\(code)"
        )
        XCTAssertTrue(
            code.contains("end = Offset(24f, 24f)"),
            "Expected end offset:\n\(code)"
        )
    }

    func testLinearGradientColorStops() {
        let svg = createSVGWithLinearGradient()
        let code = generator.generate(name: "test_icon", svg: svg)

        XCTAssertTrue(
            code.contains("0f to Color(0xFFFF0000)"),
            "Expected first color stop (red):\n\(code)"
        )
        XCTAssertTrue(
            code.contains("1f to Color(0xFF0000FF)"),
            "Expected second color stop (blue):\n\(code)"
        )
    }

    // MARK: - Radial Gradient Generation Tests

    func testGenerateRadialGradientFill() {
        let svg = createSVGWithRadialGradient()
        let code = generator.generate(name: "test_icon", svg: svg)

        XCTAssertTrue(
            code.contains("Brush.radialGradient"),
            "Expected radialGradient brush:\n\(code)"
        )
        XCTAssertTrue(
            code.contains("center = Offset(12f, 12f)"),
            "Expected center offset:\n\(code)"
        )
        XCTAssertTrue(
            code.contains("radius = 12f"),
            "Expected radius:\n\(code)"
        )
    }

    func testRadialGradientColorStops() {
        let svg = createSVGWithRadialGradient()
        let code = generator.generate(name: "test_icon", svg: svg)

        XCTAssertTrue(
            code.contains("0f to Color(0xFFFFFFFF)"),
            "Expected first color stop (white):\n\(code)"
        )
        XCTAssertTrue(
            code.contains("1f to Color(0xFF000000)"),
            "Expected second color stop (black):\n\(code)"
        )
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
            commands: [.moveTo(x: 0, y: 0, relative: false), .closePath],
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

        let code = generator.generate(name: "test_icon", svg: svg)

        // 0.5 opacity = 0x80 alpha
        XCTAssertTrue(
            code.contains("0f to Color(0x80FF0000)"),
            "Expected 50% alpha red:\n\(code)"
        )
        XCTAssertTrue(
            code.contains("1f to Color(0xFF0000FF)"),
            "Expected full alpha blue:\n\(code)"
        )
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
            commands: [.moveTo(x: 0, y: 0, relative: false), .closePath],
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

        let code = generator.generate(name: "test_icon", svg: svg)

        XCTAssertTrue(code.contains("0f to Color(0xFFFF0000)"), "Missing red:\n\(code)")
        XCTAssertTrue(code.contains("0.5f to Color(0xFF00FF00)"), "Missing green:\n\(code)")
        XCTAssertTrue(code.contains("1f to Color(0xFF0000FF)"), "Missing blue:\n\(code)")
    }

    // MARK: - Backward Compatibility Tests

    func testSolidFillStillWorks() {
        let svg = createSVGWithSolidFill()
        let code = generator.generate(name: "test_icon", svg: svg)

        XCTAssertTrue(
            code.contains("fill = SolidColor(Color(0xFFFF0000))"),
            "Expected solid fill:\n\(code)"
        )
        XCTAssertFalse(
            code.contains("Brush."),
            "Should not have Brush for solid fill:\n\(code)"
        )
    }

    // MARK: - No Fill Tests

    func testNoFillPath() {
        let path = SVGPath(
            pathData: "M0 0h24v24H0z",
            commands: [.moveTo(x: 0, y: 0, relative: false), .closePath],
            fill: nil,
            fillType: .none,
            stroke: SVGColor(red: 0, green: 0, blue: 0),
            strokeWidth: 2,
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
            paths: [path]
        )

        let code = generator.generate(name: "test_icon", svg: svg)

        XCTAssertFalse(
            code.contains("fill = "),
            "Should not have fill for .none:\n\(code)"
        )
        XCTAssertTrue(
            code.contains("stroke = SolidColor"),
            "Should have stroke:\n\(code)"
        )
    }
}
