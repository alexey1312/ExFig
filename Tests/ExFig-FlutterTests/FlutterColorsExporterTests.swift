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

    // MARK: - ColorsExporter Protocol

    func testConformsToColorsExporter() {
        let exporter: any ColorsExporter = FlutterColorsExporter()

        XCTAssertEqual(exporter.assetType, .colors)
    }

    func testExportMethodExists() async throws {
        let exporter = FlutterColorsExporter()

        // Type signature verification
        let _: (
            [FlutterColorsEntry],
            FlutterPlatformConfig,
            MockFlutterColorsExportContext
        ) async throws -> Int = exporter.exportColors
    }
}

// MARK: - Mock Context

/// Mock ColorsExportContext for testing.
struct MockFlutterColorsExportContext: ColorsExportContext {
    var isBatchMode: Bool = false
    var filter: String?

    func writeFiles(_ files: [FileContents]) throws {}
    func info(_ message: String) {}
    func warning(_ message: String) {}
    func success(_ message: String) {}

    func withSpinner<T: Sendable>(
        _ message: String,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await operation()
    }

    func loadColors(from source: ColorsSourceInput) async throws -> ColorsLoadOutput {
        ColorsLoadOutput(light: [], dark: [], lightHC: [], darkHC: [])
    }

    func processColors(
        _ colors: ColorsLoadOutput,
        platform: Platform,
        nameValidateRegexp: String?,
        nameReplaceRegexp: String?,
        nameStyle: NameStyle
    ) throws -> ColorsProcessResult {
        ColorsProcessResult(colorPairs: [], warning: nil)
    }
}
