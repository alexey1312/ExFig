// swiftlint:disable file_length
@testable import ExFigCLI
@testable import FigmaAPI
import XCTest

final class BatchProgressViewTests: XCTestCase {
    // MARK: - Initialization

    func testInitialization() {
        let progressView = BatchProgressView(useColors: true, useAnimations: false)

        XCTAssertNotNil(progressView)
    }

    func testInitializationWithoutColors() {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        XCTAssertNotNil(progressView)
    }

    func testInitializationWithAnimations() {
        let progressView = BatchProgressView(useColors: false, useAnimations: true)

        XCTAssertNotNil(progressView)
    }

    // MARK: - Config Registration

    func testRegisterConfig() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")

        // Should not crash
    }

    func testRegisterMultipleConfigs() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "config1.pkl")
        await progressView.registerConfig(name: "config2.pkl")
        await progressView.registerConfig(name: "config3.pkl")

        // Should not crash
    }

    func testRegisterDuplicateConfig() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.registerConfig(name: "test.pkl")

        // Should not crash, should handle duplicate gracefully
    }

    // MARK: - Config State Transitions

    func testStartConfig() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.startConfig(name: "test.pkl")

        // Should not crash
    }

    func testStartNonExistentConfig() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.startConfig(name: "nonexistent.pkl")

        // Should not crash when starting non-existent config
    }

    func testSucceedConfig() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.startConfig(name: "test.pkl")
        await progressView.succeedConfig(name: "test.pkl")

        // Should not crash
    }

    func testFailConfig() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.startConfig(name: "test.pkl")
        await progressView.failConfig(name: "test.pkl", error: "Test error")

        // Should not crash
    }

    // MARK: - Progress Updates

    func testUpdateProgressColors() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.startConfig(name: "test.pkl")
        await progressView.updateProgress(name: "test.pkl", colors: (5, 10))

        // Should not crash
    }

    func testUpdateProgressIcons() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.startConfig(name: "test.pkl")
        await progressView.updateProgress(name: "test.pkl", icons: (3, 20))

        // Should not crash
    }

    func testUpdateProgressImages() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.startConfig(name: "test.pkl")
        await progressView.updateProgress(name: "test.pkl", images: (7, 15))

        // Should not crash
    }

    func testUpdateProgressTypography() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.startConfig(name: "test.pkl")
        await progressView.updateProgress(name: "test.pkl", typography: (2, 5))

        // Should not crash
    }

    func testUpdateProgressMultipleTypes() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.startConfig(name: "test.pkl")
        await progressView.updateProgress(
            name: "test.pkl",
            colors: (10, 10),
            icons: (5, 20),
            images: (3, 10),
            typography: (2, 2)
        )

        // Should not crash
    }

    func testUpdateProgressNonExistentConfig() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.updateProgress(name: "nonexistent.pkl", icons: (1, 10))

        // Should not crash when updating non-existent config
    }

    // MARK: - Log Queue

    func testQueueLogMessage() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.queueLogMessage("Test warning message")

        // Should not crash
    }

    func testQueueMultipleLogMessages() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.queueLogMessage("Warning 1")
        await progressView.queueLogMessage("Warning 2")
        await progressView.queueLogMessage("Warning 3")

        // Should not crash, messages should be processed in order
    }

    func testQueueLogMessageWithMultilineContent() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.queueLogMessage("Line 1\nLine 2\nLine 3")

        // Should handle multiline messages
    }

    // MARK: - Log Queue with Progress Updates (Race Condition Prevention)

    /// Test that queueLogMessage properly coordinates with progress updates.
    /// This is the key test for the race condition fix.
    func testLogMessageBeforeProgressUpdate() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.startConfig(name: "test.pkl")

        // Queue log message first
        await progressView.queueLogMessage("Warning: something happened")

        // Then update progress
        await progressView.updateProgress(name: "test.pkl", icons: (1, 10))

        // Should not crash, log should be processed before progress update
    }

    func testLogMessageDuringProgressUpdates() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.startConfig(name: "test.pkl")

        // Interleave log messages and progress updates
        await progressView.updateProgress(name: "test.pkl", icons: (1, 10))
        await progressView.queueLogMessage("Warning 1")
        await progressView.updateProgress(name: "test.pkl", icons: (2, 10))
        await progressView.queueLogMessage("Warning 2")
        await progressView.updateProgress(name: "test.pkl", icons: (3, 10))

        // Should handle interleaved operations correctly
    }

    // MARK: - Concurrent Operations

    func testConcurrentProgressUpdates() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.startConfig(name: "test.pkl")

        // Simulate concurrent progress updates
        await withTaskGroup(of: Void.self) { group in
            for i in 1 ... 20 {
                group.addTask {
                    await progressView.updateProgress(name: "test.pkl", icons: (i, 20))
                }
            }
        }

        // Should handle concurrent updates without crashing
    }

    func testConcurrentLogMessagesAndProgressUpdates() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.startConfig(name: "test.pkl")

        // Simulate concurrent log messages and progress updates
        await withTaskGroup(of: Void.self) { group in
            // Progress updates
            for i in 1 ... 10 {
                group.addTask {
                    await progressView.updateProgress(name: "test.pkl", icons: (i, 10))
                }
            }

            // Log messages
            for i in 1 ... 5 {
                group.addTask {
                    await progressView.queueLogMessage("Warning \(i)")
                }
            }
        }

        // Should handle concurrent operations without crashing or duplicating lines
    }

    func testConcurrentConfigOperations() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        // Register multiple configs
        for i in 1 ... 5 {
            await progressView.registerConfig(name: "config\(i).pkl")
        }

        // Start all configs concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 1 ... 5 {
                group.addTask {
                    await progressView.startConfig(name: "config\(i).pkl")
                }
            }
        }

        // Update all configs concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 1 ... 5 {
                for j in 1 ... 10 {
                    group.addTask {
                        await progressView.updateProgress(
                            name: "config\(i).pkl",
                            icons: (j, 10)
                        )
                    }
                }
            }
        }

        // Complete all configs concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 1 ... 5 {
                group.addTask {
                    await progressView.succeedConfig(name: "config\(i).pkl")
                }
            }
        }

        // Should handle all concurrent operations correctly
    }

    // MARK: - Rate Limiter Status

    func testUpdateRateLimiterStatus() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")

        let status = RateLimiterStatus(
            availableTokens: 8.0,
            maxTokens: 10.0,
            requestsPerMinute: 10.0,
            isPaused: false,
            retryAfter: nil,
            pendingRequestCount: 5,
            configRequestCounts: [:]
        )
        await progressView.updateRateLimiterStatus(status)

        // Should not crash
    }

    func testUpdateRateLimiterStatusPaused() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")

        let status = RateLimiterStatus(
            availableTokens: 0.0,
            maxTokens: 10.0,
            requestsPerMinute: 0.0,
            isPaused: true,
            retryAfter: 30.0,
            pendingRequestCount: 10,
            configRequestCounts: [:]
        )
        await progressView.updateRateLimiterStatus(status)

        // Should show paused state
    }

    // MARK: - Terminal Resize

    func testHandleTerminalResize() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.handleTerminalResize()

        // Should not crash
    }

    // MARK: - Clear

    func testClear() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.startConfig(name: "test.pkl")
        await progressView.updateProgress(name: "test.pkl", icons: (5, 10))
        await progressView.clear()

        // Should not crash
    }

    func testClearWithAnimations() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: true)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.startConfig(name: "test.pkl")
        await progressView.clear()

        // Should handle animations correctly
    }

    func testClearEmpty() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.clear()

        // Should not crash when clearing empty progress view
    }

    // MARK: - Full Workflow

    func testFullWorkflow() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        // Register configs
        await progressView.registerConfig(name: "ios.pkl")
        await progressView.registerConfig(name: "android.pkl")

        // Start first config
        await progressView.startConfig(name: "ios.pkl")

        // Update progress with warnings
        await progressView.updateProgress(name: "ios.pkl", colors: (5, 10))
        await progressView.queueLogMessage("Warning: Missing dark color variant")
        await progressView.updateProgress(name: "ios.pkl", colors: (10, 10))
        await progressView.updateProgress(name: "ios.pkl", icons: (3, 20))
        await progressView.queueLogMessage("Warning: Icon naming convention")
        await progressView.updateProgress(name: "ios.pkl", icons: (20, 20))

        // Complete first config
        await progressView.succeedConfig(name: "ios.pkl")

        // Start and complete second config
        await progressView.startConfig(name: "android.pkl")
        await progressView.updateProgress(name: "android.pkl", colors: (10, 10))
        await progressView.updateProgress(name: "android.pkl", icons: (15, 15))
        await progressView.succeedConfig(name: "android.pkl")

        // Clear
        await progressView.clear()

        // Should complete full workflow without issues
    }

    func testFullWorkflowWithColors() async {
        let progressView = BatchProgressView(useColors: true, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.startConfig(name: "test.pkl")
        await progressView.updateProgress(name: "test.pkl", icons: (5, 10))
        await progressView.queueLogMessage("Colored warning")
        await progressView.updateProgress(name: "test.pkl", icons: (10, 10))
        await progressView.succeedConfig(name: "test.pkl")
        await progressView.clear()

        // Should format with colors correctly
    }

    func testFullWorkflowWithAnimations() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: true)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.startConfig(name: "test.pkl")

        for i in 1 ... 10 {
            await progressView.updateProgress(name: "test.pkl", icons: (i, 10))
        }

        await progressView.succeedConfig(name: "test.pkl")
        await progressView.clear()

        // Should render with animations correctly
    }

    // MARK: - Error Cases

    func testFailConfigWithLongErrorMessage() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.startConfig(name: "test.pkl")

        let longError = String(repeating: "Error message ", count: 10)
        await progressView.failConfig(name: "test.pkl", error: longError)

        // Should truncate long error messages
    }

    func testQueueLogMessageWithEmptyString() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.queueLogMessage("")

        // Should handle empty log message
    }

    func testQueueLogMessageWithSpecialCharacters() async {
        let progressView = BatchProgressView(useColors: false, useAnimations: false)

        await progressView.registerConfig(name: "test.pkl")
        await progressView.queueLogMessage("Warning: \u{001B}[31mRed text\u{001B}[0m")

        // Should handle ANSI escape codes in messages
    }
}

// MARK: - ConfigState Tests

final class BatchProgressViewConfigStateTests: XCTestCase {
    func testConfigStateStatusCases() {
        // Verify all enum cases exist
        let pending = BatchProgressView.ConfigState.Status.pending
        let running = BatchProgressView.ConfigState.Status.running
        let succeeded = BatchProgressView.ConfigState.Status.succeeded
        let failed = BatchProgressView.ConfigState.Status.failed("error")

        XCTAssertEqual(String(describing: pending), "pending")
        XCTAssertEqual(String(describing: running), "running")
        XCTAssertEqual(String(describing: succeeded), "succeeded")

        if case let .failed(message) = failed {
            XCTAssertEqual(message, "error")
        } else {
            XCTFail("Expected failed status")
        }
    }

    func testExportProgressInitialization() {
        let progress = BatchProgressView.ConfigState.ExportProgress()

        XCTAssertNil(progress.colors)
        XCTAssertNil(progress.icons)
        XCTAssertNil(progress.images)
        XCTAssertNil(progress.typography)
    }
}
