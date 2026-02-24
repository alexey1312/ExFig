@testable import ExFigCLI
import XCTest

final class WarningCollectorTests: XCTestCase {
    // MARK: - Empty State

    func testEmptyCollector() async {
        let collector = WarningCollector()
        let warnings = await collector.getAll()
        XCTAssertTrue(warnings.isEmpty)
        let count = await collector.count
        XCTAssertEqual(count, 0)
    }

    // MARK: - Add Warnings

    func testAddSingleWarning() async {
        let collector = WarningCollector()
        await collector.add("Test warning")
        let warnings = await collector.getAll()
        XCTAssertEqual(warnings, ["Test warning"])
    }

    func testAddMultipleWarnings() async {
        let collector = WarningCollector()
        await collector.add("Warning 1")
        await collector.add("Warning 2")
        await collector.add("Warning 3")

        let warnings = await collector.getAll()
        XCTAssertEqual(warnings, ["Warning 1", "Warning 2", "Warning 3"])
        let count = await collector.count
        XCTAssertEqual(count, 3)
    }

    // MARK: - Ordering

    func testWarningsPreserveOrder() async {
        let collector = WarningCollector()
        for i in 1 ... 5 {
            await collector.add("Warning \(i)")
        }

        let warnings = await collector.getAll()
        XCTAssertEqual(warnings, ["Warning 1", "Warning 2", "Warning 3", "Warning 4", "Warning 5"])
    }

    // MARK: - Storage

    func testStorageSetAndClear() {
        XCTAssertNil(WarningCollectorStorage.current)

        let collector = WarningCollector()
        WarningCollectorStorage.current = collector
        XCTAssertNotNil(WarningCollectorStorage.current)

        WarningCollectorStorage.current = nil
        XCTAssertNil(WarningCollectorStorage.current)
    }
}
