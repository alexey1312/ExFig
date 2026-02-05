import Foundation
@testable import XcodeExport
import XCTest

final class XcodeImagesOutputTests: XCTestCase {
    // MARK: - Initialization Tests

    func testInitWithRequiredParameters() throws {
        // swiftlint:disable:next force_unwrapping
        let assetsFolderURL = try XCTUnwrap(URL(string: "~/Assets.xcassets/Images"))

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

    func testInitWithAllParameters() throws {
        // swiftlint:disable:next force_unwrapping
        let assetsFolderURL = try XCTUnwrap(URL(string: "~/Assets.xcassets/Images"))
        // swiftlint:disable:next force_unwrapping
        let uiKitURL = try XCTUnwrap(URL(string: "~/UIImage+extension.swift"))
        // swiftlint:disable:next force_unwrapping
        let swiftUIURL = try XCTUnwrap(URL(string: "~/Image+extension.swift"))
        // swiftlint:disable:next force_unwrapping
        let templatesURL = try XCTUnwrap(URL(string: "~/Templates"))

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

    func testDefaultAssetsInSwiftPackage() throws {
        // swiftlint:disable:next force_unwrapping
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            assetsInSwiftPackage: nil
        )

        XCTAssertFalse(output.assetsInSwiftPackage)
    }

    func testDefaultAddObjcAttribute() throws {
        // swiftlint:disable:next force_unwrapping
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            addObjcAttribute: nil
        )

        XCTAssertFalse(output.addObjcAttribute)
    }

    // MARK: - Bundle Configuration Tests

    func testMainBundleConfiguration() throws {
        // swiftlint:disable:next force_unwrapping
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            assetsInSwiftPackage: false
        )

        XCTAssertTrue(output.assetsInMainBundle)
        XCTAssertFalse(output.assetsInSwiftPackage)
    }

    func testSwiftPackageBundleConfiguration() throws {
        // swiftlint:disable:next force_unwrapping
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: false,
            assetsInSwiftPackage: true
        )

        XCTAssertFalse(output.assetsInMainBundle)
        XCTAssertTrue(output.assetsInSwiftPackage)
    }

    func testSeparateBundleConfiguration() throws {
        // swiftlint:disable:next force_unwrapping
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: false,
            assetsInSwiftPackage: false
        )

        XCTAssertFalse(output.assetsInMainBundle)
        XCTAssertFalse(output.assetsInSwiftPackage)
    }

    // MARK: - Resource Bundle Names Tests

    func testEmptyResourceBundleNames() throws {
        // swiftlint:disable:next force_unwrapping
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            resourceBundleNames: []
        )

        XCTAssertNotNil(output.resourceBundleNames)
        XCTAssertTrue(output.resourceBundleNames?.isEmpty ?? false)
    }

    func testMultipleResourceBundleNames() throws {
        // swiftlint:disable:next force_unwrapping
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: false,
            resourceBundleNames: ["Bundle1", "Bundle2", "Bundle3"]
        )

        XCTAssertEqual(output.resourceBundleNames?.count, 3)
    }

    // MARK: - Preserves Vector Representation Tests

    func testPreservesVectorRepresentationPatterns() throws {
        // swiftlint:disable:next force_unwrapping
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            preservesVectorRepresentation: ["ic24*", "tabBar*", "navBar*"]
        )

        XCTAssertEqual(output.preservesVectorRepresentation?.count, 3)
        XCTAssertTrue(output.preservesVectorRepresentation?.contains("ic24*") ?? false)
    }

    func testPreservesVectorRepresentationWildcard() throws {
        // swiftlint:disable:next force_unwrapping
        let output = try XcodeImagesOutput(
            assetsFolderURL: XCTUnwrap(URL(string: "~/")),
            assetsInMainBundle: true,
            preservesVectorRepresentation: ["*"]
        )

        XCTAssertEqual(output.preservesVectorRepresentation, ["*"])
    }
}
