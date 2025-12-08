// swiftlint:disable file_length
@testable import ExFig
import ExFigCore
import FigmaAPI
import XCTest

final class FaultToleranceOptionsTests: XCTestCase {
    // MARK: - Default Values

    func testDefaultMaxRetries() throws {
        let options = try FaultToleranceOptions.parse([])

        XCTAssertEqual(options.maxRetries, 4)
    }

    func testDefaultRateLimit() throws {
        let options = try FaultToleranceOptions.parse([])

        XCTAssertEqual(options.rateLimit, 10)
    }

    func testDefaultTimeout() throws {
        let options = try FaultToleranceOptions.parse([])

        XCTAssertNil(options.timeout)
    }

    // MARK: - Timeout Flag

    func testTimeoutFlag() throws {
        let options = try FaultToleranceOptions.parse(["--timeout", "60"])

        XCTAssertEqual(options.timeout, 60)
    }

    func testTimeoutFlagWithLargeValue() throws {
        let options = try FaultToleranceOptions.parse(["--timeout", "300"])

        XCTAssertEqual(options.timeout, 300)
    }

    func testTimeoutValidationRejectsZero() {
        XCTAssertThrowsError(try FaultToleranceOptions.parse(["--timeout", "0"]))
    }

    func testTimeoutValidationRejectsNegative() {
        XCTAssertThrowsError(try FaultToleranceOptions.parse(["--timeout", "-1"]))
    }

    // MARK: - Max Retries Flag

    func testMaxRetriesFlag() throws {
        let options = try FaultToleranceOptions.parse(["--max-retries", "6"])

        XCTAssertEqual(options.maxRetries, 6)
    }

    func testMaxRetriesZero() throws {
        let options = try FaultToleranceOptions.parse(["--max-retries", "0"])

        XCTAssertEqual(options.maxRetries, 0)
    }

    // MARK: - Rate Limit Flag

    func testRateLimitFlag() throws {
        let options = try FaultToleranceOptions.parse(["--rate-limit", "20"])

        XCTAssertEqual(options.rateLimit, 20)
    }

    func testRateLimitHighValue() throws {
        let options = try FaultToleranceOptions.parse(["--rate-limit", "100"])

        XCTAssertEqual(options.rateLimit, 100)
    }

    // MARK: - Combined Flags

    func testBothRetriesAndRateLimit() throws {
        let options = try FaultToleranceOptions.parse(["--max-retries", "3", "--rate-limit", "15"])

        XCTAssertEqual(options.maxRetries, 3)
        XCTAssertEqual(options.rateLimit, 15)
    }

    func testAllFlags() throws {
        let options = try FaultToleranceOptions.parse([
            "--max-retries", "3",
            "--rate-limit", "15",
            "--timeout", "90",
        ])

        XCTAssertEqual(options.maxRetries, 3)
        XCTAssertEqual(options.rateLimit, 15)
        XCTAssertEqual(options.timeout, 90)
    }

    // MARK: - createRetryPolicy

    func testCreateRetryPolicyWithDefaults() throws {
        let options = try FaultToleranceOptions.parse([])

        let policy = options.createRetryPolicy()

        XCTAssertEqual(policy.maxRetries, 4)
    }

    func testCreateRetryPolicyWithCustomRetries() throws {
        let options = try FaultToleranceOptions.parse(["--max-retries", "8"])

        let policy = options.createRetryPolicy()

        XCTAssertEqual(policy.maxRetries, 8)
    }

    // MARK: - createRateLimiter

    func testCreateRateLimiterWithDefaults() async throws {
        let options = try FaultToleranceOptions.parse([])

        let limiter = options.createRateLimiter()

        let status = await limiter.status()
        XCTAssertEqual(status.requestsPerMinute, 10.0)
    }

    func testCreateRateLimiterWithCustomRate() async throws {
        let options = try FaultToleranceOptions.parse(["--rate-limit", "25"])

        let limiter = options.createRateLimiter()

        let status = await limiter.status()
        XCTAssertEqual(status.requestsPerMinute, 25.0)
    }

    // MARK: - createRateLimitedClient

    func testCreateRateLimitedClientReturnsClient() throws {
        let options = try FaultToleranceOptions.parse([])
        let baseClient = FigmaClient(accessToken: "test-token", timeout: nil)
        let limiter = options.createRateLimiter()

        let client = options.createRateLimitedClient(
            wrapping: baseClient,
            rateLimiter: limiter
        )

        XCTAssertNotNil(client)
        XCTAssertTrue(client is RateLimitedClient)
    }
}

// MARK: - HeavyFaultToleranceOptionsTests

final class HeavyFaultToleranceOptionsTests: XCTestCase {
    // MARK: - Default Values

