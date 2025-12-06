@testable import ExFigCore
import XCTest

final class PlatformTests: XCTestCase {
    // MARK: - Raw Values

    func testRawValues() {
        XCTAssertEqual(Platform.ios.rawValue, "ios")
        XCTAssertEqual(Platform.android.rawValue, "android")
    }

    // MARK: - Initialization from Raw Value

    func testInitFromRawValueIOS() {
        let platform = Platform(rawValue: "ios")

        XCTAssertEqual(platform, .ios)
    }

    func testInitFromRawValueAndroid() {
        let platform = Platform(rawValue: "android")

        XCTAssertEqual(platform, .android)
    }

    func testInitFromInvalidRawValue() {
        let platform = Platform(rawValue: "windows")

        XCTAssertNil(platform)
    }

    func testInitFromEmptyRawValue() {
        let platform = Platform(rawValue: "")

        XCTAssertNil(platform)
    }

    // MARK: - Equatable

    func testEquality() {
        XCTAssertEqual(Platform.ios, Platform.ios)
        XCTAssertEqual(Platform.android, Platform.android)
    }

    func testInequality() {
        XCTAssertNotEqual(Platform.ios, Platform.android)
    }

    // MARK: - Sendable Conformance

    func testSendableConformance() async {
        let platform: Platform = .ios

        let result = await Task {
            platform.rawValue
        }.value

        XCTAssertEqual(result, "ios")
    }
}
