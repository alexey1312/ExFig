import Foundation
@testable import XcodeExport
import XCTest

final class XcodeEmptyContentsTests: XCTestCase {
    // MARK: - File URL Tests

    func testFileURLIsContentsJson() {
        let emptyContents = XcodeEmptyContents()

        XCTAssertEqual(emptyContents.fileURL.lastPathComponent, "Contents.json")
    }

    // MARK: - Data Tests

    func testDataIsValidJSON() throws {
        let emptyContents = XcodeEmptyContents()

        let json = try JSONSerialization.jsonObject(with: emptyContents.data) as? [String: Any]

        XCTAssertNotNil(json)
    }

    func testDataContainsInfo() throws {
        let emptyContents = XcodeEmptyContents()

        let json = try JSONSerialization.jsonObject(with: emptyContents.data) as? [String: Any]
        let info = json?["info"] as? [String: Any]

        XCTAssertNotNil(info)
    }

    func testInfoContainsAuthor() throws {
        let emptyContents = XcodeEmptyContents()

        let json = try JSONSerialization.jsonObject(with: emptyContents.data) as? [String: Any]
        let info = json?["info"] as? [String: Any]

        XCTAssertEqual(info?["author"] as? String, "xcode")
    }

    func testInfoContainsVersion() throws {
        let emptyContents = XcodeEmptyContents()

        let json = try JSONSerialization.jsonObject(with: emptyContents.data) as? [String: Any]
        let info = json?["info"] as? [String: Any]

        XCTAssertEqual(info?["version"] as? Int, 1)
    }

    func testDataHasNoColors() throws {
        let emptyContents = XcodeEmptyContents()

        let json = try JSONSerialization.jsonObject(with: emptyContents.data) as? [String: Any]

        XCTAssertNil(json?["colors"])
    }

    func testDataHasNoImages() throws {
        let emptyContents = XcodeEmptyContents()

        let json = try JSONSerialization.jsonObject(with: emptyContents.data) as? [String: Any]

        XCTAssertNil(json?["images"])
    }

    // MARK: - String Representation Tests

    func testDataAsString() {
        let emptyContents = XcodeEmptyContents()

        let string = String(data: emptyContents.data, encoding: .utf8)

        XCTAssertNotNil(string)
        XCTAssertTrue(string!.contains("xcode"))
        XCTAssertTrue(string!.contains("version"))
    }
}
