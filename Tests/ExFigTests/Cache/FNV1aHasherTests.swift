@testable import ExFig
import ExFigKit
import XCTest

final class FNV1aHasherTests: XCTestCase {
    // MARK: - Known Test Vectors

    /// Test vectors verified against reference implementations.
    /// FNV-1a 64-bit uses:
    /// - Offset basis: 0xcbf29ce484222325
    /// - Prime: 0x100000001b3
    func testKnownTestVectors() {
        // Empty string should return offset basis
        XCTAssertEqual(FNV1aHasher.hash(Data()), 0xCBF2_9CE4_8422_2325)

        // Single character test vectors (verified against C reference)
        XCTAssertEqual(FNV1aHasher.hash(Data("a".utf8)), 0xAF63_DC4C_8601_EC8C)
        XCTAssertEqual(FNV1aHasher.hash(Data("b".utf8)), 0xAF63_DF4C_8601_F1A5)
        XCTAssertEqual(FNV1aHasher.hash(Data("c".utf8)), 0xAF63_DE4C_8601_EFF2)

        // Multi-character test vectors
        XCTAssertEqual(FNV1aHasher.hash(Data("foobar".utf8)), 0x8594_4171_F739_67E8)
    }

    // MARK: - Deterministic Output

    func testDeterministicOutputForSameInput() {
        let input = Data("test input for determinism".utf8)

        let hash1 = FNV1aHasher.hash(input)
        let hash2 = FNV1aHasher.hash(input)
        let hash3 = FNV1aHasher.hash(input)

        XCTAssertEqual(hash1, hash2)
        XCTAssertEqual(hash2, hash3)
    }

    func testDeterministicOutputForJSONData() {
        let json = """
        {"name":"icon","fills":[{"r":0.5,"g":0.5,"b":0.5,"a":1.0}]}
        """
        let input = Data(json.utf8)

        let hash1 = FNV1aHasher.hash(input)
        let hash2 = FNV1aHasher.hash(input)

        XCTAssertEqual(hash1, hash2)
    }

    // MARK: - Avalanche Property

    func testDifferentOutputForDifferentInputs() {
        let input1 = Data("input1".utf8)
        let input2 = Data("input2".utf8)
        let input3 = Data("Input1".utf8) // Case difference

        let hash1 = FNV1aHasher.hash(input1)
        let hash2 = FNV1aHasher.hash(input2)
        let hash3 = FNV1aHasher.hash(input3)

        XCTAssertNotEqual(hash1, hash2)
        XCTAssertNotEqual(hash1, hash3)
        XCTAssertNotEqual(hash2, hash3)
    }

    func testSingleBitDifferenceProducesDifferentHash() {
        // "a" vs "b" differ by single bit change
        let hashA = FNV1aHasher.hash(Data("a".utf8))
        let hashB = FNV1aHasher.hash(Data("b".utf8))

        XCTAssertNotEqual(hashA, hashB)

        // For longer inputs, verify significant bit difference (avalanche)
        // FNV-1a shows better avalanche with longer inputs
        let hashLong1 = FNV1aHasher.hash(Data("test-input-string-a".utf8))
        let hashLong2 = FNV1aHasher.hash(Data("test-input-string-b".utf8))

        let xorDiff = hashLong1 ^ hashLong2
        let bitDifference = xorDiff.nonzeroBitCount
        // With longer inputs, FNV-1a shows better avalanche
        XCTAssertGreaterThan(bitDifference, 5, "Hash should have reasonable avalanche property")
    }

    // MARK: - Empty Data Handling

    func testEmptyDataReturnsOffsetBasis() {
        let hash = FNV1aHasher.hash(Data())

        // FNV-1a 64-bit offset basis
        XCTAssertEqual(hash, 0xCBF2_9CE4_8422_2325)
    }

    // MARK: - Hex String Output

    func testHashToHexReturns16Characters() {
        let input = Data("test".utf8)

        let hex = FNV1aHasher.hashToHex(input)

        XCTAssertEqual(hex.count, 16)
    }

    func testHashToHexProducesValidHexString() {
        let input = Data("test".utf8)

        let hex = FNV1aHasher.hashToHex(input)

        // Should only contain hex characters
        let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdef")
        XCTAssertTrue(
            hex.unicodeScalars.allSatisfy { hexCharacterSet.contains($0) },
            "Hex string should only contain lowercase hex characters"
        )
    }

    func testHashToHexIsDeterministic() {
        let input = Data("determinism test".utf8)

        let hex1 = FNV1aHasher.hashToHex(input)
        let hex2 = FNV1aHasher.hashToHex(input)

        XCTAssertEqual(hex1, hex2)
    }

    func testHashToHexKnownValues() {
        // Empty string hex
        XCTAssertEqual(FNV1aHasher.hashToHex(Data()), "cbf29ce484222325")

        // "foobar" hex
        XCTAssertEqual(FNV1aHasher.hashToHex(Data("foobar".utf8)), "85944171f73967e8")
    }

    // MARK: - Large Data

    func testLargeDataHashesCorrectly() {
        // Create 1MB of data
        let largeData = Data(repeating: 0x42, count: 1_000_000)

        let hash = FNV1aHasher.hash(largeData)

        // Should not be offset basis (data was processed)
        XCTAssertNotEqual(hash, 0xCBF2_9CE4_8422_2325)

        // Should be deterministic
        let hash2 = FNV1aHasher.hash(largeData)
        XCTAssertEqual(hash, hash2)
    }

    // MARK: - Unicode Handling

    func testUnicodeStringsHashCorrectly() {
        let emoji = Data("🎨🖼️".utf8)
        let cyrillic = Data("привет".utf8)
        let chinese = Data("你好".utf8)

        // All should produce valid hashes
        let hashEmoji = FNV1aHasher.hash(emoji)
        let hashCyrillic = FNV1aHasher.hash(cyrillic)
        let hashChinese = FNV1aHasher.hash(chinese)

        // All should be different
        XCTAssertNotEqual(hashEmoji, hashCyrillic)
        XCTAssertNotEqual(hashCyrillic, hashChinese)
        XCTAssertNotEqual(hashEmoji, hashChinese)
    }
}