    func testDefaultValues() throws {
        let options = try HeavyFaultToleranceOptions.parse([])

        XCTAssertEqual(options.maxRetries, 4)
        XCTAssertEqual(options.rateLimit, 10)
        XCTAssertNil(options.timeout)
        XCTAssertFalse(options.failFast)
        XCTAssertFalse(options.resume)
    }

    // MARK: - Timeout Flag

    func testTimeoutFlag() throws {
        let options = try HeavyFaultToleranceOptions.parse(["--timeout", "60"])

        XCTAssertEqual(options.timeout, 60)
    }

    func testTimeoutValidationRejectsZero() {
        XCTAssertThrowsError(try HeavyFaultToleranceOptions.parse(["--timeout", "0"]))
    }

    func testTimeoutValidationRejectsNegative() {
        XCTAssertThrowsError(try HeavyFaultToleranceOptions.parse(["--timeout", "-1"]))
    }

    func testTimeoutWithOtherFlags() throws {
        let options = try HeavyFaultToleranceOptions.parse([
            "--timeout", "90",
            "--max-retries", "6",
            "--rate-limit", "20",
        ])

        XCTAssertEqual(options.timeout, 90)
        XCTAssertEqual(options.maxRetries, 6)
        XCTAssertEqual(options.rateLimit, 20)
    }

    // MARK: - Fail Fast Flag

    func testFailFastFlag() throws {
        let options = try HeavyFaultToleranceOptions.parse(["--fail-fast"])

        XCTAssertTrue(options.failFast)
    }

    func testFailFastDisablesRetries() throws {
        let options = try HeavyFaultToleranceOptions.parse(["--fail-fast", "--max-retries", "10"])

        let policy = options.createRetryPolicy()
        XCTAssertEqual(policy.maxRetries, 0)
    }

    // MARK: - Resume Flag

    func testResumeFlag() throws {
        let options = try HeavyFaultToleranceOptions.parse(["--resume"])

        XCTAssertTrue(options.resume)
    }

    // MARK: - All Flags

    func testAllFlags() throws {
        let options = try HeavyFaultToleranceOptions.parse([
            "--max-retries", "6",
            "--rate-limit", "20",
            "--timeout", "120",
            "--fail-fast",
            "--resume",
        ])

        XCTAssertEqual(options.maxRetries, 6)
        XCTAssertEqual(options.rateLimit, 20)
        XCTAssertEqual(options.timeout, 120)
        XCTAssertTrue(options.failFast)
        XCTAssertTrue(options.resume)
    }

    // MARK: - createRetryPolicy

    func testCreateRetryPolicyWithoutFailFast() throws {
        let options = try HeavyFaultToleranceOptions.parse(["--max-retries", "8"])

        let policy = options.createRetryPolicy()

        XCTAssertEqual(policy.maxRetries, 8)
    }

    func testCreateRetryPolicyWithFailFast() throws {
        let options = try HeavyFaultToleranceOptions.parse(["--fail-fast"])

        let policy = options.createRetryPolicy()

        XCTAssertEqual(policy.maxRetries, 0)
    }

    // MARK: - createRateLimiter

    func testCreateRateLimiterWithCustomRate() async throws {
        let options = try HeavyFaultToleranceOptions.parse(["--rate-limit", "30"])

        let limiter = options.createRateLimiter()

        let status = await limiter.status()
        XCTAssertEqual(status.requestsPerMinute, 30.0)
    }
}

// MARK: - Resume Integration Tests

final class ResumeIntegrationTests: XCTestCase {
    private var tempDirectory: URL!
    private var configFile: URL!

