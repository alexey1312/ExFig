@testable import ExFig
@testable import FigmaAPI
import XCTest

/// Integration tests for batch processing with multiple configs.
final class BatchIntegrationTests: XCTestCase {
    var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BatchIntegrationTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    // MARK: - End-to-End Tests

    func testBatchProcessesMultipleConfigsInParallel() async {
        // Given: Multiple valid config files
        let configs = [
            ConfigFile(url: URL(fileURLWithPath: "/test/config1.pkl"), name: "config1"),
            ConfigFile(url: URL(fileURLWithPath: "/test/config2.pkl"), name: "config2"),
            ConfigFile(url: URL(fileURLWithPath: "/test/config3.pkl"), name: "config3"),
            ConfigFile(url: URL(fileURLWithPath: "/test/config4.pkl"), name: "config4"),
            ConfigFile(url: URL(fileURLWithPath: "/test/config5.pkl"), name: "config5"),
        ]
        let executor = BatchExecutor(maxParallel: 3)

        let tracker = ProcessingTracker()
        let handler: ConfigHandler = { configFile in
            await tracker.recordProcessing(configFile)
            // Simulate some processing time
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
            return ConfigResult.success(
                config: configFile,
                stats: ExportStats(colors: 5, icons: 10, images: 3, typography: 2)
            )
        }

        // When: Executing batch
        let result = await executor.execute(configs: configs, handler: handler)

        // Then: All configs were processed
        let processedConfigs = await tracker.processedConfigs
        XCTAssertEqual(processedConfigs.count, 5)
        XCTAssertEqual(result.successCount, 5)
        XCTAssertEqual(result.failureCount, 0)

        // Verify aggregated stats
        XCTAssertEqual(result.totalStats.colors, 25) // 5 * 5
        XCTAssertEqual(result.totalStats.icons, 50) // 5 * 10
        XCTAssertEqual(result.totalStats.images, 15) // 5 * 3
        XCTAssertEqual(result.totalStats.typography, 10) // 5 * 2
    }

    func testBatchHandlesMixedSuccessAndFailure() async {
        // Given: Configs with some that will fail
        let configs = [
            ConfigFile(url: URL(fileURLWithPath: "/test/good1.pkl"), name: "good1"),
            ConfigFile(url: URL(fileURLWithPath: "/test/bad1.pkl"), name: "bad1"),
            ConfigFile(url: URL(fileURLWithPath: "/test/good2.pkl"), name: "good2"),
            ConfigFile(url: URL(fileURLWithPath: "/test/bad2.pkl"), name: "bad2"),
            ConfigFile(url: URL(fileURLWithPath: "/test/good3.pkl"), name: "good3"),
        ]
        let executor = BatchExecutor(maxParallel: 2, failFast: false)

        let handler: ConfigHandler = { configFile in
            if configFile.name.starts(with: "bad") {
                return ConfigResult.failure(
                    config: configFile,
                    error: BatchTestError.simulatedFailure(configFile.name)
                )
            }
            return ConfigResult.success(
                config: configFile,
                stats: ExportStats(colors: 10, icons: 5, images: 0, typography: 0)
            )
        }

        // When: Executing batch
        let result = await executor.execute(configs: configs, handler: handler)

        // Then: All configs were processed
        XCTAssertEqual(result.results.count, 5)
        XCTAssertEqual(result.successCount, 3)
        XCTAssertEqual(result.failureCount, 2)

        // Verify failures contain expected configs
        let failedNames = result.failures.map(\.config.name).sorted()
        XCTAssertEqual(failedNames, ["bad1", "bad2"])
    }

    func testBatchWithRateLimitedClient() async {
        // Given: Multiple configs with rate-limited execution
        let configs = [
            ConfigFile(url: URL(fileURLWithPath: "/test/config1.pkl"), name: "config1"),
            ConfigFile(url: URL(fileURLWithPath: "/test/config2.pkl"), name: "config2"),
            ConfigFile(url: URL(fileURLWithPath: "/test/config3.pkl"), name: "config3"),
        ]

        // Create rate limiter with high rate for testing
        let rateLimiter = SharedRateLimiter(requestsPerMinute: 600.0, burstCapacity: 10.0)
        let mockClient = MockFigmaClient()
        let executor = BatchExecutor(
            maxParallel: 2,
            failFast: false,
            rateLimiter: rateLimiter,
            baseClient: mockClient
        )

        let handler: RateLimitedConfigHandler = { configFile, _ in
            // The rate-limited client handles rate limiting internally during request()
            // For this test, we just verify the executor properly passes the client
            ConfigResult.success(
                config: configFile,
                stats: ExportStats(colors: 10, icons: 0, images: 0, typography: 0)
            )
        }

        // When: Executing with rate limiting
        let result = await executor.executeWithRateLimiting(configs: configs, handler: handler)

        // Then: All configs processed successfully
        XCTAssertEqual(result.successCount, 3)
    }

