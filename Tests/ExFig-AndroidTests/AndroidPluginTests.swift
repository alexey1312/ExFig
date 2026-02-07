@testable import ExFig_Android
import ExFigCore
import XCTest

/// Tests for AndroidPlugin conformance to PlatformPlugin protocol.
final class AndroidPluginTests: XCTestCase {
    // MARK: - Identifier

    func testIdentifierIsAndroid() {
        let plugin = AndroidPlugin()

        XCTAssertEqual(plugin.identifier, "android")
    }

    // MARK: - Platform

    func testPlatformIsAndroid() {
        let plugin = AndroidPlugin()

        XCTAssertEqual(plugin.platform, .android)
    }

    // MARK: - Config Keys

    func testConfigKeysContainsAndroid() {
        let plugin = AndroidPlugin()

        XCTAssertTrue(plugin.configKeys.contains("android"))
    }

    func testConfigKeysHasExpectedCount() {
        let plugin = AndroidPlugin()

        XCTAssertEqual(plugin.configKeys.count, 1)
    }

    // MARK: - Exporters

    func testExportersReturnsFourExporters() {
        let plugin = AndroidPlugin()

        let exporters = plugin.exporters()

        XCTAssertEqual(exporters.count, 4)
    }

    func testExportersContainsColorsExporter() {
        let plugin = AndroidPlugin()

        let exporters = plugin.exporters()
        let hasColors = exporters.contains { $0.assetType == .colors }

        XCTAssertTrue(hasColors)
    }

    func testExportersContainsIconsExporter() {
        let plugin = AndroidPlugin()

        let exporters = plugin.exporters()
        let hasIcons = exporters.contains { $0.assetType == .icons }

        XCTAssertTrue(hasIcons)
    }

    func testExportersContainsImagesExporter() {
        let plugin = AndroidPlugin()

        let exporters = plugin.exporters()
        let hasImages = exporters.contains { $0.assetType == .images }

        XCTAssertTrue(hasImages)
    }

    func testExportersContainsTypographyExporter() {
        let plugin = AndroidPlugin()

        let exporters = plugin.exporters()
        let hasTypography = exporters.contains { $0.assetType == .typography }

        XCTAssertTrue(hasTypography)
    }

    // MARK: - Sendable

    func testPluginIsSendable() async {
        let plugin = AndroidPlugin()

        let identifier = await Task {
            plugin.identifier
        }.value

        XCTAssertEqual(identifier, "android")
    }
}
