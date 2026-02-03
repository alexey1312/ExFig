# Tasks: Add YYJSON Codec

## Phase 1: Infrastructure

- [x] Add swift-yyjson dependency to Package.swift (version 0.3.0+)
- [x] Create `Sources/ExFigCore/JSON/JSONCodec.swift` with base API
- [x] Add unit tests for JSONCodec encode/decode/encodeSorted

## Phase 2: Migration — FigmaAPI

- [x] Update `BaseEndpoint.swift`: use JSONCodec.decode()
- [x] Update `UpdateVariablesEndpoint.swift`: replace JSONEncoder with JSONCodec
- [x] Verify Figma API uses camelCase (not snake_case as assumed)
- [x] Remove unnecessary CodingKeys from Node.swift, Variables.swift
- [x] Update fixtures to camelCase format
- [x] Update FixtureLoader.swift to use standard decoder (no convertFromSnakeCase)
- [x] Update test helpers to use JSONCodec and camelCase JSON
- [x] Run FigmaAPI tests, verify all pass (217 tests passed)

**Note:** Figma API uses camelCase keys (strokeWeight, blendMode, modeId).
Only Component and Style models need CodingKeys for snake_case fields
(node_id, style_type, containing_frame, page_name).

## Phase 3: Migration — ExFig Cache

- [x] Update `ExportCheckpoint.swift`: use JSONCodec for checkpoint serialization
- [x] Update `BatchCheckpoint.swift`: use JSONCodec
- [x] Update `ImageTrackingCache.swift`: use JSONCodec
- [x] Update `NodeHasher.swift`: use JSONCodec.encodeSorted for deterministic hashing
- [x] Verify cache compatibility (existing caches should still work)

## Phase 4: Migration — Export

- [x] Update `RawExporter.swift`: use JSONCodec + YYJSONSerialization for sorted keys
- [x] Update `Batch.swift`: use JSONCodec for report output
- [x] Update `PKLEvaluator.swift`: use JSONCodec for config parsing

**Note:** XcodeColorExporter and XcodeExportExtensions don't use JSONEncoder/Decoder.

## Phase 5: Cleanup

- [x] Remove JSONDecoder.default usage from BaseEndpoint.swift
- [x] Run full test suite (1803 pass, 10 fail unrelated to JSONCodec)
- [x] Run batch export integration test (89 batch tests passed)
- [x] Update CLAUDE.md dependencies table (added swift-yyjson 0.3.0+)
