@testable import ExFigCLI
import ExFigConfig
import Foundation
import XCTest

/// Coverage for `PKLModuleCache` — write/hit semantics and URL standardization.
/// Without these, a regression that drops the cache write or breaks URL canonicalization
/// would silently re-trigger PKL evaluation in `BatchConfigRunner`.
final class PKLModuleCacheTests: XCTestCase {
    func testResolverPopulatesCacheWithFirstConfig() async throws {
        let configURL = try BatchResolverFixture.make(
            figma: "rateLimit = 25",
            batch: "parallel = 8"
        )
        defer { try? FileManager.default.removeItem(at: configURL) }
        let ui = TerminalUI(outputMode: .quiet)
        let cache = PKLModuleCache()

        _ = await BatchSettingsResolver.resolve(
            cliParallel: nil,
            cliFailFast: false,
            cliResume: false,
            cliRateLimit: nil,
            cliMaxRetries: nil,
            cliConcurrentDownloads: nil,
            cliTimeout: nil,
            allConfigs: [configURL],
            verbose: false,
            ui: ui,
            moduleCache: cache
        )

        let cached = await cache.get(for: configURL)
        XCTAssertNotNil(cached, "resolver should populate cache after evaluating first config")
        XCTAssertEqual(cached?.figma?.rateLimit, 25)
        XCTAssertEqual(cached?.batch?.parallel, 8)
    }

    func testVerbosePreCheckPopulatesCacheForOtherConfigs() async throws {
        let firstURL = try BatchResolverFixture.make(figma: "rateLimit = 25", batch: nil)
        // `parallel = 25` is in-range (max is 50); using 99 would fail PKL constraints
        // and the second config wouldn't load — defeating the test's purpose.
        let secondURL = try BatchResolverFixture.make(figma: nil, batch: "parallel = 25")
        defer {
            try? FileManager.default.removeItem(at: firstURL)
            try? FileManager.default.removeItem(at: secondURL)
        }
        let ui = TerminalUI(outputMode: .quiet)
        let cache = PKLModuleCache()

        _ = await BatchSettingsResolver.resolve(
            cliParallel: nil,
            cliFailFast: false,
            cliResume: false,
            cliRateLimit: nil,
            cliMaxRetries: nil,
            cliConcurrentDownloads: nil,
            cliTimeout: nil,
            allConfigs: [firstURL, secondURL],
            verbose: true,
            ui: ui,
            moduleCache: cache
        )

        let firstCached = await cache.get(for: firstURL)
        let secondCached = await cache.get(for: secondURL)
        XCTAssertNotNil(firstCached, "first config cached after primary load")
        XCTAssertNotNil(secondCached, "second config cached during verbose pre-check")
        XCTAssertEqual(secondCached?.batch?.parallel, 25)
    }

    func testCacheStandardizesURLsForLookup() async throws {
        let configURL = try BatchResolverFixture.make(figma: nil, batch: "parallel = 7")
        defer { try? FileManager.default.removeItem(at: configURL) }
        let cache = PKLModuleCache()
        let module = try await PKLEvaluator.evaluate(configPath: configURL)
        await cache.set(module, for: configURL)

        // Look up via a non-standardized variant of the same path (e.g. with extra `/./`
        // segments). `standardizedFileURL` should normalize both keys to the same URL.
        let path = configURL.path
        let weirdURL = URL(fileURLWithPath: "/./" + path.dropFirst())
        let cached = await cache.get(for: weirdURL)
        XCTAssertNotNil(cached, "URL lookup should be insensitive to non-canonical path forms")
    }
}
