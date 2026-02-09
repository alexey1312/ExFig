@testable import ExFig_Flutter
import ExFigCore
import XCTest

/// Tests for FlutterPlugin conformance to PlatformPlugin protocol.
final class FlutterPluginTests: XCTestCase {
    // MARK: - Identifier

    func testIdentifierIsFlutter() {
        let plugin = FlutterPlugin()

        XCTAssertEqual(plugin.identifier, "flutter")
    }

    // MARK: - Platform

    func testPlatformIsFlutter() {
        let plugin = FlutterPlugin()

        XCTAssertEqual(plugin.platform, .flutter)
    }

    // MARK: - Config Keys

    func testConfigKeysContainsFlutter() {
        let plugin = FlutterPlugin()

        XCTAssertTrue(plugin.configKeys.contains("flutter"))
    }

    func testConfigKeysHasExpectedCount() {
        let plugin = FlutterPlugin()

        XCTAssertEqual(plugin.configKeys.count, 1)
    }

    // MARK: - Exporters

    func testExportersReturnsThreeExporters() {
        let plugin = FlutterPlugin()

        let exporters = plugin.exporters()

        // Flutter has no typography exporter
        XCTAssertEqual(exporters.count, 3)
    }

    func testExportersContainsColorsExporter() {
        let plugin = FlutterPlugin()

        let exporters = plugin.exporters()
        let hasColors = exporters.contains { $0.assetType == .colors }

        XCTAssertTrue(hasColors)
    }

    func testExportersContainsIconsExporter() {
        let plugin = FlutterPlugin()

        let exporters = plugin.exporters()
        let hasIcons = exporters.contains { $0.assetType == .icons }

        XCTAssertTrue(hasIcons)
    }

    func testExportersContainsImagesExporter() {
        let plugin = FlutterPlugin()

        let exporters = plugin.exporters()
        let hasImages = exporters.contains { $0.assetType == .images }

        XCTAssertTrue(hasImages)
    }

    // MARK: - Sendable

    func testPluginIsSendable() async {
        let plugin = FlutterPlugin()

        let identifier = await Task {
            plugin.identifier
        }.value

        XCTAssertEqual(identifier, "flutter")
    }
}
