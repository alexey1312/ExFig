@testable import ExFigCLI
import XCTest

final class MultiProgressManagerTests: XCTestCase {
    // MARK: - Initialization

    func testInitialization() {
        let manager = MultiProgressManager(useColors: true, useAnimations: false)

        // Should not crash
        XCTAssertNotNil(manager)
    }

    func testInitializationWithDefaultValues() {
        let manager = MultiProgressManager()

        // Should not crash
        XCTAssertNotNil(manager)
    }

    func testInitializationWithoutColors() {
        let manager = MultiProgressManager(useColors: false, useAnimations: false)

        XCTAssertNotNil(manager)
    }

    // MARK: - Create Progress

    func testCreateProgressReturnsUUID() async {
        let manager = MultiProgressManager(useColors: false, useAnimations: false)

        let id = await manager.createProgress(label: "Test task")

        XCTAssertNotNil(id)
    }

    func testCreateProgressWithTotal() async {
        let manager = MultiProgressManager(useColors: false, useAnimations: false)

        let id = await manager.createProgress(label: "Test task", total: 100)

        XCTAssertNotNil(id)
    }

    func testCreateMultipleProgressItems() async {
        let manager = MultiProgressManager(useColors: false, useAnimations: false)

        let id1 = await manager.createProgress(label: "Task 1")
        let id2 = await manager.createProgress(label: "Task 2")
        let id3 = await manager.createProgress(label: "Task 3")

        XCTAssertNotEqual(id1, id2)
        XCTAssertNotEqual(id2, id3)
        XCTAssertNotEqual(id1, id3)
    }

    // MARK: - Update Progress

    func testUpdateProgress() async {
        let manager = MultiProgressManager(useColors: false, useAnimations: false)
        let id = await manager.createProgress(label: "Downloading", total: 100)

        await manager.update(id: id, current: 50)

        // Should not crash
    }

    func testUpdateProgressWithMessage() async {
        let manager = MultiProgressManager(useColors: false, useAnimations: false)
        let id = await manager.createProgress(label: "Downloading", total: 100)

        await manager.update(id: id, current: 75, message: "Downloading file.txt")

        // Should not crash
    }

    func testUpdateNonExistentProgress() async {
        let manager = MultiProgressManager(useColors: false, useAnimations: false)
        let fakeId = UUID()

        await manager.update(id: fakeId, current: 50)

        // Should not crash when updating non-existent ID
    }

    // MARK: - Complete Progress

    func testCompleteProgressSuccess() async {
        let manager = MultiProgressManager(useColors: false, useAnimations: false)
        let id = await manager.createProgress(label: "Building")

        await manager.complete(id: id, success: true)

        // Should not crash
    }

    func testCompleteProgressFailure() async {
        let manager = MultiProgressManager(useColors: false, useAnimations: false)
        let id = await manager.createProgress(label: "Building")

        await manager.complete(id: id, success: false)

        // Should not crash
    }

    func testCompleteProgressWithMessage() async {
        let manager = MultiProgressManager(useColors: false, useAnimations: false)
        let id = await manager.createProgress(label: "Building")

        await manager.complete(id: id, success: true, message: "Build succeeded")

        // Should not crash
    }

    func testCompleteNonExistentProgress() async {
        let manager = MultiProgressManager(useColors: false, useAnimations: false)
        let fakeId = UUID()

        await manager.complete(id: fakeId, success: true)

        // Should not crash when completing non-existent ID
    }

    // MARK: - Remove Progress

    func testRemoveProgress() async {
        let manager = MultiProgressManager(useColors: false, useAnimations: false)
        let id = await manager.createProgress(label: "Task")

        await manager.remove(id: id)

        // Should not crash
    }

    func testRemoveNonExistentProgress() async {
        let manager = MultiProgressManager(useColors: false, useAnimations: false)
        let fakeId = UUID()

        await manager.remove(id: fakeId)

        // Should not crash when removing non-existent ID
    }

    // MARK: - Clear Progress

    func testClearProgress() async {
        let manager = MultiProgressManager(useColors: false, useAnimations: false)
        _ = await manager.createProgress(label: "Task 1")
        _ = await manager.createProgress(label: "Task 2")

        await manager.clear()

        // Should not crash
    }

    func testClearEmptyProgress() async {
        let manager = MultiProgressManager(useColors: false, useAnimations: false)

        await manager.clear()

        // Should not crash when clearing empty manager
    }

    func testClearWithAnimations() async {
        let manager = MultiProgressManager(useColors: false, useAnimations: true)
        _ = await manager.createProgress(label: "Task")

        await manager.clear()

        // Should handle animations correctly
    }

    // MARK: - Full Workflow

    func testFullWorkflow() async {
        let manager = MultiProgressManager(useColors: false, useAnimations: false)

        // Create multiple progress items
        let id1 = await manager.createProgress(label: "Downloading icons", total: 10)
        let id2 = await manager.createProgress(label: "Downloading images", total: 5)

        // Update progress
        for i in 1 ... 10 {
            await manager.update(id: id1, current: i)
        }

        for i in 1 ... 5 {
            await manager.update(id: id2, current: i)
        }

        // Complete items
        await manager.complete(id: id1, success: true, message: "Icons downloaded")
        await manager.complete(id: id2, success: true, message: "Images downloaded")

        // Remove items
        await manager.remove(id: id1)
        await manager.remove(id: id2)

        // Clear remaining
        await manager.clear()
    }

    func testProgressWithColors() async {
        let manager = MultiProgressManager(useColors: true, useAnimations: false)

        let id = await manager.createProgress(label: "Colorful task", total: 100)
        await manager.update(id: id, current: 50)
        await manager.complete(id: id, success: true)

        // Should format with colors without crashing
    }

    func testProgressWithAnimations() async {
        let manager = MultiProgressManager(useColors: false, useAnimations: true)

        let id = await manager.createProgress(label: "Animated task", total: 100)
        await manager.update(id: id, current: 25)
        await manager.update(id: id, current: 50)
        await manager.update(id: id, current: 75)
        await manager.update(id: id, current: 100)
        await manager.complete(id: id, success: true)
        await manager.clear()

        // Should render with animations without crashing
    }
}

// MARK: - ProgressState Tests

final class ProgressStateTests: XCTestCase {
    func testProgressStateStatusCases() {
        // Verify all enum cases exist and are distinct
        let running = MultiProgressManager.ProgressState.Status.running
        let succeeded = MultiProgressManager.ProgressState.Status.succeeded
        let failed = MultiProgressManager.ProgressState.Status.failed

        // Use Mirror to verify enum case names
        XCTAssertEqual(String(describing: running), "running")
        XCTAssertEqual(String(describing: succeeded), "succeeded")
        XCTAssertEqual(String(describing: failed), "failed")
    }
}
