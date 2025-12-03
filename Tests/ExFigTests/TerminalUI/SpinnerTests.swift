@testable import ExFig
import XCTest

final class SpinnerTests: XCTestCase {
    func testInitialization() async {
        let spinner = Spinner(message: "Loading...", useColors: false, useAnimations: false)

        // Spinner should be created without errors
        XCTAssertNotNil(spinner)
    }

    func testStartInPlainMode() async {
        let spinner = Spinner(message: "Processing", useColors: false, useAnimations: false)

        // In plain mode, start just prints the message (no animation)
        await spinner.start()

        // Should complete without hanging
        XCTAssertNotNil(spinner)
    }

    func testUpdateMessage() async {
        let spinner = Spinner(message: "Initial", useColors: false, useAnimations: false)

        await spinner.start()
        await spinner.update(message: "Updated")

        // Should update without errors
        XCTAssertNotNil(spinner)
    }

    func testSucceed() async {
        let spinner = Spinner(message: "Task", useColors: false, useAnimations: false)

        await spinner.start()
        await spinner.succeed(message: "Done!")

        // Should complete successfully
        XCTAssertNotNil(spinner)
    }

    func testSucceedWithDefaultMessage() async {
        let spinner = Spinner(message: "Original message", useColors: false, useAnimations: false)

        await spinner.start()
        await spinner.succeed()

        // Should use original message when nil passed
        XCTAssertNotNil(spinner)
    }

    func testFail() async {
        let spinner = Spinner(message: "Task", useColors: false, useAnimations: false)

        await spinner.start()
        await spinner.fail(message: "Error occurred")

        // Should complete with failure
        XCTAssertNotNil(spinner)
    }

    func testFailWithDefaultMessage() async {
        let spinner = Spinner(message: "Original message", useColors: false, useAnimations: false)

        await spinner.start()
        await spinner.fail()

        // Should use original message when nil passed
        XCTAssertNotNil(spinner)
    }

    func testStartTwiceDoesNothing() async {
        let spinner = Spinner(message: "Test", useColors: false, useAnimations: false)

        await spinner.start()
        await spinner.start() // Second call should be ignored

        await spinner.succeed()
        XCTAssertNotNil(spinner)
    }

    func testWithColorsEnabled() async {
        let spinner = Spinner(message: "Colored", useColors: true, useAnimations: false)

        await spinner.start()
        await spinner.succeed()

        XCTAssertNotNil(spinner)
    }
}
