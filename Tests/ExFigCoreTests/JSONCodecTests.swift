@testable import ExFigCore
import Foundation
import Testing

struct JSONCodecTests {
    @Test
    func encodeDecode() throws {
        struct TestModel: Codable, Equatable {
            let id: Int
            let name: String
        }

        let model = TestModel(id: 1, name: "test")
        let data = try JSONCodec.encode(model)
        let decoded = try JSONCodec.decode(TestModel.self, from: data)

        #expect(model == decoded)
    }

    @Test
    func encodeSorted() throws {
        struct TestModel: Codable, Equatable {
            let b: Int
            let a: Int
        }

        let model = TestModel(b: 2, a: 1)
        let data = try JSONCodec.encodeSorted(model)
        let string = String(bytes: data, encoding: .utf8) ?? ""

        // Verify keys are sorted: "a" should come before "b"
        guard let rangeA = string.range(of: "\"a\""),
              let rangeB = string.range(of: "\"b\"")
        else {
            Issue.record("Missing keys in JSON: \(string)")
            return
        }

        #expect(rangeA.lowerBound < rangeB.lowerBound, "Keys should be sorted: \(string)")

        let decoded = try JSONCodec.decode(TestModel.self, from: data)
        #expect(model == decoded)
    }

    @Test
    func encodePretty() throws {
        struct TestModel: Codable {
            let id: Int
        }

        let model = TestModel(id: 42)
        let data = try JSONCodec.encodePretty(model)
        let string = String(bytes: data, encoding: .utf8) ?? ""

        // Pretty-printed JSON should contain newlines
        #expect(string.contains("\n"), "Pretty output should contain newlines: \(string)")
    }

    @Test
    func decodeFigmaSnakeCase() throws {
        // Figma API uses snake_case keys
        let json = """
        {"user_id": 123, "file_name": "test.fig"}
        """
        let data = Data(json.utf8)

        struct FigmaResponse: Codable, Equatable {
            let userId: Int
            let fileName: String
        }

        let decoded = try JSONCodec.decodeFigma(FigmaResponse.self, from: data)

        #expect(decoded.userId == 123)
        #expect(decoded.fileName == "test.fig")
    }

    @Test
    func encodeSortedNestedObjects() throws {
        struct Inner: Codable, Equatable {
            let z: Int
            let y: Int
            let x: Int
        }

        struct Outer: Codable, Equatable {
            let c: Inner
            let b: String
            let a: Int
        }

        let model = Outer(c: Inner(z: 3, y: 2, x: 1), b: "test", a: 42)
        let data = try JSONCodec.encodeSorted(model)
        let string = String(bytes: data, encoding: .utf8) ?? ""

        // Verify top-level keys are sorted
        guard let rangeA = string.range(of: "\"a\""),
              let rangeB = string.range(of: "\"b\""),
              let rangeC = string.range(of: "\"c\"")
        else {
            Issue.record("Missing keys in JSON: \(string)")
            return
        }

        #expect(rangeA.lowerBound < rangeB.lowerBound)
        #expect(rangeB.lowerBound < rangeC.lowerBound)

        // Verify nested keys are sorted
        guard let rangeX = string.range(of: "\"x\""),
              let rangeY = string.range(of: "\"y\""),
              let rangeZ = string.range(of: "\"z\"")
        else {
            Issue.record("Missing nested keys in JSON: \(string)")
            return
        }

        #expect(rangeX.lowerBound < rangeY.lowerBound)
        #expect(rangeY.lowerBound < rangeZ.lowerBound)
    }

    @Test
    func hashingDeterminism() throws {
        struct TestModel: Codable, Equatable {
            let delta: Int
            let charlie: Int
            let bravo: Int
            let alpha: Int
        }

        let model = TestModel(delta: 4, charlie: 3, bravo: 2, alpha: 1)

        // Multiple encodes should produce identical output
        let data1 = try JSONCodec.encodeSorted(model)
        let data2 = try JSONCodec.encodeSorted(model)
        let data3 = try JSONCodec.encodeSorted(model)

        #expect(data1 == data2)
        #expect(data2 == data3)
    }

