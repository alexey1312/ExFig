import CustomDump
import SVGKit
import XCTest

final class SVGPathParserTests: XCTestCase {
    private let parser = SVGPathParser()

    // MARK: - Basic Commands

    func testParseMoveToAbsolute() throws {
        let commands = try parser.parse("M10,20")
        expectNoDifference(commands, [.moveTo(x: 10, y: 20, relative: false)])
    }

    func testParseMoveToRelative() throws {
        let commands = try parser.parse("m10,20")
        expectNoDifference(commands, [.moveTo(x: 10, y: 20, relative: true)])
    }

    func testParseLineToAbsolute() throws {
        let commands = try parser.parse("L30,40")
        expectNoDifference(commands, [.lineTo(x: 30, y: 40, relative: false)])
    }

    func testParseLineToRelative() throws {
        let commands = try parser.parse("l30,40")
        expectNoDifference(commands, [.lineTo(x: 30, y: 40, relative: true)])
    }

    func testParseHorizontalLineToAbsolute() throws {
        let commands = try parser.parse("H50")
        expectNoDifference(commands, [.horizontalLineTo(x: 50, relative: false)])
    }

    func testParseHorizontalLineToRelative() throws {
        let commands = try parser.parse("h50")
        expectNoDifference(commands, [.horizontalLineTo(x: 50, relative: true)])
    }

    func testParseVerticalLineToAbsolute() throws {
        let commands = try parser.parse("V60")
        expectNoDifference(commands, [.verticalLineTo(y: 60, relative: false)])
    }

    func testParseVerticalLineToRelative() throws {
        let commands = try parser.parse("v60")
        expectNoDifference(commands, [.verticalLineTo(y: 60, relative: true)])
    }

    func testParseClosePath() throws {
        let commands = try parser.parse("Z")
        expectNoDifference(commands, [.closePath])
    }

    func testParseClosePathLowercase() throws {
        let commands = try parser.parse("z")
        expectNoDifference(commands, [.closePath])
    }

    // MARK: - Curve Commands

    func testParseCurveToAbsolute() throws {
        let commands = try parser.parse("C10,20,30,40,50,60")
        expectNoDifference(commands, [.curveTo(x1: 10, y1: 20, x2: 30, y2: 40, x: 50, y: 60, relative: false)])
    }

    func testParseCurveToRelative() throws {
        let commands = try parser.parse("c10,20,30,40,50,60")
        expectNoDifference(commands, [.curveTo(x1: 10, y1: 20, x2: 30, y2: 40, x: 50, y: 60, relative: true)])
    }

    func testParseSmoothCurveToAbsolute() throws {
        let commands = try parser.parse("S30,40,50,60")
        expectNoDifference(commands, [.smoothCurveTo(x2: 30, y2: 40, x: 50, y: 60, relative: false)])
    }

    func testParseSmoothCurveToRelative() throws {
        let commands = try parser.parse("s30,40,50,60")
        expectNoDifference(commands, [.smoothCurveTo(x2: 30, y2: 40, x: 50, y: 60, relative: true)])
    }

    func testParseQuadraticBezierToAbsolute() throws {
        let commands = try parser.parse("Q10,20,30,40")
        expectNoDifference(commands, [.quadraticBezierCurveTo(x1: 10, y1: 20, x: 30, y: 40, relative: false)])
    }

    func testParseQuadraticBezierToRelative() throws {
        let commands = try parser.parse("q10,20,30,40")
        expectNoDifference(commands, [.quadraticBezierCurveTo(x1: 10, y1: 20, x: 30, y: 40, relative: true)])
    }

    func testParseSmoothQuadraticBezierToAbsolute() throws {
        let commands = try parser.parse("T30,40")
        expectNoDifference(commands, [.smoothQuadraticBezierCurveTo(x: 30, y: 40, relative: false)])
    }

    func testParseSmoothQuadraticBezierToRelative() throws {
        let commands = try parser.parse("t30,40")
        expectNoDifference(commands, [.smoothQuadraticBezierCurveTo(x: 30, y: 40, relative: true)])
    }

    // MARK: - Arc Commands

    func testParseArcToAbsolute() throws {
        let commands = try parser.parse("A10,20,30,1,0,50,60")
        expectNoDifference(commands, [.arcTo(
            rx: 10, ry: 20,
            xAxisRotation: 30,
            largeArcFlag: true,
            sweepFlag: false,
            x: 50, y: 60,
            relative: false
        )])
    }

