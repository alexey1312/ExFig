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

    // MARK: - ColorsSourceInput Validation

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
}
