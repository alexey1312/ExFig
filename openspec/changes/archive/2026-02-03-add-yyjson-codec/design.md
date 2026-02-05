# Design: YYJSON Codec

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  FigmaAPI   │     │    ExFig    │     │ XcodeExport │
│  (decode)   │     │   (cache)   │     │  (encode)   │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           ▼
                    ┌─────────────┐
                    │  JSONCodec  │
                    │ (ExFigCore) │
                    └──────┬──────┘
                           ▼
                    ┌─────────────┐
                    │ swift-yyjson│
                    └─────────────┘
```

## JSONCodec Implementation

```swift
// Sources/ExFigCore/JSON/JSONCodec.swift

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
```

## Migration Patterns

### Before (Foundation)

```swift
// Decode
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
let result = try decoder.decode(Response.self, from: data)

// Encode
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let data = try encoder.encode(value)
```

### After (JSONCodec)

```swift
// Decode
let result = try JSONCodec.decode(Response.self, from: data)

// Encode
let data = try JSONCodec.encode(value)
let prettyData = try JSONCodec.encodePretty(value)

// Encode sorted (for hashing)
let hashableData = try JSONCodec.encodeSorted(value)
```

## Key Considerations

### 1. Figma API Models

Figma API uses snake_case in JSON. Instead of global `keyDecodingStrategy = .convertFromSnakeCase`,
we use explicit `CodingKeys` in models — more reliable and explicit:

```swift
// Example: Sources/FigmaAPI/Model/Style.swift
public struct Style: Codable, Sendable {
    public let key: String
    public let name: String
    public let styleType: StyleType

    private enum CodingKeys: String, CodingKey {
        case key, name
        case styleType = "style_type"
    }
}
```

Benefits of explicit `CodingKeys`:

- Works with any decoder (Foundation, YYJSON)
- Field mapping is visible in the model
- Doesn't break when adding new fields

### 2. Sorted Keys for Hashing

`NodeHasher` requires deterministic JSON for stable hashes.
YYJSON doesn't support sorted keys directly in encoder, so we use two-step approach:

1. Encode → Data
2. Parse → Object → Serialize with sortedKeys

### 3. Linux Compatibility

swift-yyjson supports Linux. No `#if canImport(FoundationNetworking)` required.

## Dependencies Update

```swift
// Package.swift
dependencies: [
    // ... existing
    .package(url: "https://github.com/mattt/swift-yyjson.git", from: "0.3.0"),
],

// ExFigCore target
.target(
    name: "ExFigCore",
    dependencies: [
        .product(name: "YYJSON", package: "swift-yyjson"),
    ]
),
```

## Testing Strategy

1. **Unit tests**: JSONCodec encode/decode round-trip
2. **Compatibility**: Verify existing cache files still readable
3. **Integration**: Batch export with new codec
4. **Hashing**: Verify NodeHasher produces same hashes
