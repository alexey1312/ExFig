@testable import FigmaAPI
import XCTest

final class NodeHashablePropertiesTests: XCTestCase {
    // MARK: - Canonical JSON Encoding

    func testEncodingProducesSortedKeysJSON() throws {
        let props = NodeHashableProperties(
            name: "icon",
            type: "COMPONENT",
            fills: [],
            strokes: nil,
            strokeWeight: nil,
            strokeAlign: nil,
            strokeJoin: nil,
            strokeCap: nil,
            effects: nil,
            opacity: nil,
            blendMode: nil,
            clipsContent: nil,
            rotation: nil,
            children: nil
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(props)
        let json = String(data: data, encoding: .utf8)!

        // Keys should be in alphabetical order
        // "fills" should come before "name", "name" before "type"
        let fillsIndex = json.range(of: "\"fills\"")!.lowerBound
        let nameIndex = json.range(of: "\"name\"")!.lowerBound
        let typeIndex = json.range(of: "\"type\"")!.lowerBound

        XCTAssertLessThan(fillsIndex, nameIndex)
        XCTAssertLessThan(nameIndex, typeIndex)
    }

    // MARK: - Recursive Children

    func testChildrenAreIncludedRecursively() throws {
        let childProps = NodeHashableProperties(
            name: "shape",
            type: "VECTOR",
            fills: [HashablePaint(type: "SOLID", color: HashableColor(r: 0.5, g: 0.5, b: 0.5, a: 1.0))],
            strokes: nil,
            strokeWeight: 1.0,
            strokeAlign: nil,
            strokeJoin: nil,
            strokeCap: nil,
            effects: nil,
            opacity: nil,
            blendMode: nil,
            clipsContent: nil,
            rotation: nil,
            children: nil
        )

        let parentProps = NodeHashableProperties(
            name: "icon",
            type: "COMPONENT",
            fills: [],
            strokes: nil,
            strokeWeight: nil,
            strokeAlign: nil,
            strokeJoin: nil,
            strokeCap: nil,
            effects: nil,
            opacity: nil,
            blendMode: nil,
            clipsContent: nil,
            rotation: nil,
            children: [childProps]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(parentProps)
        let json = String(data: data, encoding: .utf8)!

        // Child properties should be included
        XCTAssertTrue(json.contains("\"children\""))
        XCTAssertTrue(json.contains("\"shape\""))
        XCTAssertTrue(json.contains("\"VECTOR\""))
        XCTAssertTrue(json.contains("0.5"))
    }

    // MARK: - Excluded Properties

    func testBoundVariablesIsNotIncluded() throws {
        // NodeHashableProperties should NOT have boundVariables property
        // This test verifies the type definition is correct
        let props = NodeHashableProperties(
            name: "icon",
            type: "COMPONENT",
            fills: [],
            strokes: nil,
            strokeWeight: nil,
            strokeAlign: nil,
            strokeJoin: nil,
            strokeCap: nil,
            effects: nil,
            opacity: nil,
            blendMode: nil,
            clipsContent: nil,
            rotation: nil,
            children: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(props)
        let json = String(data: data, encoding: .utf8)!

        // Should NOT contain boundVariables
        XCTAssertFalse(json.contains("boundVariables"))
    }

    func testAbsoluteBoundingBoxIsNotIncluded() throws {
        // NodeHashableProperties should NOT have absoluteBoundingBox property
        let props = NodeHashableProperties(
            name: "icon",
            type: "COMPONENT",
            fills: [],
            strokes: nil,
            strokeWeight: nil,
            strokeAlign: nil,
            strokeJoin: nil,
            strokeCap: nil,
            effects: nil,
            opacity: nil,
            blendMode: nil,
            clipsContent: nil,
            rotation: nil,
            children: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(props)
        let json = String(data: data, encoding: .utf8)!

        // Should NOT contain absoluteBoundingBox
        XCTAssertFalse(json.contains("absoluteBoundingBox"))
        XCTAssertFalse(json.contains("absoluteRenderBounds"))
    }

    // MARK: - Float Normalization

    func testFloatValuesAreNormalizedInColors() throws {
        // Colors with precision drift should normalize to same values
        let color1 = HashableColor(
            r: 0.33333334.normalized,
            g: 0.66666667.normalized,
            b: 0.5.normalized,
            a: 1.0.normalized
        )
        let color2 = HashableColor(
            r: 0.33333333.normalized,
            g: 0.66666666.normalized,
            b: 0.5.normalized,
            a: 1.0.normalized
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let data1 = try encoder.encode(color1)
        let data2 = try encoder.encode(color2)

        XCTAssertEqual(data1, data2, "Colors with precision drift should encode identically after normalization")
    }

    func testFloatValuesAreNormalizedInStrokeWeight() throws {
        let props1 = NodeHashableProperties(
            name: "icon",
            type: "VECTOR",
            fills: [],
            strokes: nil,
            strokeWeight: 1.0000001.normalized,
            strokeAlign: nil,
            strokeJoin: nil,
            strokeCap: nil,
            effects: nil,
            opacity: nil,
            blendMode: nil,
            clipsContent: nil,
            rotation: nil,
            children: nil
        )

        let props2 = NodeHashableProperties(
            name: "icon",
            type: "VECTOR",
            fills: [],
            strokes: nil,
            strokeWeight: 1.0.normalized,
            strokeAlign: nil,
            strokeJoin: nil,
            strokeCap: nil,
            effects: nil,
            opacity: nil,
            blendMode: nil,
            clipsContent: nil,
            rotation: nil,
            children: nil
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let data1 = try encoder.encode(props1)
        let data2 = try encoder.encode(props2)

        XCTAssertEqual(data1, data2, "StrokeWeight with precision drift should encode identically after normalization")
    }

    // MARK: - Complete Visual Properties

    func testAllVisualPropertiesAreIncluded() throws {
        let props = NodeHashableProperties(
            name: "complex-icon",
            type: "COMPONENT",
            fills: [HashablePaint(type: "SOLID", color: HashableColor(r: 1, g: 0, b: 0, a: 1))],
            strokes: [HashablePaint(type: "SOLID", color: HashableColor(r: 0, g: 0, b: 0, a: 1))],
            strokeWeight: 2.0,
            strokeAlign: "CENTER",
            strokeJoin: "ROUND",
            strokeCap: "ROUND",
            effects: [HashableEffect(type: "DROP_SHADOW", radius: 4.0, offset: HashableVector(x: 0, y: 2))],
            opacity: 0.9,
            blendMode: "NORMAL",
            clipsContent: true,
            rotation: 1.5707963,
            children: nil
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(props)
        let json = String(data: data, encoding: .utf8)!

        // All visual properties should be present
        XCTAssertTrue(json.contains("\"fills\""))
        XCTAssertTrue(json.contains("\"strokes\""))
        XCTAssertTrue(json.contains("\"strokeWeight\""))
        XCTAssertTrue(json.contains("\"strokeAlign\""))
        XCTAssertTrue(json.contains("\"strokeJoin\""))
        XCTAssertTrue(json.contains("\"strokeCap\""))
        XCTAssertTrue(json.contains("\"effects\""))
        XCTAssertTrue(json.contains("\"opacity\""))
        XCTAssertTrue(json.contains("\"blendMode\""))
        XCTAssertTrue(json.contains("\"clipsContent\""))
        XCTAssertTrue(json.contains("\"rotation\""))
    }
}
