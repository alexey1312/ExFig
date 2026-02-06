@testable import ExFigCLI
import XCTest

final class ConflictFormatterTests: XCTestCase {
    // MARK: - Basic Formatting

    func testFormatSingleConflict() {
        let conflict = OutputPathConflict(
            path: "./Resources/Icons.xcassets",
            configs: [
                URL(fileURLWithPath: "/path/to/icons.pkl"),
                URL(fileURLWithPath: "/path/to/more-icons.pkl"),
            ]
        )
        let formatter = ConflictFormatter()

        let result = formatter.format([conflict])

        XCTAssertTrue(result.contains("Output path conflicts detected:"))
        XCTAssertTrue(result.contains("path: ./Resources/Icons.xcassets"))
        XCTAssertTrue(result.contains("configs[2]:"))
        XCTAssertTrue(result.contains("icons.pkl"))
        XCTAssertTrue(result.contains("more-icons.pkl"))
    }

    func testFormatMultipleConflicts() {
        let conflicts = [
            OutputPathConflict(
                path: "./Resources/Icons.xcassets",
                configs: [
                    URL(fileURLWithPath: "/path/to/a.pkl"),
                    URL(fileURLWithPath: "/path/to/b.pkl"),
                ]
            ),
            OutputPathConflict(
                path: "./Resources/Colors.xcassets",
                configs: [
                    URL(fileURLWithPath: "/path/to/c.pkl"),
                    URL(fileURLWithPath: "/path/to/d.pkl"),
                ]
            ),
        ]
        let formatter = ConflictFormatter()

        let result = formatter.format(conflicts)

        XCTAssertTrue(result.contains("path: ./Resources/Icons.xcassets"))
        XCTAssertTrue(result.contains("path: ./Resources/Colors.xcassets"))
        XCTAssertTrue(result.contains("a.pkl"))
        XCTAssertTrue(result.contains("b.pkl"))
        XCTAssertTrue(result.contains("c.pkl"))
        XCTAssertTrue(result.contains("d.pkl"))
    }

    // MARK: - TOON Format

    func testOutputContainsTOONArraySyntax() {
        let conflict = OutputPathConflict(
            path: "./test.xcassets",
            configs: [
                URL(fileURLWithPath: "/a.pkl"),
                URL(fileURLWithPath: "/b.pkl"),
                URL(fileURLWithPath: "/c.pkl"),
            ]
        )
        let formatter = ConflictFormatter()

        let result = formatter.format([conflict])

        XCTAssertTrue(result.contains("configs[3]:"), "Should contain TOON array syntax")
    }

    func testOutputIsMultiline() {
        let conflict = OutputPathConflict(
            path: "./test.xcassets",
            configs: [
                URL(fileURLWithPath: "/a.pkl"),
                URL(fileURLWithPath: "/b.pkl"),
            ]
        )
        let formatter = ConflictFormatter()

        let result = formatter.format([conflict])

        let lines = result.split(separator: "\n")
        XCTAssertGreaterThanOrEqual(lines.count, 4, "Should be multi-line output")
    }

    func testConfigLinesAreIndented() {
        let conflict = OutputPathConflict(
            path: "./test.xcassets",
            configs: [
                URL(fileURLWithPath: "/path/to/icons.pkl"),
                URL(fileURLWithPath: "/path/to/images.pkl"),
            ]
        )
        let formatter = ConflictFormatter()

        let result = formatter.format([conflict])

        let lines = result.split(separator: "\n", omittingEmptySubsequences: false)
        let configLines = lines.filter { $0.contains(".pkl") }
        for line in configLines {
            XCTAssertTrue(
                line.hasPrefix("    "),
                "Config lines should be indented with 4 spaces: '\(line)'"
            )
        }
    }

    // MARK: - Edge Cases

    func testFormatEmptyConflicts() {
        let formatter = ConflictFormatter()

        let result = formatter.format([])

        XCTAssertEqual(result, "")
    }

    func testFormatManyConfigs() {
        let configs = (1 ... 20).map { URL(fileURLWithPath: "/path/to/config-\($0).pkl") }
        let conflict = OutputPathConflict(
            path: "./Resources/Icons.xcassets",
            configs: configs
        )
        let formatter = ConflictFormatter()

        let result = formatter.format([conflict])

        XCTAssertTrue(result.contains("configs[20]:"))
        XCTAssertTrue(result.contains("config-1.pkl"))
        XCTAssertTrue(result.contains("config-20.pkl"))
    }

    func testPreservesConfigOrder() {
        let conflict = OutputPathConflict(
            path: "./test.xcassets",
            configs: [
                URL(fileURLWithPath: "/zebra.pkl"),
                URL(fileURLWithPath: "/alpha.pkl"),
                URL(fileURLWithPath: "/beta.pkl"),
            ]
        )
        let formatter = ConflictFormatter()

        let result = formatter.format([conflict])

        guard let zebraRange = result.range(of: "zebra.pkl"),
              let alphaRange = result.range(of: "alpha.pkl"),
              let betaRange = result.range(of: "beta.pkl")
        else {
            XCTFail("All configs should be in output")
            return
        }

        XCTAssertLessThan(zebraRange.lowerBound, alphaRange.lowerBound)
        XCTAssertLessThan(alphaRange.lowerBound, betaRange.lowerBound)
    }
}
