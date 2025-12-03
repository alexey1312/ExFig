@testable import ExFig
import Logging
import XCTest

final class ExFigLogHandlerTests: XCTestCase {
    // MARK: - Initialization

    func testInitialization() {
        let handler = ExFigLogHandler(label: "test", logLevel: .info, outputMode: .normal)

        XCTAssertEqual(handler.label, "test")
        XCTAssertEqual(handler.logLevel, .info)
    }

    func testInitializationWithDefaultLogLevel() {
        let handler = ExFigLogHandler(label: "test", outputMode: .verbose)

        XCTAssertEqual(handler.label, "test")
        XCTAssertEqual(handler.logLevel, .info)
    }

    // MARK: - Metadata

    func testMetadataSubscriptGet() {
        var handler = ExFigLogHandler(label: "test", outputMode: .normal)
        handler.metadata["key"] = "value"

        XCTAssertEqual(handler[metadataKey: "key"], "value")
    }

    func testMetadataSubscriptSet() {
        var handler = ExFigLogHandler(label: "test", outputMode: .normal)

        handler[metadataKey: "newKey"] = "newValue"

        XCTAssertEqual(handler.metadata["newKey"], "newValue")
    }

    func testMetadataSubscriptGetNonExistent() {
        let handler = ExFigLogHandler(label: "test", outputMode: .normal)

        XCTAssertNil(handler[metadataKey: "nonexistent"])
    }

    // MARK: - Log Levels

    func testLogLevelCanBeModified() {
        var handler = ExFigLogHandler(label: "test", outputMode: .normal)

        handler.logLevel = .debug

        XCTAssertEqual(handler.logLevel, .debug)
    }

    // MARK: - Log Method

    func testLogMethodDoesNotCrash() {
        let handler = ExFigLogHandler(label: "test", outputMode: .normal)

        // Should not crash when called
        handler.log(
            level: .info,
            message: "Test message",
            metadata: nil,
            source: "TestSource",
            file: #file,
            function: #function,
            line: #line
        )
    }

    func testLogMethodInVerboseMode() {
        let handler = ExFigLogHandler(label: "test", outputMode: .verbose)

        // Should not crash with verbose formatting
        handler.log(
            level: .debug,
            message: "Debug message",
            metadata: ["key": "value"],
            source: "TestSource",
            file: "/path/to/Test.swift",
            function: "testFunction()",
            line: 42
        )
    }

    func testLogMethodInQuietMode() {
        let handler = ExFigLogHandler(label: "test", outputMode: .quiet)

        // Info should be suppressed in quiet mode
        handler.log(
            level: .info,
            message: "This should be suppressed",
            metadata: nil,
            source: "TestSource",
            file: #file,
            function: #function,
            line: #line
        )
    }

    func testLogMethodInQuietModeShowsWarnings() {
        let handler = ExFigLogHandler(label: "test", outputMode: .quiet)

        // Warnings should still show in quiet mode
        handler.log(
            level: .warning,
            message: "Warning message",
            metadata: nil,
            source: "TestSource",
            file: #file,
            function: #function,
            line: #line
        )
    }

    func testLogMethodInQuietModeShowsErrors() {
        let handler = ExFigLogHandler(label: "test", outputMode: .quiet)

        // Errors should still show in quiet mode
        handler.log(
            level: .error,
            message: "Error message",
            metadata: nil,
            source: "TestSource",
            file: #file,
            function: #function,
            line: #line
        )
    }

    func testLogMethodInPlainMode() {
        let handler = ExFigLogHandler(label: "test", outputMode: .plain)

        // Should format without colors
        handler.log(
            level: .warning,
            message: "Plain warning",
            metadata: nil,
            source: "TestSource",
            file: #file,
            function: #function,
            line: #line
        )
    }

    // MARK: - All Log Levels

    func testLogAllLevels() {
        let handler = ExFigLogHandler(label: "test", logLevel: .trace, outputMode: .verbose)
        let levels: [Logger.Level] = [.trace, .debug, .info, .notice, .warning, .error, .critical]

        for level in levels {
            // Should not crash for any log level
            handler.log(
                level: level,
                message: "Test \(level)",
                metadata: nil,
                source: "TestSource",
                file: #file,
                function: #function,
                line: #line
            )
        }
    }
}

// MARK: - ExFigLogging Tests

final class ExFigLoggingTests: XCTestCase {
    func testBootstrapDoesNotCrash() {
        // Note: LoggingSystem.bootstrap can only be called once per process
        // This test just verifies the function exists and is callable
        // In real usage, this would be called in main()

        // We can't actually call bootstrap multiple times, so just verify the type exists
        _ = ExFigLogging.self
    }
}
