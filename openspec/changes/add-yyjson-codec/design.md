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

/// Централизованный JSON кодек на основе YYJSON.
///
/// Предоставляет высокопроизводительную замену Foundation JSON.
/// Использовать вместо прямых вызовов JSONEncoder/JSONDecoder.
public enum JSONCodec {

    // MARK: - Factory Methods

    /// Создать encoder с настройками по умолчанию.
    public static func makeEncoder() -> YYJSONEncoder {
        YYJSONEncoder()
    }

    /// Создать encoder с pretty-print.
    public static func makePrettyEncoder() -> YYJSONEncoder {
        var encoder = YYJSONEncoder()
        encoder.writeOptions = [.prettyPrinted]
        return encoder
    }

    /// Создать decoder с настройками по умолчанию.
    public static func makeDecoder() -> YYJSONDecoder {
        YYJSONDecoder()
    }

    /// Создать decoder для Figma API (snake_case → camelCase).
    public static func makeFigmaDecoder() -> YYJSONDecoder {
        var decoder = YYJSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    // MARK: - Convenience Methods

    /// Encode значение в JSON data.
    public static func encode(_ value: some Encodable) throws -> Data {
        try makeEncoder().encode(value)
    }

    /// Encode значение в pretty-printed JSON.
    public static func encodePretty(_ value: some Encodable) throws -> Data {
        try makePrettyEncoder().encode(value)
    }

    /// Encode с sorted keys для детерминированного вывода.
    ///
    /// Использовать для хэширования, где порядок ключей важен.
    public static func encodeSorted(_ value: some Encodable) throws -> Data {
        let data = try makeEncoder().encode(value)
        let object = try YYJSONSerialization.jsonObject(with: data)
        return try YYJSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    /// Decode JSON data в тип.
    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try makeDecoder().decode(type, from: data)
    }

    /// Decode JSON data с Figma key strategy.
    public static func decodeFigma<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try makeFigmaDecoder().decode(type, from: data)
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
// Decode (Figma API)
let result = try JSONCodec.decodeFigma(Response.self, from: data)

// Decode (general)
let result = try JSONCodec.decode(Response.self, from: data)

// Encode
let data = try JSONCodec.encode(value)
let prettyData = try JSONCodec.encodePretty(value)

// Encode sorted (for hashing)
let hashableData = try JSONCodec.encodeSorted(value)
```

## Key Considerations

### 1. Figma API Decoder

Figma API использует snake_case. Создаём отдельный `makeFigmaDecoder()` с `.convertFromSnakeCase`.

### 2. Sorted Keys для Hashing

`NodeHasher` требует детерминированный JSON для стабильных хэшей.
YYJSON не поддерживает sorted keys напрямую в encoder, поэтому используем two-step:

1. Encode → Data
2. Parse → Object → Serialize with sortedKeys

### 3. Linux Compatibility

swift-yyjson поддерживает Linux. Не требует `#if canImport(FoundationNetworking)`.

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
