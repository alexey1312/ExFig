// swiftlint:disable type_name

@testable import ExFig_iOS
import ExFigCore
import XCTest

/// Tests for iOSPlugin conformance to PlatformPlugin protocol.
final class iOSPluginTests: XCTestCase {
    // MARK: - Identifier

    func testIdentifierIsIOS() {
        let plugin = iOSPlugin()

        XCTAssertEqual(plugin.identifier, "ios")
    }

    // MARK: - Platform

    func testPlatformIsIOS() {
        let plugin = iOSPlugin()

        XCTAssertEqual(plugin.platform, .ios)
    }

    // MARK: - Config Keys

    func testConfigKeysContainsIOS() {
        let plugin = iOSPlugin()

        XCTAssertTrue(plugin.configKeys.contains("ios"))
    }

    func testConfigKeysHasExpectedCount() {
        let plugin = iOSPlugin()

        // Should contain "ios" as the only key
        XCTAssertEqual(plugin.configKeys.count, 1)
    }

    // MARK: - Exporters

    func testExportersReturnsFourExporters() {
        let plugin = iOSPlugin()

        let exporters = plugin.exporters()

        XCTAssertEqual(exporters.count, 4)
    }

    func testExportersContainsColorsExporter() {
        let plugin = iOSPlugin()

        let exporters = plugin.exporters()
        let hasColors = exporters.contains { $0.assetType == .colors }

        XCTAssertTrue(hasColors)
    }

    func testExportersContainsIconsExporter() {
        let plugin = iOSPlugin()

        let exporters = plugin.exporters()
        let hasIcons = exporters.contains { $0.assetType == .icons }

        XCTAssertTrue(hasIcons)
    }

    func testExportersContainsImagesExporter() {
        let plugin = iOSPlugin()

        let exporters = plugin.exporters()
        let hasImages = exporters.contains { $0.assetType == .images }

        XCTAssertTrue(hasImages)
    }

    func testExportersContainsTypographyExporter() {
        let plugin = iOSPlugin()

        let exporters = plugin.exporters()
        let hasTypography = exporters.contains { $0.assetType == .typography }

        XCTAssertTrue(hasTypography)
    }

    // MARK: - Sendable

    func testPluginIsSendable() async {
        let plugin = iOSPlugin()

        let identifier = await Task {
            plugin.identifier
        }.value

        XCTAssertEqual(identifier, "ios")
    }
}

// swiftlint:enable type_name