    func testParseArcToRelative() throws {
        let commands = try parser.parse("a10,20,30,0,1,50,60")
        expectNoDifference(commands, [.arcTo(
            rx: 10, ry: 20,
            xAxisRotation: 30,
            largeArcFlag: false,
            sweepFlag: true,
            x: 50, y: 60,
            relative: true
        )])
    }

    // MARK: - Complex Paths

    func testParseComplexPath() throws {
        let commands = try parser.parse("M10,20 L30,40 H50 V60 Z")
        expectNoDifference(commands, [
            .moveTo(x: 10, y: 20, relative: false),
            .lineTo(x: 30, y: 40, relative: false),
            .horizontalLineTo(x: 50, relative: false),
            .verticalLineTo(y: 60, relative: false),
            .closePath,
        ])
    }

    func testParsePathWithoutSpaces() throws {
        let commands = try parser.parse("M0,0L10,10L20,0Z")
        expectNoDifference(commands, [
            .moveTo(x: 0, y: 0, relative: false),
            .lineTo(x: 10, y: 10, relative: false),
            .lineTo(x: 20, y: 0, relative: false),
            .closePath,
        ])
    }

    func testParsePathWithNegativeNumbers() throws {
        let commands = try parser.parse("M-10,-20 L-30,40")
        expectNoDifference(commands, [
            .moveTo(x: -10, y: -20, relative: false),
            .lineTo(x: -30, y: 40, relative: false),
        ])
    }

    func testParsePathWithDecimals() throws {
        let commands = try parser.parse("M10.5,20.25 L30.75,40.125")
        expectNoDifference(commands, [
            .moveTo(x: 10.5, y: 20.25, relative: false),
            .lineTo(x: 30.75, y: 40.125, relative: false),
        ])
    }

    func testParsePathWithScientificNotation() throws {
        let commands = try parser.parse("M1e2,2e-1")
        expectNoDifference(commands, [
            .moveTo(x: 100, y: 0.2, relative: false),
        ])
    }

    func testParseMultipleMoveToBecomesLineTo() throws {
        let commands = try parser.parse("M10,20 30,40 50,60")
        expectNoDifference(commands, [
            .moveTo(x: 10, y: 20, relative: false),
            .lineTo(x: 30, y: 40, relative: false),
            .lineTo(x: 50, y: 60, relative: false),
        ])
    }

    func testParseMultipleLineTo() throws {
        let commands = try parser.parse("L10,20 30,40")
        expectNoDifference(commands, [
            .lineTo(x: 10, y: 20, relative: false),
            .lineTo(x: 30, y: 40, relative: false),
        ])
    }

    func testParseMultipleHorizontalLineTo() throws {
        let commands = try parser.parse("H10 20 30")
        expectNoDifference(commands, [
            .horizontalLineTo(x: 10, relative: false),
            .horizontalLineTo(x: 20, relative: false),
            .horizontalLineTo(x: 30, relative: false),
        ])
    }

    func testParseMultipleVerticalLineTo() throws {
        let commands = try parser.parse("V10 20 30")
        expectNoDifference(commands, [
            .verticalLineTo(y: 10, relative: false),
            .verticalLineTo(y: 20, relative: false),
            .verticalLineTo(y: 30, relative: false),
        ])
    }

    // MARK: - Real-World Icon Path

    func testParseRealWorldIconPath() throws {
        // A simplified sun icon path
        let pathData = """
        M12,4 L12,2 M12,20 L12,22 M12,17 \
        C9.23858,17 7,14.7614 7,12 C7,9.23858 9.23858,7 12,7 \
        C14.7614,7 17,9.23858 17,12 C17,14.7614 14.7614,17 12,17 Z
        """
        let commands = try parser.parse(pathData)

        // M12,4 L12,2 M12,20 L12,22 M12,17 C... C... C... C... Z = 10 commands
        XCTAssertEqual(commands.count, 10)
        expectNoDifference(commands[0], .moveTo(x: 12, y: 4, relative: false))
        expectNoDifference(commands[1], .lineTo(x: 12, y: 2, relative: false))
        expectNoDifference(commands[9], .closePath)
    }

    // MARK: - Edge Cases

    func testParseEmptyString() throws {
        let commands = try parser.parse("")
        XCTAssertTrue(commands.isEmpty)
    }

    func testParseWhitespaceOnly() throws {
        let commands = try parser.parse("   \n\t  ")
        XCTAssertTrue(commands.isEmpty)
    }
}
