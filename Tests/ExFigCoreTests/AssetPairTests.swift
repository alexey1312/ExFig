@testable import ExFigCore
import XCTest

final class AssetPairTests: XCTestCase {
    // MARK: - Initialization with Light Only

    func testInitWithLightOnly() {
        let light = Color(name: "background", red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

        let pair = AssetPair(light: light, dark: nil)

        XCTAssertEqual(pair.light.name, "background")
        XCTAssertNil(pair.dark)
        XCTAssertNil(pair.lightHC)
        XCTAssertNil(pair.darkHC)
    }

    // MARK: - Initialization with Light and Dark

    func testInitWithLightAndDark() {
        let light = Color(name: "background", red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        let dark = Color(name: "background", red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)

        let pair = AssetPair(light: light, dark: dark)

        XCTAssertEqual(pair.light.name, "background")
        XCTAssertEqual(pair.light.red, 1.0)
        XCTAssertEqual(pair.dark?.name, "background")
        XCTAssertEqual(pair.dark?.red, 0.1)
        XCTAssertNil(pair.lightHC)
        XCTAssertNil(pair.darkHC)
    }

    // MARK: - Initialization with High Contrast Variants

    func testInitWithAllVariants() {
        let light = Color(name: "text", red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let dark = Color(name: "text", red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        let lightHC = Color(name: "text", red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let darkHC = Color(name: "text", red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

        let pair = AssetPair(light: light, dark: dark, lightHC: lightHC, darkHC: darkHC)

        XCTAssertNotNil(pair.light)
        XCTAssertNotNil(pair.dark)
        XCTAssertNotNil(pair.lightHC)
        XCTAssertNotNil(pair.darkHC)
    }

    func testInitWithLightHCOnly() {
        let light = Color(name: "accent", red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
        let lightHC = Color(name: "accent", red: 0.0, green: 0.4, blue: 0.9, alpha: 1.0)

        let pair = AssetPair(light: light, dark: nil, lightHC: lightHC)

        XCTAssertNotNil(pair.light)
        XCTAssertNil(pair.dark)
        XCTAssertNotNil(pair.lightHC)
        XCTAssertNil(pair.darkHC)
    }

    // MARK: - Generic Type Support

    func testWithImagePack() throws {
        // swiftlint:disable:next force_unwrapping
        let testURL = try XCTUnwrap(URL(string: "https://figma.com/image.png"))
        let lightImage = Image(name: "icon", url: testURL, format: "png")
        let darkImage = Image(name: "icon", url: testURL, format: "png")

        let lightPack = ImagePack(image: lightImage)
        let darkPack = ImagePack(image: darkImage)

        let pair = AssetPair(light: lightPack, dark: darkPack)

        XCTAssertEqual(pair.light.name, "icon")
        XCTAssertEqual(pair.dark?.name, "icon")
    }

    func testWithTextStyle() {
        let lightStyle = TextStyle(
            name: "heading",
            fontName: "Helvetica",
            fontSize: 24,
            fontStyle: .title1,
            letterSpacing: 0.5
        )

        let darkStyle = TextStyle(
            name: "heading",
            fontName: "Helvetica",
            fontSize: 24,
            fontStyle: .title1,
            letterSpacing: 0.5
        )

        let pair = AssetPair(light: lightStyle, dark: darkStyle)

        XCTAssertEqual(pair.light.name, "heading")
        XCTAssertEqual(pair.dark?.name, "heading")
    }

    // MARK: - Sendable Conformance

    func testSendableConformance() async {
        let light = Color(name: "async", red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        let pair = AssetPair(light: light, dark: nil)

        let result = await Task {
            pair.light.name
        }.value

        XCTAssertEqual(result, "async")
    }

    // MARK: - Default Parameter Values

    func testDefaultParametersAreNil() {
        let light = Color(name: "simple", red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)

        let pair = AssetPair(light: light, dark: nil)

        XCTAssertNil(pair.lightHC)
        XCTAssertNil(pair.darkHC)
    }
}
