@testable import FigmaAPI
import XCTest

final class FloatNormalizationTests: XCTestCase {
    // MARK: - Precision Drift Handling

    func testNormalizationHandlesPrecisionDrift() {
        // Figma API may return slightly different float values for same color
        // These should normalize to the same value
        let value1 = 0.33333334
        let value2 = 0.33333333

        XCTAssertEqual(value1.normalized, value2.normalized)
    }

    func testNormalizationTo6DecimalPlaces() {
        // Should round to 6 decimal places
        XCTAssertEqual(0.123456789.normalized, 0.123457, accuracy: 0.0000001)
        XCTAssertEqual(0.123456.normalized, 0.123456, accuracy: 0.0000001)
        XCTAssertEqual(0.1234564.normalized, 0.123456, accuracy: 0.0000001)
        XCTAssertEqual(0.1234565.normalized, 0.123457, accuracy: 0.0000001)
    }

    // MARK: - Negative Values

    func testNegativeValuesNormalizeCorrectly() {
        XCTAssertEqual((-0.123456789).normalized, -0.123457, accuracy: 0.0000001)
        XCTAssertEqual((-0.5).normalized, -0.5, accuracy: 0.0000001)
    }

    func testNegativePrecisionDrift() {
        let value1 = -0.66666667
        let value2 = -0.66666666

        XCTAssertEqual(value1.normalized, value2.normalized)
    }

    // MARK: - Special Values

    func testZeroIsStable() {
        XCTAssertEqual(0.0.normalized, 0.0)
        XCTAssertEqual((-0.0).normalized, 0.0)
    }

    func testOneIsStable() {
        XCTAssertEqual(1.0.normalized, 1.0)
        XCTAssertEqual(1.0000001.normalized, 1.0)
    }

    func testCommonColorValues() {
        // Common color values should be stable
        XCTAssertEqual(0.5.normalized, 0.5)
        XCTAssertEqual(0.25.normalized, 0.25)
        XCTAssertEqual(0.75.normalized, 0.75)
        XCTAssertEqual(0.333333.normalized, 0.333333)
    }

    // MARK: - Edge Cases

    func testVerySmallValues() {
        // Values below 6 decimal precision should round to 0
        XCTAssertEqual(0.0000001.normalized, 0.0, accuracy: 0.0000001)
        XCTAssertEqual(0.0000009.normalized, 0.000001, accuracy: 0.0000001)
    }

    func testLargeValues() {
        // Large values should also normalize correctly
        XCTAssertEqual(100.123456789.normalized, 100.123457, accuracy: 0.0000001)
        XCTAssertEqual(9999.999999.normalized, 9999.999999, accuracy: 0.0000001)
        XCTAssertEqual(9999.9999999.normalized, 10000.0, accuracy: 0.0000001)
    }

    // MARK: - Determinism

    func testNormalizationIsDeterministic() {
        let value = 0.123456789

        let normalized1 = value.normalized
        let normalized2 = value.normalized
        let normalized3 = value.normalized

        XCTAssertEqual(normalized1, normalized2)
        XCTAssertEqual(normalized2, normalized3)
    }

    func testNormalizationIsIdempotent() {
        let value = 0.123456789

        let onceNormalized = value.normalized
        let twiceNormalized = onceNormalized.normalized

        XCTAssertEqual(onceNormalized, twiceNormalized)
    }
}
