import ExFigCore
import Foundation
@testable import XcodeExport
import XCTest

final class XcodeAssetContentsTests: XCTestCase {
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    // MARK: - Color Contents Tests

    func testColorContentsWithSingleColor() throws {
        let components = XcodeAssetContents.Components(
            red: "1.000",
            alpha: "1.000",
            green: "0.000",
            blue: "0.000"
        )
        let colorInfo = XcodeAssetContents.ColorInfo(components: components)
        let colorData = XcodeAssetContents.ColorData(color: colorInfo)
        let contents = XcodeAssetContents(colors: [colorData])

        let json = try encoder.encode(contents)
        let jsonString = String(data: json, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("\"red\" : \"1.000\""))
        XCTAssertTrue(jsonString!.contains("\"green\" : \"0.000\""))
        XCTAssertTrue(jsonString!.contains("\"blue\" : \"0.000\""))
        XCTAssertTrue(jsonString!.contains("\"alpha\" : \"1.000\""))
        XCTAssertTrue(jsonString!.contains("\"color-space\" : \"srgb\""))
    }

    func testColorContentsWithDarkAppearance() throws {
        let components = XcodeAssetContents.Components(
            red: "0.100",
            alpha: "1.000",
            green: "0.100",
            blue: "0.100"
        )
        let colorInfo = XcodeAssetContents.ColorInfo(components: components)
        var colorData = XcodeAssetContents.ColorData(color: colorInfo)
        colorData.appearances = [.dark]

        let contents = XcodeAssetContents(colors: [colorData])

        let json = try encoder.encode(contents)
        let jsonString = String(data: json, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("\"appearance\" : \"luminosity\""))
        XCTAssertTrue(jsonString!.contains("\"value\" : \"dark\""))
    }

    func testColorContentsWithHighContrastAppearance() throws {
        let components = XcodeAssetContents.Components(
            red: "0.000",
            alpha: "1.000",
            green: "0.000",
            blue: "0.000"
        )
        let colorInfo = XcodeAssetContents.ColorInfo(components: components)
        var colorData = XcodeAssetContents.ColorData(color: colorInfo)
        colorData.appearances = [.highContrast]

        let contents = XcodeAssetContents(colors: [colorData])

        let json = try encoder.encode(contents)
        let jsonString = String(data: json, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("\"appearance\" : \"contrast\""))
        XCTAssertTrue(jsonString!.contains("\"value\" : \"high\""))
    }

    func testColorContentsWithMultipleAppearances() throws {
        let components = XcodeAssetContents.Components(
            red: "0.500",
            alpha: "1.000",
            green: "0.500",
            blue: "0.500"
        )
        let colorInfo = XcodeAssetContents.ColorInfo(components: components)
        var colorData = XcodeAssetContents.ColorData(color: colorInfo)
        colorData.appearances = [.dark, .highContrast]

        let contents = XcodeAssetContents(colors: [colorData])

        let json = try encoder.encode(contents)
        let jsonString = String(data: json, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("luminosity"))
        XCTAssertTrue(jsonString!.contains("contrast"))
    }

    // MARK: - Image Contents Tests

    func testImageContentsWithSingleImage() throws {
        let imageData = XcodeAssetContents.ImageData(
            appearances: nil,
            filename: "icon.pdf",
            idiom: .universal,
            isRTL: false,
            scale: nil
        )
        let contents = XcodeAssetContents(images: [imageData])

        let json = try encoder.encode(contents)
        let jsonString = String(data: json, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("\"filename\" : \"icon.pdf\""))
        XCTAssertTrue(jsonString!.contains("\"idiom\" : \"universal\""))
    }

    func testImageContentsWithScale() throws {
        let imageData = XcodeAssetContents.ImageData(
            appearances: nil,
            filename: "icon@2x.png",
            idiom: .universal,
            isRTL: false,
            scale: "2x"
        )
        let contents = XcodeAssetContents(images: [imageData])

        let json = try encoder.encode(contents)
        let jsonString = String(data: json, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("\"scale\" : \"2x\""))
    }

    func testImageContentsWithRTL() throws {
        let imageData = XcodeAssetContents.ImageData(
            appearances: nil,
            filename: "arrow.pdf",
            idiom: .universal,
            isRTL: true,
            scale: nil
        )
        let contents = XcodeAssetContents(images: [imageData])

        let json = try encoder.encode(contents)
        let jsonString = String(data: json, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("\"language-direction\" : \"left-to-right\""))
    }

    func testImageContentsWithDarkAppearance() throws {
        let imageData = XcodeAssetContents.ImageData(
            appearances: [.dark],
            filename: "icon_dark.pdf",
            idiom: .universal,
            isRTL: false,
            scale: nil
        )
        let contents = XcodeAssetContents(images: [imageData])

        let json = try encoder.encode(contents)
        let jsonString = String(data: json, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("\"appearance\" : \"luminosity\""))
        XCTAssertTrue(jsonString!.contains("\"value\" : \"dark\""))
    }

