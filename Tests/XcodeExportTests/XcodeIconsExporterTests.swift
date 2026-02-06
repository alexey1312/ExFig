// swiftlint:disable force_unwrapping file_length
import CustomDump
import ExFigCore
import Foundation
@testable import XcodeExport
import XCTest

final class XcodeIconsExporterTests: XCTestCase {
    // MARK: - Properties

    private let image1 = Image(name: "image1", url: URL(string: "1")!, format: "pdf")
    private let image1Dark = Image(name: "image1", url: URL(string: "1_dark")!, format: "pdf")
    private let image2 = Image(name: "image2", url: URL(string: "2")!, format: "pdf")
    private let image2Dark = Image(name: "image2", url: URL(string: "2_dark")!, format: "pdf")
    private let imageWithKeyword = Image(name: "class", url: URL(string: "2")!, format: "pdf")
    private let tabBarIcon = Image(name: "ic24TabBarHome", url: URL(string: "1")!, format: "pdf")

    private let uiKitImageExtensionURL = FileManager.default
        .temporaryDirectory
        .appendingPathComponent("UIImage+extension.swift")
    private let swiftUIImageExtensionURL = FileManager.default
        .temporaryDirectory
        .appendingPathComponent("Image+extension.swift")

    // MARK: - Tests

    func testExport() throws {
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeIconsExporter(output: output)
        let result = try exporter.export(
            icons: [
                AssetPair(light: ImagePack(image: image1), dark: nil),
                AssetPair(light: ImagePack(image: image2), dark: nil),
            ],
            append: false
        )

        XCTAssertEqual(result.count, 6)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("image1.imageset/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("image1.imageset/image1.pdf"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("image2.imageset/Contents.json"))
        XCTAssertTrue(result[4].destination.url.absoluteString.hasSuffix("image2.imageset/image2.pdf"))
        XCTAssertTrue(result[5].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))

        let content = result[5].data
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

    func testExportPair() throws {
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeIconsExporter(output: output)
        let result = try exporter.export(
            icons: [
                AssetPair(light: ImagePack(image: image1), dark: ImagePack(image: image1Dark)),
                AssetPair(light: ImagePack(image: image2), dark: ImagePack(image: image2Dark)),
            ],
            append: false
        )

        XCTAssertEqual(result.count, 8)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("image1.imageset/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("image1.imageset/image1L.pdf"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("image1.imageset/image1D.pdf"))
        XCTAssertTrue(result[4].destination.url.absoluteString.hasSuffix("image2.imageset/Contents.json"))
        XCTAssertTrue(result[5].destination.url.absoluteString.hasSuffix("image2.imageset/image2L.pdf"))
        XCTAssertTrue(result[6].destination.url.absoluteString.hasSuffix("image2.imageset/image2D.pdf"))
        XCTAssertTrue(result[7].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))

        let content = result[7].data
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

    func testExportWithObjc() throws {
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            addObjcAttribute: true,
            uiKitImageExtensionURL: XCTUnwrap(URL(string: "~/UIImage+extension.swift"))
        )
        let exporter = XcodeIconsExporter(output: output)
        let result = try exporter.export(
            icons: [
                AssetPair(light: ImagePack(image: image1), dark: nil),
                AssetPair(light: ImagePack(image: image2), dark: nil),
            ],
            append: false
        )

        XCTAssertEqual(result.count, 6)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("image1.imageset/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("image1.imageset/image1.pdf"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("image2.imageset/Contents.json"))
        XCTAssertTrue(result[4].destination.url.absoluteString.hasSuffix("image2.imageset/image2.pdf"))
        XCTAssertTrue(result[5].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))

        let content = result[5].data
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
            @objc static var image2: UIImage { UIImage(named: #function)! }
        }

        """
        expectNoDifference(generatedCode, referenceCode)
    }

    func testExportPairWithObjc() throws {
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            addObjcAttribute: true,
            uiKitImageExtensionURL: XCTUnwrap(URL(string: "~/UIImage+extension.swift"))
        )
        let exporter = XcodeIconsExporter(output: output)
        let result = try exporter.export(
            icons: [
                AssetPair(light: ImagePack(image: image1), dark: ImagePack(image: image1Dark)),
                AssetPair(light: ImagePack(image: image2), dark: ImagePack(image: image2Dark)),
            ],
            append: false
        )

        XCTAssertEqual(result.count, 8)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("image1.imageset/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("image1.imageset/image1L.pdf"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("image1.imageset/image1D.pdf"))
        XCTAssertTrue(result[4].destination.url.absoluteString.hasSuffix("image2.imageset/Contents.json"))
        XCTAssertTrue(result[5].destination.url.absoluteString.hasSuffix("image2.imageset/image2L.pdf"))
        XCTAssertTrue(result[6].destination.url.absoluteString.hasSuffix("image2.imageset/image2D.pdf"))
        XCTAssertTrue(result[7].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))

        let content = result[7].data
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
            @objc static var image2: UIImage { UIImage(named: #function)! }
        }

        """
        expectNoDifference(generatedCode, referenceCode)
    }

    func testExportInSeparateBundle() throws {
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: false,
            assetsInSwiftPackage: false,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeIconsExporter(output: output)
        let result = try exporter.export(
            icons: [
                AssetPair(light: ImagePack(image: image1), dark: nil),
                AssetPair(light: ImagePack(image: image2), dark: nil),
            ],
            append: false
        )

        XCTAssertEqual(result.count, 6)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("image1.imageset/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("image1.imageset/image1.pdf"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("image2.imageset/Contents.json"))
        XCTAssertTrue(result[4].destination.url.absoluteString.hasSuffix("image2.imageset/image2.pdf"))
        XCTAssertTrue(result[5].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))

        let content = result[5].data
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
            static var image2: UIImage { UIImage(named: #function, in: BundleProvider.bundle, compatibleWith: nil)! }
        }

        """
        expectNoDifference(generatedCode, referenceCode)
    }

    func testExportPairInSeparateBundle() throws {
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: false,
            assetsInSwiftPackage: false,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeIconsExporter(output: output)
        let result = try exporter.export(
            icons: [
                AssetPair(light: ImagePack(image: image1), dark: ImagePack(image: image1Dark)),
                AssetPair(light: ImagePack(image: image2), dark: ImagePack(image: image2Dark)),
            ],
            append: false
        )

        XCTAssertEqual(result.count, 8)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("image1.imageset/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("image1.imageset/image1L.pdf"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("image1.imageset/image1D.pdf"))
        XCTAssertTrue(result[4].destination.url.absoluteString.hasSuffix("image2.imageset/Contents.json"))
        XCTAssertTrue(result[5].destination.url.absoluteString.hasSuffix("image2.imageset/image2L.pdf"))
        XCTAssertTrue(result[6].destination.url.absoluteString.hasSuffix("image2.imageset/image2D.pdf"))
        XCTAssertTrue(result[7].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))

        let content = result[7].data
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
            static var image2: UIImage { UIImage(named: #function, in: BundleProvider.bundle, compatibleWith: nil)! }
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
        let exporter = XcodeIconsExporter(output: output)
        let result = try exporter.export(
            icons: [
                AssetPair(light: ImagePack(image: image1), dark: nil),
                AssetPair(light: ImagePack(image: image2), dark: nil),
            ],
            append: false
        )

        XCTAssertEqual(result.count, 6)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("image1.imageset/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("image1.imageset/image1.pdf"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("image2.imageset/Contents.json"))
        XCTAssertTrue(result[4].destination.url.absoluteString.hasSuffix("image2.imageset/image2.pdf"))
        XCTAssertTrue(result[5].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))

        let content = result[5].data
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
            static var image2: UIImage { UIImage(named: #function, in: BundleProvider.bundle, compatibleWith: nil)! }
        }

        """
        expectNoDifference(generatedCode, referenceCode)
    }

    func testExportPairInSwiftPackage() throws {
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: false,
            assetsInSwiftPackage: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeIconsExporter(output: output)
        let result = try exporter.export(
            icons: [
                AssetPair(light: ImagePack(image: image1), dark: ImagePack(image: image1Dark)),
                AssetPair(light: ImagePack(image: image2), dark: ImagePack(image: image2Dark)),
            ],
            append: false
        )

        XCTAssertEqual(result.count, 8)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("image1.imageset/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("image1.imageset/image1L.pdf"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("image1.imageset/image1D.pdf"))
        XCTAssertTrue(result[4].destination.url.absoluteString.hasSuffix("image2.imageset/Contents.json"))
        XCTAssertTrue(result[5].destination.url.absoluteString.hasSuffix("image2.imageset/image2L.pdf"))
        XCTAssertTrue(result[6].destination.url.absoluteString.hasSuffix("image2.imageset/image2D.pdf"))
        XCTAssertTrue(result[7].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))

        let content = result[7].data
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
            static var image2: UIImage { UIImage(named: #function, in: BundleProvider.bundle, compatibleWith: nil)! }
        }

        """
        expectNoDifference(generatedCode, referenceCode)
    }

    func testExportSwiftUI() throws {
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            swiftUIImageExtensionURL: swiftUIImageExtensionURL
        )
        let exporter = XcodeIconsExporter(output: output)
        let result = try exporter.export(
            icons: [
                AssetPair(light: ImagePack(image: image1), dark: nil),
                AssetPair(light: ImagePack(image: image2), dark: nil),
            ],
            append: false
        )

        XCTAssertEqual(result.count, 6)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("image1.imageset/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("image1.imageset/image1.pdf"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("image2.imageset/Contents.json"))
        XCTAssertTrue(result[4].destination.url.absoluteString.hasSuffix("image2.imageset/image2.pdf"))
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

    func testExportPairSwiftUI() throws {
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            swiftUIImageExtensionURL: swiftUIImageExtensionURL
        )
        let exporter = XcodeIconsExporter(output: output)
        let result = try exporter.export(
            icons: [
                AssetPair(light: ImagePack(image: image1), dark: ImagePack(image: image1Dark)),
                AssetPair(light: ImagePack(image: image2), dark: ImagePack(image: image2Dark)),
            ],
            append: false
        )

        XCTAssertEqual(result.count, 8)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("image1.imageset/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("image1.imageset/image1L.pdf"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("image1.imageset/image1D.pdf"))
        XCTAssertTrue(result[4].destination.url.absoluteString.hasSuffix("image2.imageset/Contents.json"))
        XCTAssertTrue(result[5].destination.url.absoluteString.hasSuffix("image2.imageset/image2L.pdf"))
        XCTAssertTrue(result[6].destination.url.absoluteString.hasSuffix("image2.imageset/image2D.pdf"))
        XCTAssertTrue(result[7].destination.url.absoluteString.hasSuffix("Image+extension.swift"))

        let content = result[7].data
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

    func testExportSwiftUIInSeparateBundle() throws {
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: false,
            swiftUIImageExtensionURL: swiftUIImageExtensionURL
        )
        let exporter = XcodeIconsExporter(output: output)
        let result = try exporter.export(
            icons: [
                AssetPair(light: ImagePack(image: image1), dark: nil),
                AssetPair(light: ImagePack(image: image2), dark: nil),
            ],
            append: false
        )

        XCTAssertEqual(result.count, 6)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("image1.imageset/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("image1.imageset/image1.pdf"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("image2.imageset/Contents.json"))
        XCTAssertTrue(result[4].destination.url.absoluteString.hasSuffix("image2.imageset/image2.pdf"))
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
            static var image1: Image { Image(#function, bundle: BundleProvider.bundle) }
            static var image2: Image { Image(#function, bundle: BundleProvider.bundle) }
        }

        """
        expectNoDifference(generatedCode, referenceCode)
    }

    func testExportPairSwiftUIInSeparateBundle() throws {
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: false,
            swiftUIImageExtensionURL: swiftUIImageExtensionURL
        )
        let exporter = XcodeIconsExporter(output: output)
        let result = try exporter.export(
            icons: [
                AssetPair(light: ImagePack(image: image1), dark: ImagePack(image: image1Dark)),
                AssetPair(light: ImagePack(image: image2), dark: ImagePack(image: image2Dark)),
            ],
            append: false
        )

        XCTAssertEqual(result.count, 8)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("image1.imageset/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("image1.imageset/image1L.pdf"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("image1.imageset/image1D.pdf"))
        XCTAssertTrue(result[4].destination.url.absoluteString.hasSuffix("image2.imageset/Contents.json"))
        XCTAssertTrue(result[5].destination.url.absoluteString.hasSuffix("image2.imageset/image2L.pdf"))
        XCTAssertTrue(result[6].destination.url.absoluteString.hasSuffix("image2.imageset/image2D.pdf"))
        XCTAssertTrue(result[7].destination.url.absoluteString.hasSuffix("Image+extension.swift"))

        let content = result[7].data
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
            static var image2: Image { Image(#function, bundle: BundleProvider.bundle) }
        }

        """
        expectNoDifference(generatedCode, referenceCode)
    }

    func testAppendAfterExport() throws {
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeIconsExporter(output: output)
        let result = try exporter.export(
            icons: [AssetPair(light: ImagePack(image: image1), dark: nil)],
            append: false
        )

        XCTAssertEqual(result.count, 4)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("image1.imageset/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("image1.imageset/image1.pdf"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))

        try write(file: result[3])

        let appendResult = try exporter.export(
            icons: [AssetPair(light: ImagePack(image: image2), dark: nil)],
            append: true
        )

        XCTAssertEqual(appendResult.count, 4)
        XCTAssertTrue(appendResult[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(appendResult[1].destination.url.absoluteString.hasSuffix("image2.imageset/Contents.json"))
        XCTAssertTrue(appendResult[2].destination.url.absoluteString.hasSuffix("image2.imageset/image2.pdf"))
        XCTAssertTrue(appendResult[3].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))
        let resultContent = try XCTUnwrap(appendResult[3].data)

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

    func testAppendPairAfterExport() throws {
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeIconsExporter(output: output)
        let result = try exporter.export(
            icons: [AssetPair(light: ImagePack(image: image1), dark: ImagePack(image: image1Dark))],
            append: false
        )

        XCTAssertEqual(result.count, 5)
        XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("image1.imageset/Contents.json"))
        XCTAssertTrue(result[2].destination.url.absoluteString.hasSuffix("image1.imageset/image1L.pdf"))
        XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("image1.imageset/image1D.pdf"))
        XCTAssertTrue(result[4].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))

        try write(file: result[4])

        let appendResult = try exporter.export(
            icons: [AssetPair(light: ImagePack(image: image2), dark: ImagePack(image: image2Dark))],
            append: true
        )

        XCTAssertEqual(appendResult.count, 5)
        XCTAssertTrue(appendResult[0].destination.url.absoluteString.hasSuffix("Contents.json"))
        XCTAssertTrue(appendResult[1].destination.url.absoluteString.hasSuffix("image2.imageset/Contents.json"))
        XCTAssertTrue(appendResult[2].destination.url.absoluteString.hasSuffix("image2.imageset/image2L.pdf"))
        XCTAssertTrue(appendResult[3].destination.url.absoluteString.hasSuffix("image2.imageset/image2D.pdf"))
        XCTAssertTrue(appendResult[4].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))
        let resultContent = try XCTUnwrap(appendResult[4].data)

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

    func testExportImageWithKeyword() throws {
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeIconsExporter(output: output)
        let result = try exporter.export(
            icons: [AssetPair(light: ImagePack(image: imageWithKeyword), dark: nil)],
            append: false
        )

        let content = try XCTUnwrap(result.last?.data)

        let generatedCode = String(data: content, encoding: .utf8)
        let referenceCode = """
        \(header)

        import UIKit

        private class BundleProvider {
            static let bundle = Bundle(for: BundleProvider.self)
        }

        public extension UIImage {
            static var `class`: UIImage { UIImage(named: #function)! }
        }

        """
        expectNoDifference(generatedCode, referenceCode)
    }

    func testExport_preservesVectorRepresentation() throws {
        #if os(Linux)
            throw XCTSkip("Skipped on Linux: YYJSON uses 2-space indent, Foundation uses 4-space")
        #else
            let output = try XcodeImagesOutput(
                assetsFolderURL: XCTUnwrap(URL(string: "~/")),
                assetsInMainBundle: true,
                preservesVectorRepresentation: ["ic24TabBar*"],
                uiKitImageExtensionURL: uiKitImageExtensionURL
            )
            let exporter = XcodeIconsExporter(output: output)
            let result = try exporter.export(
                icons: [AssetPair(light: ImagePack(image: tabBarIcon), dark: nil)],
                append: false
            )

            XCTAssertEqual(result.count, 4)
            XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
            XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("ic24TabBarHome.imageset/Contents.json"))
            XCTAssertTrue(result[2].destination.url.absoluteString
                .hasSuffix("ic24TabBarHome.imageset/ic24TabBarHome.pdf"))
            XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))

            let content = result[1].data
            XCTAssertNotNil(content)

            let generatedCode = try String(data: XCTUnwrap(content), encoding: .utf8)
            // YYJSON indentationTwoSpaces format: 2-space indent, no space before colon
            let referenceCode = """
            {
              "images": [
                {
                  "filename": "ic24TabBarHome.pdf",
                  "idiom": "universal"
                }
              ],
              "info": {
                "author": "xcode",
                "version": 1
              },
              "properties": {
                "preserves-vector-representation": true,
                "template-rendering-intent": "template"
              }
            }
            """
            expectNoDifference(generatedCode, referenceCode)
        #endif
    }

    func testExport_preservesVectorRepresentation2() throws {
        #if os(Linux)
            throw XCTSkip("Skipped on Linux: YYJSON uses 2-space indent, Foundation uses 4-space")
        #else
            let output = try XcodeImagesOutput(
                assetsFolderURL: XCTUnwrap(URL(string: "~/")),
                assetsInMainBundle: true,
                preservesVectorRepresentation: ["*"],
                uiKitImageExtensionURL: uiKitImageExtensionURL
            )
            let exporter = XcodeIconsExporter(output: output)
            let result = try exporter.export(
                icons: [AssetPair(light: ImagePack(image: tabBarIcon), dark: nil)],
                append: false
            )

            XCTAssertEqual(result.count, 4)
            XCTAssertTrue(result[0].destination.url.absoluteString.hasSuffix("Contents.json"))
            XCTAssertTrue(result[1].destination.url.absoluteString.hasSuffix("ic24TabBarHome.imageset/Contents.json"))
            XCTAssertTrue(result[2].destination.url.absoluteString
                .hasSuffix("ic24TabBarHome.imageset/ic24TabBarHome.pdf"))
            XCTAssertTrue(result[3].destination.url.absoluteString.hasSuffix("UIImage+extension.swift"))

            let content = result[1].data
            XCTAssertNotNil(content)

            let generatedCode = try String(data: XCTUnwrap(content), encoding: .utf8)
            // YYJSON indentationTwoSpaces format: 2-space indent, no space before colon
            let referenceCode = """
            {
              "images": [
                {
                  "filename": "ic24TabBarHome.pdf",
                  "idiom": "universal"
                }
              ],
              "info": {
                "author": "xcode",
                "version": 1
              },
              "properties": {
                "preserves-vector-representation": true,
                "template-rendering-intent": "template"
              }
            }
            """
            expectNoDifference(generatedCode, referenceCode)
        #endif
    }

    // MARK: - Tests for allIconNames (granular cache support)

    /// Tests that when allIconNames is provided, the extension file contains all icons
    /// even when only a subset of icons is exported (simulating granular cache behavior).
    func testExportWithAllIconNames_generatesExtensionWithAllNames() throws {
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeIconsExporter(output: output)

        // Export only image1, but provide allIconNames with both image1 and image2
        let result = try exporter.export(
            icons: [AssetPair(light: ImagePack(image: image1), dark: nil)],
            allIconNames: ["image1", "image2", "image3"],
            append: false
        )

        // Should have 4 files: Contents.json, image1.imageset/Contents.json, image1.pdf, extension.swift
        XCTAssertEqual(result.count, 4)

        // Verify extension file contains all 3 icons, not just the exported one
        let extensionFile = try XCTUnwrap(result.last)
        let content = try XCTUnwrap(extensionFile.data)
        let generatedCode = String(data: content, encoding: .utf8)

        let referenceCode = """
        \(header)

        import UIKit

        private class BundleProvider {
            static let bundle = Bundle(for: BundleProvider.self)
        }

        public extension UIImage {
            static var image1: UIImage { UIImage(named: #function)! }
            static var image2: UIImage { UIImage(named: #function)! }
            static var image3: UIImage { UIImage(named: #function)! }
        }

        """
        expectNoDifference(generatedCode, referenceCode)
    }

    /// Tests that when allIconNames is nil, the extension file is derived from exported icons.
    func testExportWithoutAllIconNames_generatesExtensionFromExportedIcons() throws {
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL
        )
        let exporter = XcodeIconsExporter(output: output)

        let result = try exporter.export(
            icons: [AssetPair(light: ImagePack(image: image1), dark: nil)],
            allIconNames: nil,
            append: false
        )

        let extensionFile = try XCTUnwrap(result.last)
        let content = try XCTUnwrap(extensionFile.data)
        let generatedCode = String(data: content, encoding: .utf8)

        let referenceCode = """
        \(header)

        import UIKit

        private class BundleProvider {
            static let bundle = Bundle(for: BundleProvider.self)
        }

        public extension UIImage {
            static var image1: UIImage { UIImage(named: #function)! }
        }

        """
        expectNoDifference(generatedCode, referenceCode)
    }

    // MARK: - Tests for Code Connect generation

    /// Tests that Code Connect file is generated when codeConnectSwiftURL is configured
    /// and icons have nodeId/fileId set.
    func testExportWithCodeConnect_generatesCodeConnectFile() throws {
        let codeConnectURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("Icons.figma.swift")

        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL,
            codeConnectSwiftURL: codeConnectURL
        )
        let exporter = XcodeIconsExporter(output: output)

        // Create icons with nodeId and fileId
        var icon1 = ImagePack(image: image1)
        icon1.nodeId = "12016:2218"
        icon1.fileId = "VXmPoarVoCQSNjdlROoJLO"

        var icon2 = ImagePack(image: image2)
        icon2.nodeId = "12016:2219"
        icon2.fileId = "VXmPoarVoCQSNjdlROoJLO"

        let result = try exporter.export(
            icons: [
                AssetPair(light: icon1, dark: nil),
                AssetPair(light: icon2, dark: nil),
            ],
            append: false
        )

        // Should have 7 files: Contents.json, 2x (imageset/Contents.json + pdf), extension, codeConnect
        XCTAssertEqual(result.count, 7)

        // Find the Code Connect file
        let codeConnectFile = result.first { $0.destination.url.absoluteString.hasSuffix("Icons.figma.swift") }
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

    /// Tests that Code Connect file is NOT generated when icons don't have nodeId/fileId.
    func testExportWithCodeConnect_noNodeId_skipsCodeConnectFile() throws {
        let codeConnectURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("Icons.figma.swift")

        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL,
            codeConnectSwiftURL: codeConnectURL
        )
        let exporter = XcodeIconsExporter(output: output)

        // Icons without nodeId/fileId
        let result = try exporter.export(
            icons: [
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

    /// Tests that Code Connect file only includes icons with valid nodeId/fileId.
    func testExportWithCodeConnect_mixedIcons_onlyIncludesValidOnes() throws {
        let codeConnectURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("Icons.figma.swift")

        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            uiKitImageExtensionURL: uiKitImageExtensionURL,
            codeConnectSwiftURL: codeConnectURL
        )
        let exporter = XcodeIconsExporter(output: output)

        // Mix of icons with and without nodeId/fileId
        var iconWithNodeId = ImagePack(image: image1)
        iconWithNodeId.nodeId = "12016:2218"
        iconWithNodeId.fileId = "VXmPoarVoCQSNjdlROoJLO"

        let iconWithoutNodeId = ImagePack(image: image2) // No nodeId/fileId

        let result = try exporter.export(
            icons: [
                AssetPair(light: iconWithNodeId, dark: nil),
                AssetPair(light: iconWithoutNodeId, dark: nil),
            ],
            append: false
        )

        // Find the Code Connect file
        let codeConnectFile = result.first { $0.destination.url.absoluteString.hasSuffix("Icons.figma.swift") }
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

    /// Tests that nodeId format is correctly converted from "12016:2218" to "12016-2218" in URL.
    func testExportWithCodeConnect_nodeIdFormatConversion() throws {
        let codeConnectURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("Icons.figma.swift")

        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            codeConnectSwiftURL: codeConnectURL
        )
        let exporter = XcodeIconsExporter(output: output)

        var icon = ImagePack(image: image1)
        icon.nodeId = "999:123" // Format with colon
        icon.fileId = "ABC123"

        let result = try exporter.export(
            icons: [AssetPair(light: icon, dark: nil)],
            append: false
        )

        let codeConnectFile = result.first { $0.destination.url.absoluteString.hasSuffix("Icons.figma.swift") }
        let content = try XCTUnwrap(codeConnectFile?.data)
        let generatedCode = try XCTUnwrap(String(data: content, encoding: .utf8))

        // Verify the colon is converted to dash in the URL
        XCTAssertTrue(generatedCode.contains("node-id=999-123"))
        XCTAssertFalse(generatedCode.contains("node-id=999:123"))
    }
}

private extension XcodeIconsExporterTests {
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
