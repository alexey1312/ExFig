import Foundation
import YYJSON

/// DOM value for untyped JSON access via subscripts.
public typealias JSONValue = YYJSONValue

/// DOM object for key-value iteration.
public typealias JSONObject = YYJSONObject

/// DOM array for indexed/sequential access.
public typealias JSONArray = YYJSONArray

/// Centralized JSON codec based on YYJSON.
///
/// High-performance replacement for Foundation JSON on all platforms.
/// Use instead of direct JSONEncoder/JSONDecoder calls.
public enum JSONCodec {
    // MARK: - DOM Parsing

    /// Parse JSON data into a DOM value for untyped access.
    ///
    /// Use when the JSON structure is too dynamic for Codable.
    /// Access values via subscripts: `value["key"]?.string`, `.number`, `.array`.
    public static func parseValue(from data: Data) throws -> JSONValue {
        try JSONValue(data: data)
    }

    // MARK: - Convenience Methods

    /// Encode value to JSON data.
    public static func encode(_ value: some Encodable) throws -> Data {
        try YYJSONEncoder().encode(value)
    }

    /// Encode value to pretty-printed JSON.
    public static func encodePretty(_ value: some Encodable) throws -> Data {
        var encoder = YYJSONEncoder()
        encoder.writeOptions = [.prettyPrinted]
        return try encoder.encode(value)
    }

    /// Encode with sorted keys for deterministic output.
    ///
    /// Use for hashing where key order matters.
    public static func encodeSorted(_ value: some Encodable) throws -> Data {
        var encoder = YYJSONEncoder()
        encoder.writeOptions = [.sortedKeys]
        return try encoder.encode(value)
    }

    /// Encode with pretty-print and sorted keys.
    ///
    /// Use for Contents.json in xcassets where human-readable output
    /// with deterministic key order is needed.
    public static func encodePrettySorted(_ value: some Encodable) throws -> Data {
        var encoder = YYJSONEncoder()
        encoder.writeOptions = [.indentationTwoSpaces, .sortedKeys]
        return try encoder.encode(value)
    }

    /// Decode JSON data to type.
    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try YYJSONDecoder().decode(type, from: data)
    }

    /// Decode JSON data with ISO8601 date decoding strategy.
    public static func decodeWithISO8601Date<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        var decoder = YYJSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }

    /// Encode value with ISO8601 date encoding and pretty-print.
    ///
    /// Use for checkpoint files where dates and human-readability matter.
    public static func encodeWithISO8601DatePretty(_ value: some Encodable) throws -> Data {
        var encoder = YYJSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.writeOptions = [.prettyPrinted]
        return try encoder.encode(value)
    }
}
