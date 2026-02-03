// swiftlint:disable file_length type_body_length
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
    func decodeFigmaCamelCase() throws {
        // Figma API uses camelCase keys
        let json = """
        {"userId": 123, "fileName": "test.fig"}
        """
        let data = Data(json.utf8)

        struct FigmaResponse: Codable, Equatable {
            let userId: Int
            let fileName: String
        }

        let decoded = try JSONCodec.decode(FigmaResponse.self, from: data)

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
    func decodeFigmaFileInfo() throws {
        // Test: decode Figma file info response (camelCase)
        let json = """
        {"lastModified": "2024-01-01", "thumbnailUrl": "https://example.com"}
        """
        let data = Data(json.utf8)

        struct FileInfo: Codable, Equatable {
            let lastModified: String
            let thumbnailUrl: String
        }

        let decoded = try JSONCodec.decode(FileInfo.self, from: data)

        #expect(decoded.lastModified == "2024-01-01")
        #expect(decoded.thumbnailUrl == "https://example.com")
    }

    @Test
    func decodeFigmaNestedDictionary() throws {
        // Test: nested dictionary with camelCase keys (matching Figma API)
        let json = """
        {
            "variableCollections": {
                "key1": {
                    "defaultModeId": "1:0",
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

        let decoded = try JSONCodec.decode(Outer.self, from: data)

        #expect(decoded.variableCollections.count == 1)
        #expect(decoded.variableCollections["key1"]?.defaultModeId == "1:0")
    }

    @Test
    func decodeFigmaFullVariableCollection() throws {
        // Test: full variable collection structure like Figma API (camelCase)
        let json = """
        {
            "variableCollections": {
                "VariableCollectionId:1:1": {
                    "defaultModeId": "1:0",
                    "id": "VariableCollectionId:1:1",
                    "name": "Colors",
                    "modes": [
                        { "modeId": "1:0", "name": "Light" },
                        { "modeId": "1:1", "name": "Dark" }
                    ],
                    "variableIds": ["id1", "id2"]
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

        let decoded = try JSONCodec.decode(Response.self, from: data)

        #expect(decoded.variableCollections.count == 1)
        let collection = decoded.variableCollections["VariableCollectionId:1:1"]
        #expect(collection?.name == "Colors")
        #expect(collection?.modes.count == 2)
    }

    @Test
    func decodeNestedDictValue() throws {
        // Test: decode nested dictionary values (camelCase)
        let json = """
        {
            "items": {
                "key1": {
                    "someField": "value"
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

        let decoded = try JSONCodec.decode(Outer.self, from: data)
        #expect(decoded.items["key1"]?.someField == "value")
    }

    @Test
    func decodeWithVarProperties() throws {
        // Test with var instead of let (like FigmaAPI models)
        let json = """
        {
            "items": {
                "key1": {
                    "someField": "value",
                    "nestedArray": [{"modeId": "1:0", "name": "Light"}]
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

        let decoded = try JSONCodec.decode(Outer.self, from: data)
        #expect(decoded.items["key1"]?.someField == "value")
        #expect(decoded.items["key1"]?.nestedArray.count == 1)
        #expect(decoded.items["key1"]?.nestedArray[0].modeId == "1:0")
    }

    // MARK: - Error Handling Tests

    @Test
    func decodeInvalidJSON() throws {
        let invalidData = Data("not valid json {{{".utf8)

        #expect(throws: (any Error).self) {
            struct TestModel: Codable { let id: Int }
            _ = try JSONCodec.decode(TestModel.self, from: invalidData)
        }
    }

    @Test
    func decodeEmptyData() throws {
        let emptyData = Data()

        #expect(throws: (any Error).self) {
            struct TestModel: Codable { let id: Int }
            _ = try JSONCodec.decode(TestModel.self, from: emptyData)
        }
    }

    @Test
    func decodeTypeMismatch() throws {
        // JSON has string "id", but model expects Int
        let json = """
        {"id": "not_an_int", "name": "test"}
        """
        let data = Data(json.utf8)

        struct TestModel: Codable {
            let id: Int
            let name: String
        }

        #expect(throws: (any Error).self) {
            _ = try JSONCodec.decode(TestModel.self, from: data)
        }
    }

    // MARK: - Unicode and Special Characters

    @Test
    func encodeDecodeUnicode() throws {
        struct TestModel: Codable, Equatable {
            let name: String
            let emoji: String
            let chinese: String
        }

        let model = TestModel(
            name: "Test \"quoted\" \\escaped\\",
            emoji: "Icon 💡🎨🚀",
            chinese: "中文测试"
        )

        let data = try JSONCodec.encode(model)
        let decoded = try JSONCodec.decode(TestModel.self, from: data)

        #expect(model == decoded)
    }

    @Test
    func encodeDecodeSpecialCharacters() throws {
        struct TestModel: Codable, Equatable {
            let text: String
        }

        // Test various special characters that need escaping
        let model = TestModel(text: "Line1\nLine2\tTabbed\r\nWindows")

        let data = try JSONCodec.encode(model)
        let decoded = try JSONCodec.decode(TestModel.self, from: data)

        #expect(model == decoded)
    }

    // MARK: - encodePrettySorted Tests

    @Test
    func encodePrettySorted() throws {
        struct TestModel: Codable {
            let z: Int
            let a: Int
        }

        let model = TestModel(z: 2, a: 1)
        let data = try JSONCodec.encodePrettySorted(model)
        let string = String(bytes: data, encoding: .utf8) ?? ""

        // Should have newlines (pretty)
        #expect(string.contains("\n"), "Should be pretty-printed: \(string)")

        // Keys should be sorted: "a" before "z"
        guard let rangeA = string.range(of: "\"a\""),
              let rangeZ = string.range(of: "\"z\"")
        else {
            Issue.record("Missing keys in JSON: \(string)")
            return
        }

        #expect(rangeA.lowerBound < rangeZ.lowerBound, "Keys should be sorted: \(string)")
    }

    @Test
    func encodePrettySortedNested() throws {
        struct Inner: Codable {
            let beta: String
            let alpha: String
        }

        struct Outer: Codable {
            let inner: Inner
            let data: Int
            let config: String
        }

        let model = Outer(
            inner: Inner(beta: "b", alpha: "a"),
            data: 42,
            config: "test"
        )

        let data = try JSONCodec.encodePrettySorted(model)
        let string = String(bytes: data, encoding: .utf8) ?? ""

        // Verify top-level keys are sorted: config, data, inner
        guard let rangeConfig = string.range(of: "\"config\""),
              let rangeData = string.range(of: "\"data\""),
              let rangeInner = string.range(of: "\"inner\"")
        else {
            Issue.record("Missing keys in JSON: \(string)")
            return
        }

        #expect(rangeConfig.lowerBound < rangeData.lowerBound)
        #expect(rangeData.lowerBound < rangeInner.lowerBound)

        // Verify nested keys are sorted: alpha, beta
        guard let rangeAlpha = string.range(of: "\"alpha\""),
              let rangeBeta = string.range(of: "\"beta\"")
        else {
            Issue.record("Missing nested keys in JSON: \(string)")
            return
        }

        #expect(rangeAlpha.lowerBound < rangeBeta.lowerBound)
    }

    // MARK: - Large Payload Test

    @Test
    func encodeDecodeLargePayload() throws {
        struct Node: Codable, Equatable {
            let id: String
            let name: String
            let value: Int
        }

        // Create 500 nodes to simulate a typical Figma response
        let nodes = (0 ..< 500).map { i in
            Node(id: "node:\(i)", name: "Node \(i)", value: i)
        }

        let data = try JSONCodec.encode(nodes)
        let decoded = try JSONCodec.decode([Node].self, from: data)

        #expect(nodes == decoded)
        #expect(decoded.count == 500)
    }
}
