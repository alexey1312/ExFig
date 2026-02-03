import Foundation
import YYJSON

/// Centralized JSON codec based on YYJSON.
///
/// Provides high-performance replacement for Foundation JSON.
/// Use instead of direct JSONEncoder/JSONDecoder calls.
public enum JSONCodec {
    // MARK: - Factory Methods

    /// Create encoder with default settings.
    public static func makeEncoder() -> YYJSONEncoder {
        YYJSONEncoder()
    }

    /// Create encoder with pretty-print.
    public static func makePrettyEncoder() -> YYJSONEncoder {
        var encoder = YYJSONEncoder()
        encoder.writeOptions = [.prettyPrinted]
        return encoder
    }

    /// Create decoder with default settings.
    public static func makeDecoder() -> YYJSONDecoder {
        YYJSONDecoder()
    }

    // MARK: - Convenience Methods

    /// Encode value to JSON data.
    public static func encode(_ value: some Encodable) throws -> Data {
        try makeEncoder().encode(value)
    }

    /// Encode value to pretty-printed JSON.
    public static func encodePretty(_ value: some Encodable) throws -> Data {
        try makePrettyEncoder().encode(value)
    }

    /// Encode with sorted keys for deterministic output.
    ///
    /// Use for hashing where key order matters.
    /// YYJSONEncoder doesn't support sortedKeys directly, so we use two-step approach:
    /// 1. Encode → Data
    /// 2. Parse → Object → Serialize with sortedKeys
    public static func encodeSorted(_ value: some Encodable) throws -> Data {
        let data = try makeEncoder().encode(value)
        let object = try YYJSONSerialization.jsonObject(with: data)
        return try YYJSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    /// Decode JSON data to type.
    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try makeDecoder().decode(type, from: data)
    }
}
