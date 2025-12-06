@testable import ExFigCore
import XCTest

final class ColorTests: XCTestCase {
    // MARK: - Initialization

    func testInitWithRequiredParameters() {
        let color = Color(name: "primary", red: 1.0, green: 0.5, blue: 0.25, alpha: 1.0)

        XCTAssertEqual(color.name, "primary")
        XCTAssertEqual(color.originalName, "primary")
        XCTAssertEqual(color.red, 1.0)
        XCTAssertEqual(color.green, 0.5)
        XCTAssertEqual(color.blue, 0.25)
        XCTAssertEqual(color.alpha, 1.0)
        XCTAssertNil(color.platform)
    }

    func testInitWithPlatform() {
        let color = Color(name: "accent", platform: .ios, red: 0.2, green: 0.4, blue: 0.8, alpha: 0.9)

        XCTAssertEqual(color.name, "accent")
        XCTAssertEqual(color.platform, .ios)
        XCTAssertEqual(color.red, 0.2)
        XCTAssertEqual(color.green, 0.4)
        XCTAssertEqual(color.blue, 0.8)
        XCTAssertEqual(color.alpha, 0.9)
    }

    func testInitWithAndroidPlatform() {
        let color = Color(name: "background", platform: .android, red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)

        XCTAssertEqual(color.platform, .android)
    }

    // MARK: - Color Component Boundaries

    func testZeroComponents() {
        let color = Color(name: "black", red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)

        XCTAssertEqual(color.red, 0.0)
        XCTAssertEqual(color.green, 0.0)
        XCTAssertEqual(color.blue, 0.0)
        XCTAssertEqual(color.alpha, 0.0)
    }

    func testMaxComponents() {
        let color = Color(name: "white", red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

        XCTAssertEqual(color.red, 1.0)
        XCTAssertEqual(color.green, 1.0)
        XCTAssertEqual(color.blue, 1.0)
        XCTAssertEqual(color.alpha, 1.0)
    }

    func testFractionalComponents() {
        let color = Color(name: "gray", red: 0.333, green: 0.666, blue: 0.999, alpha: 0.5)

        XCTAssertEqual(color.red, 0.333, accuracy: 0.001)
        XCTAssertEqual(color.green, 0.666, accuracy: 0.001)
        XCTAssertEqual(color.blue, 0.999, accuracy: 0.001)
        XCTAssertEqual(color.alpha, 0.5, accuracy: 0.001)
    }

    // MARK: - Equatable

    func testEqualityByName() {
        let color1 = Color(name: "primary", red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let color2 = Color(name: "primary", red: 0.0, green: 1.0, blue: 0.0, alpha: 0.5)

        XCTAssertEqual(color1, color2)
    }

    func testInequalityByName() {
        let color1 = Color(name: "primary", red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let color2 = Color(name: "secondary", red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)

        XCTAssertNotEqual(color1, color2)
    }

    func testEqualityIgnoresComponents() {
        let red = Color(name: "color", red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let blue = Color(name: "color", red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)

        XCTAssertEqual(red, blue)
    }

    func testEqualityIgnoresPlatform() {
        let iosColor = Color(name: "accent", platform: .ios, red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let androidColor = Color(name: "accent", platform: .android, red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)

        XCTAssertEqual(iosColor, androidColor)
    }

    // MARK: - Hashable

    func testHashValueByName() {
        let color1 = Color(name: "primary", red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let color2 = Color(name: "primary", red: 0.0, green: 1.0, blue: 0.0, alpha: 0.5)

        XCTAssertEqual(color1.hashValue, color2.hashValue)
    }

    func testHashableInSet() {
        let color1 = Color(name: "primary", red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let color2 = Color(name: "secondary", red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
        let color3 = Color(name: "primary", red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0) // Duplicate by name

        let set: Set<Color> = [color1, color2, color3]

        XCTAssertEqual(set.count, 2)
    }

    func testHashableInDictionary() {
        let color1 = Color(name: "key1", red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let color2 = Color(name: "key2", red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)

        var dict: [Color: String] = [:]
        dict[color1] = "first"
        dict[color2] = "second"

        XCTAssertEqual(dict[color1], "first")
        XCTAssertEqual(dict[color2], "second")
    }

    // MARK: - Mutable Name

    func testMutableName() {
        var color = Color(name: "old", red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)

        color.name = "new"

        XCTAssertEqual(color.name, "new")
        XCTAssertEqual(color.originalName, "old")
    }

    func testOriginalNamePreservedAfterRename() {
        var color = Color(name: "originalName", red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)

        color.name = "renamedName"

        XCTAssertEqual(color.name, "renamedName")
        XCTAssertEqual(color.originalName, "originalName")
    }

    // MARK: - Asset Protocol Conformance

    func testConformsToAssetProtocol() {
        let color = Color(name: "test", red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)

        let asset: any Asset = color

        XCTAssertEqual(asset.name, "test")
        XCTAssertNil(asset.platform)
    }

    func testAssetProtocolWithPlatform() {
        let color = Color(name: "test", platform: .ios, red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)

        XCTAssertEqual(color.platform, .ios)
    }

    // MARK: - Sendable

    func testSendableConformance() async {
        let color = Color(name: "concurrent", red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)

        let result = await Task {
            color.name
        }.value

        XCTAssertEqual(result, "concurrent")
    }
}
