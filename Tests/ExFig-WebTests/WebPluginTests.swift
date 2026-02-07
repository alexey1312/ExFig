@testable import ExFig_Web
import ExFigCore
import XCTest

/// Tests for WebPlugin conformance to PlatformPlugin protocol.
final class WebPluginTests: XCTestCase {
    // MARK: - Identifier

    func testIdentifierIsWeb() {
        let plugin = WebPlugin()

        XCTAssertEqual(plugin.identifier, "web")
    }

    // MARK: - Platform

    func testPlatformIsWeb() {
        let plugin = WebPlugin()

        XCTAssertEqual(plugin.platform, .web)
    }

    // MARK: - Config Keys

    func testConfigKeysContainsWeb() {
        let plugin = WebPlugin()

        XCTAssertTrue(plugin.configKeys.contains("web"))
    }

    func testConfigKeysHasExpectedCount() {
        let plugin = WebPlugin()

        XCTAssertEqual(plugin.configKeys.count, 1)
    }

    // MARK: - Exporters

    func testExportersReturnsThreeExporters() {
        let plugin = WebPlugin()

        let exporters = plugin.exporters()

        // Web has no typography exporter
        XCTAssertEqual(exporters.count, 3)
    }

    func testExportersContainsColorsExporter() {
        let plugin = WebPlugin()

        let exporters = plugin.exporters()
        let hasColors = exporters.contains { $0.assetType == .colors }

        XCTAssertTrue(hasColors)
    }

    func testExportersContainsIconsExporter() {
        let plugin = WebPlugin()

        let exporters = plugin.exporters()
        let hasIcons = exporters.contains { $0.assetType == .icons }

        XCTAssertTrue(hasIcons)
    }

    func testExportersContainsImagesExporter() {
        let plugin = WebPlugin()

        let exporters = plugin.exporters()
        let hasImages = exporters.contains { $0.assetType == .images }

        XCTAssertTrue(hasImages)
    }

    // MARK: - Sendable

    func testPluginIsSendable() async {
        let plugin = WebPlugin()

        let identifier = await Task {
            plugin.identifier
        }.value

        XCTAssertEqual(identifier, "web")
    }
}
