import Foundation
import Testing

@testable import ExFigConfig

/// Tests for AssetConfiguration — single/multiple configuration pattern.
@Suite("AssetConfiguration Tests")
struct AssetConfigurationTests {
    // MARK: - Single Configuration

    @Test("Decodes single object as .single")
    func decodesSingleObject() throws {
        let json = """
        {
            "output": "/path/to/output",
            "nameStyle": "camelCase"
        }
        """
        let data = Data(json.utf8)

        let config = try JSONDecoder().decode(
            AssetConfiguration<TestEntry>.self,
            from: data
        )

        guard case .single = config else {
            Issue.record("Expected .single, got .multiple")
            return
        }
    }

    @Test("Decodes array as .multiple")
    func decodesArrayAsMultiple() throws {
        let json = """
        [
            {"output": "/path/one", "nameStyle": "camelCase"},
            {"output": "/path/two", "nameStyle": "snake_case"}
        ]
        """
        let data = Data(json.utf8)

        let config = try JSONDecoder().decode(
            AssetConfiguration<TestEntry>.self,
            from: data
        )

        guard case let .multiple(entries) = config else {
            Issue.record("Expected .multiple, got .single")
            return
        }
        #expect(entries.count == 2)
    }

    @Test(".entries returns correct array for single case")
    func entriesReturnsSingleAsArray() throws {
        let json = """
        {
            "output": "/single/path",
            "nameStyle": "camelCase"
        }
        """
        let data = Data(json.utf8)

        let config = try JSONDecoder().decode(
            AssetConfiguration<TestEntry>.self,
            from: data
        )

        let entries = config.entries
        #expect(entries.count == 1)
        #expect(entries[0].output == "/single/path")
    }

    @Test(".entries returns correct array for multiple case")
    func entriesReturnsMultipleArray() throws {
        let json = """
        [
            {"output": "/first", "nameStyle": "camelCase"},
            {"output": "/second", "nameStyle": "snake_case"},
            {"output": "/third", "nameStyle": "PascalCase"}
        ]
        """
        let data = Data(json.utf8)

        let config = try JSONDecoder().decode(
            AssetConfiguration<TestEntry>.self,
            from: data
        )

        let entries = config.entries
        #expect(entries.count == 3)
        #expect(entries[0].output == "/first")
        #expect(entries[1].output == "/second")
        #expect(entries[2].output == "/third")
    }

    @Test(".isMultiple returns false for single")
    func isMultipleReturnsFalseForSingle() throws {
        let json = """
        {"output": "/path", "nameStyle": "camelCase"}
        """
        let data = Data(json.utf8)

        let config = try JSONDecoder().decode(
            AssetConfiguration<TestEntry>.self,
            from: data
        )

        #expect(!config.isMultiple)
    }

    @Test(".isMultiple returns true for multiple")
    func isMultipleReturnsTrueForMultiple() throws {
        let json = """
        [{"output": "/path", "nameStyle": "camelCase"}]
        """
        let data = Data(json.utf8)

        let config = try JSONDecoder().decode(
            AssetConfiguration<TestEntry>.self,
            from: data
        )

        #expect(config.isMultiple)
    }

    @Test("Handles empty array")
    func handlesEmptyArray() throws {
        let json = "[]"
        let data = Data(json.utf8)

        let config = try JSONDecoder().decode(
            AssetConfiguration<TestEntry>.self,
            from: data
        )

        #expect(config.isMultiple)
        #expect(config.entries.isEmpty)
    }
}

// MARK: - Test Helpers

/// Test entry type for AssetConfiguration tests.
private struct TestEntry: Decodable, Sendable {
    let output: String
    let nameStyle: String
}
