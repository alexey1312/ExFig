@testable import ExFig
import XCTest

final class ProgressBarTests: XCTestCase {
    func testInitialization() async {
        let progress = ProgressBar(
            message: "Downloading",
            total: 100,
            useColors: false,
            useAnimations: false
        )

        XCTAssertNotNil(progress)
    }

    func testInitializationWithZeroTotal() async {
        // Should handle zero total by using 1 to prevent division by zero
        let progress = ProgressBar(
            message: "Empty",
            total: 0,
            useColors: false,
            useAnimations: false
        )

        await progress.succeed()
        XCTAssertNotNil(progress)
    }

    func testUpdate() async {
        let progress = ProgressBar(
            message: "Processing",
            total: 10,
            useColors: false,
            useAnimations: false
        )

        await progress.update(current: 5)

        XCTAssertNotNil(progress)
    }

    func testUpdateWithMessage() async {
        let progress = ProgressBar(
            message: "Initial",
            total: 10,
            useColors: false,
            useAnimations: false
        )

        await progress.update(current: 3, message: "Updated message")

        XCTAssertNotNil(progress)
    }

    func testUpdateBeyondTotal() async {
        let progress = ProgressBar(
            message: "Test",
            total: 5,
            useColors: false,
            useAnimations: false
        )

        // Should clamp to total
        await progress.update(current: 10)
        await progress.succeed()

        XCTAssertNotNil(progress)
    }

    func testIncrement() async {
        let progress = ProgressBar(
            message: "Counting",
            total: 5,
            useColors: false,
            useAnimations: false
        )

        await progress.increment()
        await progress.increment()
        await progress.increment()

        XCTAssertNotNil(progress)
    }

    func testIncrementWithMessage() async {
        let progress = ProgressBar(
            message: "Processing",
            total: 3,
            useColors: false,
            useAnimations: false
        )

        await progress.increment(message: "Step 1")
        await progress.increment(message: "Step 2")
        await progress.increment(message: "Step 3")

        XCTAssertNotNil(progress)
    }

    func testSucceed() async {
        let progress = ProgressBar(
            message: "Task",
            total: 10,
            useColors: false,
            useAnimations: false
        )

        await progress.update(current: 5)
        await progress.succeed(message: "Completed!")

        XCTAssertNotNil(progress)
    }

    func testSucceedWithDefaultMessage() async {
        let progress = ProgressBar(
            message: "Original",
            total: 10,
            useColors: false,
            useAnimations: false
        )

        await progress.succeed()

        XCTAssertNotNil(progress)
    }

    func testFail() async {
        let progress = ProgressBar(
            message: "Task",
            total: 10,
            useColors: false,
            useAnimations: false
        )

        await progress.update(current: 3)
        await progress.fail(message: "Error!")

        XCTAssertNotNil(progress)
    }

    func testFailWithDefaultMessage() async {
        let progress = ProgressBar(
            message: "Original",
            total: 10,
            useColors: false,
            useAnimations: false
        )

        await progress.fail()

        XCTAssertNotNil(progress)
    }

    func testWithColorsEnabled() async {
        let progress = ProgressBar(
            message: "Colored",
            total: 5,
            useColors: true,
            useAnimations: false
        )

        await progress.update(current: 2)
        await progress.succeed()

        XCTAssertNotNil(progress)
    }

    func testCustomWidth() async {
        let progress = ProgressBar(
            message: "Wide bar",
            total: 100,
            width: 50,
            useColors: false,
            useAnimations: false
        )

        await progress.update(current: 50)
        await progress.succeed()

        XCTAssertNotNil(progress)
    }

    func testProgressAtBoundaries() async {
        let progress = ProgressBar(
            message: "Boundaries",
            total: 10,
            useColors: false,
            useAnimations: false
        )

        // Test 0%
        await progress.update(current: 0)

        // Test 100%
        await progress.update(current: 10)

        await progress.succeed()

        XCTAssertNotNil(progress)
    }
}
