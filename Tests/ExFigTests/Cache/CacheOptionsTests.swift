@testable import ExFig
import XCTest

final class CacheOptionsTests: XCTestCase {
    // MARK: - isEnabled

    func testIsEnabledReturnsFalseByDefault() {
        let options = CacheOptions()

        XCTAssertFalse(options.isEnabled(configEnabled: false))
    }

    func testIsEnabledReturnsTrueWhenCacheFlagIsSet() {
        var options = CacheOptions()
        options.cache = true

        XCTAssertTrue(options.isEnabled(configEnabled: false))
    }

    func testIsEnabledReturnsTrueWhenConfigEnabled() {
        let options = CacheOptions()

        XCTAssertTrue(options.isEnabled(configEnabled: true))
    }

    func testNoCacheFlagOverridesConfig() {
        var options = CacheOptions()
        options.noCache = true

        XCTAssertFalse(options.isEnabled(configEnabled: true))
    }

    func testForceFlagEnablesCache() {
        var options = CacheOptions()
        options.force = true

        XCTAssertTrue(options.isEnabled(configEnabled: false))
    }

    func testNoCacheTakesPriorityOverCacheFlag() {
        var options = CacheOptions()
        options.cache = true
        options.noCache = true

        XCTAssertFalse(options.isEnabled(configEnabled: true))
    }

    // MARK: - resolvePath

    func testResolvePathReturnsNilByDefault() {
        let options = CacheOptions()

        XCTAssertNil(options.resolvePath(configPath: nil))
    }

    func testResolvePathReturnsConfigPath() {
        let options = CacheOptions()

        XCTAssertEqual(
            options.resolvePath(configPath: "/custom/path.json"),
            "/custom/path.json"
        )
    }

    func testResolvePathCLIOverridesConfig() {
        var options = CacheOptions()
        options.cachePath = "/cli/path.json"

        XCTAssertEqual(
            options.resolvePath(configPath: "/config/path.json"),
            "/cli/path.json"
        )
    }
}
