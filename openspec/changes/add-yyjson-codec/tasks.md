# Tasks: Add YYJSON Codec

## Phase 1: Infrastructure

- [x] Add swift-yyjson dependency to Package.swift (version 0.3.0+)
- [x] Create `Sources/ExFigCore/JSON/JSONCodec.swift` with base API
- [x] Add unit tests for JSONCodec encode/decode/encodeSorted

## Phase 2: Migration — FigmaAPI

- [x] Update `BaseEndpoint.swift`: use JSONCodec.decode()
- [x] Update `UpdateVariablesEndpoint.swift`: replace JSONEncoder with JSONCodec
- [x] Add explicit CodingKeys to Variables.swift models
- [ ] Add explicit CodingKeys to Node.swift models (TypeStyle, etc.)
- [ ] Add explicit CodingKeys to Style.swift models
- [ ] Add explicit CodingKeys to remaining models with snake_case fields
- [ ] Update FixtureLoader.swift to not use convertFromSnakeCase
- [ ] Run FigmaAPI tests, verify all pass

**Note:** YYJSON limitation discovered - keyDecodingStrategy doesn't recursively
apply to nested structures inside arrays within dictionaries. Solution: use
explicit CodingKeys in all models.

## Phase 3: Migration — ExFig Cache

- [ ] Update `ExportCheckpoint.swift`: use JSONCodec for checkpoint serialization
- [ ] Update `BatchCheckpoint.swift`: use JSONCodec
- [ ] Update `ImageTrackingCache.swift`: use JSONCodec
- [ ] Update `NodeHasher.swift`: use JSONCodec.encodeSorted for deterministic hashing
- [ ] Verify cache compatibility (existing caches should still work)

## Phase 4: Migration — Export

- [ ] Update `XcodeColorExporter.swift`: use JSONCodec for Contents.json
- [ ] Update `XcodeExportExtensions.swift`: use JSONCodec
- [ ] Update `RawExporter.swift`: use JSONCodec
- [ ] Update `Batch.swift`: use JSONCodec for debug output

## Phase 5: Cleanup

- [x] Remove JSONDecoder.default usage from BaseEndpoint.swift
- [ ] Run full test suite
- [ ] Run batch export integration test
- [ ] Update CLAUDE.md dependencies table
