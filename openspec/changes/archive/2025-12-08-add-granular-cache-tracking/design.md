# Design: Granular Node-Level Cache Tracking

## Context

Figma REST API provides only file-level change detection:

| Field          | Scope | Behavior                                         |
| -------------- | ----- | ------------------------------------------------ |
| `version`      | File  | Changes on library publish or manual version     |
| `lastModified` | File  | Changes on ANY edit (even auto-saves)            |
| Node `id`      | Node  | Stable identifier, no change tracking            |
| Node props     | Node  | JSON properties - must hash locally for tracking |

**Key limitation:** No per-node `hash`, `updatedAt`, or `version` fields exist. We must compute hashes locally.

## Prior Art

### Existing Tools - No Granular Caching

| Tool                     | File Cache | Node Hash | Content Hash | Granular Export |
| ------------------------ | ---------- | --------- | ------------ | --------------- |
| RedMadRobot/figma-export | ❌         | ❌        | ❌           | ❌              |
| @figma-export/cli        | ❌         | ❌        | ❌           | ❌              |
| Figmagic                 | ❌         | ❌        | ❌           | ❌              |
| iAdvize (custom)         | ❌         | ❌        | ✅ SVG       | ❌              |
| **ExFig (current)**      | ✅         | ❌        | ❌           | ❌              |
| **ExFig (proposed)**     | ✅         | ✅        | ❌           | ✅              |

**Key findings:**

- All public tools perform **full export every run** - no incremental capability
- iAdvize hashes **downloaded SVG content** for CDN versioning (not for skipping downloads)
- No tool hashes **node JSON before download** to decide what to fetch

### iAdvize Content Hash Approach

```
1. Download ALL SVGs from Figma API
2. Hash SVG content → use as filename (icon_a1b2c3.svg)
3. Purpose: CDN cache-busting, not export optimization
```

**Limitation:** Must download everything first to compute hashes.

### Our Node JSON Hash Approach

```
1. Fetch components list (GET /v1/files/:key/components) - existing call
2. Fetch node details (GET /v1/files/:key/nodes?ids=...) - existing call, already fetches full tree
3. Hash node properties locally (FNV-1a, ~2 GB/s)
4. Compare with cached hashes
5. Download ONLY changed nodes (GET /v1/images/:key?ids=changed)
```

**Advantage:** Skip image downloads entirely for unchanged nodes.

### API Call Analysis

**Current flow (without granular cache):**

| Step | API Call                           | Data                          |
| ---- | ---------------------------------- | ----------------------------- |
| 1    | `GET /v1/files/:key/components`    | Component list (name, nodeId) |
| 2    | `GET /v1/files/:key/nodes?ids=...` | Full node tree with children  |
| 3    | `GET /v1/images/:key?ids=...`      | Image URLs (batched)          |

**Proposed flow (with granular cache):**

| Step | API Call                           | Data                             |
| ---- | ---------------------------------- | -------------------------------- |
| 1    | `GET /v1/files/:key/components`    | Component list (existing)        |
| 2    | `GET /v1/files/:key/nodes?ids=...` | Full node tree (existing, reuse) |
| 3    | Compute hashes locally             | FNV-1a of visual properties      |
| 4    | Compare with cache                 | Dictionary lookup                |
| 5    | `GET /v1/images/:key?ids=changed`  | Only changed images              |

**Key insight:** No additional API call needed! The existing `nodes` endpoint already returns full tree with children.

## Node Structure Analysis

Based on real Figma API responses for icons and illustrations:

### Icons (simple, ~20 children)

```yaml
type: COMPONENT
name: "indrive"
children:
  - type: VECTOR
    name: "shape"
    fills: [{type: SOLID, color: {r, g, b, a}}]
    strokes: []
    strokeWeight: 0.25
```

### Illustrations (complex, 20+ children with deep nesting)

```yaml
type: COMPONENT
name: "inlocal-intro-geo-color"
children[23]:
  - type: VECTOR
    fills: [{type: SOLID, color: {r, g, b, a}}]
    boundVariables:
      fills: [{type: VARIABLE_ALIAS, id: "VariableID:..."}]
  - type: GROUP
    children[12]:
      - type: VECTOR
        strokes: [{type: SOLID, color: {...}}]
        strokeWeight: 1
        strokeAlign: CENTER
        strokeJoin: ROUND
        strokeCap: ROUND
```

