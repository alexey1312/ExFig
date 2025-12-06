@testable import ExFigCore
import Foundation
@testable import XcodeExport
import XCTest

final class ScaleExtensionTests: XCTestCase {
    func testAllScaleStringReturnsNil() {
        let scale = Scale.all

        XCTAssertNil(scale.string)
    }

    func testIndividualScale1ReturnsString() {
        let scale = Scale.individual(1.0)

        XCTAssertEqual(scale.string, "1x")
    }

    func testIndividualScale2ReturnsString() {
        let scale = Scale.individual(2.0)

        XCTAssertEqual(scale.string, "2x")
    }

    func testIndividualScale3ReturnsString() {
        let scale = Scale.individual(3.0)

        XCTAssertEqual(scale.string, "3x")
    }

    func testIndividualScale1_5ReturnsString() {
        let scale = Scale.individual(1.5)

        XCTAssertEqual(scale.string, "1.5x")
    }
}

final class ImageXcodeExtensionTests: XCTestCase {
    // swiftlint:disable:next force_unwrapping
    private let testURL = URL(string: "https://figma.com/image.png")!

    func testMakeFileContents() {
        let image = Image(name: "icon", url: testURL, format: "png")
        let directory = URL(fileURLWithPath: "/output")

        let contents = image.makeFileContents(to: directory, appearance: nil)

        XCTAssertEqual(contents.sourceURL, testURL)
        XCTAssertTrue(contents.destination.file.absoluteString.contains("icon"))
    }

    func testMakeFileContentsWithLightAppearance() {
        let image = Image(name: "icon", url: testURL, format: "png")
        let directory = URL(fileURLWithPath: "/output")

        let contents = image.makeFileContents(to: directory, appearance: .light)

        XCTAssertTrue(contents.destination.file.absoluteString.contains("L"))
    }

    func testMakeFileContentsWithDarkAppearance() {
        let image = Image(name: "icon", url: testURL, format: "png")
        let directory = URL(fileURLWithPath: "/output")

        let contents = image.makeFileContents(to: directory, appearance: .dark)

        XCTAssertTrue(contents.destination.file.absoluteString.contains("D"))
    }

    func testMakeXcodeAssetContentsImageData() {
        let image = Image(name: "icon", scale: .individual(2.0), url: testURL, format: "png")

        let imageData = image.makeXcodeAssetContentsImageData(
            scale: .individual(2.0),
            appearance: nil,
            isRTL: false
        )

        XCTAssertEqual(imageData.scale, "2x")
        XCTAssertEqual(imageData.idiom, .universal)
        XCTAssertNil(imageData.languageDirection)
    }

    func testMakeXcodeAssetContentsImageDataWithDarkAppearance() {
        let image = Image(name: "icon", url: testURL, format: "png")

        let imageData = image.makeXcodeAssetContentsImageData(
            scale: .all,
            appearance: .dark,
            isRTL: false
        )

        XCTAssertNotNil(imageData.appearances)
        XCTAssertEqual(imageData.appearances?.first?.value, "dark")
    }

    func testMakeXcodeAssetContentsImageDataWithLightAppearance() {
        let image = Image(name: "icon", url: testURL, format: "png")

        let imageData = image.makeXcodeAssetContentsImageData(
            scale: .all,
            appearance: .light,
            isRTL: false
        )

        XCTAssertNil(imageData.appearances)
    }

    func testMakeXcodeAssetContentsImageDataWithRTL() {
        let image = Image(name: "arrow", url: testURL, format: "png", isRTL: true)

        let imageData = image.makeXcodeAssetContentsImageData(
            scale: .all,
            appearance: nil,
            isRTL: true
        )

        XCTAssertEqual(imageData.languageDirection, "left-to-right")
    }

    func testMakeXcodeAssetContentsImageDataWithIdiom() {
        let image = Image(name: "icon", idiom: "iphone", url: testURL, format: "png")

        let imageData = image.makeXcodeAssetContentsImageData(
            scale: .individual(2.0),
            appearance: nil,
            isRTL: false
        )

        XCTAssertEqual(imageData.idiom, .iphone)
    }
}

final class ImagePackXcodeExtensionTests: XCTestCase {
    // swiftlint:disable:next force_unwrapping
    private let testURL = URL(string: "https://figma.com/image.png")!

    func testPackForXcodeWithAllScale() {
        let image = Image(name: "icon", scale: .all, url: testURL, format: "pdf")
        let pack = ImagePack(name: "icon", images: [image])

        let xcodePack = pack.packForXcode()

        XCTAssertNotNil(xcodePack)
        XCTAssertEqual(xcodePack?.images.count, 1)
    }

    func testPackForXcodeWithValidScales() {
        let images = [
            Image(name: "icon", scale: .individual(1.0), url: testURL, format: "png"),
            Image(name: "icon", scale: .individual(2.0), url: testURL, format: "png"),
            Image(name: "icon", scale: .individual(3.0), url: testURL, format: "png"),
        ]
        let pack = ImagePack(name: "icon", images: images)

        let xcodePack = pack.packForXcode()

        XCTAssertNotNil(xcodePack)
        XCTAssertEqual(xcodePack?.images.count, 3)
    }

