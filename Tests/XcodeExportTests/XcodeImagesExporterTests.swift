// swiftlint:disable force_unwrapping file_length type_body_length
import CustomDump
import ExFigCore
import Foundation
@testable import XcodeExport
import XCTest

final class XcodeImagesExporterTests: XCTestCase {
    // MARK: - Properties

    private let image1 = Image(name: "image1", url: URL(string: "1")!, format: "png")
    private let image1Dark = Image(name: "image1", url: URL(string: "1_dark")!, format: "png")
    private let image2 = Image(name: "image2", url: URL(string: "2")!, format: "png")
    private let image2Dark = Image(name: "image2", url: URL(string: "2_dark")!, format: "png")

    private let uiKitImageExtensionURL = FileManager.default
        .temporaryDirectory
        .appendingPathComponent("UIImage+extension.swift")
    private let swiftUIImageExtensionURL = FileManager.default
        .temporaryDirectory
        .appendingPathComponent("Image+extension.swift")

    // MARK: - Basic Export Tests

    func testExportSingleImage() throws {
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeImagesExporter(output: output)
        let result = try exporter.export(
            assets: [AssetPair(light: ImagePack(image: image1), dark: nil)],
            append: false
        )

        XCTAssertEqual(result.count, 4)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("image1.imageset/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("image1.imageset/image1.png"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))
    }

    func testExportMultipleImages() throws {
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeImagesExporter(output: output)
        let result = try exporter.export(
            assets: [
                AssetPair(light: ImagePack(image: image1), dark: nil),
                AssetPair(light: ImagePack(image: image2), dark: nil),
            ],
            append: false
        )

        XCTAssertEqual(result.count, 6)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("image1.imageset/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("image1.imageset/image1.png"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("image2.imageset/Contents.json"))
        XCTAssertTrue(result[4].destination.url.absoluteString.hasSuffix("image2.imageset/image2.png"))
        XCTAssertTrue(result[5].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))
    }

    // MARK: - Dark Mode Export Tests

    func testExportWithDarkVariant() throws {
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeImagesExporter(output: output)
        let result = try exporter.export(
            assets: [
                AssetPair(light: ImagePack(image: image1), dark: ImagePack(image: image1Dark)),
            ],
            append: false
        )

        XCTAssertEqual(result.count, 5)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("image1.imageset/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("image1.imageset/image1L.png"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("image1.imageset/image1D.png"))
        XCTAssertTrue(result[4].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))
    }

    func testExportMultipleWithDarkVariants() throws {
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeImagesExporter(output: output)
        let result = try exporter.export(
            assets: [
                AssetPair(light: ImagePack(image: image1), dark: ImagePack(image: image1Dark)),
                AssetPair(light: ImagePack(image: image2), dark: ImagePack(image: image2Dark)),
            ],
            append: false
        )

        XCTAssertEqual(result.count, 8)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("image1.imageset/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("image1.imageset/image1L.png"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("image1.imageset/image1D.png"))
        XCTAssertTrue(result[4].destination.url.absoluteString.hasSuffix("image2.imageset/Contents.json"))
        XCTAssertTrue(result[5].destination.url.absoluteString.hasSuffix("image2.imageset/image2L.png"))
        XCTAssertTrue(result[6].destination.url.absoluteString.hasSuffix("image2.imageset/image2D.png"))
        XCTAssertTrue(result[7].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))
    }

    // MARK: - UIKit Extension Tests

    func testExportGeneratesUIKitExtension() throws {
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeImagesExporter(output: output)
        let result = try exporter.export(
            assets: [
                AssetPair(light: ImagePack(image: image1), dark: nil),
                AssetPair(light: ImagePack(image: image2), dark: nil),
            ],
            append: false
        )

        let content = result.last?.data
        XCTAssertNotNil(content)

        let generatedCode = String(data: content!, encoding: .utf8)
        let referenceCode = """
        \(header)

        import UIKit

        private class BundleProvider {
            static let bundle = Bundle(for: BundleProvider.self)
        }

        public extension UIImage {
            static var image1: UIImage { UIImage(named: #function)! }
            static var image2: UIImage { UIImage(named: #function)! }
        }

        """
        expectNoDifference(generatedCode, referenceCode)
    }

    // MARK: - SwiftUI Extension Tests

    func testExportSwiftUIExtension() throws {
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: true,
            swiftUIImageExtensionURL: swiftUIImageExtensionURL
        )
        let exporter = XcodeImagesExporter(output: output)
        let result = try exporter.export(
            assets: [
                AssetPair(light: ImagePack(image: image1), dark: nil),
                AssetPair(light: ImagePack(image: image2), dark: nil),
            ],
            append: false
        )

        XCTAssertEqual(result.count, 6)
        XCTAssertTrue(result[5].destination.url.absoluteString.hasSuffix("Image+extension.swift"))

        let content = result[5].data
        XCTAssertNotNil(content)

        let generatedCode = String(data: content!, encoding: .utf8)
        let referenceCode = """
        \(header)

        import SwiftUI

        private class BundleProvider {
            static let bundle = Bundle(for: BundleProvider.self)
        }

        public extension Image {
            static var image1: Image { Image(#function) }
            static var image2: Image { Image(#function) }
        }

        """
        expectNoDifference(generatedCode, referenceCode)
    }

