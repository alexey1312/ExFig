@testable import ExFig
import XCTest

final class TerminalOutputManagerTests: XCTestCase {
    // Note: TerminalOutputManager is a singleton that writes directly to stdout,
    // so we test its state management rather than actual output.

    // MARK: - Animation State Management

    func testInitialStateHasNoActiveAnimation() {
        let manager = TerminalOutputManager.shared

        // Clear any state from previous tests
        manager.hasActiveAnimation = false
        manager.clearAnimationState()

        XCTAssertFalse(manager.hasActiveAnimation)
    }

    func testHasActiveAnimationCanBeSet() {
        let manager = TerminalOutputManager.shared

        manager.hasActiveAnimation = true
        XCTAssertTrue(manager.hasActiveAnimation)

        manager.hasActiveAnimation = false
        XCTAssertFalse(manager.hasActiveAnimation)
    }

    func testClearAnimationState() {
        let manager = TerminalOutputManager.shared

        // Set up some state
        manager.hasActiveAnimation = true
        manager.writeAnimationFrame("test frame")

        // Clear animation state (only clears lastAnimationLine, not hasActiveAnimation)
        manager.clearAnimationState()

        // hasActiveAnimation is not affected by clearAnimationState
        XCTAssertTrue(manager.hasActiveAnimation)

        // Clean up
        manager.hasActiveAnimation = false
    }

    // MARK: - Singleton Pattern

    func testSharedInstanceIsSingleton() {
        let instance1 = TerminalOutputManager.shared
        let instance2 = TerminalOutputManager.shared

        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Thread Safety

    func testConcurrentAnimationStateAccess() async {
        let manager = TerminalOutputManager.shared
        manager.hasActiveAnimation = false

        await withTaskGroup(of: Void.self) { group in
            // Multiple concurrent reads
            for _ in 0 ..< 100 {
                group.addTask {
                    _ = manager.hasActiveAnimation
                }
            }

            // Multiple concurrent writes
            for i in 0 ..< 100 {
                group.addTask {
                    manager.hasActiveAnimation = i % 2 == 0
                }
            }
        }

        // Test should complete without crash or race condition
        // Final state is indeterminate but access should be safe
        _ = manager.hasActiveAnimation
    }

    func testConcurrentWriteAnimationFrame() async {
        let manager = TerminalOutputManager.shared
        manager.hasActiveAnimation = true

        await withTaskGroup(of: Void.self) { group in
            for i in 0 ..< 50 {
                group.addTask {
                    manager.writeAnimationFrame("Frame \(i)")
                }
            }
        }

        // Should complete without crash
        manager.hasActiveAnimation = false
        manager.clearAnimationState()
    }

    func testConcurrentPrint() async {
        let manager = TerminalOutputManager.shared
        manager.hasActiveAnimation = false

        await withTaskGroup(of: Void.self) { group in
            for i in 0 ..< 50 {
                group.addTask {
                    manager.print("Message \(i)")
                }
            }
        }

        // Should complete without crash
    }

    func testConcurrentPrintWithAnimation() async {
        let manager = TerminalOutputManager.shared
        manager.hasActiveAnimation = true
        manager.writeAnimationFrame("Active animation")

        await withTaskGroup(of: Void.self) { group in
            // Mix animation frames and print messages
            for i in 0 ..< 25 {
                group.addTask {
                    manager.writeAnimationFrame("Frame \(i)")
                }
                group.addTask {
                    manager.print("Log \(i)")
                }
            }
        }

        // Clean up
        manager.hasActiveAnimation = false
        manager.clearAnimationState()
    }

    // MARK: - Start Animation

    func testStartAnimationSetsActiveState() {
        let manager = TerminalOutputManager.shared
        manager.hasActiveAnimation = false

        manager.startAnimation(initialFrame: "Loading...")

        XCTAssertTrue(manager.hasActiveAnimation)

        // Clean up
        manager.hasActiveAnimation = false
        manager.clearAnimationState()
    }

    // MARK: - Edge Cases

    func testEmptyAnimationFrame() {
        let manager = TerminalOutputManager.shared
        manager.hasActiveAnimation = true

        // Should not crash with empty frame
        manager.writeAnimationFrame("")

        manager.hasActiveAnimation = false
        manager.clearAnimationState()
    }

    func testPrintWithNoAnimation() {
        let manager = TerminalOutputManager.shared
        manager.hasActiveAnimation = false

        // Should not crash when printing without active animation
        manager.print("Test message")
    }

    func testWriteDirectBypassesAnimationCoordination() {
        let manager = TerminalOutputManager.shared
        manager.hasActiveAnimation = true

        // Should not crash with direct write
        manager.writeDirect("Direct output")

        manager.hasActiveAnimation = false
    }
}
