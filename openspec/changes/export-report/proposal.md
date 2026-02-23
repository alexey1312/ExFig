## Why

`exfig batch --report results.json` already generates a structured JSON report via `BatchReport`, but single export commands (`colors`, `icons`, `images`, `typography`) have no `--report` flag. This forces `exfig-action` to **parse stdout with fragile regex** (`output.match(/^✓.*- (\d+) /gm)`), which breaks on any CLI output format change. The action already has `parseReportFile()` — it just cannot use it for single-command exports.

## What Changes

**Phase 1 — `--report` for single export commands:**

- Add `--report <path>` option to `ExportColors`, `ExportIcons`, `ExportImages`, `ExportTypography`
- New `ExportReport` struct (analogous to `BatchReport` but for a single command): command name, config path, timing, success/error, stats, collected warnings
- Reuse existing `ExportStats` from `BatchResult.swift` and `JSONCodec.encodePrettySorted()` from swift-yyjson

**Phase 2 — Asset Manifest:**

- New `AssetManifest` struct tracking every generated file: path, action (`created`/`modified`/`unchanged`/`deleted`), optional SHA256 checksum, asset type
- Track file write status in `FileWriter` and attach manifest to `ExportReport`
- Enables: precise change tracking, PR diff comments, design drift detection

**Phase 3 — exfig-action integration:**

- Update `exfig-action/src/index.ts` to use `--report` instead of regex parsing for all commands
- Add optional `pr_comment` input for PR comments with asset diff summary
- Depends on Phase 1 shipping in ExFig CLI

## Capabilities

### New Capabilities

- `export-report`: Structured JSON report (`--report <path>`) for single export commands, with timing, stats, warnings, and asset manifest

### Modified Capabilities

_(none — batch report behavior is unchanged; single commands currently have no report spec)_

## Impact

- `Sources/ExFigCLI/Subcommands/ExportColors.swift` — add `--report` option
- `Sources/ExFigCLI/Subcommands/ExportIcons.swift` — add `--report` option
- `Sources/ExFigCLI/Subcommands/ExportImages.swift` — add `--report` option
- `Sources/ExFigCLI/Subcommands/ExportTypography.swift` — add `--report` option
- `Sources/ExFigCLI/Batch/BatchResult.swift` — reuse `ExportStats`
- `Sources/ExFigCLI/Output/FileWriter.swift` — track write status for manifest
- External: `alexey1312/exfig-action` repo (Phase 3)
