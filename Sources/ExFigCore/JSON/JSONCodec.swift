import Foundation

#if canImport(YYJSON)
    import YYJSON
#endif

/// Centralized JSON codec based on YYJSON (macOS) or Foundation (Linux).
///
/// Provides high-performance replacement for Foundation JSON on macOS.
/// Falls back to standard JSONEncoder/JSONDecoder on Linux.
/// Use instead of direct JSONEncoder/JSONDecoder calls.
public enum JSONCodec {
    // MARK: - Convenience Methods

    /// Encode value to JSON data.
    public static func encode(_ value: some Encodable) throws -> Data {
        #if canImport(YYJSON)
            try YYJSONEncoder().encode(value)
        #else
            try JSONEncoder().encode(value)
        #endif
    }

    /// Encode value to pretty-printed JSON.
    public static func encodePretty(_ value: some Encodable) throws -> Data {
        #if canImport(YYJSON)
            var encoder = YYJSONEncoder()
            encoder.writeOptions = [.prettyPrinted]
            return try encoder.encode(value)
        #else
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            return try encoder.encode(value)
        #endif
    }

    /// Encode with sorted keys for deterministic output.
    ///
    /// Use for hashing where key order matters.
    public static func encodeSorted(_ value: some Encodable) throws -> Data {
        #if canImport(YYJSON)
            var encoder = YYJSONEncoder()
            encoder.writeOptions = [.sortedKeys]
            return try encoder.encode(value)
        #else
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            return try encoder.encode(value)
        #endif
    }

    /// Encode with pretty-print and sorted keys.
    ///
    /// Use for Contents.json in xcassets where human-readable output
    /// with deterministic key order is needed.
    public static func encodePrettySorted(_ value: some Encodable) throws -> Data {
        #if canImport(YYJSON)
            var encoder = YYJSONEncoder()
            encoder.writeOptions = [.prettyPrintedTwoSpaces, .sortedKeys]
            return try encoder.encode(value)
        #else
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return try encoder.encode(value)
        #endif
    }

    /// Decode JSON data to type.
    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        #if canImport(YYJSON)
            try YYJSONDecoder().decode(type, from: data)
        #else
            try JSONDecoder().decode(type, from: data)
        #endif
    }

    /// Decode JSON data with ISO8601 date decoding strategy.
    public static func decodeWithISO8601Date<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        #if canImport(YYJSON)
            var decoder = YYJSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        #else
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        #endif
    }

    /// Encode value with ISO8601 date encoding and pretty-print.
    ///
    /// Use for checkpoint files where dates and human-readability matter.
    public static func encodeWithISO8601DatePretty(_ value: some Encodable) throws -> Data {
        #if canImport(YYJSON)
            var encoder = YYJSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.writeOptions = [.prettyPrinted]
            return try encoder.encode(value)
        #else
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted]
            return try encoder.encode(value)
        #endif
    }
}