    override func setUp() async throws {
        try await super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        configFile = tempDirectory.appendingPathComponent("config.yaml")
        try "figma:\n  fileKey: test123\nicons:\n  - name: test\n".write(
            to: configFile, atomically: true, encoding: .utf8
        )
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDirectory)
        try await super.tearDown()
    }

    // MARK: - Resume After Interruption

    func testResumeFromCheckpointAfterInterruption() async throws {
        // GIVEN: An export that was interrupted with 2 of 5 icons completed
        let initialTracker = try CheckpointTracker(
            configPath: configFile.path,
            directory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1", "icon2", "icon3", "icon4", "icon5"]
        )
        await initialTracker.markCompleted(["icon1", "icon2"])
        try await initialTracker.save()

        // WHEN: Running with --resume flag
        let options = try HeavyFaultToleranceOptions.parse(["--resume"])
        let ui = TerminalUI(outputMode: .quiet)

        let resumedTracker = try await options.loadOrCreateCheckpoint(
            configPath: configFile.path,
            workingDirectory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1", "icon2", "icon3", "icon4", "icon5"],
            ui: ui
        )

        // THEN: Checkpoint is loaded with correct state
        XCTAssertNotNil(resumedTracker)
        let completed = await resumedTracker!.completedNames
        let pending = await resumedTracker!.pendingNames

        XCTAssertEqual(completed, ["icon1", "icon2"])
        XCTAssertEqual(pending, ["icon3", "icon4", "icon5"])
    }

    func testResumeFiltersAlreadyDownloadedFiles() async throws {
        // GIVEN: A checkpoint with some icons completed
        let tracker = try CheckpointTracker(
            configPath: configFile.path,
            directory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1", "icon2", "icon3"]
        )
        await tracker.markCompleted(["icon1"])
        try await tracker.save()

        // AND: Options with --resume
        let options = try HeavyFaultToleranceOptions.parse(["--resume"])
        let ui = TerminalUI(outputMode: .quiet)

        let resumedTracker = try await options.loadOrCreateCheckpoint(
            configPath: configFile.path,
            workingDirectory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1", "icon2", "icon3"],
            ui: ui
        )

        // WHEN: Filtering files for download
        let allFiles = [
            makeFileContents(name: "icon1"),
            makeFileContents(name: "icon2"),
            makeFileContents(name: "icon3"),
        ]
        let filesToDownload = await options.filterFilesForDownload(allFiles, checkpoint: resumedTracker)

        // THEN: Only pending files are returned
        XCTAssertEqual(filesToDownload.count, 2)
        let names = Set(filesToDownload.map { $0.destination.file.deletingPathExtension().lastPathComponent })
        XCTAssertEqual(names, ["icon2", "icon3"])
    }

    func testResumeCompletesAndClearsCheckpoint() async throws {
        // GIVEN: A resumed export with one icon remaining
        let tracker = try CheckpointTracker(
            configPath: configFile.path,
            directory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1", "icon2"]
        )
        await tracker.markCompleted(["icon1"])
        try await tracker.save()

        let options = try HeavyFaultToleranceOptions.parse(["--resume"])
        let ui = TerminalUI(outputMode: .quiet)

        let resumedTracker = try await options.loadOrCreateCheckpoint(
            configPath: configFile.path,
            workingDirectory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1", "icon2"],
            ui: ui
        )!

        // WHEN: Completing the last icon
        let remainingFiles = [makeFileContents(name: "icon2")]
        await options.markFilesCompleted(remainingFiles, checkpoint: resumedTracker)

        // AND: Finalizing the checkpoint
        try await options.finalizeCheckpoint(resumedTracker)

        // THEN: Checkpoint file is deleted
        let checkpointPath = tempDirectory.appendingPathComponent(ExportCheckpoint.fileName)
        XCTAssertFalse(FileManager.default.fileExists(atPath: checkpointPath.path))
    }

    func testNoResumeWithoutFlag() async throws {
        // GIVEN: A saved checkpoint exists
        let tracker = try CheckpointTracker(
            configPath: configFile.path,
            directory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1"]
        )
        try await tracker.save()

        // WHEN: Running without --resume flag
        let options = try HeavyFaultToleranceOptions.parse([])
        let ui = TerminalUI(outputMode: .quiet)

        let loadedTracker = try await options.loadOrCreateCheckpoint(
            configPath: configFile.path,
            workingDirectory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1"],
            ui: ui
        )

        // THEN: No checkpoint tracker is returned
        XCTAssertNil(loadedTracker)
    }

    func testResumeWithChangedConfigStartsFresh() async throws {
        // GIVEN: A checkpoint from a different config
        let tracker = try CheckpointTracker(
            configPath: configFile.path,
            directory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1"]
        )
        await tracker.markCompleted(["icon1"])
        try await tracker.save()

        // WHEN: Config file changes
        try "figma:\n  fileKey: differentKey\nicons:\n  - name: changed\n".write(
            to: configFile, atomically: true, encoding: .utf8
        )

        let options = try HeavyFaultToleranceOptions.parse(["--resume"])
        let ui = TerminalUI(outputMode: .quiet)

        let resumedTracker = try await options.loadOrCreateCheckpoint(
            configPath: configFile.path,
            workingDirectory: tempDirectory,
            assetType: .icons,
            assetNames: ["icon1", "icon2"],
            ui: ui
        )

        // THEN: A fresh checkpoint is created (old one invalidated by hash mismatch)
        XCTAssertNotNil(resumedTracker)
        let completed = await resumedTracker!.completedNames
        let pending = await resumedTracker!.pendingNames

        XCTAssertTrue(completed.isEmpty)
        XCTAssertEqual(pending, ["icon1", "icon2"])
    }

    // MARK: - Helper Methods

    private func makeFileContents(name: String) -> FileContents {
        let fileURL = URL(fileURLWithPath: "\(name).svg")
        let dest = Destination(directory: tempDirectory, file: fileURL)
        return FileContents(destination: dest, data: Data("test".utf8))
    }
}