    func testPackForXcodeFiltersInvalidIPhoneScales() {
        let images = [
            Image(name: "icon", scale: .individual(1.0), idiom: "iphone", url: testURL, format: "png"),
            Image(name: "icon", scale: .individual(2.0), idiom: "iphone", url: testURL, format: "png"),
            Image(name: "icon", scale: .individual(4.0), idiom: "iphone", url: testURL, format: "png"),
        ]
        let pack = ImagePack(name: "icon", images: images)

        let xcodePack = pack.packForXcode()

        XCTAssertEqual(xcodePack?.images.count, 2)
    }

    func testPackForXcodeFiltersInvalidIPadScales() {
        let images = [
            Image(name: "icon", scale: .individual(1.0), idiom: "ipad", url: testURL, format: "png"),
            Image(name: "icon", scale: .individual(2.0), idiom: "ipad", url: testURL, format: "png"),
            Image(name: "icon", scale: .individual(3.0), idiom: "ipad", url: testURL, format: "png"),
        ]
        let pack = ImagePack(name: "icon", images: images)

        let xcodePack = pack.packForXcode()

        XCTAssertEqual(xcodePack?.images.count, 2)
    }

    func testPackForXcodeWatchOnlyScale2() {
        let images = [
            Image(name: "icon", scale: .individual(1.0), idiom: "watch", url: testURL, format: "png"),
            Image(name: "icon", scale: .individual(2.0), idiom: "watch", url: testURL, format: "png"),
        ]
        let pack = ImagePack(name: "icon", images: images)

        let xcodePack = pack.packForXcode()

        XCTAssertEqual(xcodePack?.images.count, 1)
        XCTAssertEqual(xcodePack?.images.first?.scale.value, 2.0)
    }

    func testPackForXcodeCarValidScales() {
        let images = [
            Image(name: "icon", scale: .individual(1.0), idiom: "car", url: testURL, format: "png"),
            Image(name: "icon", scale: .individual(2.0), idiom: "car", url: testURL, format: "png"),
            Image(name: "icon", scale: .individual(3.0), idiom: "car", url: testURL, format: "png"),
        ]
        let pack = ImagePack(name: "icon", images: images)

        let xcodePack = pack.packForXcode()

        XCTAssertEqual(xcodePack?.images.count, 2)
    }

    func testMakeImageFileContents() {
        let images = [
            Image(name: "icon", scale: .individual(1.0), url: testURL, format: "png"),
            Image(name: "icon", scale: .individual(2.0), url: testURL, format: "png"),
        ]
        let pack = ImagePack(name: "icon", images: images)
        let directory = URL(fileURLWithPath: "/output")

        let contents = pack.makeImageFileContents(to: directory)

        XCTAssertEqual(contents.count, 2)
    }

    func testMakeXcodeAssetContentsImageData() {
        let images = [
            Image(name: "icon", scale: .individual(1.0), url: testURL, format: "png"),
            Image(name: "icon", scale: .individual(2.0), url: testURL, format: "png"),
        ]
        let pack = ImagePack(name: "icon", images: images)

        let data = pack.makeXcodeAssetContentsImageData()

        XCTAssertEqual(data.count, 2)
    }
}

final class XcodeEmptyContentsExtensionTests: XCTestCase {
    func testMakeFileContents() {
        let empty = XcodeEmptyContents()
        let directory = URL(fileURLWithPath: "/output/Assets.xcassets")

        let contents = empty.makeFileContents(to: directory)

        XCTAssertNotNil(contents.data)
        XCTAssertTrue(contents.destination.file.absoluteString.contains("Contents.json"))
    }
}

final class XcodeAssetContentsExtensionTests: XCTestCase {
    func testMakeFileContents() throws {
        let assetContents = XcodeAssetContents(images: [])
        let directory = URL(fileURLWithPath: "/output/icon.imageset")

        let contents = try assetContents.makeFileContents(to: directory)

        XCTAssertNotNil(contents.data)
        XCTAssertTrue(contents.destination.file.absoluteString.contains("Contents.json"))
    }

    func testMakeFileContentsWithImages() throws {
        let imageData = XcodeAssetContents.ImageData(
            appearances: nil,
            filename: "icon.png",
            idiom: .universal,
            isRTL: false,
            scale: "2x"
        )
        let assetContents = XcodeAssetContents(images: [imageData])
        let directory = URL(fileURLWithPath: "/output/icon.imageset")

        let contents = try assetContents.makeFileContents(to: directory)

        XCTAssertNotNil(contents.data)

        let json = String(data: contents.data!, encoding: .utf8)
        XCTAssertTrue(json?.contains("icon.png") == true)
    }
}
