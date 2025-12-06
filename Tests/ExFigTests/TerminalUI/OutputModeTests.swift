@testable import ExFig
import XCTest

final class OutputModeTests: XCTestCase {
    // MARK: - showProgress

    func testShowProgressForNormalMode() {
        XCTAssertTrue(OutputMode.normal.showProgress)
    }

    func testShowProgressForVerboseMode() {
        XCTAssertTrue(OutputMode.verbose.showProgress)
    }

    func testShowProgressForQuietMode() {
        XCTAssertFalse(OutputMode.quiet.showProgress)
    }

    func testShowProgressForPlainMode() {
        XCTAssertFalse(OutputMode.plain.showProgress)
    }

    // MARK: - useAnimations

    func testUseAnimationsForNormalMode() {
        XCTAssertTrue(OutputMode.normal.useAnimations)
    }

    func testUseAnimationsForVerboseMode() {
        XCTAssertFalse(OutputMode.verbose.useAnimations)
    }

    func testUseAnimationsForQuietMode() {
        XCTAssertFalse(OutputMode.quiet.useAnimations)
    }

    func testUseAnimationsForPlainMode() {
        XCTAssertFalse(OutputMode.plain.useAnimations)
    }

    // MARK: - useColors

    func testUseColorsForNormalMode() {
        XCTAssertTrue(OutputMode.normal.useColors)
    }

    func testUseColorsForVerboseMode() {
        XCTAssertTrue(OutputMode.verbose.useColors)
    }

    func testUseColorsForQuietMode() {
        XCTAssertFalse(OutputMode.quiet.useColors)
    }

    func testUseColorsForPlainMode() {
        XCTAssertFalse(OutputMode.plain.useColors)
    }

    // MARK: - showDebug

    func testShowDebugForNormalMode() {
        XCTAssertFalse(OutputMode.normal.showDebug)
    }

    func testShowDebugForVerboseMode() {
        XCTAssertTrue(OutputMode.verbose.showDebug)
    }

    func testShowDebugForQuietMode() {
        XCTAssertFalse(OutputMode.quiet.showDebug)
    }

    func testShowDebugForPlainMode() {
        XCTAssertFalse(OutputMode.plain.showDebug)
    }
}