    @Test
    func decodeFigmaCamelCaseInput() throws {
        // Test: decodeFigma with camelCase JSON input (some Figma responses)
        let json = """
        {"lastModified": "2024-01-01", "thumbnailUrl": "https://example.com"}
        """
        let data = Data(json.utf8)

        struct FileInfo: Codable, Equatable {
            let lastModified: String
            let thumbnailUrl: String
        }

        let decoded = try JSONCodec.decodeFigma(FileInfo.self, from: data)

        #expect(decoded.lastModified == "2024-01-01")
        #expect(decoded.thumbnailUrl == "https://example.com")
    }

    @Test
    func decodeFigmaNestedDictionary() throws {
        // Test: nested dictionary with snake_case keys
        let json = """
        {
            "variable_collections": {
                "key1": {
                    "default_mode_id": "1:0",
                    "id": "key1",
                    "name": "Test"
                }
            }
        }
        """
        let data = Data(json.utf8)

        struct Inner: Codable, Equatable {
            let defaultModeId: String
            let id: String
            let name: String
        }

        struct Outer: Codable, Equatable {
            let variableCollections: [String: Inner]
        }

        let decoded = try JSONCodec.decodeFigma(Outer.self, from: data)

        #expect(decoded.variableCollections.count == 1)
        #expect(decoded.variableCollections["key1"]?.defaultModeId == "1:0")
    }

    @Test
    func decodeFigmaFullVariableCollection() throws {
        // Test: full variable collection structure like Figma API
        let json = """
        {
            "variable_collections": {
                "VariableCollectionId:1:1": {
                    "default_mode_id": "1:0",
                    "id": "VariableCollectionId:1:1",
                    "name": "Colors",
                    "modes": [
                        { "mode_id": "1:0", "name": "Light" },
                        { "mode_id": "1:1", "name": "Dark" }
                    ],
                    "variable_ids": ["id1", "id2"]
                }
            }
        }
        """
        let data = Data(json.utf8)

        struct Mode: Codable, Equatable {
            let modeId: String
            let name: String
        }

        struct Collection: Codable, Equatable {
            let defaultModeId: String
            let id: String
            let name: String
            let modes: [Mode]
            let variableIds: [String]
        }

        struct Response: Codable, Equatable {
            let variableCollections: [String: Collection]
        }

        let decoded = try JSONCodec.decodeFigma(Response.self, from: data)

        #expect(decoded.variableCollections.count == 1)
        let collection = decoded.variableCollections["VariableCollectionId:1:1"]
        #expect(collection?.name == "Colors")
        #expect(collection?.modes.count == 2)
    }

    @Test
    func yyjsonKeyStrategyOnNestedDictValue() throws {
        // Minimal test: does YYJSON apply keyDecodingStrategy to dictionary values?
        let json = """
        {
            "items": {
                "key1": {
                    "some_field": "value"
                }
            }
        }
        """
        let data = Data(json.utf8)

        struct Inner: Codable, Equatable {
            let someField: String
        }

        struct Outer: Codable, Equatable {
            let items: [String: Inner]
        }

        let decoded = try JSONCodec.decodeFigma(Outer.self, from: data)
        #expect(decoded.items["key1"]?.someField == "value")
    }

    @Test
    func yyjsonWithVarProperties() throws {
        // Test with var instead of let (like FigmaAPI models)
        let json = """
        {
            "items": {
                "key1": {
                    "some_field": "value",
                    "nested_array": [{"mode_id": "1:0", "name": "Light"}]
                }
            }
        }
        """
        let data = Data(json.utf8)

        struct Mode: Codable, Sendable {
            var modeId: String
            var name: String
        }

        struct Inner: Codable, Sendable {
            var someField: String
            var nestedArray: [Mode]
        }

        struct Outer: Codable, Sendable {
            var items: [String: Inner]
        }

        let decoded = try JSONCodec.decodeFigma(Outer.self, from: data)
        #expect(decoded.items["key1"]?.someField == "value")
        #expect(decoded.items["key1"]?.nestedArray.count == 1)
        #expect(decoded.items["key1"]?.nestedArray[0].modeId == "1:0")
    }
}
