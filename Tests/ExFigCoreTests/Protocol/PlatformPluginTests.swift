@testable import ExFigCore
import XCTest

// MARK: - Mock Implementations for Testing

/// Mock exporter for testing purposes.
struct MockColorsExporter: AssetExporter {
    let assetType: AssetType = .colors
}

/// Mock exporter for icons.
struct MockIconsExporter: AssetExporter {
    let assetType: AssetType = .icons
}

/// Mock platform plugin for testing.
struct MockPlatformPlugin: PlatformPlugin {
    let identifier: String
    let platform: Platform
    let configKeys: Set<String>
    private let mockExporters: [any AssetExporter]

    init(
        identifier: String = "mock",
        platform: Platform = .ios,
        configKeys: Set<String> = ["colors", "icons"],
        exporters: [any AssetExporter] = [MockColorsExporter(), MockIconsExporter()]
    ) {
        self.identifier = identifier
        self.platform = platform
        self.configKeys = configKeys
        mockExporters = exporters
    }

    func exporters() -> [any AssetExporter] {
        mockExporters
    }
}

// MARK: - PlatformPlugin Tests

final class PlatformPluginTests: XCTestCase {
    // MARK: - Identifier

    func testPluginProvidesIdentifier() {
        let plugin = MockPlatformPlugin(identifier: "ios-plugin")

        XCTAssertEqual(plugin.identifier, "ios-plugin")
    }

    func testPluginIdentifierIsNonEmpty() {
        let plugin = MockPlatformPlugin(identifier: "android")

        XCTAssertFalse(plugin.identifier.isEmpty)
    }

    // MARK: - Platform

    func testPluginProvidesPlatform() {
        let plugin = MockPlatformPlugin(platform: .android)

        XCTAssertEqual(plugin.platform, .android)
    }

    // MARK: - Config Keys

    func testPluginProvidesConfigKeys() {
        let plugin = MockPlatformPlugin(configKeys: ["colors", "icons", "images"])

        XCTAssertEqual(plugin.configKeys, ["colors", "icons", "images"])
    }

    func testPluginConfigKeysCanBeEmpty() {
        let plugin = MockPlatformPlugin(configKeys: [])

        XCTAssertTrue(plugin.configKeys.isEmpty)
    }

    func testPluginConfigKeysContainsExpectedKey() {
        let plugin = MockPlatformPlugin(configKeys: ["colors", "typography"])

        XCTAssertTrue(plugin.configKeys.contains("colors"))
        XCTAssertTrue(plugin.configKeys.contains("typography"))
        XCTAssertFalse(plugin.configKeys.contains("images"))
    }

    // MARK: - Exporters

    func testPluginReturnsExporters() {
        let plugin = MockPlatformPlugin()

        let exporters = plugin.exporters()

        XCTAssertFalse(exporters.isEmpty)
    }

    func testPluginReturnsCorrectNumberOfExporters() {
        let exporters: [any AssetExporter] = [
            MockColorsExporter(),
            MockIconsExporter(),
        ]
        let plugin = MockPlatformPlugin(exporters: exporters)

        XCTAssertEqual(plugin.exporters().count, 2)
    }

    func testPluginExportersHaveCorrectAssetTypes() {
        let plugin = MockPlatformPlugin()

        let exporters = plugin.exporters()
        let assetTypes = exporters.map(\.assetType)

        XCTAssertTrue(assetTypes.contains(.colors))
        XCTAssertTrue(assetTypes.contains(.icons))
    }

    func testPluginCanReturnEmptyExporters() {
        let plugin = MockPlatformPlugin(exporters: [])

        XCTAssertTrue(plugin.exporters().isEmpty)
    }

    // MARK: - Sendable Conformance

    func testPluginIsSendable() async {
        let plugin = MockPlatformPlugin(identifier: "test")

        let result = await Task {
            plugin.identifier
        }.value

        XCTAssertEqual(result, "test")
    }
}

// MARK: - AssetType Tests

final class AssetTypeTests: XCTestCase {
    func testAssetTypeRawValues() {
        XCTAssertEqual(AssetType.colors.rawValue, "colors")
        XCTAssertEqual(AssetType.icons.rawValue, "icons")
        XCTAssertEqual(AssetType.images.rawValue, "images")
        XCTAssertEqual(AssetType.typography.rawValue, "typography")
    }

    func testAssetTypeInitFromRawValue() {
        XCTAssertEqual(AssetType(rawValue: "colors"), .colors)
        XCTAssertEqual(AssetType(rawValue: "icons"), .icons)
        XCTAssertEqual(AssetType(rawValue: "images"), .images)
        XCTAssertEqual(AssetType(rawValue: "typography"), .typography)
    }

    func testAssetTypeInitFromInvalidRawValue() {
        XCTAssertNil(AssetType(rawValue: "unknown"))
        XCTAssertNil(AssetType(rawValue: ""))
    }

    func testAssetTypeEquality() {
        XCTAssertEqual(AssetType.colors, AssetType.colors)
        XCTAssertNotEqual(AssetType.colors, AssetType.icons)
    }

    func testAssetTypeIsSendable() async {
        let assetType: AssetType = .colors

        let result = await Task {
            assetType.rawValue
        }.value

        XCTAssertEqual(result, "colors")
    }

    func testAllCases() {
        let allCases = AssetType.allCases

        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.colors))
        XCTAssertTrue(allCases.contains(.icons))
        XCTAssertTrue(allCases.contains(.images))
        XCTAssertTrue(allCases.contains(.typography))
    }
}
