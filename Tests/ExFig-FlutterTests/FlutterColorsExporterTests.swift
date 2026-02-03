@testable import ExFig_Flutter
import ExFigCore
import XCTest

/// Tests for FlutterColorsExporter conformance to AssetExporter protocol.
final class FlutterColorsExporterTests: XCTestCase {
    // MARK: - Asset Type

    func testAssetTypeIsColors() {
        let exporter = FlutterColorsExporter()

        XCTAssertEqual(exporter.assetType, .colors)
    }

    // MARK: - Sendable

    func testExporterIsSendable() async {
        let exporter = FlutterColorsExporter()

        let assetType = await Task {
            exporter.assetType
        }.value

        XCTAssertEqual(assetType, .colors)
    }
}
