@testable import ExFigCore
import Foundation
import XCTest

final class ScaleTests: XCTestCase {
    func testAllScaleValue() {
        let scale = Scale.all

        XCTAssertEqual(scale.value, 1.0)
    }

    func testIndividualScaleValue() {
        let scale1 = Scale.individual(1.0)
        let scale2 = Scale.individual(2.0)
        let scale3 = Scale.individual(3.0)

        XCTAssertEqual(scale1.value, 1.0)
        XCTAssertEqual(scale2.value, 2.0)
        XCTAssertEqual(scale3.value, 3.0)
    }
}

final class ImageTests: XCTestCase {
    // swiftlint:disable:next force_unwrapping
    private let testURL = URL(string: "https://figma.com/image.png")!

    // MARK: - Initialization

    func testInitWithRequiredParameters() {
        let image = Image(name: "icon", url: testURL, format: "png")

        XCTAssertEqual(image.name, "icon")
        XCTAssertEqual(image.url, testURL)
        XCTAssertEqual(image.format, "png")
        XCTAssertEqual(image.scale.value, 1.0)
        XCTAssertNil(image.platform)
        XCTAssertNil(image.idiom)
        XCTAssertFalse(image.isRTL)
    }

    func testInitWithAllParameters() {
        let image = Image(
            name: "back_arrow",
            scale: .individual(2.0),
            platform: .ios,
            idiom: "iphone",
            url: testURL,
            format: "pdf",
            isRTL: true
        )

        XCTAssertEqual(image.name, "back_arrow")
        XCTAssertEqual(image.scale.value, 2.0)
        XCTAssertEqual(image.platform, .ios)
        XCTAssertEqual(image.idiom, "iphone")
        XCTAssertEqual(image.format, "pdf")
        XCTAssertTrue(image.isRTL)
    }

    func testInitWithAllScale() {
        let image = Image(name: "vector", scale: .all, url: testURL, format: "svg")

        XCTAssertEqual(image.scale.value, 1.0)
    }

    // MARK: - Equatable

    func testEqualityByName() {
        let image1 = Image(name: "icon", url: testURL, format: "png")
        let image2 = Image(
            name: "icon",
            scale: .individual(2.0),
            url: testURL,
            format: "svg",
            isRTL: true
        )

        XCTAssertEqual(image1, image2)
    }

    func testInequalityByName() {
        let image1 = Image(name: "icon1", url: testURL, format: "png")
        let image2 = Image(name: "icon2", url: testURL, format: "png")

        XCTAssertNotEqual(image1, image2)
    }

    // MARK: - Hashable

    func testHashValue() {
        let image1 = Image(name: "icon", url: testURL, format: "png")
        let image2 = Image(name: "icon", scale: .individual(3.0), url: testURL, format: "svg")

        XCTAssertEqual(image1.hashValue, image2.hashValue)
    }

    func testHashableInSet() {
        let image1 = Image(name: "icon1", url: testURL, format: "png")
        let image2 = Image(name: "icon2", url: testURL, format: "png")

        let set: Set<Image> = [image1, image2]

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Mutable Name

    func testMutableName() {
        var image = Image(name: "old", url: testURL, format: "png")

        image.name = "new"

        XCTAssertEqual(image.name, "new")
    }

    // MARK: - Mutable Platform

    func testMutablePlatform() {
        var image = Image(name: "icon", url: testURL, format: "png")

        XCTAssertNil(image.platform)

        image.platform = .android

        XCTAssertEqual(image.platform, .android)
    }
}

final class ImagePackTests: XCTestCase {
    // swiftlint:disable:next force_unwrapping
    private let testURL = URL(string: "https://figma.com/image.png")!

    // MARK: - Initialization

    func testInitWithImages() {
        let images = [
            Image(name: "icon", scale: .individual(1.0), url: testURL, format: "png"),
            Image(name: "icon", scale: .individual(2.0), url: testURL, format: "png"),
            Image(name: "icon", scale: .individual(3.0), url: testURL, format: "png"),
        ]

        let pack = ImagePack(name: "icon", images: images)

        XCTAssertEqual(pack.name, "icon")
        XCTAssertEqual(pack.images.count, 3)
        XCTAssertNil(pack.platform)
        XCTAssertEqual(pack.renderMode, .template)
    }

    func testInitWithPlatform() {
        let images = [Image(name: "icon", url: testURL, format: "png")]

        let pack = ImagePack(name: "icon", images: images, platform: .ios)

        XCTAssertEqual(pack.platform, .ios)
    }

    func testInitWithSingleImage() {
        let image = Image(name: "icon", url: testURL, format: "png")

        let pack = ImagePack(image: image)

        XCTAssertEqual(pack.name, "icon")
        XCTAssertEqual(pack.images.count, 1)
        XCTAssertEqual(pack.images.first?.name, "icon")
    }

    func testInitWithSingleImageAndPlatform() {
        let image = Image(name: "icon", url: testURL, format: "png")

        let pack = ImagePack(image: image, platform: .android)

        XCTAssertEqual(pack.platform, .android)
    }

    // MARK: - Name Update Propagation

    func testNameUpdatePropagatestoImages() {
        let images = [
            Image(name: "old", scale: .individual(1.0), url: testURL, format: "png"),
            Image(name: "old", scale: .individual(2.0), url: testURL, format: "png"),
        ]
        var pack = ImagePack(name: "old", images: images)

        pack.name = "new"

        XCTAssertEqual(pack.name, "new")
        XCTAssertTrue(pack.images.allSatisfy { $0.name == "new" })
    }

    // MARK: - Render Mode

    func testDefaultRenderModeIsTemplate() {
        let pack = ImagePack(name: "icon", images: [])

        XCTAssertEqual(pack.renderMode, .template)
    }

    func testMutableRenderMode() {
        var pack = ImagePack(name: "icon", images: [])

        pack.renderMode = .original

        XCTAssertEqual(pack.renderMode, .original)
    }
}
