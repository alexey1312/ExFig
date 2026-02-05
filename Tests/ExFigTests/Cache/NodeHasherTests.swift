@testable import ExFig
@testable import FigmaAPI
import XCTest

final class NodeHasherTests: XCTestCase {
    // MARK: - Determinism

    func testSameNodeProducesSameHash() {
        let props = makeSimpleNode()

        let hash1 = NodeHasher.computeHash(props)
        let hash2 = NodeHasher.computeHash(props)

        XCTAssertEqual(hash1, hash2)
    }

    // MARK: - Visual Property Changes

    func testDifferentFillsProduceDifferentHash() {
        let props1 = makeNode(fills: [makePaint(r: 1, g: 0, b: 0)])
        let props2 = makeNode(fills: [makePaint(r: 0, g: 1, b: 0)])

        let hash1 = NodeHasher.computeHash(props1)
        let hash2 = NodeHasher.computeHash(props2)

        XCTAssertNotEqual(hash1, hash2)
    }

    func testDifferentStrokesProduceDifferentHash() {
        let props1 = makeNode(type: "VECTOR", strokes: [makePaint(r: 0, g: 0, b: 0)], strokeWeight: 1.0)
        let props2 = makeNode(type: "VECTOR", strokes: [makePaint(r: 1, g: 0, b: 0)], strokeWeight: 1.0)

        let hash1 = NodeHasher.computeHash(props1)
        let hash2 = NodeHasher.computeHash(props2)

        XCTAssertNotEqual(hash1, hash2)
    }

    func testDifferentChildrenProduceDifferentHash() {
        let child1 = makeNode(name: "shape1", type: "VECTOR", fills: [makePaint(r: 1, g: 0, b: 0)])
        let child2 = makeNode(name: "shape2", type: "VECTOR", fills: [makePaint(r: 0, g: 1, b: 0)])

        let props1 = makeNode(children: [child1])
        let props2 = makeNode(children: [child2])

        let hash1 = NodeHasher.computeHash(props1)
        let hash2 = NodeHasher.computeHash(props2)

        XCTAssertNotEqual(hash1, hash2)
    }

    // MARK: - Name Changes

    func testNameChangeDoesChangeHash() {
        let props1 = makeNode(name: "icon-v1")
        let props2 = makeNode(name: "icon-v2")

        let hash1 = NodeHasher.computeHash(props1)
        let hash2 = NodeHasher.computeHash(props2)

        XCTAssertNotEqual(hash1, hash2, "Name change should affect hash")
    }

    // MARK: - Hex String Output

    func testComputeHashReturns16CharHexString() {
        let props = makeSimpleNode()

        let hash = NodeHasher.computeHash(props)

        XCTAssertEqual(hash.count, 16)
        let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdef")
        XCTAssertTrue(
            hash.unicodeScalars.allSatisfy { hexCharacterSet.contains($0) },
            "Hash should be lowercase hex"
        )
    }

    // MARK: - Effects

    func testDifferentEffectsProduceDifferentHash() {
        let props1 = makeNode(effects: [HashableEffect(type: "DROP_SHADOW", radius: 4.0)])
        let props2 = makeNode(effects: [HashableEffect(type: "DROP_SHADOW", radius: 8.0)])

        let hash1 = NodeHasher.computeHash(props1)
        let hash2 = NodeHasher.computeHash(props2)

        XCTAssertNotEqual(hash1, hash2)
    }

    // MARK: - Opacity and BlendMode

    func testDifferentOpacityProducesDifferentHash() {
        let props1 = makeNode(opacity: 1.0)
        let props2 = makeNode(opacity: 0.5)

        let hash1 = NodeHasher.computeHash(props1)
        let hash2 = NodeHasher.computeHash(props2)

        XCTAssertNotEqual(hash1, hash2)
    }

    // MARK: - Cross-Platform Hash Consistency

