@testable import ExFig
import Noora
import XCTest

final class NooraUITests: XCTestCase {
    // MARK: - Format Success

    func testFormatSuccessWithColors() {
        let result = NooraUI.formatSuccess("Build completed", useColors: true)

        XCTAssertTrue(result.contains("✓"))
        XCTAssertTrue(result.contains("Build completed"))
    }

    func testFormatSuccessWithoutColors() {
        let result = NooraUI.formatSuccess("Build completed", useColors: false)

        XCTAssertEqual(result, "✓ Build completed")
    }

    // MARK: - Format Error

    func testFormatErrorWithColors() {
        let result = NooraUI.formatError("Build failed", useColors: true)

        XCTAssertTrue(result.contains("✗"))
        XCTAssertTrue(result.contains("Build failed"))
    }

    func testFormatErrorWithoutColors() {
        let result = NooraUI.formatError("Build failed", useColors: false)

        XCTAssertEqual(result, "✗ Build failed")
    }

    // MARK: - Format Warning

    func testFormatWarningWithColors() {
        let result = NooraUI.formatWarning("Deprecated API", useColors: true)

        XCTAssertTrue(result.contains("⚠"))
        XCTAssertTrue(result.contains("Deprecated API"))
    }

    func testFormatWarningWithoutColors() {
        let result = NooraUI.formatWarning("Deprecated API", useColors: false)

        XCTAssertEqual(result, "⚠ Deprecated API")
    }

    // MARK: - Format Info

    func testFormatInfoWithColors() {
        let result = NooraUI.formatInfo("Loading config", useColors: true)

        XCTAssertTrue(result.contains("Loading config"))
    }

    func testFormatInfoWithoutColors() {
        let result = NooraUI.formatInfo("Loading config", useColors: false)

        XCTAssertEqual(result, "Loading config")
    }

    // MARK: - Format Debug

    func testFormatDebugWithColors() {
        let result = NooraUI.formatDebug("Cache hit", useColors: true)

        XCTAssertTrue(result.contains("[DEBUG]"))
        XCTAssertTrue(result.contains("Cache hit"))
    }

    func testFormatDebugWithoutColors() {
        let result = NooraUI.formatDebug("Cache hit", useColors: false)

        XCTAssertEqual(result, "[DEBUG] Cache hit")
    }

    // MARK: - Format Multiline Error

    func testFormatMultilineErrorSingleLine() {
        let result = NooraUI.formatMultilineError("Single line error", useColors: false)

        XCTAssertEqual(result, "✗ Single line error")
    }

    func testFormatMultilineErrorMultipleLines() {
        let result = NooraUI.formatMultilineError("First line\nSecond line", useColors: false)
        let lines = result.split(separator: "\n")

        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(String(lines[0]), "✗ First line")
        XCTAssertEqual(String(lines[1]), "  Second line")
    }

    func testFormatMultilineErrorPreservesEmptyLines() {
        let result = NooraUI.formatMultilineError("First\n\nThird", useColors: false)
        let lines = result.split(separator: "\n", omittingEmptySubsequences: false)

        XCTAssertEqual(lines.count, 3)
    }

    // MARK: - Format Multiline Warning

    func testFormatMultilineWarningSingleLine() {
        let result = NooraUI.formatMultilineWarning("Single warning", useColors: false)

        XCTAssertEqual(result, "⚠ Single warning")
    }

    func testFormatMultilineWarningMultipleLines() {
        let result = NooraUI.formatMultilineWarning("Line 1\nLine 2", useColors: false)
        let lines = result.split(separator: "\n")

        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(String(lines[0]), "⚠ Line 1")
        XCTAssertEqual(String(lines[1]), "  Line 2")
    }

    // MARK: - Raw Format

    func testFormatTerminalText() {
        let text: TerminalText = "Hello \(.success("World"))"
        let result = NooraUI.format(text)

        XCTAssertTrue(result.contains("Hello"))
        XCTAssertTrue(result.contains("World"))
    }
}
