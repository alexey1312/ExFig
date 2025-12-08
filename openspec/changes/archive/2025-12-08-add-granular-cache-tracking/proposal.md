# Change: Add Granular Node-Level Cache Tracking

## Why

The current cache implementation operates at file-level granularity only, tracking Figma's `version` field. When ANY
change occurs in a Figma file, ALL assets from that file are re-exported, even if only one icon was modified. For large
design systems with 500+ icons or 100+ illustrations, this means a single asset tweak triggers full re-export (API
calls, downloads, file writes). Node-level tracking would skip unchanged assets, reducing export time by 80-95% in
typical incremental update scenarios.

**Key insight from Figma API analysis:** The Figma REST API provides NO per-node change tracking (no hashes, timestamps,
or version fields on nodes). The recommended approach from the community is to compute local JSON hashes of each node's
visual properties and compare on each sync cycle.

**Important discovery:** The existing `GET /v1/files/:key/nodes?ids=...` endpoint already returns the full node tree
with all children - no additional API call is needed for hash computation.

## What Changes

- **EXPERIMENTAL** Add `--experimental-granular-cache` flag to icons/images commands
- Store per-node FNV-1a 64-bit hashes in cache manifest alongside file-level version
- Compute hashes from visual properties only (fills, strokes, effects, children - recursive)
- Normalize floats to 6 decimal places to prevent false positives from precision drift
- On export, compare node hashes to identify which specific assets changed
- Export only changed nodes via selective `GET /v1/images/:key?ids=changed_ids`
- Fall back to full export if hash manifest is missing or corrupted
- Silently remove deleted nodes from cache during export

## Impact

- Affected specs: caching (new capability spec)
- Affected code:
  - `Sources/ExFig/Cache/ImageTrackingCache.swift` - extend schema to v2, add nodeHashes
  - `Sources/ExFig/Cache/ImageTrackingManager.swift` - add node-level tracking
  - `Sources/ExFig/Input/CacheOptions.swift` - add experimental flag
  - `Sources/ExFig/Loaders/IconsLoader.swift` - selective export based on hash diff
  - `Sources/ExFig/Loaders/ImagesLoader.swift` - selective export based on hash diff
  - New: `Sources/ExFig/Cache/NodeHasher.swift` - FNV-1a hash computation with recursive children
  - New: `Sources/FigmaAPI/Model/NodeHashableProperties.swift` - hashable visual properties struct

## Risks

- **Float precision instability**: Figma may return slightly different float values for same node
- **Large cache files**: Files with many nodes will have larger hash manifests
- **Config changes not detected**: If user changes filter/output config, cache won't invalidate

## Mitigation

- Normalize floats to 6 decimal places before hashing (same precision as SVG)
- Hash strings are only 16 chars each - ~25KB for 1000 nodes
- Document requirement to use `--force` when config changes
- Flag is experimental - users opt-in explicitly
- Use canonical JSON serialization (sorted keys) for stable hashes