### Properties That Affect Visual Output

| Property               | Affects Export            | Include in Hash     |
| ---------------------- | ------------------------- | ------------------- |
| `fills`                | ✅ Yes                    | ✅ Yes              |
| `strokes`              | ✅ Yes                    | ✅ Yes              |
| `strokeWeight`         | ✅ Yes                    | ✅ Yes              |
| `strokeAlign`          | ✅ Yes                    | ✅ Yes              |
| `strokeJoin`           | ✅ Yes                    | ✅ Yes              |
| `strokeCap`            | ✅ Yes                    | ✅ Yes              |
| `effects`              | ✅ Yes                    | ✅ Yes              |
| `opacity`              | ✅ Yes                    | ✅ Yes              |
| `blendMode`            | ✅ Yes                    | ✅ Yes              |
| `children`             | ✅ Yes                    | ✅ Recursive        |
| `boundVariables`       | ❌ No (resolved in fills) | ❌ No               |
| `absoluteBoundingBox`  | ❌ No (position only)     | ❌ No               |
| `absoluteRenderBounds` | ❌ No (computed)          | ❌ No               |
| `constraints`          | ❌ No (layout only)       | ❌ No               |
| `interactions`         | ❌ No                     | ❌ No               |
| `pluginData`           | ❌ No                     | ❌ No               |
| `name`                 | ⚠️ Partial                 | ✅ Yes (for naming) |
| `type`                 | ⚠️ Indirect                | ✅ Yes (structure)  |

## Reliability Analysis

### Hash Collision Probability

FNV-1a 64-bit collision probability for change detection:

| Scenario            | Nodes  | Collision Probability | Risk Level |
| ------------------- | ------ | --------------------- | ---------- |
| Small project       | 100    | ~2.7 × 10⁻¹⁶          | Negligible |
| Medium project      | 1,000  | ~2.7 × 10⁻¹⁴          | Negligible |
| Large design system | 10,000 | ~2.7 × 10⁻¹²          | Negligible |
| Extreme (birthday)  | 10⁹    | ~2.7 × 10⁻²           | Still low  |

**Conclusion:** For change detection (not security), 64-bit hash is reliable. Even with 10,000 icons, collision
probability is ~1 in 370 trillion.

### False Positive Risk (Unnecessary Re-export)

Triggers when node JSON changes but visual output is identical:

- Figma internal metadata changes → **Mitigated:** hash only visual properties
- Float precision drift → **Mitigated:** normalize floats to 6 decimal places
- Property reordering → **Mitigated:** canonical JSON with sorted keys

**Worst case:** Unnecessary re-export (safe, just slower). No risk of missing changes.

### False Negative Risk (Missing Changes)

Could occur if:

- Hash collision (see probability above - negligible)
- Visual property not included in hash → **Mitigated:** comprehensive property list
- Child node changes not detected → **Mitigated:** recursive hashing of all children

**Safeguard:** `--force` flag always triggers full re-export.

## Performance Analysis

### Hash Computation Speed

For 500 illustrations with ~50 children each (~25,000 total nodes):

| Operation          | Time      | Notes                         |
| ------------------ | --------- | ----------------------------- |
| JSON serialization | ~50ms     | JSONEncoder with sorted keys  |
| FNV-1a hashing     | ~5ms      | 50 MB @ 2 GB/s                |
| Hash comparison    | \<1ms     | Dictionary lookup             |
| **Total overhead** | **~55ms** | Per 500 complex illustrations |

### Export Time Savings (Typical Scenarios)

| Scenario                     | Without Granular | With Granular | Savings |
| ---------------------------- | ---------------- | ------------- | ------- |
| 100 illustrations, 0 changed | 60s full export  | \<1s (skip)   | 98%     |
| 100 illustrations, 3 changed | 60s full export  | ~3s selective | 95%     |
| 500 icons, 5 changed         | 45s full export  | ~5s selective | 89%     |
| 500 icons, 500 changed (all) | 45s full export  | 45s + 55ms    | ~0%     |

**Break-even point:** ~90% of nodes changed (rare in practice).

