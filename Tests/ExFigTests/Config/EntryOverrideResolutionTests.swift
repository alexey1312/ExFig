// swiftlint:disable type_name

import ExFig_Android
import ExFig_Flutter
import ExFig_iOS
import ExFig_Web
import ExFigCore
import Foundation
import XCTest

// MARK: - iOS Entry Override Resolution

final class iOSEntryOverrideResolutionTests: XCTestCase {
    // MARK: - xcassetsPath

    func testIconsEntry_xcassetsPathOverride_resolvesEntryValue() throws {
        let entry = try makeIOSIconsEntry(xcassetsPath: "/custom/path.xcassets")
        let fallback = URL(fileURLWithPath: "/default/path.xcassets")

        let resolved = entry.resolvedXcassetsPath(fallback: fallback)

        XCTAssertEqual(resolved?.path, "/custom/path.xcassets")
    }

    func testIconsEntry_xcassetsPathNil_fallsBackToConfig() throws {
        let entry = try makeIOSIconsEntry()
        let fallback = URL(fileURLWithPath: "/default/path.xcassets")

        let resolved = entry.resolvedXcassetsPath(fallback: fallback)

        XCTAssertEqual(resolved, fallback)
    }

    func testImagesEntry_xcassetsPathOverride_resolvesEntryValue() throws {
        let entry = try makeIOSImagesEntry(xcassetsPath: "/images/custom.xcassets")
        let fallback = URL(fileURLWithPath: "/default/images.xcassets")

        let resolved = entry.resolvedXcassetsPath(fallback: fallback)

        XCTAssertEqual(resolved?.path, "/images/custom.xcassets")
    }

    func testImagesEntry_xcassetsPathNil_fallsBackToConfig() throws {
        let entry = try makeIOSImagesEntry()
        let fallback = URL(fileURLWithPath: "/default/images.xcassets")

        let resolved = entry.resolvedXcassetsPath(fallback: fallback)

        XCTAssertEqual(resolved, fallback)
    }

    // MARK: - templatesPath

    func testIconsEntry_templatesPathOverride_resolvesEntryValue() throws {
        let entry = try makeIOSIconsEntry(templatesPath: "/custom/templates")
        let fallback = URL(fileURLWithPath: "/default/templates")

        let resolved = entry.resolvedTemplatesPath(fallback: fallback)

        XCTAssertEqual(resolved?.path, "/custom/templates")
    }

    func testIconsEntry_templatesPathNil_fallsBackToConfig() throws {
        let entry = try makeIOSIconsEntry()
        let fallback = URL(fileURLWithPath: "/default/templates")

        let resolved = entry.resolvedTemplatesPath(fallback: fallback)

        XCTAssertEqual(resolved, fallback)
    }

    // MARK: - figmaFileId

    func testIconsEntry_figmaFileIdOverride_resolvesEntryValue() throws {
        let entry = try makeIOSIconsEntry(figmaFileId: "entry-file-id")

        let resolved = entry.resolvedFigmaFileId(fallback: "global-file-id")

        XCTAssertEqual(resolved, "entry-file-id")
    }

    func testIconsEntry_figmaFileIdNil_fallsBackToGlobal() throws {
        let entry = try makeIOSIconsEntry()

        let resolved = entry.resolvedFigmaFileId(fallback: "global-file-id")

        XCTAssertEqual(resolved, "global-file-id")
    }

    func testImagesEntry_figmaFileIdOverride_resolvesEntryValue() throws {
        let entry = try makeIOSImagesEntry(figmaFileId: "entry-images-id")

        let resolved = entry.resolvedFigmaFileId(fallback: "global-id")

        XCTAssertEqual(resolved, "entry-images-id")
    }

    // MARK: - Helpers

