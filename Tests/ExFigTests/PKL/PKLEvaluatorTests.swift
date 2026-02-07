import ExFigConfig
import Foundation
import Testing

@Suite("PKLEvaluator Tests")
struct PKLEvaluatorTests {
    /// Path to test fixtures
    static let fixturesPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures/PKL")

    @Test("Evaluates valid PKL to ExFig module")
    func evaluatesValidPkl() async throws {
        let configPath = Self.fixturesPath.appendingPathComponent("valid-config.pkl")

        let module = try await PKLEvaluator.evaluate(configPath: configPath)

        #expect(module.ios != nil)
        #expect(module.ios?.xcodeprojPath == "Test.xcodeproj")
        #expect(module.ios?.target == "TestTarget")
        #expect(module.common?.variablesColors?.tokensFileId == "test-file-id")
    }

    @Test("Returns colors as array")
    func returnsColorsAsArray() async throws {
        let configPath = Self.fixturesPath.appendingPathComponent("valid-config.pkl")

        let module = try await PKLEvaluator.evaluate(configPath: configPath)

        let colors = module.ios?.colors
        #expect(colors?.count == 1)
        #expect(colors?.first?.useColorAssets == true)
    }

    @Test("Throws configNotFound for nonexistent file")
    func throwsConfigNotFoundForMissingFile() async throws {
        let fakePath = URL(fileURLWithPath: "/nonexistent/path/config.pkl")

        await #expect(throws: PKLError.self) {
            try await PKLEvaluator.evaluate(configPath: fakePath)
        }
    }

    @Test("Throws error for invalid PKL syntax")
    func throwsErrorForInvalidSyntax() async throws {
        let configPath = Self.fixturesPath.appendingPathComponent("invalid-syntax.pkl")

        await #expect(throws: (any Error).self) {
            try await PKLEvaluator.evaluate(configPath: configPath)
        }
    }
}
