# Design: Export Report for Single Commands

## Context

`exfig batch --report results.json` already writes structured JSON via `BatchReport`, but single export commands
(`colors`, `icons`, `images`, `typography`) have no `--report` flag. This forces `exfig-action` to parse stdout with
fragile regex (`output.match(/^✓.*- (\d+) /gm)`), which breaks on any CLI output format change. The action already has
`parseReportFile()` ready to consume structured reports -- it just cannot use it for single-command exports.

### Stakeholders

- `exfig-action` maintainers (GitHub Action consuming CLI output)
- CI/CD pipelines that need machine-readable export results
- Developers tracking asset drift between Figma and codebase

## Goals / Non-Goals

**Goals:**

- Add `--report <path>` to all single export commands (colors, icons, images, typography)
- Create `ExportReport` struct for single-command JSON reports with timing, stats, and warnings
- Add asset manifest with per-file tracking (path, action, checksum, asset type)
- Enable `exfig-action` to use structured reports instead of regex parsing

**Non-Goals:**

- Changing `BatchReport` format (batch mode is unchanged)
- Adding HTML/PDF report formats
- Real-time report streaming
- Modifying batch mode behavior

## Decisions

### Decision 1: ExportReport Struct (Parallel to BatchReport)

**What**: New lightweight `ExportReport` struct for single-command exports, separate from `BatchReport`.

**Options considered**:

| Option                    | Pros                       | Cons                                  |
| ------------------------- | -------------------------- | ------------------------------------- |
| Extend BatchReport        | Reuse existing type        | Different shape (single vs multi)     |
| New ExportReport struct   | Clean separation, tailored | Small duplication of Stats fields     |
| Generic Report<T> wrapper | Maximum reuse              | Over-engineering for two report types |

**Decision**: New `ExportReport` struct with its own `ReportStats: Encodable` containing count fields only
(colors, icons, images, typography). `ExportStats` from `BatchResult.swift` is NOT Codable and contains
batch-only fields (`computedNodeHashes`, `granularCacheStats`, `fileVersions`), so direct reuse is not viable.
This matches the pattern already established by `BatchReport.Stats` which manually maps the same count fields.
BatchReport stays private to `Batch.swift`, ExportReport is internal to ExFigCLI. Different shapes: BatchReport
has `results: [ConfigReport]` array, ExportReport has flat `stats` + `manifest` for a single command.

### Decision 2: `--report <path>` Flag

**What**: Optional ArgumentParser `@Option` on each export subcommand, same pattern as batch mode.

**Options considered**:

| Option                     | Pros               | Cons                           |
| -------------------------- | ------------------ | ------------------------------ |
| `@Option --report <path>`  | Explicit, familiar | Repeated in 4 subcommands      |
| Always write to fixed path | Zero config        | Breaks existing workflows      |
| Environment variable       | No CLI change      | Hidden behavior, hard to debug |

**Decision**: `@Option(name: .long, help: "Path to write JSON report") var report: String?` on each export
subcommand. Same pattern as `Batch.report`. Could be extracted to a shared `ReportOptions` `@OptionGroup` if
the option set grows.

### Decision 3: JSON Serialization via JSONCodec

**What**: Use `JSONCodec.encodePrettySorted()` from swift-yyjson for deterministic, human-readable output.

**Options considered**:

| Option                         | Pros                | Cons                        |
| ------------------------------ | ------------------- | --------------------------- |
| JSONCodec.encodePrettySorted() | Project standard    | None                        |
| Foundation JSONEncoder         | No extra dependency | Against project conventions |
| JSONCodec.encodePretty()       | Simpler             | Non-deterministic key order |

**Decision**: `JSONCodec.encodePrettySorted()`. Deterministic output enables diffing reports across runs
(useful for asset drift detection). Matches batch mode which already uses this method.

### Decision 4: Warning Collection

**What**: Collect warnings emitted during export for inclusion in the report.

**Options considered**:

| Option                       | Pros                                    | Cons                           |
| ---------------------------- | --------------------------------------- | ------------------------------ |
| Add collection to TerminalUI | Single point of interception            | Adds state to stateless class  |
| Separate WarningCollector    | Clean separation, follows actor pattern | Must wire into export commands |
| Intercept at queueLogMessage | No TerminalUI changes                   | Only works in batch mode       |

