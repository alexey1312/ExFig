@testable import ExFig_Web
import ExFigCore
import XCTest

/// Tests for WebColorsExporter conformance to AssetExporter protocol.
final class WebColorsExporterTests: XCTestCase {
    // MARK: - Asset Type

    func testAssetTypeIsColors() {
        let exporter = WebColorsExporter()

        XCTAssertEqual(exporter.assetType, .colors)
    }

    // MARK: - Sendable

    func testExporterIsSendable() async {
        let exporter = WebColorsExporter()

        let assetType = await Task {
            exporter.assetType
        }.value

        XCTAssertEqual(assetType, .colors)
    }
}