    func testImageContentsWithMultipleIdioms() throws {
        let iphoneImage = XcodeAssetContents.ImageData(
            appearances: nil,
            filename: "icon~iphone.pdf",
            idiom: .iphone,
            isRTL: false,
            scale: nil
        )
        let ipadImage = XcodeAssetContents.ImageData(
            appearances: nil,
            filename: "icon~ipad.pdf",
            idiom: .ipad,
            isRTL: false,
            scale: nil
        )
        let contents = XcodeAssetContents(images: [iphoneImage, ipadImage])

        let json = try encoder.encode(contents)
        let jsonString = String(data: json, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("\"idiom\" : \"iphone\""))
        XCTAssertTrue(jsonString!.contains("\"idiom\" : \"ipad\""))
    }

    // MARK: - Properties Tests

    func testImageContentsWithPreservesVectorRepresentation() throws {
        let properties = XcodeAssetContents.Properties(
            preserveVectorData: true,
            renderMode: nil
        )
        let imageData = XcodeAssetContents.ImageData(
            appearances: nil,
            filename: "icon.pdf",
            idiom: .universal,
            isRTL: false,
            scale: nil
        )
        let contents = XcodeAssetContents(images: [imageData], properties: properties)

        let json = try encoder.encode(contents)
        let jsonString = String(data: json, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("\"preserves-vector-representation\" : true"))
    }

    func testImageContentsWithTemplateRenderMode() throws {
        let properties = XcodeAssetContents.Properties(
            preserveVectorData: nil,
            renderMode: .template
        )
        let imageData = XcodeAssetContents.ImageData(
            appearances: nil,
            filename: "icon.pdf",
            idiom: .universal,
            isRTL: false,
            scale: nil
        )
        let contents = XcodeAssetContents(images: [imageData], properties: properties)

        let json = try encoder.encode(contents)
        let jsonString = String(data: json, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("\"template-rendering-intent\" : \"template\""))
    }

    func testImageContentsWithOriginalRenderMode() throws {
        let properties = XcodeAssetContents.Properties(
            preserveVectorData: nil,
            renderMode: .original
        )
        let imageData = XcodeAssetContents.ImageData(
            appearances: nil,
            filename: "image.png",
            idiom: .universal,
            isRTL: false,
            scale: nil
        )
        let contents = XcodeAssetContents(images: [imageData], properties: properties)

        let json = try encoder.encode(contents)
        let jsonString = String(data: json, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("\"template-rendering-intent\" : \"original\""))
    }

    func testPropertiesNilWhenBothNil() {
        let properties = XcodeAssetContents.Properties(
            preserveVectorData: nil,
            renderMode: nil
        )

        XCTAssertNil(properties)
    }

    func testPropertiesNilWhenPreserveVectorDataFalse() {
        let properties = XcodeAssetContents.Properties(
            preserveVectorData: false,
            renderMode: nil
        )

        XCTAssertNil(properties)
    }

    // MARK: - Info Tests

    func testInfoIsAlwaysPresent() throws {
        let contents = XcodeAssetContents(colors: [])

        let json = try encoder.encode(contents)
        let jsonString = String(data: json, encoding: .utf8)

        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("\"author\" : \"xcode\""))
        XCTAssertTrue(jsonString!.contains("\"version\" : 1"))
    }

    // MARK: - Idiom Tests

    func testAllIdiomRawValues() {
        XCTAssertEqual(XcodeAssetIdiom.universal.rawValue, "universal")
        XCTAssertEqual(XcodeAssetIdiom.iphone.rawValue, "iphone")
        XCTAssertEqual(XcodeAssetIdiom.ipad.rawValue, "ipad")
        XCTAssertEqual(XcodeAssetIdiom.mac.rawValue, "mac")
        XCTAssertEqual(XcodeAssetIdiom.tv.rawValue, "tv")
        XCTAssertEqual(XcodeAssetIdiom.watch.rawValue, "watch")
        XCTAssertEqual(XcodeAssetIdiom.car.rawValue, "car")
    }

    // MARK: - Appearance Static Properties

    func testDarkAppearanceValues() {
        XCTAssertEqual(XcodeAssetContents.Appearance.dark.appearance, "luminosity")
        XCTAssertEqual(XcodeAssetContents.Appearance.dark.value, "dark")
    }

    func testHighContrastAppearanceValues() {
        XCTAssertEqual(XcodeAssetContents.Appearance.highContrast.appearance, "contrast")
        XCTAssertEqual(XcodeAssetContents.Appearance.highContrast.value, "high")
    }
}