**Decision**: Create new `WarningCollector` actor following `SharedThemeAttributesCollector` pattern
(see `Sources/ExFigCLI/Batch/SharedThemeAttributes.swift`). TerminalUI currently does NOT store warnings —
it only prints/queues them. The collector is injected into export commands when `--report` is specified,
and `TerminalUI.warning()` is extended to also forward to the active collector. Collected as `[String]`
(formatted message strings) for inclusion in the report.

### Decision 5: Asset Manifest with FileWriter Tracking

**What**: Track every file write in `FileWriter`, recording path, action, checksum, and asset type.

**Options considered**:

| Option                      | Pros                          | Cons                           |
| --------------------------- | ----------------------------- | ------------------------------ |
| Track writes in FileWriter  | Accurate, captures all writes | Adds state to stateless writer |
| Post-hoc file system scan   | No code changes to writer     | Cannot detect "unchanged"      |
| Separate manifest collector | Clean separation              | Must intercept all write paths |

**Decision**: Add optional tracking to `FileWriter`. When `--report` is specified, FileWriter records each
file write with its action and checksum. Tracking is opt-in -- zero overhead when `--report` is not used.

### Decision 6: File Action Detection

**What**: Classify each written file as `created`, `modified`, `unchanged`, or `deleted`.

**Approach**:

- `created`: file did not exist before write
- `modified`: file existed but content hash differs from new content
- `unchanged`: file existed with identical content (hash match)
- `deleted`: file existed in previous report but is not generated in current run

Detection uses content hash comparison before write. For `deleted`, the system compares against a previous
report file at the same path (if it exists). This is the only action that requires a previous report.

### Decision 7: Content Checksum

**What**: Compute a content hash for each file in the manifest.

**Options considered**:

| Option                  | Pros                                     | Cons                                                     |
| ----------------------- | ---------------------------------------- | -------------------------------------------------------- |
| SHA256 (CryptoKit)      | Industry standard, 64-char hex           | macOS-only; Linux needs `swift-crypto` dependency        |
| SHA256 (swift-crypto)   | Cross-platform, industry standard        | New dependency                                           |
| FNV-1a (already in use) | No new deps, fast (~2 GB/s), in codebase | Non-cryptographic, 16-char hex, collision-prone at scale |

**Decision**: Use `FNV1aHasher.hashToHex()` already available in the codebase (see
`Sources/ExFigCLI/Cache/FNV1aHasher.swift`). The checksum purpose is change detection, not security —
same use case as granular cache node hashing. Produces 16-character lowercase hex string. If downstream
tools later require SHA256, `swift-crypto` can be added as a future enhancement. The checksum is computed
from data already in memory during write — no additional I/O. Only computed when `--report` is specified.

### Decision 8: Report Write Failure Isolation

**What**: Report write failure MUST NOT fail the export command.

**Rationale**: The export itself is the primary operation. If the report file cannot be written (permissions,
disk full, invalid path), the export results are still valid. The system logs a warning and continues.
This matches batch mode behavior where report write failure is caught and logged.

### Decision 9: Report Version Field

**What**: Include a `version` integer field in `ExportReport` for forward compatibility.

**Rationale**: As the report schema evolves (e.g., adding manifest in Phase 2), downstream consumers
(exfig-action) need to know which fields to expect. Starting at `version: 1` for the initial report
(timing, stats, warnings). Increment when adding breaking changes to the schema structure.

### Decision 10: Export Command Result Capture

**What**: Modify single export commands' `run()` methods to capture export results instead of discarding them.

**Current state**: All four export commands discard results: `_ = try await performExport(...)`. The
`performExportWithResult()` method exists but is only called in batch mode.

**Decision**: In `run()`, call `performExportWithResult()` (or `performExport()` and capture count)
to obtain the stats needed for the report. Wrap the export in a do/catch to capture both success
and failure states. Capture `startTime` before export and `endTime` after.

## Risks / Trade-offs

| Risk                              | Impact | Mitigation                                            |
| --------------------------------- | ------ | ----------------------------------------------------- |
| FileWriter tracking overhead      | Low    | Only active when `--report` specified                 |
| FNV-1a collision risk             | Low    | Non-cryptographic but sufficient for change detection |
| exfig-action Phase 3 dependency   | Medium | Action requires CLI release with `--report` first     |
| Report format evolution           | Low    | `version` field in report for forward compat          |
| `deleted` detection needs history | Low    | Optional -- requires previous report at same path     |
| Warning collector wiring          | Low    | Follow SharedThemeAttributesCollector actor pattern   |
| run() refactor for result capture | Low    | performExportWithResult() already exists              |
