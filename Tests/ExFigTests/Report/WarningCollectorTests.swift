@testable import ExFigCLI
import XCTest

final class WarningCollectorTests: XCTestCase {
    // MARK: - Empty State

    func testEmptyCollector() {
        let collector = WarningCollector()
        let warnings = collector.getAll()
        XCTAssertTrue(warnings.isEmpty)
        XCTAssertEqual(collector.count, 0)
    }

    // MARK: - Add Warnings

    func testAddSingleWarning() {
        let collector = WarningCollector()
        collector.add("Test warning")
        let warnings = collector.getAll()
        XCTAssertEqual(warnings, ["Test warning"])
    }

    func testAddMultipleWarnings() {
        let collector = WarningCollector()
        collector.add("Warning 1")
        collector.add("Warning 2")
        collector.add("Warning 3")

        let warnings = collector.getAll()
        XCTAssertEqual(warnings, ["Warning 1", "Warning 2", "Warning 3"])
        XCTAssertEqual(collector.count, 3)
    }

    // MARK: - Ordering

    func testWarningsPreserveOrder() {
        let collector = WarningCollector()
        for i in 1 ... 5 {
            collector.add("Warning \(i)")
        }

        let warnings = collector.getAll()
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
