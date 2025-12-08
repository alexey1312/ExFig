@testable import ExFig
import XCTest

final class BatchResultTests: XCTestCase {
    // MARK: - ExportStats Tests

    func testExportStatsInitWithDefaults() {
        let stats = ExportStats()

        XCTAssertEqual(stats.colors, 0)
        XCTAssertEqual(stats.icons, 0)
        XCTAssertEqual(stats.images, 0)
        XCTAssertEqual(stats.typography, 0)
        XCTAssertTrue(stats.computedNodeHashes.isEmpty)
        XCTAssertNil(stats.granularCacheStats)
    }

    func testExportStatsInitWithValues() {
        let hashes = ["fileA": ["1:1": "hash1"]]
        let granularStats = GranularCacheStats(skipped: 10, exported: 2)

        let stats = ExportStats(
            colors: 5,
            icons: 10,
            images: 3,
            typography: 2,
            computedNodeHashes: hashes,
            granularCacheStats: granularStats
        )

        XCTAssertEqual(stats.colors, 5)
        XCTAssertEqual(stats.icons, 10)
        XCTAssertEqual(stats.images, 3)
        XCTAssertEqual(stats.typography, 2)
        XCTAssertEqual(stats.computedNodeHashes["fileA"]?["1:1"], "hash1")
        XCTAssertEqual(stats.granularCacheStats?.skipped, 10)
        XCTAssertEqual(stats.granularCacheStats?.exported, 2)
    }

    func testExportStatsZero() {
        let zero = ExportStats.zero

        XCTAssertEqual(zero.colors, 0)
        XCTAssertEqual(zero.icons, 0)
        XCTAssertEqual(zero.images, 0)
        XCTAssertEqual(zero.typography, 0)
        XCTAssertTrue(zero.computedNodeHashes.isEmpty)
        XCTAssertNil(zero.granularCacheStats)
    }

    // MARK: - ExportStats Addition

    func testExportStatsAdditionBasicCounts() {
        let stats1 = ExportStats(colors: 5, icons: 10, images: 3, typography: 2)
        let stats2 = ExportStats(colors: 3, icons: 5, images: 7, typography: 1)

        let combined = stats1 + stats2

        XCTAssertEqual(combined.colors, 8)
        XCTAssertEqual(combined.icons, 15)
        XCTAssertEqual(combined.images, 10)
        XCTAssertEqual(combined.typography, 3)
    }

    func testExportStatsAdditionMergesHashes() {
        let stats1 = ExportStats(
            computedNodeHashes: ["fileA": ["1:1": "hashA1", "1:2": "hashA2"]]
        )
        let stats2 = ExportStats(
            computedNodeHashes: ["fileB": ["2:1": "hashB1"]]
        )

        let combined = stats1 + stats2

        XCTAssertEqual(combined.computedNodeHashes["fileA"]?["1:1"], "hashA1")
        XCTAssertEqual(combined.computedNodeHashes["fileA"]?["1:2"], "hashA2")
        XCTAssertEqual(combined.computedNodeHashes["fileB"]?["2:1"], "hashB1")
    }

    func testExportStatsAdditionMergesSameFileHashes() {
        let stats1 = ExportStats(
            computedNodeHashes: ["fileA": ["1:1": "hashA1"]]
        )
        let stats2 = ExportStats(
            computedNodeHashes: ["fileA": ["1:2": "hashA2"]]
        )

        let combined = stats1 + stats2

        XCTAssertEqual(combined.computedNodeHashes["fileA"]?.count, 2)
        XCTAssertEqual(combined.computedNodeHashes["fileA"]?["1:1"], "hashA1")
        XCTAssertEqual(combined.computedNodeHashes["fileA"]?["1:2"], "hashA2")
    }

    func testExportStatsAdditionNewHashOverwritesOld() {
        let stats1 = ExportStats(
            computedNodeHashes: ["fileA": ["1:1": "oldHash"]]
        )
        let stats2 = ExportStats(
            computedNodeHashes: ["fileA": ["1:1": "newHash"]]
        )

        let combined = stats1 + stats2

        // New hash should overwrite old
        XCTAssertEqual(combined.computedNodeHashes["fileA"]?["1:1"], "newHash")
    }

    func testExportStatsAdditionMergesGranularStats() {
        let stats1 = ExportStats(
            granularCacheStats: GranularCacheStats(skipped: 10, exported: 2)
        )
        let stats2 = ExportStats(
            granularCacheStats: GranularCacheStats(skipped: 5, exported: 3)
        )

        let combined = stats1 + stats2

        XCTAssertEqual(combined.granularCacheStats?.skipped, 15)
        XCTAssertEqual(combined.granularCacheStats?.exported, 5)
    }

    func testExportStatsAdditionWithNilGranularStats() {
        let stats1 = ExportStats(
            granularCacheStats: GranularCacheStats(skipped: 10, exported: 2)
        )
        let stats2 = ExportStats(granularCacheStats: nil)

        let combined = stats1 + stats2

        XCTAssertEqual(combined.granularCacheStats?.skipped, 10)
        XCTAssertEqual(combined.granularCacheStats?.exported, 2)
    }

    func testExportStatsAdditionBothNilGranularStats() {
        let stats1 = ExportStats(granularCacheStats: nil)
        let stats2 = ExportStats(granularCacheStats: nil)

        let combined = stats1 + stats2

        XCTAssertNil(combined.granularCacheStats)
    }

    // MARK: - GranularCacheStats Tests

