@testable import ExFigConfig
import Foundation
import Testing

/// Tests for NameProcessingConfig — decoding and initialization.
@Suite("NameProcessingConfig Tests")
struct NameProcessingConfigTests {
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
}
