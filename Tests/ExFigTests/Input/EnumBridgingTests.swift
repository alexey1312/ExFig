// swiftlint:disable file_length type_body_length

import ExFig_Android
import ExFig_iOS
import ExFigConfig
import ExFigCore
import XCTest

final class EnumBridgingTests: XCTestCase {
    // MARK: - NameStyle Bridging

    func testAllPKLNameStyleCasesBridgeToExFigCore() {
        // Every Common.NameStyle case must map to a non-nil ExFigCore.NameStyle.
        // This ensures no cases are silently dropped during bridging.
        for pklCase in Common.NameStyle.allCases {
            XCTAssertNotNil(
                NameStyle(rawValue: pklCase.rawValue),
                "Common.NameStyle.\(pklCase) has no ExFigCore.NameStyle mapping (rawValue: \(pklCase.rawValue))"
            )
        }
    }

    func testAllExFigCoreNameStyleCasesHavePKLEquivalent() {
        // Every ExFigCore.NameStyle case must have a matching Common.NameStyle.
        for coreCase in NameStyle.allCases {
            XCTAssertNotNil(
                Common.NameStyle(rawValue: coreCase.rawValue),
                "ExFigCore.NameStyle.\(coreCase) has no Common.NameStyle mapping (rawValue: \(coreCase.rawValue))"
            )
        }
    }

    func testNameStyleCaseCount() {
        // Both enums must have the same number of cases.
        XCTAssertEqual(
            Common.NameStyle.allCases.count,
            NameStyle.allCases.count,
            "Common.NameStyle and ExFigCore.NameStyle have different case counts"
        )
    }

    // MARK: - iOS coreNameStyle Switch Exhaustiveness

    func testiOSColorsEntryCoreNameStyleMapsAllCases() {
        // Verify the switch-based bridging in iOSColorsEntry covers all cases correctly.
        let expectations: [(Common.NameStyle, NameStyle)] = [
            (.camelCase, .camelCase),
            (.snake_case, .snakeCase),
            (.pascalCase, .pascalCase),
            (.flatCase, .flatCase),
            (.kebab_case, .kebabCase),
            (.sCREAMING_SNAKE_CASE, .screamingSnakeCase),
        ]

        for (pklStyle, expectedCore) in expectations {
            let entry = iOS.ColorsEntry(
                useColorAssets: false,
                assetsFolder: nil,
                nameStyle: pklStyle,
                groupUsingNamespace: nil,
                colorSwift: nil,
                swiftuiColorSwift: nil,
                syncCodeSyntax: nil,
                codeSyntaxTemplate: nil,
                tokensFileId: nil,
                tokensCollectionName: nil,
                lightModeName: nil,
                darkModeName: nil,
                lightHCModeName: nil,
                darkHCModeName: nil,
                primitivesModeName: nil,
                nameValidateRegexp: nil,
                nameReplaceRegexp: nil
            )
            XCTAssertEqual(
                entry.coreNameStyle, expectedCore,
                "iOS.ColorsEntry with nameStyle=\(pklStyle) should bridge to \(expectedCore)"
            )
        }
    }

    // MARK: - iOS IconsEntry coreNameStyle

    func testiOSIconsEntryCoreNameStyleMapsAllCases() {
        let expectations: [(Common.NameStyle, NameStyle)] = [
            (.camelCase, .camelCase),
            (.snake_case, .snakeCase),
            (.pascalCase, .pascalCase),
            (.flatCase, .flatCase),
            (.kebab_case, .kebabCase),
            (.sCREAMING_SNAKE_CASE, .screamingSnakeCase),
        ]

        for (pklStyle, expectedCore) in expectations {
            let entry = iOS.IconsEntry(
                format: .svg,
                assetsFolder: "Icons",
                preservesVectorRepresentation: nil,
                nameStyle: pklStyle,
                imageSwift: nil,
                swiftUIImageSwift: nil,
                codeConnectSwift: nil,
                renderMode: nil,
                renderModeDefaultSuffix: nil,
                renderModeOriginalSuffix: nil,
                renderModeTemplateSuffix: nil,
                figmaFrameName: nil,
                nameValidateRegexp: nil,
                nameReplaceRegexp: nil
            )
            XCTAssertEqual(
                entry.coreNameStyle, expectedCore,
                "iOS.IconsEntry with nameStyle=\(pklStyle) should bridge to \(expectedCore)"
            )
        }
    }

    // MARK: - iOS ImagesEntry coreNameStyle

