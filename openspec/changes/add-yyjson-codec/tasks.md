# Tasks: Add YYJSON Codec

## Phase 1: Infrastructure

- [ ] Add swift-yyjson dependency to Package.swift (version 0.3.0+)
- [ ] Create `Sources/ExFigCore/JSON/JSONCodec.swift` with base API
- [ ] Add unit tests for JSONCodec encode/decode/encodeSorted

## Phase 2: Migration — FigmaAPI

- [ ] Update `BaseEndpoint.swift`: replace `JSONDecoder.default` with `JSONCodec.makeDecoder()`
- [ ] Update `UpdateVariablesEndpoint.swift`: replace JSONEncoder with JSONCodec
- [ ] Run FigmaAPI tests, verify API responses decode correctly

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

- [ ] Remove `JSONDecoder.default` extension from BaseEndpoint.swift
- [ ] Run full test suite
- [ ] Run batch export integration test
- [ ] Update CLAUDE.md dependencies table
