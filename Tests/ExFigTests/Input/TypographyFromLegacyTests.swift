import ExFig_Android
import ExFig_iOS
@testable import ExFigCLI
import ExFigCore
import XCTest

final class TypographyFromLegacyTests: XCTestCase {
    // MARK: - iOS Typography fromLegacy

    func testIOSEntryRegexpTakesPriorityOverCommon() {
        let entry = iOSTypographyEntry(
            nameValidateRegexp: "^entry_(.+)$",
            nameReplaceRegexp: "style_$1"
        )

        let common = makeCommonWithTypography(
            nameValidateRegexp: "^common_(.+)$",
            nameReplaceRegexp: "common_$1"
        )

        let result = iOSTypographyEntry.fromLegacy(entry, common: common)

        XCTAssertEqual(result.nameValidateRegexp, "^entry_(.+)$")
        XCTAssertEqual(result.nameReplaceRegexp, "style_$1")
    }

    func testIOSCommonRegexpUsedWhenEntryRegexpIsNil() {
        let entry = iOSTypographyEntry(
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil
        )

        let common = makeCommonWithTypography(
            nameValidateRegexp: "^common_(.+)$",
            nameReplaceRegexp: "common_$1"
        )

        let result = iOSTypographyEntry.fromLegacy(entry, common: common)

        XCTAssertEqual(result.nameValidateRegexp, "^common_(.+)$")
        XCTAssertEqual(result.nameReplaceRegexp, "common_$1")
    }

    func testIOSFromLegacyPreservesAllOtherFields() {
        let entry = iOSTypographyEntry(
            fileId: "file-123",
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil,
            nameStyle: .snakeCase,
            fontSwift: URL(string: "./Fonts.swift"),
            swiftUIFontSwift: URL(string: "./SwiftUIFonts.swift"),
            generateLabels: true,
            labelsDirectory: URL(string: "./Labels"),
            labelStyleSwift: URL(string: "./LabelStyle.swift")
        )

        let result = iOSTypographyEntry.fromLegacy(entry, common: nil)

        XCTAssertEqual(result.fileId, "file-123")
        XCTAssertEqual(result.nameStyle, .snakeCase)
        XCTAssertEqual(result.fontSwift, URL(string: "./Fonts.swift"))
        XCTAssertEqual(result.swiftUIFontSwift, URL(string: "./SwiftUIFonts.swift"))
        XCTAssertTrue(result.generateLabels)
        XCTAssertEqual(result.labelsDirectory, URL(string: "./Labels"))
        XCTAssertEqual(result.labelStyleSwift, URL(string: "./LabelStyle.swift"))
    }

    func testIOSFromLegacyWithNilCommonUsesNilRegexp() {
        let entry = iOSTypographyEntry(
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil
        )

        let result = iOSTypographyEntry.fromLegacy(entry, common: nil)

        XCTAssertNil(result.nameValidateRegexp)
        XCTAssertNil(result.nameReplaceRegexp)
    }

    // MARK: - Android Typography fromLegacy

    func testAndroidEntryRegexpTakesPriorityOverCommon() {
        let entry = AndroidTypographyEntry(
            nameValidateRegexp: "^entry_(.+)$",
            nameReplaceRegexp: "style_$1"
        )

        let common = makeCommonWithTypography(
            nameValidateRegexp: "^common_(.+)$",
            nameReplaceRegexp: "common_$1"
        )

        let result = AndroidTypographyEntry.fromLegacy(entry, common: common)

        XCTAssertEqual(result.nameValidateRegexp, "^entry_(.+)$")
        XCTAssertEqual(result.nameReplaceRegexp, "style_$1")
    }

    func testAndroidCommonRegexpUsedWhenEntryRegexpIsNil() {
        let entry = AndroidTypographyEntry(
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil
        )

        let common = makeCommonWithTypography(
            nameValidateRegexp: "^common_(.+)$",
            nameReplaceRegexp: "common_$1"
        )

        let result = AndroidTypographyEntry.fromLegacy(entry, common: common)

        XCTAssertEqual(result.nameValidateRegexp, "^common_(.+)$")
        XCTAssertEqual(result.nameReplaceRegexp, "common_$1")
    }

    func testAndroidFromLegacyPreservesAllOtherFields() {
        let entry = AndroidTypographyEntry(
            fileId: "android-file",
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil,
            nameStyle: .camelCase,
            composePackageName: "com.example.typography"
        )

        let result = AndroidTypographyEntry.fromLegacy(entry, common: nil)

        XCTAssertEqual(result.fileId, "android-file")
        XCTAssertEqual(result.nameStyle, .camelCase)
        XCTAssertEqual(result.composePackageName, "com.example.typography")
    }

    func testAndroidFromLegacyWithNilCommonUsesNilRegexp() {
        let entry = AndroidTypographyEntry(
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil
        )

        let result = AndroidTypographyEntry.fromLegacy(entry, common: nil)

        XCTAssertNil(result.nameValidateRegexp)
        XCTAssertNil(result.nameReplaceRegexp)
    }

    // MARK: - Helpers

    private func makeCommonWithTypography(
        nameValidateRegexp: String?,
        nameReplaceRegexp: String?
    ) -> PKLConfig.Common {
        var typParts: [String] = []
        if let v = nameValidateRegexp { typParts.append("\"nameValidateRegexp\": \"\(v)\"") }
        if let r = nameReplaceRegexp { typParts.append("\"nameReplaceRegexp\": \"\(r)\"") }
        let json = "{\"typography\": {\(typParts.joined(separator: ", "))}}"
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(PKLConfig.Common.self, from: Data(json.utf8))
    }
}
