@testable import ExFigCLI
import XCTest

final class CacheOptionsTests: XCTestCase {
    // MARK: - isEnabled

    func testIsEnabledReturnsFalseByDefault() throws {
        let options = try CacheOptions.parse([])

        XCTAssertFalse(options.isEnabled(configEnabled: false))
    }

    func testIsEnabledReturnsTrueWhenCacheFlagIsSet() throws {
        let options = try CacheOptions.parse(["--cache"])

        XCTAssertTrue(options.isEnabled(configEnabled: false))
    }

    func testIsEnabledReturnsTrueWhenConfigEnabled() throws {
        let options = try CacheOptions.parse([])

        XCTAssertTrue(options.isEnabled(configEnabled: true))
    }

    func testNoCacheFlagOverridesConfig() throws {
        let options = try CacheOptions.parse(["--no-cache"])

        XCTAssertFalse(options.isEnabled(configEnabled: true))
    }

    func testForceFlagEnablesCache() throws {
        let options = try CacheOptions.parse(["--force"])

        XCTAssertTrue(options.isEnabled(configEnabled: false))
    }

    func testNoCacheTakesPriorityOverCacheFlag() throws {
        let options = try CacheOptions.parse(["--cache", "--no-cache"])

        XCTAssertFalse(options.isEnabled(configEnabled: true))
    }

    // MARK: - resolvePath

    func testResolvePathReturnsNilByDefault() throws {
        let options = try CacheOptions.parse([])

        XCTAssertNil(options.resolvePath(configPath: nil))
    }

    func testResolvePathReturnsConfigPath() throws {
        let options = try CacheOptions.parse([])

        XCTAssertEqual(
            options.resolvePath(configPath: "/custom/path.json"),
            "/custom/path.json"
        )
    }

    func testResolvePathCLIOverridesConfig() throws {
        let options = try CacheOptions.parse(["--cache-path", "/cli/path.json"])

        XCTAssertEqual(
            options.resolvePath(configPath: "/config/path.json"),
            "/cli/path.json"
        )
    }

    // MARK: - Experimental Granular Cache

    func testGranularCacheDisabledByDefault() throws {
        let options = try CacheOptions.parse([])

        XCTAssertFalse(options.experimentalGranularCache)
    }

    func testGranularCacheFlagParsed() throws {
        let options = try CacheOptions.parse(["--experimental-granular-cache"])

        XCTAssertTrue(options.experimentalGranularCache)
    }

    func testIsGranularCacheEnabledReturnsFalseWithoutCacheFlag() throws {
        let options = try CacheOptions.parse(["--experimental-granular-cache"])

        XCTAssertFalse(options.isGranularCacheEnabled(configEnabled: false))
    }

    func testIsGranularCacheEnabledReturnsTrueWithCacheFlag() throws {
        let options = try CacheOptions.parse(["--cache", "--experimental-granular-cache"])

        XCTAssertTrue(options.isGranularCacheEnabled(configEnabled: false))
    }

    func testIsGranularCacheEnabledReturnsTrueWithConfigEnabled() throws {
        let options = try CacheOptions.parse(["--experimental-granular-cache"])

        XCTAssertTrue(options.isGranularCacheEnabled(configEnabled: true))
    }

    func testGranularCacheWarningWhenNoCacheEnabled() throws {
        let options = try CacheOptions.parse(["--experimental-granular-cache"])

        let warning = options.granularCacheWarning(configEnabled: false)

        XCTAssertEqual(warning, .granularCacheWithoutCache)
    }

    func testNoGranularCacheWarningWhenCacheEnabled() throws {
        let options = try CacheOptions.parse(["--cache", "--experimental-granular-cache"])

        let warning = options.granularCacheWarning(configEnabled: false)

        XCTAssertNil(warning)
    }

    func testNoGranularCacheWarningWhenNotRequested() throws {
        let options = try CacheOptions.parse([])

        let warning = options.granularCacheWarning(configEnabled: false)

        XCTAssertNil(warning)
    }
}
