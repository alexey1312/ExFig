@testable import ExFig
import XCTest

final class GlobalOptionsTests: XCTestCase {
    func testDefaultValues() throws {
        let options = try GlobalOptions.parse([])

        XCTAssertFalse(options.verbose)
        XCTAssertFalse(options.quiet)
    }

    func testVerboseFlag() throws {
        let options = try GlobalOptions.parse(["--verbose"])

        XCTAssertTrue(options.verbose)
        XCTAssertFalse(options.quiet)
    }

    func testVerboseShortFlag() throws {
        let options = try GlobalOptions.parse(["-v"])

        XCTAssertTrue(options.verbose)
    }

    func testQuietFlag() throws {
        let options = try GlobalOptions.parse(["--quiet"])

        XCTAssertFalse(options.verbose)
        XCTAssertTrue(options.quiet)
    }

    func testQuietShortFlag() throws {
        let options = try GlobalOptions.parse(["-q"])

        XCTAssertTrue(options.quiet)
    }

    func testBothFlags() throws {
        let options = try GlobalOptions.parse(["--verbose", "--quiet"])

        XCTAssertTrue(options.verbose)
        XCTAssertTrue(options.quiet)
    }
}
