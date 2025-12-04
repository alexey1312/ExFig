@testable import ExFig
import XCTest

final class BatchExecutorTests: XCTestCase {
    // MARK: - Basic Execution Tests

    func testExecuteSingleConfig() async throws {
        // Given: A single config
        let config = ConfigFile(url: URL(fileURLWithPath: "/test/config.yaml"), name: "config")
        let executor = BatchExecutor(maxParallel: 3)

        let tracker = ExecutionTracker()
        let handler: ConfigHandler = { configFile in
            await tracker.recordExecution(configFile)
            return ConfigResult.success(
                config: configFile,
                stats: ExportStats(colors: 10, icons: 5, images: 3, typography: 2)
            )
        }

        // When: Executing batch
        let result = await executor.execute(configs: [config], handler: handler)

        // Then: Config was processed
        let executedConfigs = await tracker.executedConfigs
        XCTAssertEqual(executedConfigs.count, 1)
        XCTAssertEqual(executedConfigs.first?.name, "config")
        XCTAssertEqual(result.results.count, 1)
        XCTAssertTrue(result.results.first?.isSuccess ?? false)
    }

    func testExecuteMultipleConfigs() async throws {
        // Given: Multiple configs
        let configs = [
            ConfigFile(url: URL(fileURLWithPath: "/test/config1.yaml"), name: "config1"),
            ConfigFile(url: URL(fileURLWithPath: "/test/config2.yaml"), name: "config2"),
            ConfigFile(url: URL(fileURLWithPath: "/test/config3.yaml"), name: "config3"),
        ]
        let executor = BatchExecutor(maxParallel: 3)

        let tracker = ExecutionTracker()
        let handler: ConfigHandler = { configFile in
            await tracker.recordExecution(configFile)
            return ConfigResult.success(
                config: configFile,
                stats: ExportStats(colors: 10, icons: 5, images: 0, typography: 0)
            )
        }

        // When: Executing batch
        let result = await executor.execute(configs: configs, handler: handler)

        // Then: All configs were processed
        let executedNames = await tracker.executedNames
        XCTAssertEqual(executedNames.count, 3)
        XCTAssertEqual(result.results.count, 3)
        XCTAssertEqual(result.successCount, 3)
        XCTAssertEqual(result.failureCount, 0)
    }

    // MARK: - Parallelism Tests

    func testRespectsMaxParallelism() async throws {
        // Given: More configs than max parallelism
        let configs = (1 ... 10).map { i in
            ConfigFile(url: URL(fileURLWithPath: "/test/config\(i).yaml"), name: "config\(i)")
        }
        let executor = BatchExecutor(maxParallel: 2)

        let concurrencyTracker = ConcurrencyTracker()

        let handler: ConfigHandler = { configFile in
            await concurrencyTracker.enter()

            // Simulate work
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

            await concurrencyTracker.exit()

            return ConfigResult.success(
                config: configFile,
                stats: ExportStats(colors: 1, icons: 0, images: 0, typography: 0)
            )
        }

        // When: Executing batch
        let result = await executor.execute(configs: configs, handler: handler)

        // Then: Never exceeded max parallelism
        let maxConcurrent = await concurrencyTracker.maxConcurrent
        XCTAssertLessThanOrEqual(maxConcurrent, 2)
        XCTAssertEqual(result.results.count, 10)
    }

    // MARK: - Error Handling Tests

    func testContinueOnErrorByDefault() async throws {
        // Given: Some configs that will fail
        let configs = [
            ConfigFile(url: URL(fileURLWithPath: "/test/good1.yaml"), name: "good1"),
            ConfigFile(url: URL(fileURLWithPath: "/test/bad.yaml"), name: "bad"),
            ConfigFile(url: URL(fileURLWithPath: "/test/good2.yaml"), name: "good2"),
        ]
        let executor = BatchExecutor(maxParallel: 1, failFast: false)

        let tracker = ExecutionTracker()
        let handler: ConfigHandler = { configFile in
            await tracker.recordExecution(configFile)
            if configFile.name == "bad" {
                return ConfigResult.failure(
                    config: configFile,
                    error: TestError.simulatedFailure
                )
            }
            return ConfigResult.success(
                config: configFile,
                stats: ExportStats(colors: 10, icons: 0, images: 0, typography: 0)
            )
        }

        // When: Executing batch
        let result = await executor.execute(configs: configs, handler: handler)

        // Then: All configs were processed despite error
        let processedCount = await tracker.executedConfigs.count
        XCTAssertEqual(processedCount, 3)
        XCTAssertEqual(result.successCount, 2)
        XCTAssertEqual(result.failureCount, 1)
    }