    private func makeIOSIconsEntry(
        xcassetsPath: String? = nil,
        templatesPath: String? = nil,
        figmaFileId: String? = nil
    ) throws -> iOSIconsEntry {
        var fields = [String]()
        fields.append("\"format\": \"svg\"")
        fields.append("\"assetsFolder\": \"Icons\"")
        fields.append("\"nameStyle\": \"camelCase\"")
        if let xcassetsPath { fields.append("\"xcassetsPath\": \"\(xcassetsPath)\"") }
        if let templatesPath { fields.append("\"templatesPath\": \"\(templatesPath)\"") }
        if let figmaFileId { fields.append("\"figmaFileId\": \"\(figmaFileId)\"") }
        let json = "{ \(fields.joined(separator: ", ")) }"
        return try JSONDecoder().decode(iOSIconsEntry.self, from: Data(json.utf8))
    }

    private func makeIOSImagesEntry(
        xcassetsPath: String? = nil,
        figmaFileId: String? = nil
    ) throws -> iOSImagesEntry {
        var fields = [String]()
        fields.append("\"nameStyle\": \"camelCase\"")
        fields.append("\"assetsFolder\": \"Images\"")
        if let xcassetsPath { fields.append("\"xcassetsPath\": \"\(xcassetsPath)\"") }
        if let figmaFileId { fields.append("\"figmaFileId\": \"\(figmaFileId)\"") }
        let json = "{ \(fields.joined(separator: ", ")) }"
        return try JSONDecoder().decode(iOSImagesEntry.self, from: Data(json.utf8))
    }
}

// MARK: - Android Entry Override Resolution

final class AndroidEntryOverrideResolutionTests: XCTestCase {
    func testIconsEntry_mainResOverride_resolvesEntryValue() throws {
        let entry = try makeAndroidIconsEntry(mainRes: "/custom/res")
        let fallback = URL(fileURLWithPath: "/default/res")

        let resolved = entry.resolvedMainRes(fallback: fallback)

        XCTAssertEqual(resolved.path, "/custom/res")
    }

    func testIconsEntry_mainResNil_fallsBackToConfig() throws {
        let entry = try makeAndroidIconsEntry()
        let fallback = URL(fileURLWithPath: "/default/res")

        let resolved = entry.resolvedMainRes(fallback: fallback)

        XCTAssertEqual(resolved, fallback)
    }

    func testImagesEntry_mainResOverride_resolvesEntryValue() throws {
        let entry = try makeAndroidImagesEntry(mainRes: "/images/res")
        let fallback = URL(fileURLWithPath: "/default/res")

        let resolved = entry.resolvedMainRes(fallback: fallback)

        XCTAssertEqual(resolved.path, "/images/res")
    }

    func testImagesEntry_figmaFileIdOverride_resolvesEntryValue() throws {
        let entry = try makeAndroidImagesEntry(figmaFileId: "android-entry-id")

        let resolved = entry.resolvedFigmaFileId(fallback: "global-id")

        XCTAssertEqual(resolved, "android-entry-id")
    }

    func testImagesEntry_figmaFileIdNil_fallsBackToGlobal() throws {
        let entry = try makeAndroidImagesEntry()

        let resolved = entry.resolvedFigmaFileId(fallback: "global-id")

        XCTAssertEqual(resolved, "global-id")
    }

    // MARK: - Helpers

    private func makeAndroidIconsEntry(mainRes: String? = nil) throws -> AndroidIconsEntry {
        var fields = [String]()
        fields.append("\"output\": \"drawable\"")
        if let mainRes { fields.append("\"mainRes\": \"\(mainRes)\"") }
        let json = "{ \(fields.joined(separator: ", ")) }"
        return try JSONDecoder().decode(AndroidIconsEntry.self, from: Data(json.utf8))
    }

    private func makeAndroidImagesEntry(
        mainRes: String? = nil,
        figmaFileId: String? = nil
    ) throws -> AndroidImagesEntry {
        var fields = [String]()
        fields.append("\"format\": \"png\"")
        fields.append("\"output\": \"drawable\"")
        if let mainRes { fields.append("\"mainRes\": \"\(mainRes)\"") }
        if let figmaFileId { fields.append("\"figmaFileId\": \"\(figmaFileId)\"") }
        let json = "{ \(fields.joined(separator: ", ")) }"
        return try JSONDecoder().decode(AndroidImagesEntry.self, from: Data(json.utf8))
    }
}

// MARK: - Flutter Entry Override Resolution

