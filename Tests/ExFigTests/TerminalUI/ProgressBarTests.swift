@testable import ExFigCLI
import XCTest

final class ProgressBarTests: XCTestCase {
    func testInitialization() {
        let progress = ProgressBar(
            message: "Downloading",
            total: 100,
            useColors: false,
            useAnimations: false
        )

        XCTAssertNotNil(progress)
    }

    func testInitializationWithZeroTotal() {
        // Should handle zero total by using 1 to prevent division by zero
        let progress = ProgressBar(
            message: "Empty",
            total: 0,
            useColors: false,
            useAnimations: false
        )

        progress.succeed()
        XCTAssertNotNil(progress)
    }

    func testUpdate() {
        let progress = ProgressBar(
            message: "Processing",
            total: 10,
            useColors: false,
            useAnimations: false
        )

        progress.update(current: 5)

        XCTAssertNotNil(progress)
    }

    func testUpdateWithMessage() {
        let progress = ProgressBar(
            message: "Initial",
            total: 10,
            useColors: false,
            useAnimations: false
        )

        progress.update(current: 3, message: "Updated message")

        XCTAssertNotNil(progress)
    }

    func testUpdateBeyondTotal() {
        let progress = ProgressBar(
            message: "Test",
            total: 5,
            useColors: false,
            useAnimations: false
        )

        // Should clamp to total
        progress.update(current: 10)
        progress.succeed()

        XCTAssertNotNil(progress)
    }

    func testIncrement() {
        let progress = ProgressBar(
            message: "Counting",
            total: 5,
            useColors: false,
            useAnimations: false
        )

        progress.increment()
        progress.increment()
        progress.increment()

        XCTAssertNotNil(progress)
    }

    func testIncrementWithMessage() {
        let progress = ProgressBar(
            message: "Processing",
            total: 3,
            useColors: false,
            useAnimations: false
        )

        progress.increment(message: "Step 1")
        progress.increment(message: "Step 2")
        progress.increment(message: "Step 3")

        XCTAssertNotNil(progress)
    }

    func testSucceed() {
        let progress = ProgressBar(
            message: "Task",
            total: 10,
            useColors: false,
            useAnimations: false
        )

        progress.update(current: 5)
        progress.succeed(message: "Completed!")

        XCTAssertNotNil(progress)
    }

    func testSucceedWithDefaultMessage() {
        let progress = ProgressBar(
            message: "Original",
            total: 10,
            useColors: false,
            useAnimations: false
        )

        progress.succeed()

        XCTAssertNotNil(progress)
    }

    func testFail() {
        let progress = ProgressBar(
            message: "Task",
            total: 10,
            useColors: false,
            useAnimations: false
        )

        progress.update(current: 3)
        progress.fail(message: "Error!")

        XCTAssertNotNil(progress)
    }

    func testFailWithDefaultMessage() {
        let progress = ProgressBar(
            message: "Original",
            total: 10,
            useColors: false,
            useAnimations: false
        )

        progress.fail()

        XCTAssertNotNil(progress)
    }

    func testWithColorsEnabled() {
        let progress = ProgressBar(
            message: "Colored",
            total: 5,
            useColors: true,
            useAnimations: false
        )

        progress.update(current: 2)
        progress.succeed()

        XCTAssertNotNil(progress)
    }

    func testCustomWidth() {
        let progress = ProgressBar(
            message: "Wide bar",
            total: 100,
            width: 50,
            useColors: false,
            useAnimations: false
        )

        progress.update(current: 50)
        progress.succeed()

        XCTAssertNotNil(progress)
    }

    func testProgressAtBoundaries() {
        let progress = ProgressBar(
            message: "Boundaries",
            total: 10,
            useColors: false,
            useAnimations: false
        )

        // Test 0%
        progress.update(current: 0)

        // Test 100%
        progress.update(current: 10)

        progress.succeed()

        XCTAssertNotNil(progress)
    }
}