    func testiOSImagesEntryCoreNameStyleMapsAllCases() {
        let expectations: [(Common.NameStyle, NameStyle)] = [
            (.camelCase, .camelCase),
            (.snake_case, .snakeCase),
            (.pascalCase, .pascalCase),
            (.flatCase, .flatCase),
            (.kebab_case, .kebabCase),
            (.sCREAMING_SNAKE_CASE, .screamingSnakeCase),
        ]

        for (pklStyle, expectedCore) in expectations {
            let entry = iOS.ImagesEntry(
                assetsFolder: "Images",
                nameStyle: pklStyle,
                scales: nil,
                imageSwift: nil,
                swiftUIImageSwift: nil,
                codeConnectSwift: nil,
                sourceFormat: nil,
                outputFormat: nil,
                heicOptions: nil,
                renderMode: nil,
                renderModeDefaultSuffix: nil,
                renderModeOriginalSuffix: nil,
                renderModeTemplateSuffix: nil,
                figmaFrameName: nil,
                nameValidateRegexp: nil,
                nameReplaceRegexp: nil
            )
            XCTAssertEqual(
                entry.coreNameStyle, expectedCore,
                "iOS.ImagesEntry with nameStyle=\(pklStyle) should bridge to \(expectedCore)"
            )
        }
    }

    // MARK: - Android IconsEntry effectiveNameStyle

    func testAndroidIconsEntryEffectiveNameStyleMapsAllCases() {
        let expectations: [(Common.NameStyle, NameStyle)] = [
            (.camelCase, .camelCase),
            (.snake_case, .snakeCase),
            (.pascalCase, .pascalCase),
            (.flatCase, .flatCase),
            (.kebab_case, .kebabCase),
            (.sCREAMING_SNAKE_CASE, .screamingSnakeCase),
        ]

        for (pklStyle, expectedCore) in expectations {
            let entry = Android.IconsEntry(
                output: "icons",
                composePackageName: nil,
                composeFormat: nil,
                composeExtensionTarget: nil,
                nameStyle: pklStyle,
                pathPrecision: nil,
                strictPathValidation: nil,
                figmaFrameName: nil,
                nameValidateRegexp: nil,
                nameReplaceRegexp: nil
            )
            XCTAssertEqual(
                entry.effectiveNameStyle, expectedCore,
                "Android.IconsEntry with nameStyle=\(pklStyle) should bridge to \(expectedCore)"
            )
        }
    }

    func testAndroidIconsEntryEffectiveNameStyleDefaultsToSnakeCase() {
        let entry = Android.IconsEntry(
            output: "icons",
            composePackageName: nil,
            composeFormat: nil,
            composeExtensionTarget: nil,
            nameStyle: nil,
            pathPrecision: nil,
            strictPathValidation: nil,
            figmaFrameName: nil,
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil
        )
        XCTAssertEqual(entry.effectiveNameStyle, .snakeCase)
    }

    // MARK: - Android ImagesEntry effectiveNameStyle

    func testAndroidImagesEntryEffectiveNameStyleMapsAllCases() {
        let expectations: [(Common.NameStyle, NameStyle)] = [
            (.camelCase, .camelCase),
            (.snake_case, .snakeCase),
            (.pascalCase, .pascalCase),
            (.flatCase, .flatCase),
            (.kebab_case, .kebabCase),
            (.sCREAMING_SNAKE_CASE, .screamingSnakeCase),
        ]

        for (pklStyle, expectedCore) in expectations {
            let entry = Android.ImagesEntry(
                scales: nil,
                output: "images",
                format: .png,
                webpOptions: nil,
                sourceFormat: nil,
                nameStyle: pklStyle,
                figmaFrameName: nil,
                nameValidateRegexp: nil,
                nameReplaceRegexp: nil
            )
            XCTAssertEqual(
                entry.effectiveNameStyle, expectedCore,
                "Android.ImagesEntry with nameStyle=\(pklStyle) should bridge to \(expectedCore)"
            )
        }
    }

    func testAndroidImagesEntryEffectiveNameStyleDefaultsToSnakeCase() {
        let entry = Android.ImagesEntry(
            scales: nil,
            output: "images",
            format: .png,
            webpOptions: nil,
            sourceFormat: nil,
            nameStyle: nil,
            figmaFrameName: nil,
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil
        )
        XCTAssertEqual(entry.effectiveNameStyle, .snakeCase)
    }

    // MARK: - Android NameTransform resolvedStyle

