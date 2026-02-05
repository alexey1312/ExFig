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
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
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
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
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
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
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
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
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
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
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

        let generatedCode = try String(data: XCTUnwrap(content), encoding: .utf8)
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
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
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

        let generatedCode = try String(data: XCTUnwrap(content), encoding: .utf8)
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
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
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

        let generatedCode = try String(data: XCTUnwrap(content), encoding: .utf8)
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
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
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

        let generatedCode = try String(data: XCTUnwrap(content), encoding: .utf8)
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
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
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

        let generatedCode = try String(data: XCTUnwrap(content), encoding: .utf8)
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
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeImagesExporter(output: output)

        // First export
        let result = try exporter.export(
            assets: [AssetPair(light: ImagePack(image: image1), dark: nil)],
            append: false
        )

        try write(file: XCTUnwrap(result.last))

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
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
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

        let generatedCode = try String(data: XCTUnwrap(content), encoding: .utf8)
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
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
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
        let image1x = try Image(name: "hero", scale: .individual(1.0), url: XCTUnwrap(URL(string: "1")), format: "png")
        let image2x = try Image(name: "hero", scale: .individual(2.0), url: XCTUnwrap(URL(string: "2")), format: "png")
        let image3x = try Image(name: "hero", scale: .individual(3.0), url: XCTUnwrap(URL(string: "3")), format: "png")
        let pack = ImagePack(name: "hero", images: [image1x, image2x, image3x])

        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
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
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
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
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
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

    // MARK: - Code Connect Tests

    /// Tests that Code Connect file is generated when codeConnectSwiftURL is configured
    /// and images have nodeId/fileId set.
    func testExportWithCodeConnect_generatesCodeConnectFile() throws {
        let codeConnectURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("Images.figma.swift")

        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL,
            codeConnectSwiftURL: codeConnectURL
        )
        let exporter = XcodeImagesExporter(output: output)

        // Create images with nodeId and fileId
        var img1 = ImagePack(image: image1)
        img1.nodeId = "12016:2218"
        img1.fileId = "VXmPoarVoCQSNjdlROoJLO"

        var img2 = ImagePack(image: image2)
        img2.nodeId = "12016:2219"
        img2.fileId = "VXmPoarVoCQSNjdlROoJLO"

        let result = try exporter.export(
            assets: [
                AssetPair(light: img1, dark: nil),
                AssetPair(light: img2, dark: nil),
            ],
            append: false
        )

        // Should have 7 files: Contents.json, 2x (imageset/Contents.json + png), extension, codeConnect
        XCTAssertEqual(result.count, 7)

        // Find the Code Connect file
        let codeConnectFile = result.first { $0.destination.url.absoluteString.hasSuffix("Images.figma.swift") }
        XCTAssertNotNil(codeConnectFile)

        let content = try XCTUnwrap(codeConnectFile?.data)
        let generatedCode = String(data: content, encoding: .utf8)

        let referenceCode = """
        \(header)

        #if DEBUG
        import SwiftUI


        struct Asset_image1: FigmaConnect {
            let figmaNodeUrl = "https://www.figma.com/design/VXmPoarVoCQSNjdlROoJLO?node-id=12016-2218"

            var body: some View {
                Image("image1")
            }
        }


        struct Asset_image2: FigmaConnect {
            let figmaNodeUrl = "https://www.figma.com/design/VXmPoarVoCQSNjdlROoJLO?node-id=12016-2219"

            var body: some View {
                Image("image2")
            }
        }


        #endif

        """
        expectNoDifference(generatedCode, referenceCode)
    }

    /// Tests that Code Connect file is NOT generated when images don't have nodeId/fileId.
    func testExportWithCodeConnect_noNodeId_skipsCodeConnectFile() throws {
        let codeConnectURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("Images.figma.swift")

        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL,
            codeConnectSwiftURL: codeConnectURL
        )
        let exporter = XcodeImagesExporter(output: output)

        // Images without nodeId/fileId
        let result = try exporter.export(
            assets: [
                AssetPair(light: ImagePack(image: image1), dark: nil),
                AssetPair(light: ImagePack(image: image2), dark: nil),
            ],
            append: false
        )

        // Should have 6 files (no Code Connect file)
        XCTAssertEqual(result.count, 6)

        // Verify no Code Connect file
        let codeConnectFile = result.first { $0.destination.url.absoluteString.hasSuffix(".figma.swift") }
        XCTAssertNil(codeConnectFile)
    }

    /// Tests that Code Connect file only includes images with valid nodeId/fileId.
    func testExportWithCodeConnect_mixedImages_onlyIncludesValidOnes() throws {
        let codeConnectURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("Images.figma.swift")

        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL,
            codeConnectSwiftURL: codeConnectURL
        )
        let exporter = XcodeImagesExporter(output: output)

        // Mix of images with and without nodeId/fileId
        var imgWithNodeId = ImagePack(image: image1)
        imgWithNodeId.nodeId = "12016:2218"
        imgWithNodeId.fileId = "VXmPoarVoCQSNjdlROoJLO"

        let imgWithoutNodeId = ImagePack(image: image2) // No nodeId/fileId

        let result = try exporter.export(
            assets: [
                AssetPair(light: imgWithNodeId, dark: nil),
                AssetPair(light: imgWithoutNodeId, dark: nil),
            ],
            append: false
        )

        // Find the Code Connect file
        let codeConnectFile = result.first { $0.destination.url.absoluteString.hasSuffix("Images.figma.swift") }
        XCTAssertNotNil(codeConnectFile)

        let content = try XCTUnwrap(codeConnectFile?.data)
        let generatedCode = String(data: content, encoding: .utf8)

        // Should only include image1 (with nodeId), not image2
        let referenceCode = """
        \(header)

        #if DEBUG
        import SwiftUI


        struct Asset_image1: FigmaConnect {
            let figmaNodeUrl = "https://www.figma.com/design/VXmPoarVoCQSNjdlROoJLO?node-id=12016-2218"

            var body: some View {
                Image("image1")
            }
        }


        #endif

        """
        expectNoDifference(generatedCode, referenceCode)
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
