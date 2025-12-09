@testable import FigmaAPI
import XCTest

/// Tests for children order stability in Document to NodeHashableProperties conversion.
final class DocumentHashChildrenOrderTests: XCTestCase {
    func testChildrenOrderDoesNotAffectHash() throws {
        // Same children in different order should produce the same hash
        let redFill = """
        {"type": "SOLID", "color": {"r": 1.0, "g": 0.0, "b": 0.0, "a": 1.0}}
        """
        let greenFill = """
        {"type": "SOLID", "color": {"r": 0.0, "g": 1.0, "b": 0.0, "a": 1.0}}
        """
        let blueFill = """
        {"type": "SOLID", "color": {"r": 0.0, "g": 0.0, "b": 1.0, "a": 1.0}}
        """

        let jsonOrder1 = """
        {
            "id": "1:2",
            "name": "parent",
            "type": "FRAME",
            "fills": [],
            "children": [
                {"id": "1:3", "name": "aaa", "type": "VECTOR", "fills": [\(redFill)]},
                {"id": "1:4", "name": "bbb", "type": "VECTOR", "fills": [\(greenFill)]},
                {"id": "1:5", "name": "ccc", "type": "VECTOR", "fills": [\(blueFill)]}
            ]
        }
        """

        let jsonOrder2 = """
        {
            "id": "1:2",
            "name": "parent",
            "type": "FRAME",
            "fills": [],
            "children": [
                {"id": "1:5", "name": "ccc", "type": "VECTOR", "fills": [\(blueFill)]},
                {"id": "1:3", "name": "aaa", "type": "VECTOR", "fills": [\(redFill)]},
                {"id": "1:4", "name": "bbb", "type": "VECTOR", "fills": [\(greenFill)]}
            ]
        }
        """

        let doc1 = try JSONDecoder().decode(Document.self, from: Data(jsonOrder1.utf8))
        let doc2 = try JSONDecoder().decode(Document.self, from: Data(jsonOrder2.utf8))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let hash1 = try encoder.encode(doc1.toHashableProperties())
        let hash2 = try encoder.encode(doc2.toHashableProperties())

        XCTAssertEqual(hash1, hash2, "Children order should not affect hash")
    }

    func testNestedChildrenOrderDoesNotAffectHash() throws {
        // Nested children in different order should also produce the same hash
        let fill = """
        {"type": "SOLID", "color": {"r": 1.0, "g": 0.0, "b": 0.0, "a": 1.0}}
        """

        let jsonOrder1 = """
        {
            "id": "1:1",
            "name": "root",
            "type": "FRAME",
            "fills": [],
            "children": [
                {
                    "id": "1:2",
                    "name": "group",
                    "type": "GROUP",
                    "fills": [],
                    "children": [
                        {"id": "1:3", "name": "aaa", "type": "VECTOR", "fills": [\(fill)]},
                        {"id": "1:4", "name": "bbb", "type": "VECTOR", "fills": [\(fill)]}
                    ]
                }
            ]
        }
        """

        let jsonOrder2 = """
        {
            "id": "1:1",
            "name": "root",
            "type": "FRAME",
            "fills": [],
            "children": [
                {
                    "id": "1:2",
                    "name": "group",
                    "type": "GROUP",
                    "fills": [],
                    "children": [
                        {"id": "1:4", "name": "bbb", "type": "VECTOR", "fills": [\(fill)]},
                        {"id": "1:3", "name": "aaa", "type": "VECTOR", "fills": [\(fill)]}
                    ]
                }
            ]
        }
        """

        let doc1 = try JSONDecoder().decode(Document.self, from: Data(jsonOrder1.utf8))
        let doc2 = try JSONDecoder().decode(Document.self, from: Data(jsonOrder2.utf8))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let hash1 = try encoder.encode(doc1.toHashableProperties())
        let hash2 = try encoder.encode(doc2.toHashableProperties())

        XCTAssertEqual(hash1, hash2, "Nested children order should not affect hash")
    }
}
