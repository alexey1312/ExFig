@testable import ExFig_Android
import ExFigCore
import XCTest

/// Tests for AndroidColorsExporter conformance to AssetExporter protocol.
final class AndroidColorsExporterTests: XCTestCase {
    // MARK: - Asset Type

    func testAssetTypeIsColors() {
        let exporter = AndroidColorsExporter()

        XCTAssertEqual(exporter.assetType, .colors)
    }

    // MARK: - Sendable

    func testExporterIsSendable() async {
        let exporter = AndroidColorsExporter()

        let assetType = await Task {
            exporter.assetType
        }.value

        XCTAssertEqual(assetType, .colors)
    }
}
