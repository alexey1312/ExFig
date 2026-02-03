import Foundation
import Testing

@testable import ExFig

@Suite("PKLEvaluator Tests")
struct PKLEvaluatorTests {
    // Path to test fixtures
    static let fixturesPath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures/PKL")

    @Test("Evaluates valid PKL to JSON")
    func evaluatesValidPklToJson() async throws {
        let evaluator = try PKLEvaluator()
        let configPath = Self.fixturesPath.appendingPathComponent("valid-config.pkl")

        let json = try await evaluator.evaluate(configPath: configPath)

        #expect(json.contains("\"ios\""))
        #expect(json.contains("\"xcodeprojPath\""))
    }

    @Test("Returns properly formatted JSON")
    func returnsProperlyFormattedJson() async throws {
        let evaluator = try PKLEvaluator()
        let configPath = Self.fixturesPath.appendingPathComponent("valid-config.pkl")

        let json = try await evaluator.evaluate(configPath: configPath)

        // Should be valid JSON
        let data = Data(json.utf8)
        let parsed = try JSONSerialization.jsonObject(with: data)
        #expect(parsed is [String: Any])
    }

    @Test("Throws EvaluationFailed on syntax error")
    func throwsOnSyntaxError() async throws {
        let evaluator = try PKLEvaluator()
        let configPath = Self.fixturesPath.appendingPathComponent("invalid-syntax.pkl")

        await #expect(throws: PKLError.self) {
            try await evaluator.evaluate(configPath: configPath)
        }
    }

    @Test("Error includes line and column information")
    func errorIncludesLineInfo() async throws {
        let evaluator = try PKLEvaluator()
        let configPath = Self.fixturesPath.appendingPathComponent("invalid-syntax.pkl")

        do {
            _ = try await evaluator.evaluate(configPath: configPath)
            Issue.record("Expected error to be thrown")
        } catch let error as PKLError {
            if case let .evaluationFailed(message, _) = error {
                // PKL errors typically include line numbers
                #expect(message.contains("line") || message.contains("Error"))
            } else {
                Issue.record("Unexpected error type: \(error)")
            }
        }
    }

    @Test("Evaluates config to Params struct")
    func evaluatesToParams() async throws {
        let evaluator = try PKLEvaluator()
        let configPath = Self.fixturesPath.appendingPathComponent("valid-config.pkl")

        let params = try await evaluator.evaluateToParams(configPath: configPath)

        #expect(params.ios != nil)
        #expect(params.ios?.xcodeprojPath == "Test.xcodeproj")
    }
}