    // MARK: - Bundle Configuration Tests

    func testExportInSeparateBundle() throws {
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: false,
            assetsInSwiftPackage: false,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeImagesExporter(output: output)
        let result = try exporter.export(
            assets: [
                AssetPair(light: ImagePack(image: image1), dark: nil),
            ],
            append: false
        )

        let content = result.last?.data
        XCTAssertNotNil(content)

        let generatedCode = String(data: content!, encoding: .utf8)
        let referenceCode = """
        \(header)

        import UIKit

        private class BundleProvider {
            static let bundle = Bundle(for: BundleProvider.self)
        }

        public extension UIImage {
            static var image1: UIImage { UIImage(named: #function, in: BundleProvider.bundle, compatibleWith: nil)! }
        }

        """
        expectNoDifference(generatedCode, referenceCode)
    }

    func testExportInSwiftPackage() throws {
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: false,
            assetsInSwiftPackage: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeImagesExporter(output: output)
        let result = try exporter.export(
            assets: [
                AssetPair(light: ImagePack(image: image1), dark: nil),
            ],
            append: false
        )

        let content = result.last?.data
        XCTAssertNotNil(content)

        let generatedCode = String(data: content!, encoding: .utf8)
        let referenceCode = """
        \(header)

        import UIKit

        private class BundleProvider {
            static let bundle = Bundle.module
        }

        public extension UIImage {
            static var image1: UIImage { UIImage(named: #function, in: BundleProvider.bundle, compatibleWith: nil)! }
        }

        """
        expectNoDifference(generatedCode, referenceCode)
    }

    func testExportSwiftUIInSeparateBundle() throws {
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: false,
            swiftUIImageExtensionURL: swiftUIImageExtensionURL
        )
        let exporter = XcodeImagesExporter(output: output)
        let result = try exporter.export(
            assets: [
                AssetPair(light: ImagePack(image: image1), dark: nil),
            ],
            append: false
        )

        let content = result.last?.data
        XCTAssertNotNil(content)

