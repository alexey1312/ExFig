# Tasks: Granular Node-Level Cache Tracking

> **Development approach:** TDD (Test-Driven Development) - write tests BEFORE implementation.

## 1. FNV-1a Hasher (TDD)

- [x] 1.1 **TEST FIRST:** Create `FNV1aHasherTests.swift` with test cases:
  - Known test vectors (verify against reference implementation)
  - Deterministic output for same input
  - Different output for different inputs (avalanche property)
  - Empty data handling
  - Cross-platform consistency (compare with Linux CI)
- [x] 1.2 Create `FNV1aHasher.swift` with pure Swift implementation
- [x] 1.3 Add `hashToHex()` method returning 16-char hex string

## 2. Float Normalization (TDD)

- [x] 2.1 **TEST FIRST:** Create `FloatNormalizationTests.swift`:
  - `0.33333334.normalized` == `0.33333333.normalized`
  - `0.123456789.normalized` == `0.123457` (6 decimal places)
  - Negative values work correctly
  - Zero and one are stable
- [x] 2.2 Add `Double.normalized` extension

## 3. NodeHashableProperties Model (TDD)

- [x] 3.1 **TEST FIRST:** Create `NodeHashablePropertiesTests.swift`:
  - Encoding produces sorted keys JSON
  - Children are included recursively
  - `boundVariables` is excluded
  - `absoluteBoundingBox` is excluded
  - Float values are normalized before encoding
- [x] 3.2 Create `NodeHashableProperties.swift` in FigmaAPI module
- [x] 3.3 Add initializer from existing `Node`/`Document` types
- [x] 3.4 Add recursive `children` mapping

## 4. NodeHasher (TDD)

- [x] 4.1 **TEST FIRST:** Create `NodeHasherTests.swift`:
  - Same node produces same hash
  - Different fills produce different hash
  - Different strokes produce different hash
  - Different children produce different hash
  - Position change does NOT change hash
  - Name change DOES change hash
- [x] 4.2 Create `NodeHasher.swift` combining FNV-1a + NodeHashableProperties
- [x] 4.3 Add `computeHash(node:) -> String` method
- [x] 4.4 Verify tests pass on both macOS and Linux

## 5. Cache Model Extension (TDD)

- [x] 5.1 **TEST FIRST:** Create tests for schema migration v1 → v2
  - Existing `files` data preserved
  - `nodeHashes` initialized as empty
  - Schema version updated to 2
- [x] 5.2 **TEST FIRST:** Create tests for `changedNodeIds()` method
  - Returns all IDs when no cached hashes
  - Returns empty when all hashes match
  - Returns only changed IDs when some differ
  - Returns new IDs not in cache
  - Excludes deleted IDs from result
- [x] 5.3 Add `nodeHashes: [String: String]?` to `CachedFileInfo`
- [x] 5.4 Implement schema migration (preserve existing data)
- [x] 5.5 Add `changedNodeIds(fileId:currentHashes:)` method
- [x] 5.6 Add `updateNodeHashes(fileId:hashes:)` method
- [x] 5.7 Add `clearNodeHashes(fileId:)` for `--force` flag

## 6. CLI Flag

- [x] 6.1 Add `--experimental-granular-cache` flag to `CacheOptions.swift`
- [x] 6.2 Add validation: warn if used without `--cache`
- [x] 6.3 Add flag description to `--help` output
- [x] 6.4 Add to `ExFigWarning` enum: `.granularCacheWithoutCache`

## 7. FigmaAPI Model Extension

- [x] 7.1 Extend `Document` model to decode additional visual properties:
  - `strokes: [Paint]?`
  - `strokeWeight: Double?`
  - `strokeAlign: String?`
  - `strokeJoin: String?`
  - `strokeCap: String?`
  - `effects: [Effect]?`
  - `opacity: Double?`
  - `blendMode: String?`
  - `clipsContent: Bool?`
  - `children: [Document]?`
- [x] 7.2 Create `Effect` model (shadows, blurs)
- [x] 7.3 Verify existing endpoints return these fields (they should with current depth)
- [x] 7.4 Add `toHashableProperties()` conversion method to `Document`
- [x] 7.5 Move `FloatNormalization` to FigmaAPI module (shared dependency)

## 8. Loader Integration (TDD)

- [x] 8.1 **TEST FIRST:** Integration test - granular cache hit (all hashes match)
- [x] 8.2 **TEST FIRST:** Integration test - partial change detection (3 of 100 changed)
- [x] 8.3 **TEST FIRST:** Integration test - first run populates hashes
- [x] 8.4 **TEST FIRST:** Integration test - deleted node cleanup
- [x] 8.5 Create `GranularCacheManager` for per-node hash tracking
- [x] 8.6 Add `fetchImageComponentsWithGranularCache()` to `ImageLoaderBase`
- [x] 8.7 Wire up granular cache in `ExportIcons` command
- [x] 8.8 Wire up granular cache in `ExportImages` command
- [x] 8.9 Update cache with node hashes after successful export

## 9. Documentation

- [x] 9.1 Update `CLAUDE.md` with granular cache section:
  - Flag description and usage
  - Known limitations (config changes require `--force`)
  - Performance expectations
- [x] 9.2 Add inline documentation to `NodeHasher.swift` explaining:
  - Algorithm choice (FNV-1a)
  - Float normalization rationale
  - Recursive hashing strategy
- [x] 9.3 Update `.claude/EXFIG.toon` with new flag and types

## 10. Cross-Platform Verification

- [x] 10.1 Run full test suite on macOS
- [x] 10.2 Run full test suite on Linux (CI)
- [x] 10.3 Add specific hash consistency test with fixture:
  - Same JSON input on macOS and Linux must produce identical hash
  - Add test fixture file with known input/output pairs

## Acceptance Criteria

- [x] All tests pass on macOS (1307 tests)
- [x] All tests pass on Linux (CI)
- [x] `mise run lint` passes
- [x] `mise run format` passes
- [x] No new external dependencies added (pure Swift FNV-1a)
- [x] Backward compatible with schema v1 cache files
- [x] `--force` flag clears node hashes and triggers full export
- [x] Deleted nodes are cleaned from cache silently
