@testable import FigmaAPI
import XCTest

final class FigmaClientErrorTests: XCTestCase {
    func testNotFoundError() {
        let json = """
        {"status": 404, "err": "Not found"}
        """
        // swiftlint:disable:next force_try
        let error = try! JSONDecoder().decode(FigmaClientError.self, from: Data(json.utf8))

        XCTAssertEqual(error.status, 404)
        XCTAssertEqual(error.err, "Not found")
        XCTAssertTrue(error.errorDescription?.contains("Figma file not found") == true)
        XCTAssertTrue(error.errorDescription?.contains("lightFileId") == true)
    }

    func testGenericError() {
        let json = """
        {"status": 500, "err": "Internal server error"}
        """
        // swiftlint:disable:next force_try
        let error = try! JSONDecoder().decode(FigmaClientError.self, from: Data(json.utf8))

        XCTAssertEqual(error.status, 500)
        XCTAssertEqual(error.err, "Internal server error")
        XCTAssertEqual(error.errorDescription, "Figma API: Internal server error")
    }

    func testRateLimitError() {
        let json = """
        {"status": 429, "err": "Rate limit exceeded"}
        """
        // swiftlint:disable:next force_try
        let error = try! JSONDecoder().decode(FigmaClientError.self, from: Data(json.utf8))

        XCTAssertEqual(error.status, 429)
        XCTAssertEqual(error.errorDescription, "Figma API: Rate limit exceeded")
    }
}
