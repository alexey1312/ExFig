@testable import ExFig
import XCTest

final class ConflictFormatterTests: XCTestCase {
    // MARK: - Basic Formatting

    func testFormatSingleConflict() {
        let conflict = OutputPathConflict(
            path: "./Resources/Icons.xcassets",
            configs: [
                URL(fileURLWithPath: "/path/to/icons.yaml"),
                URL(fileURLWithPath: "/path/to/more-icons.yaml"),
            ]
        )
        let formatter = ConflictFormatter()

        let result = formatter.format([conflict])

        XCTAssertTrue(result.contains("Output path conflicts detected:"))
        XCTAssertTrue(result.contains("path: ./Resources/Icons.xcassets"))
        XCTAssertTrue(result.contains("configs[2]:"))
        XCTAssertTrue(result.contains("icons.yaml"))
        XCTAssertTrue(result.contains("more-icons.yaml"))
    }

    func testFormatMultipleConflicts() {
        let conflicts = [
            OutputPathConflict(
                path: "./Resources/Icons.xcassets",
                configs: [
                    URL(fileURLWithPath: "/path/to/a.yaml"),
                    URL(fileURLWithPath: "/path/to/b.yaml"),
                ]
            ),
            OutputPathConflict(
                path: "./Resources/Colors.xcassets",
                configs: [
                    URL(fileURLWithPath: "/path/to/c.yaml"),
                    URL(fileURLWithPath: "/path/to/d.yaml"),
                ]
            ),
        ]
        let formatter = ConflictFormatter()

        let result = formatter.format(conflicts)

        XCTAssertTrue(result.contains("path: ./Resources/Icons.xcassets"))
        XCTAssertTrue(result.contains("path: ./Resources/Colors.xcassets"))
        XCTAssertTrue(result.contains("a.yaml"))
        XCTAssertTrue(result.contains("b.yaml"))
        XCTAssertTrue(result.contains("c.yaml"))
        XCTAssertTrue(result.contains("d.yaml"))
    }

    // MARK: - TOON Format

    func testOutputContainsTOONArraySyntax() {
        let conflict = OutputPathConflict(
            path: "./test.xcassets",
            configs: [
                URL(fileURLWithPath: "/a.yaml"),
                URL(fileURLWithPath: "/b.yaml"),
                URL(fileURLWithPath: "/c.yaml"),
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
                URL(fileURLWithPath: "/a.yaml"),
                URL(fileURLWithPath: "/b.yaml"),
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
                URL(fileURLWithPath: "/path/to/icons.yaml"),
                URL(fileURLWithPath: "/path/to/images.yaml"),
            ]
        )
        let formatter = ConflictFormatter()

        let result = formatter.format([conflict])

        let lines = result.split(separator: "\n", omittingEmptySubsequences: false)
        let configLines = lines.filter { $0.contains(".yaml") }
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
        let configs = (1 ... 20).map { URL(fileURLWithPath: "/path/to/config-\($0).yaml") }
        let conflict = OutputPathConflict(
            path: "./Resources/Icons.xcassets",
            configs: configs
        )
        let formatter = ConflictFormatter()

        let result = formatter.format([conflict])

        XCTAssertTrue(result.contains("configs[20]:"))
        XCTAssertTrue(result.contains("config-1.yaml"))
        XCTAssertTrue(result.contains("config-20.yaml"))
    }

    func testPreservesConfigOrder() {
        let conflict = OutputPathConflict(
            path: "./test.xcassets",
            configs: [
                URL(fileURLWithPath: "/zebra.yaml"),
                URL(fileURLWithPath: "/alpha.yaml"),
                URL(fileURLWithPath: "/beta.yaml"),
            ]
        )
        let formatter = ConflictFormatter()

        let result = formatter.format([conflict])

        guard let zebraRange = result.range(of: "zebra.yaml"),
              let alphaRange = result.range(of: "alpha.yaml"),
              let betaRange = result.range(of: "beta.yaml")
        else {
            XCTFail("All configs should be in output")
            return
        }

        XCTAssertLessThan(zebraRange.lowerBound, alphaRange.lowerBound)
        XCTAssertLessThan(alphaRange.lowerBound, betaRange.lowerBound)
    }
}
