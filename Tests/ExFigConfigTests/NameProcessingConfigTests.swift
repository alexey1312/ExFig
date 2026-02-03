import Foundation
import Testing

@testable import ExFigConfig

/// Tests for NameProcessingConfig — regexp validation and replacement.
@Suite("NameProcessingConfig Tests")
struct NameProcessingConfigTests {
    // MARK: - Validation Regexp

    @Test("Validates name against regexp - matches")
    func validatesNameMatches() throws {
        let config = NameProcessingConfig(
            nameValidateRegexp: "^icon_",
            nameReplaceRegexp: nil
        )

        #expect(config.validates(name: "icon_home"))
        #expect(config.validates(name: "icon_settings"))
    }

    @Test("Validates name against regexp - no match")
    func validatesNameNoMatch() throws {
        let config = NameProcessingConfig(
            nameValidateRegexp: "^icon_",
            nameReplaceRegexp: nil
        )

        #expect(!config.validates(name: "image_home"))
        #expect(!config.validates(name: "button_primary"))
    }

    @Test("Validates all names when no regexp provided")
    func validatesAllWhenNoRegexp() throws {
        let config = NameProcessingConfig(
            nameValidateRegexp: nil,
            nameReplaceRegexp: nil
        )

        #expect(config.validates(name: "anything"))
        #expect(config.validates(name: ""))
    }

    // MARK: - Replacement Regexp

    @Test("Applies replacement regexp with capture groups")
    func appliesReplacementWithCapture() throws {
        let config = NameProcessingConfig(
            nameValidateRegexp: "^(icon|image)_(.+)$",
            nameReplaceRegexp: "$2"
        )

        let result = config.processName("icon_home")

        #expect(result == "home")
    }

    @Test("Returns original name when no replacement")
    func returnsOriginalWhenNoReplacement() throws {
        let config = NameProcessingConfig(
            nameValidateRegexp: "^icon_",
            nameReplaceRegexp: nil
        )

        let result = config.processName("icon_home")

        #expect(result == "icon_home")
    }

    @Test("Returns original name when regexp doesn't match")
    func returnsOriginalWhenNoMatch() throws {
        let config = NameProcessingConfig(
            nameValidateRegexp: "^icon_(.+)$",
            nameReplaceRegexp: "$1"
        )

        let result = config.processName("button_primary")

        #expect(result == "button_primary")
    }

    @Test("Handles complex replacement patterns")
    func handlesComplexPatterns() throws {
        let config = NameProcessingConfig(
            nameValidateRegexp: "^([a-z]+)/([a-z]+)/(.+)$",
            nameReplaceRegexp: "$2_$3"
        )

        let result = config.processName("icons/navigation/arrow_back")

        #expect(result == "navigation_arrow_back")
    }

    // MARK: - Decoding

    @Test("Decodes from JSON")
    func decodesFromJson() throws {
        let json = """
        {
            "nameValidateRegexp": "^test_",
            "nameReplaceRegexp": "processed_$0"
        }
        """
        let data = Data(json.utf8)

        let config = try JSONDecoder().decode(NameProcessingConfig.self, from: data)

        #expect(config.nameValidateRegexp == "^test_")
        #expect(config.nameReplaceRegexp == "processed_$0")
    }

    @Test("Decodes with optional fields")
    func decodesWithOptionalFields() throws {
        let json = "{}"
        let data = Data(json.utf8)

        let config = try JSONDecoder().decode(NameProcessingConfig.self, from: data)

        #expect(config.nameValidateRegexp == nil)
        #expect(config.nameReplaceRegexp == nil)
    }

    // MARK: - Edge Cases

    @Test("Handles invalid regexp gracefully")
    func handlesInvalidRegexp() throws {
        let config = NameProcessingConfig(
            nameValidateRegexp: "[invalid(", // Invalid regexp
            nameReplaceRegexp: nil
        )

        // Should not crash, returns false for validation
        #expect(!config.validates(name: "test"))
    }
}
