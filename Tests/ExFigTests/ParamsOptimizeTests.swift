@testable import ExFig
import Foundation
import XCTest
import Yams

final class ParamsOptimizeTests: XCTestCase {
    // MARK: - OptimizeOptions Decoding

    func testOptimizeOptionsDecodingWithAllowLossyTrue() throws {
        let yaml = """
        allowLossy: true
        """

        let options = try YAMLDecoder().decode(OptimizeOptions.self, from: yaml)

        XCTAssertEqual(options.allowLossy, true)
    }

    func testOptimizeOptionsDecodingWithAllowLossyFalse() throws {
        let yaml = """
        allowLossy: false
        """

        let options = try YAMLDecoder().decode(OptimizeOptions.self, from: yaml)

        XCTAssertEqual(options.allowLossy, false)
    }

    func testOptimizeOptionsDefaultAllowLossy() throws {
        let yaml = "{}"

        let options = try YAMLDecoder().decode(OptimizeOptions.self, from: yaml)

        XCTAssertNil(options.allowLossy)
    }

    // MARK: - iOS.Images with optimize

    func testIOSImagesWithOptimizeEnabled() throws {
        let yaml = """
        assetsFolder: "Assets.xcassets"
        nameStyle: camelCase
        optimize: true
        optimizeOptions:
          allowLossy: false
        """

        let images = try YAMLDecoder().decode(Params.iOS.Images.self, from: yaml)

        XCTAssertEqual(images.optimize, true)
        XCTAssertEqual(images.optimizeOptions?.allowLossy, false)
    }

    func testIOSImagesWithOptimizeDisabled() throws {
        let yaml = """
        assetsFolder: "Assets.xcassets"
        nameStyle: camelCase
        optimize: false
        """

        let images = try YAMLDecoder().decode(Params.iOS.Images.self, from: yaml)

        XCTAssertEqual(images.optimize, false)
        XCTAssertNil(images.optimizeOptions)
    }

    func testIOSImagesBackwardCompatibility() throws {
        let yaml = """
        assetsFolder: "Assets.xcassets"
        nameStyle: camelCase
        """

        let images = try YAMLDecoder().decode(Params.iOS.Images.self, from: yaml)

        XCTAssertNil(images.optimize)
        XCTAssertNil(images.optimizeOptions)
    }

    // MARK: - Android.Images with optimize

    func testAndroidImagesWithOptimizeEnabled() throws {
        let yaml = """
        output: "app/src/main/res/drawable"
        format: png
        optimize: true
        optimizeOptions:
          allowLossy: true
        """

        let images = try YAMLDecoder().decode(Params.Android.Images.self, from: yaml)

        XCTAssertEqual(images.optimize, true)
        XCTAssertEqual(images.optimizeOptions?.allowLossy, true)
    }

    func testAndroidImagesBackwardCompatibility() throws {
        let yaml = """
        output: "app/src/main/res/drawable"
        format: png
        """

        let images = try YAMLDecoder().decode(Params.Android.Images.self, from: yaml)

        XCTAssertNil(images.optimize)
        XCTAssertNil(images.optimizeOptions)
    }

    // MARK: - Flutter.Images with optimize

    func testFlutterImagesWithOptimizeEnabled() throws {
        let yaml = """
        output: "assets/images"
        optimize: true
        optimizeOptions:
          allowLossy: false
        """

        let images = try YAMLDecoder().decode(Params.Flutter.Images.self, from: yaml)

        XCTAssertEqual(images.optimize, true)
        XCTAssertEqual(images.optimizeOptions?.allowLossy, false)
    }

    func testFlutterImagesBackwardCompatibility() throws {
        let yaml = """
        output: "assets/images"
        """

        let images = try YAMLDecoder().decode(Params.Flutter.Images.self, from: yaml)

        XCTAssertNil(images.optimize)
        XCTAssertNil(images.optimizeOptions)
    }

    // MARK: - Full Config Integration

    func testFullConfigWithOptimize() throws {
        let yaml = """
        figma:
          lightFileId: "abc123"
        ios:
          xcodeprojPath: "Example.xcodeproj"
          target: "Example"
          xcassetsPath: "Example/Assets.xcassets"
          xcassetsInMainBundle: true
          images:
            assetsFolder: "Images"
            nameStyle: camelCase
            optimize: true
            optimizeOptions:
              allowLossy: true
        """

        let params = try YAMLDecoder().decode(Params.self, from: yaml)

        XCTAssertEqual(params.ios?.images?.optimize, true)
        XCTAssertEqual(params.ios?.images?.optimizeOptions?.allowLossy, true)
    }
}