    func testAndroidNameTransformResolvedStyleMapsAllCases() {
        let expectations: [(Common.NameStyle, NameStyle)] = [
            (.camelCase, .camelCase),
            (.snake_case, .snakeCase),
            (.pascalCase, .pascalCase),
            (.flatCase, .flatCase),
            (.kebab_case, .kebabCase),
            (.sCREAMING_SNAKE_CASE, .screamingSnakeCase),
        ]

        for (pklStyle, expectedCore) in expectations {
            let transform = Android.NameTransform(
                style: pklStyle,
                prefix: nil,
                stripPrefixes: nil
            )
            XCTAssertEqual(
                transform.resolvedStyle, expectedCore,
                "Android.NameTransform with style=\(pklStyle) should resolve to \(expectedCore)"
            )
        }
    }

    func testAndroidNameTransformResolvedStyleDefaultsToPascalCase() {
        let transform = Android.NameTransform(
            style: nil,
            prefix: nil,
            stripPrefixes: nil
        )
        XCTAssertEqual(transform.resolvedStyle, .pascalCase)
    }

    // MARK: - iOS XcodeRenderMode Bridging

    func testiOSIconsEntryCoreRenderModeBridgesAllCases() {
        for pklCase in iOS.XcodeRenderMode.allCases {
            let entry = iOS.IconsEntry(
                format: .svg,
                assetsFolder: "Icons",
                preservesVectorRepresentation: nil,
                nameStyle: .camelCase,
                imageSwift: nil,
                swiftUIImageSwift: nil,
                codeConnectSwift: nil,
                renderMode: pklCase,
                renderModeDefaultSuffix: nil,
                renderModeOriginalSuffix: nil,
                renderModeTemplateSuffix: nil,
                figmaFrameName: nil,
                nameValidateRegexp: nil,
                nameReplaceRegexp: nil
            )
            XCTAssertNotNil(
                entry.coreRenderMode,
                "iOS.IconsEntry with renderMode=\(pklCase) should bridge to non-nil XcodeRenderMode"
            )
        }
    }

    func testiOSImagesEntryCoreRenderModeBridgesAllCases() {
        for pklCase in iOS.XcodeRenderMode.allCases {
            let entry = iOS.ImagesEntry(
                assetsFolder: "Images",
                nameStyle: .camelCase,
                scales: nil,
                imageSwift: nil,
                swiftUIImageSwift: nil,
                codeConnectSwift: nil,
                sourceFormat: nil,
                outputFormat: nil,
                heicOptions: nil,
                renderMode: pklCase,
                renderModeDefaultSuffix: nil,
                renderModeOriginalSuffix: nil,
                renderModeTemplateSuffix: nil,
                figmaFrameName: nil,
                nameValidateRegexp: nil,
                nameReplaceRegexp: nil
            )
            XCTAssertNotNil(
                entry.coreRenderMode,
                "iOS.ImagesEntry with renderMode=\(pklCase) should bridge to non-nil XcodeRenderMode"
            )
        }
    }

    // MARK: - VectorFormat Bridging

    func testVectorFormatBridgesAllCases() {
        for pklCase in Common.VectorFormat.allCases {
            XCTAssertNotNil(
                VectorFormat(rawValue: pklCase.rawValue),
                "Common.VectorFormat.\(pklCase) has no ExFigCore.VectorFormat mapping"
            )
        }
    }

    // MARK: - ImageSourceFormat Bridging

    func testImageSourceFormatBridgesAllCases() {
        for pklCase in Common.SourceFormat.allCases {
            XCTAssertNotNil(
                ImageSourceFormat(rawValue: pklCase.rawValue),
                "Common.SourceFormat.\(pklCase) has no ExFigCore.ImageSourceFormat mapping"
            )
        }
    }

    // MARK: - HEIC Encoding Bridging

    func testHeicEncodingBridgesAllCases() {
        for pklCase in iOS.HeicEncoding.allCases {
            XCTAssertNotNil(
                HeicConverterOptions.Encoding(rawValue: pklCase.rawValue),
                "iOS.HeicEncoding.\(pklCase) has no HeicConverterOptions.Encoding mapping"
            )
        }
    }

    // MARK: - iOS ColorsSourceInput Validation

    func testValidatedColorsSourceInputThrowsOnMissingTokensFileId() {
        let entry = iOS.ColorsEntry(
            useColorAssets: false,
            assetsFolder: nil,
            nameStyle: .camelCase,
            groupUsingNamespace: nil,
            colorSwift: nil,
            swiftuiColorSwift: nil,
            syncCodeSyntax: nil,
            codeSyntaxTemplate: nil,
            tokensFileId: nil,
            tokensCollectionName: "Collection",
            lightModeName: "Light",
            darkModeName: nil,
            lightHCModeName: nil,
            darkHCModeName: nil,
            primitivesModeName: nil,
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil
        )
        XCTAssertThrowsError(try entry.validatedColorsSourceInput()) { error in
            XCTAssert(error is ColorsConfigError)
        }
    }

