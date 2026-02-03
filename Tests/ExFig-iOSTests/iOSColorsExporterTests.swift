// swiftlint:disable type_name

@testable import ExFig_iOS
import ExFigCore
import XCTest

/// Tests for iOSColorsExporter conformance to AssetExporter protocol.
final class iOSColorsExporterTests: XCTestCase {
    // MARK: - Asset Type

    func testAssetTypeIsColors() {
        let exporter = iOSColorsExporter()

        XCTAssertEqual(exporter.assetType, .colors)
    }

    // MARK: - Sendable

    func testExporterIsSendable() async {
        let exporter = iOSColorsExporter()

        let assetType = await Task {
            exporter.assetType
        }.value

        XCTAssertEqual(assetType, .colors)
    }

    // MARK: - ColorsExporter Protocol

    func testConformsToColorsExporter() {
        // Verify type conformance at compile time
        let exporter: any ColorsExporter = iOSColorsExporter()

        XCTAssertEqual(exporter.assetType, .colors)
    }

    func testExportMethodExists() async throws {
        // This test verifies the export method signature exists
        // Full integration test would require mock context
        let exporter = iOSColorsExporter()

        // Type signature verification
        let _: (
            [iOSColorsEntry],
            iOSPlatformConfig,
            MockColorsExportContext
        ) async throws -> Int = exporter.exportColors
    }
}

// MARK: - Mock Context

/// Mock ColorsExportContext for testing.
struct MockColorsExportContext: ColorsExportContext {
    var isBatchMode: Bool = false
    var filter: String?

    var writtenFiles: [FileContents] = []
    var infoMessages: [String] = []
    var warningMessages: [String] = []
    var successMessages: [String] = []

    func writeFiles(_ files: [FileContents]) throws {
        // No-op for testing
    }

    func info(_ message: String) {
        // No-op for testing
    }

    func warning(_ message: String) {
        // No-op for testing
    }

    func success(_ message: String) {
        // No-op for testing
    }

    func withSpinner<T: Sendable>(
        _ message: String,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await operation()
    }

    func loadColors(from source: ColorsSourceInput) async throws -> ColorsLoadOutput {
        // Return empty colors for testing
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

// swiftlint:enable type_name
