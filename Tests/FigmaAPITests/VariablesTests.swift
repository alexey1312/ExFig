@testable import FigmaAPI
import Foundation
import XCTest

final class ModeTests: XCTestCase {
    func testDecoding() throws {
        let json = """
        {"mode_id": "123:0", "name": "Light"}
        """

        let mode = try JSONDecoder().decode(Mode.self, from: Data(json.utf8))

        XCTAssertEqual(mode.modeId, "123:0")
        XCTAssertEqual(mode.name, "Light")
    }
}

final class VariableCollectionValueTests: XCTestCase {
    func testDecoding() throws {
        let json = """
        {
            "default_mode_id": "123:0",
            "id": "collection-1",
            "name": "Colors",
            "modes": [
                {"mode_id": "123:0", "name": "Light"},
                {"mode_id": "123:1", "name": "Dark"}
            ],
            "variable_ids": ["var-1", "var-2"]
        }
        """

        let collection = try JSONDecoder().decode(VariableCollectionValue.self, from: Data(json.utf8))

        XCTAssertEqual(collection.defaultModeId, "123:0")
        XCTAssertEqual(collection.id, "collection-1")
        XCTAssertEqual(collection.name, "Colors")
        XCTAssertEqual(collection.modes.count, 2)
        XCTAssertEqual(collection.variableIds, ["var-1", "var-2"])
    }
}

final class VariableAliasTests: XCTestCase {
    func testDecoding() throws {
        let json = """
        {"id": "alias-123", "type": "VARIABLE_ALIAS"}
        """

        let alias = try JSONDecoder().decode(VariableAlias.self, from: Data(json.utf8))

        XCTAssertEqual(alias.id, "alias-123")
        XCTAssertEqual(alias.type, "VARIABLE_ALIAS")
    }

    func testEncoding() throws {
        let alias = VariableAlias(id: "alias-456", type: "VARIABLE_ALIAS")

        let data = try JSONEncoder().encode(alias)
        let decoded = try JSONDecoder().decode(VariableAlias.self, from: data)

        XCTAssertEqual(decoded.id, "alias-456")
        XCTAssertEqual(decoded.type, "VARIABLE_ALIAS")
    }
}

final class ValuesByModeTests: XCTestCase {
    func testDecodingVariableAlias() throws {
        let json = """
        {"id": "alias-123", "type": "VARIABLE_ALIAS"}
        """

        let value = try JSONDecoder().decode(ValuesByMode.self, from: Data(json.utf8))

        if case let .variableAlias(alias) = value {
            XCTAssertEqual(alias.id, "alias-123")
        } else {
            XCTFail("Expected variableAlias case")
        }
    }

    func testDecodingColor() throws {
        let json = """
        {"r": 1.0, "g": 0.5, "b": 0.25, "a": 1.0}
        """

        let value = try JSONDecoder().decode(ValuesByMode.self, from: Data(json.utf8))

        if case let .color(color) = value {
            XCTAssertEqual(color.r, 1.0)
            XCTAssertEqual(color.g, 0.5)
            XCTAssertEqual(color.b, 0.25)
            XCTAssertEqual(color.a, 1.0)
        } else {
            XCTFail("Expected color case")
        }
    }

    func testDecodingString() throws {
        let json = """
        "test string"
        """

        let value = try JSONDecoder().decode(ValuesByMode.self, from: Data(json.utf8))

        if case let .string(str) = value {
            XCTAssertEqual(str, "test string")
        } else {
            XCTFail("Expected string case")
        }
    }

    func testDecodingNumber() throws {
        let json = """
        42.5
        """

        let value = try JSONDecoder().decode(ValuesByMode.self, from: Data(json.utf8))

        if case let .number(num) = value {
            XCTAssertEqual(num, 42.5)
        } else {
            XCTFail("Expected number case")
        }
    }

    func testDecodingBoolean() throws {
        let json = """
        true
        """

        let value = try JSONDecoder().decode(ValuesByMode.self, from: Data(json.utf8))

        if case let .boolean(bool) = value {
            XCTAssertTrue(bool)
        } else {
            XCTFail("Expected boolean case")
        }
    }

    func testDecodingBooleanFalse() throws {
        let json = """
        false
        """

        let value = try JSONDecoder().decode(ValuesByMode.self, from: Data(json.utf8))

        if case let .boolean(bool) = value {
            XCTAssertFalse(bool)
        } else {
            XCTFail("Expected boolean case")
        }
    }

    func testDecodingInvalidDataThrows() {
        let json = """
        [1, 2, 3]
        """

        XCTAssertThrowsError(try JSONDecoder().decode(ValuesByMode.self, from: Data(json.utf8)))
    }
}

final class VariableValueTests: XCTestCase {
    func testDecoding() throws {
        let json = """
        {
            "id": "var-1",
            "name": "primary",
            "variable_collection_id": "collection-1",
            "values_by_mode": {
                "123:0": {"r": 1.0, "g": 0.0, "b": 0.0, "a": 1.0}
            },
            "description": "Primary color"
        }
        """

        let variable = try JSONDecoder().decode(VariableValue.self, from: Data(json.utf8))

        XCTAssertEqual(variable.id, "var-1")
        XCTAssertEqual(variable.name, "primary")
        XCTAssertEqual(variable.variableCollectionId, "collection-1")
        XCTAssertEqual(variable.description, "Primary color")
        XCTAssertEqual(variable.valuesByMode.count, 1)
    }
}

final class VariablesMetaTests: XCTestCase {
    func testDecoding() throws {
        let json = """
        {
            "variable_collections": {
                "collection-1": {
                    "default_mode_id": "123:0",
                    "id": "collection-1",
                    "name": "Colors",
                    "modes": [{"mode_id": "123:0", "name": "Light"}],
                    "variable_ids": ["var-1"]
                }
            },
            "variables": {
                "var-1": {
                    "id": "var-1",
                    "name": "primary",
                    "variable_collection_id": "collection-1",
                    "values_by_mode": {"123:0": {"r": 1.0, "g": 0.0, "b": 0.0, "a": 1.0}},
                    "description": ""
                }
            }
        }
        """

        let meta = try JSONDecoder().decode(VariablesMeta.self, from: Data(json.utf8))

        XCTAssertEqual(meta.variableCollections.count, 1)
        XCTAssertEqual(meta.variables.count, 1)
        XCTAssertNotNil(meta.variableCollections["collection-1"])
        XCTAssertNotNil(meta.variables["var-1"])
    }
}

final class VariablesResponseTests: XCTestCase {
    func testDecoding() throws {
        let json = """
        {
            "meta": {
                "variable_collections": {},
                "variables": {}
            }
        }
        """

        let response = try JSONDecoder().decode(VariablesResponse.self, from: Data(json.utf8))

        XCTAssertTrue(response.meta.variableCollections.isEmpty)
        XCTAssertTrue(response.meta.variables.isEmpty)
    }
}