final class FlutterEntryOverrideResolutionTests: XCTestCase {
    func testIconsEntry_templatesPathOverride_resolvesEntryValue() throws {
        let entry = try makeFlutterIconsEntry(templatesPath: "/custom/templates")
        let fallback = URL(fileURLWithPath: "/default/templates")

        let resolved = entry.resolvedTemplatesPath(fallback: fallback)

        XCTAssertEqual(resolved?.path, "/custom/templates")
    }

    func testIconsEntry_templatesPathNil_fallsBackToConfig() throws {
        let entry = try makeFlutterIconsEntry()
        let fallback = URL(fileURLWithPath: "/default/templates")

        let resolved = entry.resolvedTemplatesPath(fallback: fallback)

        XCTAssertEqual(resolved, fallback)
    }

    func testIconsEntry_figmaFileIdOverride_resolvesEntryValue() throws {
        let entry = try makeFlutterIconsEntry(figmaFileId: "flutter-entry-id")

        let resolved = entry.resolvedFigmaFileId(fallback: "global-id")

        XCTAssertEqual(resolved, "flutter-entry-id")
    }

    // MARK: - Helpers

    private func makeFlutterIconsEntry(
        templatesPath: String? = nil,
        figmaFileId: String? = nil
    ) throws -> FlutterIconsEntry {
        var fields = [String]()
        fields.append("\"output\": \"assets/icons\"")
        if let templatesPath { fields.append("\"templatesPath\": \"\(templatesPath)\"") }
        if let figmaFileId { fields.append("\"figmaFileId\": \"\(figmaFileId)\"") }
        let json = "{ \(fields.joined(separator: ", ")) }"
        return try JSONDecoder().decode(FlutterIconsEntry.self, from: Data(json.utf8))
    }
}

// MARK: - Web Entry Override Resolution

final class WebEntryOverrideResolutionTests: XCTestCase {
    func testIconsEntry_templatesPathOverride_resolvesEntryValue() throws {
        let entry = try makeWebIconsEntry(templatesPath: "/custom/templates")
        let fallback = URL(fileURLWithPath: "/default/templates")

        let resolved = entry.resolvedTemplatesPath(fallback: fallback)

        XCTAssertEqual(resolved?.path, "/custom/templates")
    }

    func testIconsEntry_templatesPathNil_fallsBackToConfig() throws {
        let entry = try makeWebIconsEntry()
        let fallback = URL(fileURLWithPath: "/default/templates")

        let resolved = entry.resolvedTemplatesPath(fallback: fallback)

        XCTAssertEqual(resolved, fallback)
    }

    func testImagesEntry_figmaFileIdOverride_resolvesEntryValue() throws {
        let entry = try makeWebImagesEntry(figmaFileId: "web-entry-id")

        let resolved = entry.resolvedFigmaFileId(fallback: "global-id")

        XCTAssertEqual(resolved, "web-entry-id")
    }

    func testImagesEntry_figmaFileIdNil_fallsBackToGlobal() throws {
        let entry = try makeWebImagesEntry()

        let resolved = entry.resolvedFigmaFileId(fallback: "global-id")

        XCTAssertEqual(resolved, "global-id")
    }

    // MARK: - Helpers

    private func makeWebIconsEntry(templatesPath: String? = nil) throws -> WebIconsEntry {
        var fields = [String]()
        fields.append("\"outputDirectory\": \"dist/icons\"")
        if let templatesPath { fields.append("\"templatesPath\": \"\(templatesPath)\"") }
        let json = "{ \(fields.joined(separator: ", ")) }"
        return try JSONDecoder().decode(WebIconsEntry.self, from: Data(json.utf8))
    }

    private func makeWebImagesEntry(figmaFileId: String? = nil) throws -> WebImagesEntry {
        var fields = [String]()
        fields.append("\"outputDirectory\": \"dist/images\"")
        if let figmaFileId { fields.append("\"figmaFileId\": \"\(figmaFileId)\"") }
        let json = "{ \(fields.joined(separator: ", ")) }"
        return try JSONDecoder().decode(WebImagesEntry.self, from: Data(json.utf8))
    }
}

// swiftlint:enable type_name
