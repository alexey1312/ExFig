@testable import ExFigCLI
import FigmaAPI
import XCTest

final class BatchConfigRunnerTests: XCTestCase {
    private var tempFiles: [URL] = []

    override func tearDown() {
        super.tearDown()
        for url in tempFiles {
            try? FileManager.default.removeItem(at: url)
        }
        tempFiles.removeAll()
    }

    func testProcessConfigSuccess() async throws {
        setenv("FIGMA_PERSONAL_TOKEN", "token", 1)
        let configURL = try makeConfigFile()
        let runner = BatchConfigRunner(
            rateLimiter: SharedRateLimiter(requestsPerMinute: 600),
            retryPolicy: RetryPolicy(maxRetries: 1),
            globalOptions: GlobalOptions(),
            maxRetries: 1,
            resume: false,
            exporter: MockExporter(
                stats: ExportStats(colors: 1, icons: 2, images: 3, typography: 4)
            )
        )
        let ui = TerminalUI.create(verbose: false, quiet: true)
        let result = await runner.process(configFile: ConfigFile(url: configURL), ui: ui)

        switch result {
        case let .success(_, stats):
            XCTAssertEqual(stats.colors, 1)
            XCTAssertEqual(stats.icons, 2)
            XCTAssertEqual(stats.images, 3)
            XCTAssertEqual(stats.typography, 4)
        default:
            XCTFail("Expected success")
        }
    }

    func testProcessConfigFailure() async throws {
        setenv("FIGMA_PERSONAL_TOKEN", "token", 1)
        let configURL = try makeConfigFile()
        let runner = BatchConfigRunner(
            rateLimiter: SharedRateLimiter(requestsPerMinute: 600),
            retryPolicy: RetryPolicy(maxRetries: 1),
            globalOptions: GlobalOptions(),
            maxRetries: 1,
            resume: false,
            exporter: MockExporter(
                stats: .zero,
                shouldThrow: true
            )
        )
        let ui = TerminalUI.create(verbose: false, quiet: true)
        let result = await runner.process(configFile: ConfigFile(url: configURL), ui: ui)

        switch result {
        case .failure:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected failure")
        }
    }

    func testCacheAndConcurrencyOptionsPassedToExporter() {
        // Given
        let runner = BatchConfigRunner(
            rateLimiter: SharedRateLimiter(requestsPerMinute: 600),
            retryPolicy: RetryPolicy(maxRetries: 1),
            globalOptions: GlobalOptions(),
            maxRetries: 1,
            resume: true,
            cache: true,
            noCache: false,
            force: true,
            cachePath: "/custom/path",
            experimentalGranularCache: true,
            concurrentDownloads: 50
        )

        // Then - verify options are stored in runner
        XCTAssertTrue(runner.cache)
        XCTAssertFalse(runner.noCache)
        XCTAssertTrue(runner.force)
        XCTAssertEqual(runner.cachePath, "/custom/path")
        XCTAssertTrue(runner.experimentalGranularCache)
        XCTAssertEqual(runner.concurrentDownloads, 50)
        XCTAssertTrue(runner.resume)
    }

    func testDefaultCacheAndConcurrencyOptions() {
        // Given
        let runner = BatchConfigRunner(
            rateLimiter: SharedRateLimiter(requestsPerMinute: 600),
            retryPolicy: RetryPolicy(maxRetries: 1),
            globalOptions: GlobalOptions(),
            maxRetries: 1,
            resume: false
        )

        // Then - verify defaults
        XCTAssertFalse(runner.cache)
        XCTAssertFalse(runner.noCache)
        XCTAssertFalse(runner.force)
        XCTAssertNil(runner.cachePath)
        XCTAssertFalse(runner.experimentalGranularCache)
        XCTAssertEqual(runner.concurrentDownloads, 20)
    }

    private func makeConfigFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".pkl")
        let content = """
        figma {
          lightFileId = "abc123"
        }
        """
        try content.write(to: url, atomically: true, encoding: .utf8)
        tempFiles.append(url)
        return url
    }
}

private enum MockError: Error {
    case failure
}

private final class MockExporter: ConfigExportPerforming {
    let stats: ExportStats
    let shouldThrow: Bool

    init(stats: ExportStats, shouldThrow: Bool = false) {
        self.stats = stats
        self.shouldThrow = shouldThrow
    }

    func export(
        configFile: ConfigFile,
        options: ExFigOptions,
        client: Client,
        ui: TerminalUI
    ) async throws -> ExportStats {
        if shouldThrow {
            throw MockError.failure
        }
        _ = configFile
        _ = options
        _ = client
        _ = ui
        return stats
    }
}
