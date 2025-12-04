# Change: Add Fault Tolerance to Individual Commands

## Why

The `batch` command has full fault tolerance support (retry, rate limiting, checkpoints), but individual commands
(`colors`, `icons`, `images`, `typography`, `fetch`, `download`) use plain `FigmaClient` without:

- Configurable retry attempts (`--max-retries`)
- Rate limiting (`--rate-limit`)
- Fail-fast option (`--fail-fast`)
- Checkpoint/resume for large exports (`--resume`)

Users running single commands don't benefit from the fault tolerance features implemented in `add-fault-tolerance`.

## What Changes

- Add `--max-retries` flag to individual export commands
- Add `--rate-limit` flag to control API request rate
- Add `--fail-fast` flag to disable retries
- Optionally add `--resume` for commands that export multiple items (icons, images)
- Refactor commands to use `RateLimitedClient` instead of plain `FigmaClient`

## Impact

- Affected specs: `reliability` (extend existing)
- Affected code:
  - `Sources/ExFig/Subcommands/ExportColors.swift`
  - `Sources/ExFig/Subcommands/ExportIcons.swift`
  - `Sources/ExFig/Subcommands/ExportImages.swift`
  - `Sources/ExFig/Subcommands/ExportTypography.swift`
  - `Sources/ExFig/Subcommands/Fetch.swift`
  - `Sources/ExFig/Subcommands/Download.swift`
  - Shared options group for fault tolerance flags