        let generatedCode = String(data: content!, encoding: .utf8)
        let referenceCode = """
        \(header)

        import SwiftUI

        private class BundleProvider {
            static let bundle = Bundle(for: BundleProvider.self)
        }

        public extension Image {
            static var image1: Image { Image(#function, bundle: BundleProvider.bundle) }
        }

        """
        expectNoDifference(generatedCode, referenceCode)
    }

    // MARK: - Append Mode Tests

    func testAppendAfterExport() throws {
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeImagesExporter(output: output)

        // First export
        let result = try exporter.export(
            assets: [AssetPair(light: ImagePack(image: image1), dark: nil)],
            append: false
        )

        try write(file: result.last!)

        // Append export
        let appendResult = try exporter.export(
            assets: [AssetPair(light: ImagePack(image: image2), dark: nil)],
            append: true
        )

        XCTAssertEqual(appendResult.count, 4)
        let resultContent = try XCTUnwrap(appendResult.last?.data)

        let generatedCode = String(data: resultContent, encoding: .utf8)
        let referenceCode = """
        \(header)

        import UIKit

        private class BundleProvider {
            static let bundle = Bundle(for: BundleProvider.self)
        }

        public extension UIImage {
            static var image1: UIImage { UIImage(named: #function)! }
            static var image2: UIImage { UIImage(named: #function)! }
        }

        """
        expectNoDifference(generatedCode, referenceCode)
    }

    // MARK: - ObjC Attribute Tests

    func testExportWithObjcAttribute() throws {
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: true,
            addObjcAttribute: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeImagesExporter(output: output)
        let result = try exporter.export(
            assets: [
                AssetPair(light: ImagePack(image: image1), dark: nil),
            ],
            append: false
        )

        let content = result.last?.data
        XCTAssertNotNil(content)

        let generatedCode = String(data: content!, encoding: .utf8)
        let referenceCode = """
        \(header)

        import UIKit

        private class BundleProvider {
            static let bundle = Bundle(for: BundleProvider.self)
        }

        public extension UIImage {
            @objc static var image1: UIImage { UIImage(named: #function)! }
        }

        """
        expectNoDifference(generatedCode, referenceCode)
    }

    // MARK: - Empty Assets Tests

    func testExportEmptyAssets() throws {
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeImagesExporter(output: output)
        let result = try exporter.export(assets: [], append: false)

        // Should still generate Contents.json and extension file
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))
    }

    // MARK: - Multiple Scales Tests

    func testExportMultipleScales() throws {
        let image1x = Image(name: "hero", scale: .individual(1.0), url: URL(string: "1")!, format: "png")
        let image2x = Image(name: "hero", scale: .individual(2.0), url: URL(string: "2")!, format: "png")
        let image3x = Image(name: "hero", scale: .individual(3.0), url: URL(string: "3")!, format: "png")
        let pack = ImagePack(name: "hero", images: [image1x, image2x, image3x])

        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeImagesExporter(output: output)
        let result = try exporter.export(
            assets: [AssetPair(light: pack, dark: nil)],
            append: false
        )

        XCTAssertEqual(result.count, 6)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("hero.imageset/Contents.json"))
        // Images at different scales (1x, 2x, 3x all have scale suffix)
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("hero.imageset/hero@1x.png"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("hero.imageset/hero@2x.png"))
        XCTAssertTrue(result[4].destination.url.absoluteString.hasSuffix("hero.imageset/hero@3x.png"))
        XCTAssertTrue(result[5].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))
    }

    // MARK: - No Extension URLs Tests

    func testExportWithoutExtensionURLs() throws {
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: true
        )
        let exporter = XcodeImagesExporter(output: output)
        let result = try exporter.export(
            assets: [AssetPair(light: ImagePack(image: image1), dark: nil)],
            append: false
        )

        // Should only generate Contents.json and image files, no extensions
        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("image1.imageset/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("image1.imageset/image1.png"))
    }

    // MARK: - Both Extension URLs Tests

    func testExportWithBothExtensionURLs() throws {
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL,
            swiftUIImageExtensionURL: swiftUIImageExtensionURL
        )
        let exporter = XcodeImagesExporter(output: output)
        let result = try exporter.export(
            assets: [AssetPair(light: ImagePack(image: image1), dark: nil)],
            append: false
        )

        XCTAssertEqual(result.count, 5)
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("Image+extension.swift"))
        XCTAssertTrue(result[4].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))
    }
}

// MARK: - Helpers

private extension XcodeImagesExporterTests {
    func write(file: FileContents) throws {
        let content = try XCTUnwrap(file.data)

        let directoryURL = URL(fileURLWithPath: file.destination.directory.path)
        try FileManager.default.createDirectory(
            atPath: directoryURL.path,
            withIntermediateDirectories: true,
            attributes: [:]
        )
        let fileURL = URL(fileURLWithPath: file.destination.url.path)

        try content.write(to: fileURL, options: .atomic)
    }
}