    func testGranularCacheStatsTotal() {
        let stats = GranularCacheStats(skipped: 100, exported: 5)

        XCTAssertEqual(stats.total, 105)
    }

    func testGranularCacheStatsMergeBothPresent() {
        let lhs = GranularCacheStats(skipped: 10, exported: 2)
        let rhs = GranularCacheStats(skipped: 5, exported: 3)

        let merged = GranularCacheStats.merge(lhs, rhs)

        XCTAssertEqual(merged?.skipped, 15)
        XCTAssertEqual(merged?.exported, 5)
    }

    func testGranularCacheStatsMergeLeftOnly() {
        let lhs = GranularCacheStats(skipped: 10, exported: 2)

        let merged = GranularCacheStats.merge(lhs, nil)

        XCTAssertEqual(merged?.skipped, 10)
        XCTAssertEqual(merged?.exported, 2)
    }

    func testGranularCacheStatsMergeRightOnly() {
        let rhs = GranularCacheStats(skipped: 5, exported: 3)

        let merged = GranularCacheStats.merge(nil, rhs)

        XCTAssertEqual(merged?.skipped, 5)
        XCTAssertEqual(merged?.exported, 3)
    }

    func testGranularCacheStatsMergeBothNil() {
        let merged = GranularCacheStats.merge(nil, nil)

        XCTAssertNil(merged)
    }

    // MARK: - BatchResult Tests

    func testBatchResultTotalStatsAggregatesComputedHashes() {
        let config1 = ConfigFile(url: URL(fileURLWithPath: "/config1.yaml"), name: "config1")
        let config2 = ConfigFile(url: URL(fileURLWithPath: "/config2.yaml"), name: "config2")

        let stats1 = ExportStats(
            icons: 5,
            computedNodeHashes: ["fileA": ["1:1": "hashA1"]]
        )
        let stats2 = ExportStats(
            icons: 3,
            computedNodeHashes: ["fileA": ["1:2": "hashA2"], "fileB": ["2:1": "hashB1"]]
        )

        let results: [ConfigResult] = [
            .success(config: config1, stats: stats1),
            .success(config: config2, stats: stats2),
        ]

        let batchResult = BatchResult(
            results: results,
            duration: 1.0,
            startTime: Date(),
            endTime: Date()
        )

        let totalStats = batchResult.totalStats

        XCTAssertEqual(totalStats.icons, 8)
        XCTAssertEqual(totalStats.computedNodeHashes["fileA"]?.count, 2)
        XCTAssertEqual(totalStats.computedNodeHashes["fileB"]?.count, 1)
    }

    func testBatchResultTotalStatsAggregatesGranularStats() {
        let config1 = ConfigFile(url: URL(fileURLWithPath: "/config1.yaml"), name: "config1")
        let config2 = ConfigFile(url: URL(fileURLWithPath: "/config2.yaml"), name: "config2")

        let stats1 = ExportStats(
            icons: 5,
            granularCacheStats: GranularCacheStats(skipped: 100, exported: 5)
        )
        let stats2 = ExportStats(
            icons: 3,
            granularCacheStats: GranularCacheStats(skipped: 50, exported: 2)
        )

        let results: [ConfigResult] = [
            .success(config: config1, stats: stats1),
            .success(config: config2, stats: stats2),
        ]

        let batchResult = BatchResult(
            results: results,
            duration: 1.0,
            startTime: Date(),
            endTime: Date()
        )

        let totalStats = batchResult.totalStats

        XCTAssertEqual(totalStats.granularCacheStats?.skipped, 150)
        XCTAssertEqual(totalStats.granularCacheStats?.exported, 7)
        XCTAssertEqual(totalStats.granularCacheStats?.total, 157)
    }

    func testBatchResultTotalStatsIgnoresFailures() {
        let config1 = ConfigFile(url: URL(fileURLWithPath: "/config1.yaml"), name: "config1")
        let config2 = ConfigFile(url: URL(fileURLWithPath: "/config2.yaml"), name: "config2")

        let stats1 = ExportStats(
            icons: 5,
            computedNodeHashes: ["fileA": ["1:1": "hash1"]],
            granularCacheStats: GranularCacheStats(skipped: 10, exported: 2)
        )

        let results: [ConfigResult] = [
            .success(config: config1, stats: stats1),
            .failure(config: config2, error: TestError.simulatedFailure),
        ]

        let batchResult = BatchResult(
            results: results,
            duration: 1.0,
            startTime: Date(),
            endTime: Date()
        )

        let totalStats = batchResult.totalStats

        XCTAssertEqual(totalStats.icons, 5)
        XCTAssertEqual(totalStats.computedNodeHashes.count, 1)
        XCTAssertEqual(totalStats.granularCacheStats?.skipped, 10)
    }

    func testBatchResultSuccessesIncludesStats() {
        let config1 = ConfigFile(url: URL(fileURLWithPath: "/config1.yaml"), name: "config1")
        let stats1 = ExportStats(
            icons: 5,
            computedNodeHashes: ["fileA": ["1:1": "hash1"]]
        )

        let results: [ConfigResult] = [
            .success(config: config1, stats: stats1),
        ]

        let batchResult = BatchResult(
            results: results,
            duration: 1.0,
            startTime: Date(),
            endTime: Date()
        )

        let successes = batchResult.successes
        XCTAssertEqual(successes.count, 1)
        XCTAssertEqual(successes.first?.stats.computedNodeHashes["fileA"]?["1:1"], "hash1")
    }
}

// MARK: - Test Helpers

private enum TestError: Error {
    case simulatedFailure
}
