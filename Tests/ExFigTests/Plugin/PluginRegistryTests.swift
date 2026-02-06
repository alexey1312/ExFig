@testable import ExFigCLI
import ExFigCore
import XCTest

/// Tests for PluginRegistry functionality.
final class PluginRegistryTests: XCTestCase {
    // MARK: - Registration

    func testDefaultRegistryContainsAllPlugins() {
        let registry = PluginRegistry.default

        XCTAssertEqual(registry.allPlugins.count, 4)
    }

    func testDefaultRegistryContainsIOSPlugin() {
        let registry = PluginRegistry.default

        let hasIOS = registry.allPlugins.contains { $0.identifier == "ios" }

        XCTAssertTrue(hasIOS)
    }

    func testDefaultRegistryContainsAndroidPlugin() {
        let registry = PluginRegistry.default

        let hasAndroid = registry.allPlugins.contains { $0.identifier == "android" }

        XCTAssertTrue(hasAndroid)
    }

    func testDefaultRegistryContainsFlutterPlugin() {
        let registry = PluginRegistry.default

        let hasFlutter = registry.allPlugins.contains { $0.identifier == "flutter" }

        XCTAssertTrue(hasFlutter)
    }

    func testDefaultRegistryContainsWebPlugin() {
        let registry = PluginRegistry.default

        let hasWeb = registry.allPlugins.contains { $0.identifier == "web" }

        XCTAssertTrue(hasWeb)
    }

    // MARK: - Routing by Config Key

    func testPluginForConfigKeyReturnsIOSPlugin() {
        let registry = PluginRegistry.default

        let plugin = registry.plugin(forConfigKey: "ios")

        XCTAssertEqual(plugin?.identifier, "ios")
    }

    func testPluginForConfigKeyReturnsAndroidPlugin() {
        let registry = PluginRegistry.default

        let plugin = registry.plugin(forConfigKey: "android")

        XCTAssertEqual(plugin?.identifier, "android")
    }

    func testPluginForConfigKeyReturnsFlutterPlugin() {
        let registry = PluginRegistry.default

        let plugin = registry.plugin(forConfigKey: "flutter")

        XCTAssertEqual(plugin?.identifier, "flutter")
    }

    func testPluginForConfigKeyReturnsWebPlugin() {
        let registry = PluginRegistry.default

        let plugin = registry.plugin(forConfigKey: "web")

        XCTAssertEqual(plugin?.identifier, "web")
    }

    func testPluginForConfigKeyReturnsNilForUnknownKey() {
        let registry = PluginRegistry.default

        let plugin = registry.plugin(forConfigKey: "unknown")

        XCTAssertNil(plugin)
    }

    func testPluginForConfigKeyReturnsNilForEmptyKey() {
        let registry = PluginRegistry.default

        let plugin = registry.plugin(forConfigKey: "")

        XCTAssertNil(plugin)
    }

    // MARK: - Plugin by Identifier

    func testPluginByIdentifierReturnsCorrectPlugin() {
        let registry = PluginRegistry.default

        let plugin = registry.plugin(withIdentifier: "ios")

        XCTAssertEqual(plugin?.identifier, "ios")
        XCTAssertEqual(plugin?.platform, .ios)
    }

    func testPluginByIdentifierReturnsNilForUnknown() {
        let registry = PluginRegistry.default

        let plugin = registry.plugin(withIdentifier: "macos")

        XCTAssertNil(plugin)
    }

    // MARK: - Plugins for Platform

    func testPluginForPlatformReturnsCorrectPlugin() {
        let registry = PluginRegistry.default

        let plugin = registry.plugin(for: .ios)

        XCTAssertEqual(plugin?.identifier, "ios")
    }

    func testPluginForAllPlatformsReturnsCorrectPlugins() {
        let registry = PluginRegistry.default

        for platform in [Platform.ios, .android, .flutter, .web] {
            let plugin = registry.plugin(for: platform)
            XCTAssertNotNil(plugin, "Expected plugin for \(platform)")
            XCTAssertEqual(plugin?.platform, platform)
        }
    }

    // MARK: - Custom Registry

    func testCustomRegistryWithEmptyPlugins() {
        let registry = PluginRegistry(plugins: [])

        XCTAssertEqual(registry.allPlugins.count, 0)
    }

    func testCustomRegistryRoutesToRegisteredPlugin() {
        let mockPlugin = MockPlugin()
        let registry = PluginRegistry(plugins: [mockPlugin])

        let plugin = registry.plugin(forConfigKey: "mock")

        XCTAssertEqual(plugin?.identifier, "mock")
    }

    // MARK: - Sendable

    func testRegistryIsSendable() async {
        let registry = PluginRegistry.default

        let count = await Task {
            registry.allPlugins.count
        }.value

        XCTAssertEqual(count, 4)
    }
}

// MARK: - Mock Plugin

private struct MockPlugin: PlatformPlugin {
    let identifier = "mock"
    let platform: Platform = .ios
    let configKeys: Set<String> = ["mock"]

    func exporters() -> [any AssetExporter] {
        []
    }
}
