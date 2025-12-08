import Foundation

public extension Double {
    /// Normalizes a floating-point value to 6 decimal places.
    ///
    /// Used for stable hashing of visual properties from Figma API.
    /// Figma may return slightly different float values for the same visual
    /// (e.g., 0.33333334 vs 0.33333333 for the same color component).
    /// Normalizing to 6 decimal places matches SVG precision and prevents
    /// false positives in change detection.
    ///
    /// Algorithm: Multiply by 1,000,000, round, divide by 1,000,000.
    ///
    /// Examples:
    /// - `0.33333334.normalized` → `0.333333`
    /// - `0.123456789.normalized` → `0.123457`
    /// - `1.0.normalized` → `1.0`
    var normalized: Double {
        (self * 1_000_000).rounded() / 1_000_000
    }
}