    func testBatchDiscoveryAndExecution() async throws {
        // Given: Directory with multiple config files
        try createValidConfigFile(name: "ios-colors.pkl")
        try createValidConfigFile(name: "android-icons.pkl")
        try createValidConfigFile(name: "flutter-all.pkl")
        try createInvalidConfigFile(name: "not-a-config.pkl")

        // When: Discovering and filtering configs
        let discovery = ConfigDiscovery()
        let allConfigs = try discovery.discoverConfigs(in: tempDirectory)
        let validConfigs = discovery.filterValidConfigs(allConfigs)

        // Then: Only valid configs are found
        XCTAssertEqual(allConfigs.count, 4)
        XCTAssertEqual(validConfigs.count, 3)

        // When: Processing valid configs
        let configs = validConfigs.map { ConfigFile(url: $0) }
        let executor = BatchExecutor(maxParallel: 2)

        let handler: ConfigHandler = { configFile in
            .success(config: configFile, stats: ExportStats(colors: 5, icons: 5, images: 5, typography: 5))
        }

        let result = await executor.execute(configs: configs, handler: handler)

        // Then: All valid configs were processed
        XCTAssertEqual(result.successCount, 3)
        XCTAssertEqual(result.totalStats.colors, 15)
    }

    func testBatchWithOutputPathConflicts() throws {
        // Given: Configs with conflicting output paths
        try createConfigFileWithXcassets(name: "app1.pkl", path: "./Shared/Assets.xcassets")
        try createConfigFileWithXcassets(name: "app2.pkl", path: "./Shared/Assets.xcassets")
        try createConfigFileWithXcassets(name: "app3.pkl", path: "./Different/Assets.xcassets")

        // When: Detecting conflicts
        let discovery = ConfigDiscovery()
        let configs = try discovery.discoverConfigs(in: tempDirectory)
        let conflicts = try discovery.detectOutputPathConflicts(configs)

        // Then: Conflict is detected
        XCTAssertEqual(conflicts.count, 1)
        XCTAssertEqual(conflicts.first?.configs.count, 2)
        XCTAssertTrue(conflicts.first?.path.contains("Shared/Assets.xcassets") ?? false)
    }

    func testBatchReportsCorrectTiming() async {
        // Given: Configs with known processing time
        let configs = [
            ConfigFile(url: URL(fileURLWithPath: "/test/config1.pkl"), name: "config1"),
            ConfigFile(url: URL(fileURLWithPath: "/test/config2.pkl"), name: "config2"),
        ]
        let executor = BatchExecutor(maxParallel: 1) // Sequential for predictable timing

        let handler: ConfigHandler = { configFile in
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms each
            return ConfigResult.success(
                config: configFile,
                stats: ExportStats(colors: 1, icons: 0, images: 0, typography: 0)
            )
        }

        // When: Executing batch
        let result = await executor.execute(configs: configs, handler: handler)

        // Then: Duration is approximately 100ms (2 * 50ms sequential)
        XCTAssertGreaterThan(result.duration, 0.09)
        XCTAssertLessThan(result.duration, 1.0) // Should be well under 1 second

        // Verify start and end times are valid
        XCTAssertTrue(result.endTime > result.startTime)
    }

    // MARK: - Helper Methods

    private func createValidConfigFile(name: String) throws {
        let content = """
        amends "package://github.com/niceplaces/exfig@2.0.0#/ExFig.pkl"

        figma {
          lightFileId = "abc123"
        }
        ios {
          xcodeprojPath = "./MyApp.xcodeproj"
          target = "MyApp"
          xcassetsPath = "./Resources/Assets.xcassets"
        }
        """
        try content.write(
            to: tempDirectory.appendingPathComponent(name),
            atomically: true,
            encoding: .utf8
        )
    }

    private func createInvalidConfigFile(name: String) throws {
        let content = """
        not_a_config = true
        some_other_key = "value"
        """
        try content.write(
            to: tempDirectory.appendingPathComponent(name),
            atomically: true,
            encoding: .utf8
        )
    }

    private func createConfigFileWithXcassets(name: String, path: String) throws {
        let content = """
        amends "package://github.com/niceplaces/exfig@2.0.0#/ExFig.pkl"

        figma {
          lightFileId = "abc123"
        }
        ios {
          xcodeprojPath = "./MyApp.xcodeproj"
          target = "MyApp"
          xcassetsPath = "\(path)"
        }
        """
        try content.write(
            to: tempDirectory.appendingPathComponent(name),
            atomically: true,
            encoding: .utf8
        )
    }
}

// MARK: - Test Helpers

private enum BatchTestError: Error, LocalizedError {
    case simulatedFailure(String)

    var errorDescription: String? {
        switch self {
        case let .simulatedFailure(name):
            "Simulated failure for \(name)"
        }
    }
}

/// Actor to track config processing.
private actor ProcessingTracker {
    var processedConfigs: [ConfigFile] = []

    func recordProcessing(_ config: ConfigFile) {
        processedConfigs.append(config)
    }
}

/// Mock Figma client for testing rate-limited execution.
private final class MockFigmaClient: Client, @unchecked Sendable {
    var requestCount = 0

    func request<E: Endpoint>(_ endpoint: E) async throws -> E.Content {
        requestCount += 1
        // Return empty response - we don't actually need the content for these tests
        fatalError("MockFigmaClient.request should not be called in these tests")
    }
}