    func testValidatedColorsSourceInputThrowsOnEmptyTokensFileId() {
        let entry = iOS.ColorsEntry(
            useColorAssets: false,
            assetsFolder: nil,
            nameStyle: .camelCase,
            groupUsingNamespace: nil,
            colorSwift: nil,
            swiftuiColorSwift: nil,
            syncCodeSyntax: nil,
            codeSyntaxTemplate: nil,
            tokensFileId: "",
            tokensCollectionName: "Collection",
            lightModeName: "Light",
            darkModeName: nil,
            lightHCModeName: nil,
            darkHCModeName: nil,
            primitivesModeName: nil,
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil
        )
        XCTAssertThrowsError(try entry.validatedColorsSourceInput()) { error in
            XCTAssert(error is ColorsConfigError)
        }
    }

    func testValidatedColorsSourceInputSucceedsWithAllRequiredFields() throws {
        let entry = iOS.ColorsEntry(
            useColorAssets: false,
            assetsFolder: nil,
            nameStyle: .camelCase,
            groupUsingNamespace: nil,
            colorSwift: nil,
            swiftuiColorSwift: nil,
            syncCodeSyntax: nil,
            codeSyntaxTemplate: nil,
            tokensFileId: "file123",
            tokensCollectionName: "Collection",
            lightModeName: "Light",
            darkModeName: "Dark",
            lightHCModeName: nil,
            darkHCModeName: nil,
            primitivesModeName: nil,
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil
        )
        let sourceInput = try entry.validatedColorsSourceInput()
        XCTAssertEqual(sourceInput.tokensFileId, "file123")
        XCTAssertEqual(sourceInput.tokensCollectionName, "Collection")
        XCTAssertEqual(sourceInput.lightModeName, "Light")
        XCTAssertEqual(sourceInput.darkModeName, "Dark")
    }

    // MARK: - Android ColorsSourceInput Validation

    func testAndroidColorsEntryThrowsOnMissingTokensFileId() {
        let entry = Android.ColorsEntry(
            xmlOutputFileName: nil,
            xmlDisabled: nil,
            composePackageName: nil,
            colorKotlin: nil,
            themeAttributes: nil,
            tokensFileId: nil,
            tokensCollectionName: "Collection",
            lightModeName: "Light",
            darkModeName: nil,
            lightHCModeName: nil,
            darkHCModeName: nil,
            primitivesModeName: nil,
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil
        )
        XCTAssertThrowsError(try entry.validatedColorsSourceInput()) { error in
            XCTAssert(error is ColorsConfigError)
        }
    }

    func testAndroidColorsEntryThrowsOnEmptyTokensFileId() {
        let entry = Android.ColorsEntry(
            xmlOutputFileName: nil,
            xmlDisabled: nil,
            composePackageName: nil,
            colorKotlin: nil,
            themeAttributes: nil,
            tokensFileId: "",
            tokensCollectionName: "Collection",
            lightModeName: "Light",
            darkModeName: nil,
            lightHCModeName: nil,
            darkHCModeName: nil,
            primitivesModeName: nil,
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil
        )
        XCTAssertThrowsError(try entry.validatedColorsSourceInput()) { error in
            XCTAssert(error is ColorsConfigError)
        }
    }

    func testAndroidColorsEntryValidatesSuccessfully() throws {
        let entry = Android.ColorsEntry(
            xmlOutputFileName: nil,
            xmlDisabled: nil,
            composePackageName: nil,
            colorKotlin: nil,
            themeAttributes: nil,
            tokensFileId: "file456",
            tokensCollectionName: "Colors",
            lightModeName: "Light",
            darkModeName: "Dark",
            lightHCModeName: nil,
            darkHCModeName: nil,
            primitivesModeName: nil,
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil
        )
        let sourceInput = try entry.validatedColorsSourceInput()
        XCTAssertEqual(sourceInput.tokensFileId, "file456")
        XCTAssertEqual(sourceInput.tokensCollectionName, "Colors")
        XCTAssertEqual(sourceInput.lightModeName, "Light")
        XCTAssertEqual(sourceInput.darkModeName, "Dark")
    }
}
