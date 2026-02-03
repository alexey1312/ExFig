import Foundation
import Testing

@testable import ExFigConfig

/// Tests for SourceConfig — Figma Variables source configuration.
@Suite("SourceConfig Tests")
struct SourceConfigTests {
    // MARK: - Figma Variables Source

    @Test("Decodes all Figma Variables fields")
    func decodesAllVariablesFields() throws {
        let json = """
        {
            "tokensFileId": "abc123",
            "tokensCollectionName": "Design Tokens",
            "lightModeName": "Light",
            "darkModeName": "Dark",
            "lightHCModeName": "Light HC",
            "darkHCModeName": "Dark HC",
            "primitivesModeName": "Primitives"
        }
        """
        let data = Data(json.utf8)

        let config = try JSONDecoder().decode(VariablesSourceConfig.self, from: data)

        #expect(config.tokensFileId == "abc123")
        #expect(config.tokensCollectionName == "Design Tokens")
        #expect(config.lightModeName == "Light")
        #expect(config.darkModeName == "Dark")
        #expect(config.lightHCModeName == "Light HC")
        #expect(config.darkHCModeName == "Dark HC")
        #expect(config.primitivesModeName == "Primitives")
    }

    @Test("Handles optional dark mode fields")
    func handlesOptionalDarkModeFields() throws {
        let json = """
        {
            "tokensFileId": "abc123",
            "tokensCollectionName": "Colors",
            "lightModeName": "Default"
        }
        """
        let data = Data(json.utf8)

        let config = try JSONDecoder().decode(VariablesSourceConfig.self, from: data)

        #expect(config.tokensFileId == "abc123")
        #expect(config.lightModeName == "Default")
        #expect(config.darkModeName == nil)
        #expect(config.lightHCModeName == nil)
        #expect(config.darkHCModeName == nil)
        #expect(config.primitivesModeName == nil)
    }

    // MARK: - Figma Frame Source

    @Test("Decodes Figma Frame fields")
    func decodesFrameFields() throws {
        let json = """
        {
            "figmaFrameName": "Icons/24px"
        }
        """
        let data = Data(json.utf8)

        let config = try JSONDecoder().decode(FrameSourceConfig.self, from: data)

        #expect(config.figmaFrameName == "Icons/24px")
    }

    @Test("Handles optional figmaFrameName")
    func handlesOptionalFrameName() throws {
        let json = "{}"
        let data = Data(json.utf8)

        let config = try JSONDecoder().decode(FrameSourceConfig.self, from: data)

        #expect(config.figmaFrameName == nil)
    }

    // MARK: - Combined Source

    @Test("Decodes combined source with variables and frame")
    func decodesCombinedSource() throws {
        let json = """
        {
            "tokensFileId": "file123",
            "tokensCollectionName": "Tokens",
            "lightModeName": "Light",
            "figmaFrameName": "Frame/Name"
        }
        """
        let data = Data(json.utf8)

        let config = try JSONDecoder().decode(CombinedSourceConfig.self, from: data)

        #expect(config.tokensFileId == "file123")
        #expect(config.figmaFrameName == "Frame/Name")
    }
}
