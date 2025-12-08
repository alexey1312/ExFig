@testable import FigmaAPI
import XCTest

/// Tests for Document to NodeHashableProperties conversion.
final class DocumentHashConversionTests: XCTestCase {
    // MARK: - Basic Conversion

    func testDocumentToHashablePropertiesConvertsAllFields() throws {
        let json = """
        {
            "id": "1:2",
            "name": "test-icon",
            "type": "COMPONENT",
            "fills": [{"type": "SOLID", "color": {"r": 1.0, "g": 0.5, "b": 0.0, "a": 1.0}}],
            "strokes": [{"type": "SOLID", "color": {"r": 0.0, "g": 0.0, "b": 0.0, "a": 1.0}}],
            "strokeWeight": 2.0,
            "strokeAlign": "CENTER",
            "strokeJoin": "ROUND",
            "strokeCap": "ROUND",
            "effects": [{"type": "DROP_SHADOW", "radius": 4.0, "visible": true}],
            "opacity": 0.9,
            "blendMode": "NORMAL",
            "clipsContent": true
        }
        """

        let document = try JSONDecoder().decode(Document.self, from: Data(json.utf8))
        let hashable = document.toHashableProperties()

        XCTAssertEqual(hashable.name, "test-icon")
        XCTAssertEqual(hashable.type, "COMPONENT")
        XCTAssertEqual(hashable.fills.count, 1)
        XCTAssertEqual(hashable.fills[0].type, "SOLID")
        XCTAssertEqual(hashable.strokes?.count, 1)
        XCTAssertEqual(hashable.strokeWeight, 2.0)
        XCTAssertEqual(hashable.strokeAlign, "CENTER")
        XCTAssertEqual(hashable.strokeJoin, "ROUND")
        XCTAssertEqual(hashable.strokeCap, "ROUND")
        XCTAssertEqual(hashable.effects?.count, 1)
        XCTAssertEqual(hashable.effects?[0].type, "DROP_SHADOW")
        XCTAssertEqual(hashable.opacity, 0.9)
        XCTAssertEqual(hashable.blendMode, "NORMAL")
        XCTAssertEqual(hashable.clipsContent, true)
    }

    // MARK: - Float Normalization

    func testDocumentToHashablePropertiesNormalizesFloats() throws {
        let json = """
        {
            "id": "1:2",
            "name": "icon",
            "type": "VECTOR",
            "fills": [{"type": "SOLID", "color": {"r": 0.33333334, "g": 0.66666667, "b": 0.5, "a": 1.0}}],
            "strokeWeight": 1.0000001,
            "opacity": 0.9999999
        }
        """

        let document = try JSONDecoder().decode(Document.self, from: Data(json.utf8))
        let hashable = document.toHashableProperties()

        // Values should be normalized to 6 decimal places
        XCTAssertEqual(hashable.fills[0].color?.r, 0.333333)
        XCTAssertEqual(hashable.fills[0].color?.g, 0.666667)
        XCTAssertEqual(hashable.strokeWeight, 1.0)
        XCTAssertEqual(hashable.opacity, 1.0)
    }

    // MARK: - Children

    func testDocumentToHashablePropertiesConvertsChildren() throws {
        let json = """
        {
            "id": "1:2",
            "name": "parent",
            "type": "FRAME",
            "fills": [],
            "children": [
                {
                    "id": "1:3",
                    "name": "child",
                    "type": "VECTOR",
                    "fills": [{"type": "SOLID", "color": {"r": 1.0, "g": 0.0, "b": 0.0, "a": 1.0}}]
                }
            ]
        }
        """

        let document = try JSONDecoder().decode(Document.self, from: Data(json.utf8))
        let hashable = document.toHashableProperties()

        XCTAssertEqual(hashable.children?.count, 1)
        XCTAssertEqual(hashable.children?[0].name, "child")
        XCTAssertEqual(hashable.children?[0].type, "VECTOR")
        XCTAssertEqual(hashable.children?[0].fills.count, 1)
    }

    // MARK: - Gradients

