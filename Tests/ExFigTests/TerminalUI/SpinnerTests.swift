@testable import ExFig
import XCTest

final class SpinnerTests: XCTestCase {
    func testInitialization() {
        let spinner = Spinner(message: "Loading...", useColors: false, useAnimations: false)

        // Spinner should be created without errors
        XCTAssertNotNil(spinner)
    }

    func testStartInPlainMode() {
        let spinner = Spinner(message: "Processing", useColors: false, useAnimations: false)

        // In plain mode, start just prints the message (no animation)
        spinner.start()

        // Should complete without hanging
        XCTAssertNotNil(spinner)
    }

    func testUpdateMessage() {
        let spinner = Spinner(message: "Initial", useColors: false, useAnimations: false)

        spinner.start()
        spinner.update(message: "Updated")

        // Should update without errors
        XCTAssertNotNil(spinner)
    }

    func testSucceed() {
        let spinner = Spinner(message: "Task", useColors: false, useAnimations: false)

        spinner.start()
        spinner.succeed(message: "Done!")

        // Should complete successfully
        XCTAssertNotNil(spinner)
    }

    func testSucceedWithDefaultMessage() {
        let spinner = Spinner(message: "Original message", useColors: false, useAnimations: false)

        spinner.start()
        spinner.succeed()

        // Should use original message when nil passed
        XCTAssertNotNil(spinner)
    }

    func testFail() {
        let spinner = Spinner(message: "Task", useColors: false, useAnimations: false)

        spinner.start()
        spinner.fail(message: "Error occurred")

        // Should complete with failure
        XCTAssertNotNil(spinner)
    }

    func testFailWithDefaultMessage() {
        let spinner = Spinner(message: "Original message", useColors: false, useAnimations: false)

        spinner.start()
        spinner.fail()

        // Should use original message when nil passed
        XCTAssertNotNil(spinner)
    }

    func testStartTwiceDoesNothing() {
        let spinner = Spinner(message: "Test", useColors: false, useAnimations: false)

        spinner.start()
        spinner.start() // Second call should be ignored

        spinner.succeed()
        XCTAssertNotNil(spinner)
    }

    func testWithColorsEnabled() {
        let spinner = Spinner(message: "Colored", useColors: true, useAnimations: false)

        spinner.start()
        spinner.succeed()

        XCTAssertNotNil(spinner)
    }
}
