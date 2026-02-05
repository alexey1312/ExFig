# json-codec Specification

## Purpose

Provide high-performance JSON encoding/decoding via YYJSON, replacing Foundation's JSONEncoder/JSONDecoder throughout the codebase for improved performance and deterministic output.

## Requirements

### Requirement: JSONCodec SHALL provide high-performance JSON encoding

The system MUST provide a centralized `JSONCodec` enum in ExFigCore module that wraps swift-yyjson for high-performance JSON operations.

#### Scenario: Encode a Codable value to JSON data

- **Given** a value conforming to `Encodable`
- **When** calling `JSONCodec.encode(value)`
- **Then** returns JSON `Data` representation

#### Scenario: Encode with pretty printing

- **Given** a value conforming to `Encodable`
- **When** calling `JSONCodec.encodePretty(value)`
- **Then** returns human-readable JSON with indentation

#### Scenario: Encode with sorted keys for deterministic output

- **Given** a value conforming to `Encodable`
- **When** calling `JSONCodec.encodeSorted(value)`
- **Then** returns JSON with keys sorted alphabetically
- **And** calling multiple times produces identical output

#### Scenario: Encode with pretty printing and sorted keys

- **Given** a value conforming to `Encodable`
- **When** calling `JSONCodec.encodePrettySorted(value)`
- **Then** returns human-readable JSON with indentation and sorted keys
- **And** suitable for Contents.json in xcassets

---

### Requirement: JSONCodec SHALL provide high-performance JSON decoding

The system MUST decode JSON data using YYJSON backend.

#### Scenario: Decode JSON data to a type

- **Given** valid JSON `Data`
- **And** a target type conforming to `Decodable`
- **When** calling `JSONCodec.decode(Type.self, from: data)`
- **Then** returns decoded value

#### Scenario: Decode Figma API responses using explicit CodingKeys

- **Given** Figma API models with snake_case fields (e.g., `node_id`, `style_type`)
- **When** models define explicit `CodingKeys` enum with string raw values
- **Then** `JSONCodec.decode()` maps snake_case JSON keys to camelCase properties
- **Note** This approach is preferred over global `keyDecodingStrategy` for reliability

---

### Requirement: JSONCodec MUST replace Foundation JSON in all modules

All existing `JSONEncoder`/`JSONDecoder` usages MUST migrate to `JSONCodec`.

#### Scenario: FigmaAPI decodes responses via JSONCodec

- **Given** a Figma API response
- **When** `BaseEndpoint` processes the response
- **Then** uses `JSONCodec.decode()` with models using explicit `CodingKeys`

#### Scenario: Cache serialization uses JSONCodec

- **Given** checkpoint or tracking data to persist
- **When** `ExportCheckpoint`, `BatchCheckpoint`, or `ImageTrackingCache` saves/loads
- **Then** uses `JSONCodec.encode()`/`JSONCodec.decode()`

#### Scenario: NodeHasher uses sorted keys for stable hashes

- **Given** a node to hash
- **When** `NodeHasher` serializes node properties
- **Then** uses `JSONCodec.encodeSorted()` for deterministic output
- **And** same node always produces same hash

#### Scenario: Xcode export uses JSONCodec for Contents.json

- **Given** xcassets Contents.json generation
- **When** `XcodeColorExporter` or `XcodeExportExtensions` creates JSON
- **Then** uses `JSONCodec.encodePrettySorted()`