    func testFailFastStopsOnFirstError() async throws {
        // Given: Some configs that will fail
        let configs = [
            ConfigFile(url: URL(fileURLWithPath: "/test/good1.yaml"), name: "good1"),
            ConfigFile(url: URL(fileURLWithPath: "/test/bad.yaml"), name: "bad"),
            ConfigFile(url: URL(fileURLWithPath: "/test/good2.yaml"), name: "good2"),
        ]
        let executor = BatchExecutor(maxParallel: 1, failFast: true)

        let tracker = ExecutionTracker()
        let handler: ConfigHandler = { configFile in
            await tracker.recordExecution(configFile)
            if configFile.name == "bad" {
                return ConfigResult.failure(
                    config: configFile,
                    error: TestError.simulatedFailure
                )
            }
            return ConfigResult.success(
                config: configFile,
                stats: ExportStats(colors: 10, icons: 0, images: 0, typography: 0)
            )
        }

        // When: Executing batch
        let result = await executor.execute(configs: configs, handler: handler)

        // Then: Processing stopped after failure
        let processedNames = await tracker.executedNames
        XCTAssertEqual(processedNames, ["good1", "bad"])
        XCTAssertEqual(result.failureCount, 1)
    }

    // MARK: - Result Aggregation Tests

    func testBatchResultAggregatesStats() async throws {
        // Given: Configs with various stats
        let configs = [
            ConfigFile(url: URL(fileURLWithPath: "/test/config1.yaml"), name: "config1"),
            ConfigFile(url: URL(fileURLWithPath: "/test/config2.yaml"), name: "config2"),
        ]
        let executor = BatchExecutor(maxParallel: 3)

        let statsProvider = StatsProvider(stats: [
            ExportStats(colors: 10, icons: 5, images: 3, typography: 2),
            ExportStats(colors: 20, icons: 10, images: 6, typography: 4),
        ])

        let handler: ConfigHandler = { configFile in
            let stat = await statsProvider.nextStats()
            return ConfigResult.success(config: configFile, stats: stat)
        }

        // When: Executing batch
        let result = await executor.execute(configs: configs, handler: handler)

        // Then: Stats are aggregated
        XCTAssertEqual(result.totalStats.colors, 30)
        XCTAssertEqual(result.totalStats.icons, 15)
        XCTAssertEqual(result.totalStats.images, 9)
        XCTAssertEqual(result.totalStats.typography, 6)
    }

    func testBatchResultTracksTimings() async throws {
        // Given: A config
        let config = ConfigFile(url: URL(fileURLWithPath: "/test/config.yaml"), name: "config")
        let executor = BatchExecutor(maxParallel: 1)

        let handler: ConfigHandler = { configFile in
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            return ConfigResult.success(
                config: configFile,
                stats: ExportStats(colors: 1, icons: 0, images: 0, typography: 0)
            )
        }

        // When: Executing batch
        let result = await executor.execute(configs: [config], handler: handler)

        // Then: Duration is tracked
        XCTAssertGreaterThan(result.duration, 0.05) // At least 50ms
    }
}

// MARK: - Test Helpers

private enum TestError: Error {
    case simulatedFailure
}

/// Actor to track execution order and count.
private actor ExecutionTracker {
    var executedConfigs: [ConfigFile] = []

    var executedNames: [String] {
        executedConfigs.map(\.name)
    }

    func recordExecution(_ config: ConfigFile) {
        executedConfigs.append(config)
    }
}

/// Actor to track max concurrency.
private actor ConcurrencyTracker {
    var current = 0
    var maxConcurrent = 0

    func enter() {
        current += 1
        maxConcurrent = max(maxConcurrent, current)
    }

    func exit() {
        current -= 1
    }
}

/// Actor to provide stats sequentially.
private actor StatsProvider {
    var stats: [ExportStats]
    var index = 0

    init(stats: [ExportStats]) {
        self.stats = stats
    }

    func nextStats() -> ExportStats {
        let stat = stats[index]
        index += 1
        return stat
    }
}
