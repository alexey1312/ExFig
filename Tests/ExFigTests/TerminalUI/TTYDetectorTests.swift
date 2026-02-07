@testable import ExFigCLI
import XCTest

final class TTYDetectorTests: XCTestCase {
    // MARK: - isTTY

    func testIsTTYReturnsValue() {
        // In test environment, isTTY may be true or false depending on how tests are run
        // Just verify it returns a Bool without crashing
        _ = TTYDetector.isTTY
    }

    // MARK: - forceColor

    func testForceColorReturnsValue() {
        // Environment may or may not have FORCE_COLOR set
        _ = TTYDetector.forceColor
    }

    // MARK: - noColor

    func testNoColorReturnsValue() {
        // Environment may or may not have NO_COLOR set
        _ = TTYDetector.noColor
    }

    // MARK: - isCI

    func testIsCIReturnsValue() {
        // In CI environment this will be true, locally false
        _ = TTYDetector.isCI
    }

    // MARK: - effectiveMode

    func testEffectiveModeQuietTakesPriority() {
        let mode = TTYDetector.effectiveMode(verbose: true, quiet: true)

        XCTAssertEqual(mode, .quiet)
    }

    func testEffectiveModeVerbose() {
        let mode = TTYDetector.effectiveMode(verbose: true, quiet: false)

        XCTAssertEqual(mode, .verbose)
    }

    func testEffectiveModeDefault() {
        // When not verbose and not quiet, mode depends on TTY/CI
        let mode = TTYDetector.effectiveMode(verbose: false, quiet: false)

        // Either .normal or .plain depending on environment
        XCTAssertTrue(mode == .normal || mode == .plain)
    }

    // MARK: - colorsEnabled

    func testColorsEnabledReturnsValue() {
        // Value depends on environment (TTY, CI, FORCE_COLOR, NO_COLOR)
        _ = TTYDetector.colorsEnabled
    }
}