### Memory Overhead

Cache file size for node hashes:

| Nodes  | Hash Size | Total Cache Size |
| ------ | --------- | ---------------- |
| 100    | 16 chars  | ~3 KB            |
| 1,000  | 16 chars  | ~25 KB           |
| 10,000 | 16 chars  | ~250 KB          |

**Conclusion:** Negligible memory/disk overhead.

## Goals / Non-Goals

**Goals:**

- Skip re-export of unchanged icons/images when only some assets changed
- Reduce API calls and export time for incremental updates
- Maintain backward compatibility with existing `--cache` behavior
- Provide clear experimental flag for opt-in

**Non-Goals:**

- Real-time webhook integration (out of scope)
- Cross-platform cache sharing (iOS/Android/Flutter share same cache file)
- Automatic cache invalidation on config changes

## Decisions

### Decision 1: Hash Algorithm - FNV-1a 64-bit (Fast, Cross-Platform)

**Choice:** Use FNV-1a 64-bit hash - pure Swift implementation, no external dependencies.

**Rationale:** For change detection we need speed, not cryptographic security. FNV-1a is:

- ~10x faster than SHA256
- Zero dependencies (pure Swift, works on macOS and Linux)
- Good avalanche properties (small input changes → different hashes)
- 64-bit output sufficient for change detection (not security)

```swift
// FNV-1a 64-bit - simple, fast, cross-platform
func fnv1a64(_ data: Data) -> UInt64 {
    var hash: UInt64 = 0xcbf29ce484222325  // FNV offset basis
    for byte in data {
        hash ^= UInt64(byte)
        hash &*= 0x100000001b3  // FNV prime
    }
    return hash
}
```

**Alternatives considered:**

| Algorithm       | Speed    | Dependencies           | Use Case               |
| --------------- | -------- | ---------------------- | ---------------------- |
| FNV-1a 64-bit   | ~2 GB/s  | None (pure Swift)      | ✅ Change detection    |
| SHA256          | ~500MB/s | CryptoKit/swift-crypto | Cryptographic needs    |
| xxHash          | ~10 GB/s | External C library     | Extreme performance    |
| Polynomial hash | ~1 GB/s  | None                   | ❌ Too collision-prone |

**Linux compatibility:** FNV-1a is pure Swift - no `#if canImport` needed, no platform-specific code.

### Decision 2: What to Hash - Recursive Visual Properties

**Choice:** Hash visual properties recursively for each COMPONENT node and all its children.

**Hashable properties struct:**

```swift
struct NodeHashableProperties: Encodable {
    let name: String
    let type: String
    let fills: [Fill]?
    let strokes: [Stroke]?
    let strokeWeight: Double?
    let strokeAlign: String?
    let strokeJoin: String?
    let strokeCap: String?
    let effects: [Effect]?
    let opacity: Double?
    let blendMode: String?
    let clipsContent: Bool?
    let children: [NodeHashableProperties]?  // Recursive!
}
```

**Float normalization:**

```swift
extension Double {
    /// Normalize to 6 decimal places for stable hashing
    var normalized: Double { (self * 1_000_000).rounded() / 1_000_000 }
}

// Apply to all color values and strokeWeight
let normalizedColor = PaintColor(
    r: color.r.normalized,
    g: color.g.normalized,
    b: color.b.normalized,
    a: color.a.normalized
)
```

**Rationale:**

- Recursive hashing ensures child changes propagate to parent hash
- Float normalization prevents false positives from precision drift
- Excluding `boundVariables` - values are already resolved in `fills`/`strokes`
- Excluding `absoluteBoundingBox` - position doesn't affect exported image content

**Alternatives considered:**

- Hash full node JSON: Includes irrelevant properties, more false positives
- Hash rendered PNG bytes: Requires downloading first, defeats purpose
- Hash SVG output: SVG has floating-point instability (per Figma community reports)

### Decision 3: Cache Schema Extension

**Choice:** Extend `ImageTrackingCache` with optional `nodeHashes` field per file:

```json
{
  "schemaVersion": 2,
  "files": {
    "fileId123": {
      "version": "1234567890",
      "lastExport": "2025-12-07T10:00:00Z",
      "fileName": "Icons",
      "nodeHashes": {
        "1:23": "a1b2c3d4e5f67890",
        "4:56": "0987654321fedcba"
      }
    }
  }
}
```

