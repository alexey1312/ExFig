@testable import ExFigCore
import XCTest

// MARK: - Mock Exporter for Testing

/// Full-featured mock exporter with load/process/export cycle.
actor MockFullExporter: AssetExporter {
    let assetType: AssetType

    private var loadCalled = false
    private var processCalled = false
    private var exportCalled = false
    private var loadedData: [String] = []
    private var processedData: [String] = []

    init(assetType: AssetType) {
        self.assetType = assetType
    }

    func load() async throws -> [String] {
        loadCalled = true
        loadedData = ["item1", "item2", "item3"]
        return loadedData
    }

    func process(_ data: [String]) async throws -> [String] {
        processCalled = true
        processedData = data.map { $0.uppercased() }
        return processedData
    }

    func export(_ data: [String]) async throws -> ExportResult {
        exportCalled = true
        return ExportResult(
            filesWritten: data.count,
            assetType: assetType
        )
    }

    /// Test inspection methods
    func wasLoadCalled() -> Bool {
        loadCalled
    }

    func wasProcessCalled() -> Bool {
        processCalled
    }

    func wasExportCalled() -> Bool {
        exportCalled
    }

    func getLoadedData() -> [String] {
        loadedData
    }

    func getProcessedData() -> [String] {
        processedData
    }
}

/// Mock exporter that simulates load failure.
actor MockFailingLoadExporter: AssetExporter {
    let assetType: AssetType = .colors

    func load() async throws -> [String] {
        throw ExporterError.loadFailed("Network error")
    }

    func process(_ data: [String]) async throws -> [String] {
        data
    }

    func export(_ data: [String]) async throws -> ExportResult {
        ExportResult(filesWritten: 0, assetType: assetType)
    }
}

/// Error type for exporter failures.
enum ExporterError: Error, Equatable {
    case loadFailed(String)
    case processFailed(String)
    case exportFailed(String)
}

// MARK: - AssetExporter Tests

final class AssetExporterTests: XCTestCase {
    // MARK: - Asset Type

    func testExporterProvidesAssetType() async {
        let exporter = MockFullExporter(assetType: .colors)

        await XCTAssertEqualAsync(exporter.assetType, .colors)
    }

    func testExporterCanHaveDifferentAssetTypes() async {
        let colorsExporter = MockFullExporter(assetType: .colors)
        let iconsExporter = MockFullExporter(assetType: .icons)
        let imagesExporter = MockFullExporter(assetType: .images)
        let typographyExporter = MockFullExporter(assetType: .typography)

        await XCTAssertEqualAsync(colorsExporter.assetType, .colors)
        await XCTAssertEqualAsync(iconsExporter.assetType, .icons)
        await XCTAssertEqualAsync(imagesExporter.assetType, .images)
        await XCTAssertEqualAsync(typographyExporter.assetType, .typography)
    }

    // MARK: - Load/Process/Export Cycle

    func testExporterLoadReturnsData() async throws {
        let exporter = MockFullExporter(assetType: .icons)

        let data = try await exporter.load()

        XCTAssertFalse(data.isEmpty)
        XCTAssertEqual(data, ["item1", "item2", "item3"])
    }

    func testExporterProcessTransformsData() async throws {
        let exporter = MockFullExporter(assetType: .colors)
        let input = ["red", "green", "blue"]

        let output = try await exporter.process(input)

        XCTAssertEqual(output, ["RED", "GREEN", "BLUE"])
    }

    func testExporterExportReturnsResult() async throws {
        let exporter = MockFullExporter(assetType: .images)
        let data = ["image1", "image2"]

        let result = try await exporter.export(data)

        XCTAssertEqual(result.filesWritten, 2)
        XCTAssertEqual(result.assetType, .images)
    }

    func testFullLoadProcessExportCycle() async throws {
        let exporter = MockFullExporter(assetType: .colors)

        // Load
        let loaded = try await exporter.load()
        let wasLoadCalled = await exporter.wasLoadCalled()
        XCTAssertTrue(wasLoadCalled)

        // Process
        let processed = try await exporter.process(loaded)
        let wasProcessCalled = await exporter.wasProcessCalled()
        XCTAssertTrue(wasProcessCalled)
        XCTAssertEqual(processed, ["ITEM1", "ITEM2", "ITEM3"])

        // Export
        let result = try await exporter.export(processed)
        let wasExportCalled = await exporter.wasExportCalled()
        XCTAssertTrue(wasExportCalled)
        XCTAssertEqual(result.filesWritten, 3)
    }

    // MARK: - Error Handling

    func testExporterLoadCanFail() async {
        let exporter = MockFailingLoadExporter()

        do {
            _ = try await exporter.load()
            XCTFail("Expected load to throw")
        } catch let error as ExporterError {
            XCTAssertEqual(error, .loadFailed("Network error"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Sendable Conformance

    func testExporterIsSendable() async {
        let exporter = MockFullExporter(assetType: .typography)

        let result = await Task {
            await exporter.assetType
        }.value

        XCTAssertEqual(result, .typography)
    }
}

// MARK: - ExportResult Tests

final class ExportResultTests: XCTestCase {
    func testExportResultStoresFilesWritten() {
        let result = ExportResult(filesWritten: 5, assetType: .colors)

        XCTAssertEqual(result.filesWritten, 5)
    }

    func testExportResultStoresAssetType() {
        let result = ExportResult(filesWritten: 10, assetType: .icons)

        XCTAssertEqual(result.assetType, .icons)
    }

    func testExportResultCanHaveZeroFiles() {
        let result = ExportResult(filesWritten: 0, assetType: .images)

        XCTAssertEqual(result.filesWritten, 0)
    }

    func testExportResultEquality() {
        let result1 = ExportResult(filesWritten: 3, assetType: .colors)
        let result2 = ExportResult(filesWritten: 3, assetType: .colors)
        let result3 = ExportResult(filesWritten: 5, assetType: .colors)

        XCTAssertEqual(result1, result2)
        XCTAssertNotEqual(result1, result3)
    }

    func testExportResultIsSendable() async {
        let result = ExportResult(filesWritten: 7, assetType: .typography)

        let filesWritten = await Task {
            result.filesWritten
        }.value

        XCTAssertEqual(filesWritten, 7)
    }
}

// MARK: - Test Helpers

extension XCTestCase {
    func XCTAssertEqualAsync<T: Equatable>(
        _ expression: @autoclosure () async -> T,
        _ expected: T,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let actual = await expression()
        XCTAssertEqual(actual, expected, file: file, line: line)
    }
}
