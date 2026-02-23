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

**Decision**: New `ExportReport` struct. Reuses `ExportStats` for counts. BatchReport stays private to `Batch.swift`,
ExportReport is internal to ExFigCLI. Different shapes: BatchReport has `results: [ConfigReport]` array, ExportReport
has flat `stats` + `manifest` for a single command.

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

**What**: Expose warnings collected by TerminalUI in the report.

**Options considered**:

| Option                     | Pros              | Cons                        |
| -------------------------- | ----------------- | --------------------------- |
| Expose TerminalUI warnings | Already collected | Couples report to UI layer  |
| Separate warning collector | Clean separation  | Duplicates collection logic |

**Decision**: TerminalUI already collects warnings via its internal list. Expose collected warnings as `[String]`
for inclusion in the report. No new collection mechanism needed.

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

### Decision 7: SHA256 Checksum

**What**: Compute SHA256 hex digest for each file in the manifest.

**Rationale**: Enables downstream tools (exfig-action, CI scripts) to detect changes without reading file
contents. SHA256 is computed from data already in memory during write -- no additional I/O. The checksum
is only computed when `--report` is specified.

### Decision 8: Report Write Failure Isolation

**What**: Report write failure MUST NOT fail the export command.

**Rationale**: The export itself is the primary operation. If the report file cannot be written (permissions,
disk full, invalid path), the export results are still valid. The system logs a warning and continues.
This matches batch mode behavior where report write failure is caught and logged.

## Risks / Trade-offs

| Risk                              | Impact | Mitigation                                        |
| --------------------------------- | ------ | ------------------------------------------------- |
| FileWriter tracking overhead      | Low    | Only active when `--report` specified             |
| SHA256 computation cost           | Low    | Computed from in-memory data during write         |
| exfig-action Phase 3 dependency   | Medium | Action requires CLI release with `--report` first |
| Report format evolution           | Low    | Add `version` field to report for forward compat  |
| `deleted` detection needs history | Low    | Optional -- requires previous report at same path |
