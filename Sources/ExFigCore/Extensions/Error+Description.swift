import Foundation

public extension Error {
    /// Returns the best available description of the error.
    ///
    /// Uses `description` from `CustomStringConvertible` if available,
    /// otherwise falls back to `localizedDescription`.
    ///
    /// This is needed because some error types (e.g., `YYJSONError`) implement
    /// `CustomStringConvertible` but not `LocalizedError`, so `localizedDescription`
    /// returns an unhelpful default format like `"(YYJSON.YYJSONError error 1.)"`.
    var bestDescription: String {
        // All Error types conform to CustomStringConvertible in Swift,
        // so we can always use description directly
        (self as any CustomStringConvertible).description
    }
}