    func testDocumentToHashablePropertiesConvertsGradientStops() throws {
        let json = """
        {
            "id": "1:2",
            "name": "gradient-icon",
            "type": "VECTOR",
            "fills": [{
                "type": "GRADIENT_LINEAR",
                "gradientStops": [
                    {"position": 0.0, "color": {"r": 1.0, "g": 0.0, "b": 0.0, "a": 1.0}},
                    {"position": 1.0, "color": {"r": 0.0, "g": 0.0, "b": 1.0, "a": 1.0}}
                ]
            }]
        }
        """

        let document = try JSONDecoder().decode(Document.self, from: Data(json.utf8))
        let hashable = document.toHashableProperties()

        XCTAssertEqual(hashable.fills[0].type, "GRADIENT_LINEAR")
        XCTAssertEqual(hashable.fills[0].gradientStops?.count, 2)
        XCTAssertEqual(hashable.fills[0].gradientStops?[0].position, 0.0)
        XCTAssertEqual(hashable.fills[0].gradientStops?[1].position, 1.0)
    }

    // MARK: - Effects

    func testDocumentToHashablePropertiesConvertsEffectWithOffset() throws {
        let json = """
        {
            "id": "1:2",
            "name": "shadow-icon",
            "type": "VECTOR",
            "fills": [],
            "effects": [{
                "type": "DROP_SHADOW",
                "radius": 4.0,
                "offset": {"x": 2.0, "y": 4.0},
                "color": {"r": 0.0, "g": 0.0, "b": 0.0, "a": 0.5},
                "visible": true
            }]
        }
        """

        let document = try JSONDecoder().decode(Document.self, from: Data(json.utf8))
        let hashable = document.toHashableProperties()

        XCTAssertEqual(hashable.effects?.count, 1)
        XCTAssertEqual(hashable.effects?[0].type, "DROP_SHADOW")
        XCTAssertEqual(hashable.effects?[0].radius, 4.0)
        XCTAssertEqual(hashable.effects?[0].offset?.x, 2.0)
        XCTAssertEqual(hashable.effects?[0].offset?.y, 4.0)
        XCTAssertEqual(hashable.effects?[0].color?.a, 0.5)
        XCTAssertEqual(hashable.effects?[0].visible, true)
    }

    // MARK: - Minimal Document

    func testDocumentToHashablePropertiesHandlesMinimalDocument() throws {
        let json = """
        {
            "id": "1:2",
            "name": "minimal",
            "fills": []
        }
        """

        let document = try JSONDecoder().decode(Document.self, from: Data(json.utf8))
        let hashable = document.toHashableProperties()

        XCTAssertEqual(hashable.name, "minimal")
        XCTAssertEqual(hashable.type, "UNKNOWN")
        XCTAssertTrue(hashable.fills.isEmpty)
        XCTAssertNil(hashable.strokes)
        XCTAssertNil(hashable.strokeWeight)
        XCTAssertNil(hashable.effects)
        XCTAssertNil(hashable.opacity)
        XCTAssertNil(hashable.children)
    }

    // MARK: - Rotation

    func testDocumentToHashablePropertiesConvertsRotation() throws {
        let json = """
        {
            "id": "1:2",
            "name": "rotated-vector",
            "type": "VECTOR",
            "fills": [],
            "rotation": -1.0471975434247853
        }
        """

        let document = try JSONDecoder().decode(Document.self, from: Data(json.utf8))
        let hashable = document.toHashableProperties()

        // Rotation should be normalized to 6 decimal places
        XCTAssertEqual(hashable.rotation, -1.047198)
    }

    func testRotationChangeProducesDifferentHash() throws {
        let jsonNoRotation = """
        {
            "id": "1:2",
            "name": "icon",
            "type": "VECTOR",
            "fills": [{"type": "SOLID", "color": {"r": 1.0, "g": 0.0, "b": 0.0, "a": 1.0}}]
        }
        """

        let jsonWithRotation = """
        {
            "id": "1:2",
            "name": "icon",
            "type": "VECTOR",
            "fills": [{"type": "SOLID", "color": {"r": 1.0, "g": 0.0, "b": 0.0, "a": 1.0}}],
            "rotation": 1.5707963267948966
        }
        """

        let docNoRotation = try JSONDecoder().decode(Document.self, from: Data(jsonNoRotation.utf8))
        let docWithRotation = try JSONDecoder().decode(Document.self, from: Data(jsonWithRotation.utf8))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let hashNoRotation = try encoder.encode(docNoRotation.toHashableProperties())
        let hashWithRotation = try encoder.encode(docWithRotation.toHashableProperties())

        XCTAssertNotEqual(hashNoRotation, hashWithRotation)
    }

