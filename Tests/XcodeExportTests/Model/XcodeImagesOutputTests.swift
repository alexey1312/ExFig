import Foundation
@testable import XcodeExport
import XCTest

final class XcodeImagesOutputTests: XCTestCase {
    // MARK: - Initialization Tests

    func testInitWithRequiredParameters() {
        // swiftlint:disable:next force_unwrapping
        let assetsFolderURL = URL(string: "~/Assets.xcassets/Images")!

        let output = XcodeImagesOutput(
            assetsFolderURL: assetsFolderURL,
            assetsInMainBundle: true
        )

        XCTAssertEqual(output.assetsFolderURL, assetsFolderURL)
        XCTAssertTrue(output.assetsInMainBundle)
        XCTAssertFalse(output.assetsInSwiftPackage)
        XCTAssertNil(output.resourceBundleNames)
        XCTAssertFalse(output.addObjcAttribute)
        XCTAssertNil(output.preservesVectorRepresentation)
        XCTAssertNil(output.templatesPath)
        XCTAssertNil(output.uiKitImageExtensionURL)
        XCTAssertNil(output.swiftUIImageExtensionURL)
    }

    func testInitWithAllParameters() {
        // swiftlint:disable:next force_unwrapping
        let assetsFolderURL = URL(string: "~/Assets.xcassets/Images")!
        // swiftlint:disable:next force_unwrapping
        let uiKitURL = URL(string: "~/UIImage+extension.swift")!
        // swiftlint:disable:next force_unwrapping
        let swiftUIURL = URL(string: "~/Image+extension.swift")!
        // swiftlint:disable:next force_unwrapping
        let templatesURL = URL(string: "~/Templates")!

        let output = XcodeImagesOutput(
            assetsFolderURL: assetsFolderURL,
            assetsInMainBundle: false,
            assetsInSwiftPackage: true,
            resourceBundleNames: ["MyBundle", "OtherBundle"],
            addObjcAttribute: true,
            preservesVectorRepresentation: ["icon*", "tabBar*"],
            uiKitImageExtensionURL: uiKitURL,
            swiftUIImageExtensionURL: swiftUIURL,
            templatesPath: templatesURL
        )

        XCTAssertEqual(output.assetsFolderURL, assetsFolderURL)
        XCTAssertFalse(output.assetsInMainBundle)
        XCTAssertTrue(output.assetsInSwiftPackage)
        XCTAssertEqual(output.resourceBundleNames, ["MyBundle", "OtherBundle"])
        XCTAssertTrue(output.addObjcAttribute)
        XCTAssertEqual(output.preservesVectorRepresentation, ["icon*", "tabBar*"])
        XCTAssertEqual(output.uiKitImageExtensionURL, uiKitURL)
        XCTAssertEqual(output.swiftUIImageExtensionURL, swiftUIURL)
        XCTAssertEqual(output.templatesPath, templatesURL)
    }

    // MARK: - Default Values Tests

    func testDefaultAssetsInSwiftPackage() {
        // swiftlint:disable:next force_unwrapping
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: true,
            assetsInSwiftPackage: nil
        )

        XCTAssertFalse(output.assetsInSwiftPackage)
    }

    func testDefaultAddObjcAttribute() {
        // swiftlint:disable:next force_unwrapping
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: true,
            addObjcAttribute: nil
        )

        XCTAssertFalse(output.addObjcAttribute)
    }

    // MARK: - Bundle Configuration Tests

    func testMainBundleConfiguration() {
        // swiftlint:disable:next force_unwrapping
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: true,
            assetsInSwiftPackage: false
        )

        XCTAssertTrue(output.assetsInMainBundle)
        XCTAssertFalse(output.assetsInSwiftPackage)
    }

    func testSwiftPackageBundleConfiguration() {
        // swiftlint:disable:next force_unwrapping
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: false,
            assetsInSwiftPackage: true
        )

        XCTAssertFalse(output.assetsInMainBundle)
        XCTAssertTrue(output.assetsInSwiftPackage)
    }

    func testSeparateBundleConfiguration() {
        // swiftlint:disable:next force_unwrapping
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: false,
            assetsInSwiftPackage: false
        )

        XCTAssertFalse(output.assetsInMainBundle)
        XCTAssertFalse(output.assetsInSwiftPackage)
    }

    // MARK: - Resource Bundle Names Tests

    func testEmptyResourceBundleNames() {
        // swiftlint:disable:next force_unwrapping
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: true,
            resourceBundleNames: []
        )

        XCTAssertNotNil(output.resourceBundleNames)
        XCTAssertTrue(output.resourceBundleNames?.isEmpty ?? false)
    }

    func testMultipleResourceBundleNames() {
        // swiftlint:disable:next force_unwrapping
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: false,
            resourceBundleNames: ["Bundle1", "Bundle2", "Bundle3"]
        )

        XCTAssertEqual(output.resourceBundleNames?.count, 3)
    }

    // MARK: - Preserves Vector Representation Tests

    func testPreservesVectorRepresentationPatterns() {
        // swiftlint:disable:next force_unwrapping
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: true,
            preservesVectorRepresentation: ["ic24*", "tabBar*", "navBar*"]
        )

        XCTAssertEqual(output.preservesVectorRepresentation?.count, 3)
        XCTAssertTrue(output.preservesVectorRepresentation?.contains("ic24*") ?? false)
    }

    func testPreservesVectorRepresentationWildcard() {
        // swiftlint:disable:next force_unwrapping
        let output = XcodeImagesOutput(
            assetsFolderURL: URL(string: "~/")!,
            assetsInMainBundle: true,
            preservesVectorRepresentation: ["*"]
        )

        XCTAssertEqual(output.preservesVectorRepresentation, ["*"])
    }
}
