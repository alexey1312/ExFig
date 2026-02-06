@testable import ExFigCLI
import XCTest

final class ANSICodesTests: XCTestCase {
    // MARK: - Static Constants

    func testEscapeCode() {
        XCTAssertEqual(ANSICodes.escape, "\u{001B}")
    }

    func testCSI() {
        XCTAssertEqual(ANSICodes.csi, "\u{001B}[")
    }

    func testHideCursor() {
        XCTAssertEqual(ANSICodes.hideCursor, "\u{001B}[?25l")
    }

    func testShowCursor() {
        XCTAssertEqual(ANSICodes.showCursor, "\u{001B}[?25h")
    }

    func testCarriageReturn() {
        XCTAssertEqual(ANSICodes.carriageReturn, "\r")
    }

    func testSaveCursor() {
        XCTAssertEqual(ANSICodes.saveCursor, "\u{001B}[s")
    }

    func testRestoreCursor() {
        XCTAssertEqual(ANSICodes.restoreCursor, "\u{001B}[u")
    }

    func testClearToEndOfLine() {
        XCTAssertEqual(ANSICodes.clearToEndOfLine, "\u{001B}[K")
    }

    func testClearLine() {
        XCTAssertEqual(ANSICodes.clearLine, "\u{001B}[2K")
    }

    func testClearToEndOfScreen() {
        XCTAssertEqual(ANSICodes.clearToEndOfScreen, "\u{001B}[J")
    }

    // MARK: - Functions

    func testCursorUpDefault() {
        XCTAssertEqual(ANSICodes.cursorUp(), "\u{001B}[1A")
    }

    func testCursorUpCustom() {
        XCTAssertEqual(ANSICodes.cursorUp(5), "\u{001B}[5A")
    }

    func testCursorDownDefault() {
        XCTAssertEqual(ANSICodes.cursorDown(), "\u{001B}[1B")
    }

    func testCursorDownCustom() {
        XCTAssertEqual(ANSICodes.cursorDown(3), "\u{001B}[3B")
    }

    func testFlushStdout() {
        // Should not throw
        ANSICodes.flushStdout()
    }
}