    // MARK: - Effect Spread

    func testDocumentToHashablePropertiesConvertsEffectSpread() throws {
        let json = """
        {
            "id": "1:2",
            "name": "shadow-icon",
            "type": "VECTOR",
            "fills": [],
            "effects": [{
                "type": "DROP_SHADOW",
                "radius": 4.0,
                "spread": 2.0,
                "offset": {"x": 0.0, "y": 2.0},
                "color": {"r": 0.0, "g": 0.0, "b": 0.0, "a": 0.25},
                "visible": true
            }]
        }
        """

        let document = try JSONDecoder().decode(Document.self, from: Data(json.utf8))
        let hashable = document.toHashableProperties()

        XCTAssertEqual(hashable.effects?[0].spread, 2.0)
    }

    func testSpreadChangeProducesDifferentHash() throws {
        let jsonSpread2 = """
        {
            "id": "1:2",
            "name": "icon",
            "type": "VECTOR",
            "fills": [],
            "effects": [{"type": "DROP_SHADOW", "radius": 4.0, "spread": 2.0, "visible": true}]
        }
        """

        let jsonSpread4 = """
        {
            "id": "1:2",
            "name": "icon",
            "type": "VECTOR",
            "fills": [],
            "effects": [{"type": "DROP_SHADOW", "radius": 4.0, "spread": 4.0, "visible": true}]
        }
        """

        let docSpread2 = try JSONDecoder().decode(Document.self, from: Data(jsonSpread2.utf8))
        let docSpread4 = try JSONDecoder().decode(Document.self, from: Data(jsonSpread4.utf8))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let hashSpread2 = try encoder.encode(docSpread2.toHashableProperties())
        let hashSpread4 = try encoder.encode(docSpread4.toHashableProperties())

        XCTAssertNotEqual(hashSpread2, hashSpread4)
    }

    // MARK: - Paint BlendMode

    func testDocumentToHashablePropertiesConvertsPaintBlendMode() throws {
        let json = """
        {
            "id": "1:2",
            "name": "blended-icon",
            "type": "VECTOR",
            "fills": [{
                "type": "SOLID",
                "blendMode": "MULTIPLY",
                "color": {"r": 1.0, "g": 0.0, "b": 0.0, "a": 1.0}
            }]
        }
        """

        let document = try JSONDecoder().decode(Document.self, from: Data(json.utf8))
        let hashable = document.toHashableProperties()

        XCTAssertEqual(hashable.fills[0].blendMode, "MULTIPLY")
    }

    func testPaintBlendModeChangeProducesDifferentHash() throws {
        let jsonNormal = """
        {
            "id": "1:2",
            "name": "icon",
            "type": "VECTOR",
            "fills": [{"type": "SOLID", "blendMode": "NORMAL", "color": {"r": 1.0, "g": 0.0, "b": 0.0, "a": 1.0}}]
        }
        """

        let jsonMultiply = """
        {
            "id": "1:2",
            "name": "icon",
            "type": "VECTOR",
            "fills": [{"type": "SOLID", "blendMode": "MULTIPLY", "color": {"r": 1.0, "g": 0.0, "b": 0.0, "a": 1.0}}]
        }
        """

        let docNormal = try JSONDecoder().decode(Document.self, from: Data(jsonNormal.utf8))
        let docMultiply = try JSONDecoder().decode(Document.self, from: Data(jsonMultiply.utf8))

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let hashNormal = try encoder.encode(docNormal.toHashableProperties())
        let hashMultiply = try encoder.encode(docMultiply.toHashableProperties())

        XCTAssertNotEqual(hashNormal, hashMultiply)
    }
}