**Rationale:** Keeps node hashes alongside file version for atomic updates. Schema version bump enables migration.

### Decision 4: Selective Image Export

**Choice:** When only some nodes changed, call `GET /v1/images/:key?ids=changed_node_ids` instead of exporting all.

**Flow:**

1. Check file version against cache
2. If file version unchanged → skip entirely (existing behavior, no hash computation)
3. If file version changed AND `--experimental-granular-cache`:
   - Fetch components list (existing)
   - Fetch node details (existing - already has full tree)
   - Compute hashes for all COMPONENT nodes (recursive)
   - Compare with cached hashes
   - If some hashes differ → export only changed node IDs
   - Update cache with new version and hashes
4. If file version changed WITHOUT flag → full export (existing behavior)

### Decision 5: Experimental Flag

**Choice:** `--experimental-granular-cache` flag, requires `--cache` to be enabled.

```bash
# Enable granular tracking
exfig icons --cache --experimental-granular-cache

# Ignored without --cache
exfig icons --experimental-granular-cache  # Warning: --cache not enabled
```

**Rationale:** Clear experimental status, easy to remove flag when feature stabilizes.

### Decision 6: Handling Deleted Nodes

**Choice:** When a node exists in cache but not in current components list, remove from cache silently.

**Rationale:**

- Deleted icons should not trigger warnings (intentional designer action)
- Cache cleanup happens automatically during export
- No risk of stale data accumulating

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      IconsLoader                            │
├─────────────────────────────────────────────────────────────┤
│  1. Check file version (existing)                           │
│  2. If version UNCHANGED → skip (no hash computation)       │
│  3. If version CHANGED AND --experimental-granular-cache:   │
│     └─ Compute hashes → compare → export only changed       │
│  4. If version CHANGED without flag → full export           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    NodeHasher (new)                         │
├─────────────────────────────────────────────────────────────┤
│  - computeHash(node: FigmaNode) -> String                   │
│  - Recursive hashing of children                            │
│  - Float normalization to 6 decimal places                  │
│  - Uses FNV-1a 64-bit (pure Swift, cross-platform)          │
│  - Canonical JSON serialization (sorted keys)               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              ImageTrackingCache (extended)                  │
├─────────────────────────────────────────────────────────────┤
│  schemaVersion: 2                                           │
│  files: [fileId: CachedFileInfo]                            │
│    └─ nodeHashes: [nodeId: hashString]?   // NEW            │
└─────────────────────────────────────────────────────────────┘
```

## Risks / Trade-offs

| Risk                        | Impact | Mitigation                                     |
| --------------------------- | ------ | ---------------------------------------------- |
| Float precision instability | Low    | Normalize to 6 decimal places                  |
| Large cache files           | Low    | Hash strings are 16 chars each, ~50KB for 1000 |
| Recursive hashing slow      | Low    | ~55ms for 500 illustrations (acceptable)       |
| Config changes not detected | Medium | Document: use `--force` when config changes    |
| Deleted nodes in Figma      | Low    | Silent cache cleanup during export             |

## Linux Compatibility

**No special handling required.** The implementation uses:

- Pure Swift FNV-1a hash (no CryptoKit/CommonCrypto)
- Standard Foundation types (Data, JSONEncoder)
- No platform-specific imports

**Testing on Linux:**

```bash
# Run tests with single worker (libpng memory issues)
swift test --parallel --num-workers 1 --filter NodeHasherTests
```

**CI consideration:** Hash tests should run on both macOS and Linux runners to ensure cross-platform consistency.

## Migration Plan

1. Schema version 1 → 2 migration: preserve existing `files` data, add empty `nodeHashes`
2. Existing caches continue to work (granular tracking disabled by default)
3. First run with `--experimental-granular-cache` populates hash manifest

## Open Questions

1. ~~Should we hash at component level or instance level for component sets?~~ → **Resolved:** Hash COMPONENT nodes only
2. ~~Should deleted nodes in cache trigger warning or silent cleanup?~~ → **Resolved:** Silent cleanup
3. Should `--force` clear only file version or also node hashes? → **Recommendation:** Clear both
