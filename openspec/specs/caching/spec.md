# caching Specification

## Purpose

TBD - created by archiving change add-granular-cache-tracking. Update Purpose after archive.

## Requirements

### Requirement: Granular Node-Level Cache Tracking

The system SHALL support node-level change detection via JSON hash comparison when the `--experimental-granular-cache`
flag is enabled alongside `--cache`.

#### Scenario: File version unchanged (granular cache enabled)

- **GIVEN** a cache file exists with node hashes for file "icons.fig"
- **AND** the file version matches cached version
- **WHEN** `exfig icons --cache --experimental-granular-cache` is executed
- **THEN** the export is skipped with message "No changes detected"
- **AND** node hashes are NOT recomputed (performance optimization)

#### Scenario: File version changed but all node hashes match

- **GIVEN** a cache file exists with node hashes for file "icons.fig"
- **AND** the file version has changed (e.g., metadata-only edit)
- **AND** all node hashes match cached hashes after recomputation
- **WHEN** `exfig icons --cache --experimental-granular-cache` is executed
- **THEN** the export is skipped with message "No changes detected (granular)"
- **AND** the cache is updated with new file version (hashes unchanged)

#### Scenario: Granular cache detects partial changes

- **GIVEN** a cache file exists with node hashes for 100 icons
- **AND** the file version has changed
- **AND** only 3 node hashes differ from cached values
- **WHEN** `exfig icons --cache --experimental-granular-cache` is executed
- **THEN** only the 3 changed icons are exported
- **AND** the cache is updated with new version and hashes

#### Scenario: Granular cache with no prior hashes

- **GIVEN** a cache file exists with file version but no node hashes
- **WHEN** `exfig icons --cache --experimental-granular-cache` is executed
- **THEN** all icons are exported (full export)
- **AND** node hashes are computed and stored for future runs

#### Scenario: Granular flag without cache flag

- **GIVEN** user runs `exfig icons --experimental-granular-cache` without `--cache`
- **WHEN** the command executes
- **THEN** a warning is displayed: "--experimental-granular-cache requires --cache flag"
- **AND** export proceeds without caching

#### Scenario: Deleted node in Figma

- **GIVEN** a cache file exists with hash for node "1:23"
- **AND** node "1:23" no longer exists in the Figma file
- **WHEN** `exfig icons --cache --experimental-granular-cache` is executed
- **THEN** node "1:23" is removed from cache silently
- **AND** no warning is displayed

### Requirement: Node Hash Computation

The system SHALL compute FNV-1a 64-bit hashes of node visual properties for change detection.

#### Scenario: Hash computation for icon node

- **GIVEN** a Figma node with id "1:23" containing fills, strokes, and effects
- **WHEN** the node hash is computed
- **THEN** a 16-character hexadecimal FNV-1a 64-bit hash is returned
- **AND** the hash is deterministic for identical node properties
- **AND** the same hash is produced on macOS and Linux

#### Scenario: Hash excludes non-visual properties

- **GIVEN** two nodes with identical visual properties
- **AND** different `boundVariables` values
- **WHEN** hashes are computed for both nodes
- **THEN** the hashes are identical

#### Scenario: Hash excludes position properties

- **GIVEN** two nodes with identical visual properties
- **AND** different `absoluteBoundingBox` values
- **WHEN** hashes are computed for both nodes
- **THEN** the hashes are identical

#### Scenario: Hash includes child changes (recursive)

- **GIVEN** a COMPONENT node with children
- **AND** one child's fill color changes
- **WHEN** the parent node hash is computed
- **THEN** the hash differs from the previous value

#### Scenario: Float normalization prevents false positives

- **GIVEN** a node with fill color r=0.33333334
- **AND** the same node fetched again returns r=0.33333333
- **WHEN** hashes are computed for both
- **THEN** the hashes are identical (normalized to 6 decimal places)

### Requirement: Visual Properties Hashing

The system SHALL hash the following visual properties recursively:

| Property       | Included | Notes                          |
| -------------- | -------- | ------------------------------ |
| `name`         | Yes      | Affects output filename        |
| `type`         | Yes      | Node structure                 |
| `fills`        | Yes      | Background/fill colors         |
| `strokes`      | Yes      | Border/stroke colors           |
| `strokeWeight` | Yes      | Stroke thickness               |
| `strokeAlign`  | Yes      | Inside/center/outside          |
| `strokeJoin`   | Yes      | Miter/round/bevel              |
| `strokeCap`    | Yes      | None/round/square              |
| `effects`      | Yes      | Shadows, blurs                 |
| `opacity`      | Yes      | Node transparency              |
| `blendMode`    | Yes      | Layer blend mode               |
| `clipsContent` | Yes      | Frame clipping                 |
| `rotation`     | Yes      | Node rotation in radians       |
| `children`     | Yes      | Recursive hash of all children |

Paint properties hashed: `type`, `blendMode`, `color`, `opacity`, `gradientStops`.

Effect properties hashed: `type`, `radius`, `spread`, `offset`, `color`, `visible`.

#### Scenario: Fill color change produces different hash

- **GIVEN** a node with fill color red
- **WHEN** the fill color is changed to blue
- **THEN** the computed hash differs from the original

#### Scenario: Rotation change produces different hash

- **GIVEN** a node with no rotation
- **WHEN** the node is rotated by 90 degrees
- **THEN** the computed hash differs from the original

#### Scenario: Effect spread change produces different hash

- **GIVEN** a node with DROP_SHADOW effect having spread=2.0
- **WHEN** the effect spread is changed to 4.0
- **THEN** the computed hash differs from the original

#### Scenario: Paint blendMode change produces different hash

- **GIVEN** a node with fill blendMode=NORMAL
- **WHEN** the fill blendMode is changed to MULTIPLY
- **THEN** the computed hash differs from the original

### Requirement: Cache Schema Migration

The system SHALL migrate cache files from schema version 1 to version 2 preserving existing data.

#### Scenario: Schema v1 to v2 migration

- **GIVEN** a cache file with schema version 1
- **WHEN** the cache is loaded with granular tracking enabled
- **THEN** the schema is upgraded to version 2
- **AND** existing file version data is preserved
- **AND** `nodeHashes` field is initialized as empty for each file

#### Scenario: Schema v2 backward compatibility

- **GIVEN** a cache file with schema version 2 and node hashes
- **WHEN** loaded by a version without granular support
- **THEN** the cache loads successfully
- **AND** node hashes are ignored (file-level tracking only)

#### Scenario: Force flag clears node hashes

- **GIVEN** a cache file with node hashes
- **WHEN** `exfig icons --cache --force` is executed
- **THEN** all node hashes for the file are cleared
- **AND** full export is performed
- **AND** new hashes are computed and stored