    /// Test fixture for hash consistency verification.
    /// Uses YYJSON on macOS, Foundation JSONEncoder on Linux - hashes differ by platform.
    func testCrossPlatformHashConsistency_FixtureIcon() {
        // Fixed input: a simple icon with known properties
        let props = NodeHashableProperties(
            name: "fixture-icon",
            type: "COMPONENT",
            fills: [
                HashablePaint(
                    type: "SOLID",
                    color: HashableColor(r: 0.2, g: 0.4, b: 0.6, a: 1.0)
                ),
            ],
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

        let hash = NodeHasher.computeHash(props)

        // Hashes differ by platform due to YYJSON (macOS) vs Foundation (Linux) JSON encoding
        #if os(macOS)
            XCTAssertEqual(hash, "68988f8b6635b4c7", "macOS hash mismatch")
        #else
            XCTAssertEqual(hash, "12ff28aab4c720c1", "Linux hash mismatch")
        #endif
    }

    /// Test fixture with complex nested children for hash verification.
    func testCrossPlatformHashConsistency_FixtureWithChildren() throws {
        #if os(Linux)
            throw XCTSkip("Granular cache hashes are platform-specific (YYJSON vs Foundation)")
        #endif
        let child = NodeHashableProperties(
            name: "shape",
            type: "VECTOR",
            fills: [
                HashablePaint(
                    type: "SOLID",
                    color: HashableColor(r: 1.0, g: 0.5, b: 0.0, a: 0.8)
                ),
            ],
            strokes: [
                HashablePaint(
                    type: "SOLID",
                    color: HashableColor(r: 0.0, g: 0.0, b: 0.0, a: 1.0)
                ),
            ],
            strokeWeight: 2.0,
            strokeAlign: "CENTER",
            strokeJoin: "ROUND",
            strokeCap: "ROUND",
            effects: nil,
            opacity: 1.0,
            blendMode: "NORMAL",
            clipsContent: nil,
            rotation: nil,
            children: nil
        )

        let props = NodeHashableProperties(
            name: "fixture-complex",
            type: "COMPONENT",
            fills: [],
            strokes: nil,
            strokeWeight: nil,
            strokeAlign: nil,
            strokeJoin: nil,
            strokeCap: nil,
            effects: [
                HashableEffect(
                    type: "DROP_SHADOW",
                    radius: 4.0,
                    offset: HashableVector(x: 0.0, y: 2.0),
                    color: HashableColor(r: 0.0, g: 0.0, b: 0.0, a: 0.25)
                ),
            ],
            opacity: nil,
            blendMode: nil,
            clipsContent: true,
            rotation: nil,
            children: [child]
        )

        let hash = NodeHasher.computeHash(props)

        XCTAssertEqual(hash, "2afce4b5fcc030f2", "Hash mismatch for complex node")
    }

    /// Test fixture with normalized float values for hash verification.
    func testCrossPlatformHashConsistency_FixtureNormalizedFloats() throws {
        #if os(Linux)
            throw XCTSkip("Granular cache hashes are platform-specific (YYJSON vs Foundation)")
        #endif
        // Use normalized float values (6 decimal places)
        let props = NodeHashableProperties(
            name: "float-test",
            type: "COMPONENT",
            fills: [
                HashablePaint(
                    type: "SOLID",
                    color: HashableColor(
                        r: 0.333333, // Normalized from 0.33333334
                        g: 0.666667, // Normalized from 0.66666668
                        b: 0.123457, // Normalized from 0.123456789
                        a: 1.0
                    )
                ),
            ],
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

        let hash = NodeHasher.computeHash(props)

        XCTAssertEqual(hash, "fb90b6a9927d1234", "Hash mismatch for normalized floats")
    }

    // MARK: - Helpers

    private func makeSimpleNode() -> NodeHashableProperties {
        makeNode(fills: [makePaint(r: 0.5, g: 0.5, b: 0.5)])
    }

    private func makePaint(r: Double, g: Double, b: Double, a: Double = 1.0) -> HashablePaint {
        HashablePaint(type: "SOLID", color: HashableColor(r: r, g: g, b: b, a: a))
    }

    private func makeNode(
        name: String = "icon",
        type: String = "COMPONENT",
        fills: [HashablePaint] = [],
        strokes: [HashablePaint]? = nil,
        strokeWeight: Double? = nil,
        effects: [HashableEffect]? = nil,
        opacity: Double? = nil,
        children: [NodeHashableProperties]? = nil
    ) -> NodeHashableProperties {
        NodeHashableProperties(
            name: name,
            type: type,
            fills: fills,
            strokes: strokes,
            strokeWeight: strokeWeight,
            strokeAlign: nil,
            strokeJoin: nil,
            strokeCap: nil,
            effects: effects,
            opacity: opacity,
            blendMode: nil,
            clipsContent: nil,
            rotation: nil,
            children: children
        )
    }
}
