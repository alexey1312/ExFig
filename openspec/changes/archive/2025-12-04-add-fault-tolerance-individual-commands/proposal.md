# Change: Add Fault Tolerance to Individual Commands

**Status:** Completed

## Implementation Summary

All individual commands now support fault tolerance:

- **Retry**: `--max-retries` flag (default: 4) with exponential backoff
- **Rate limiting**: `--rate-limit` flag (default: 10 req/min)
- **Fail-fast**: `--fail-fast` flag for heavy commands (icons, images, fetch)
- **Resume**: `--resume` flag parsed by heavy commands; checkpoint infrastructure in place

The checkpoint tracking infrastructure (`CheckpointTracker`, `ExportCheckpoint`) is implemented and tested. Deep
integration of checkpoint resume into the multi-platform download flows (iOS, Android, Flutter) requires additional
architectural work and is tracked as follow-up.

## Why

The `batch` command has full fault tolerance support (retry, rate limiting, checkpoints), but individual commands use
plain `FigmaClient` without:

- Configurable retry attempts (`--max-retries`)
- Rate limiting (`--rate-limit`)
- Fail-fast option (`--fail-fast`)
- Checkpoint/resume for large exports (`--resume`)

Users running single commands don't benefit from the fault tolerance features implemented in `add-fault-tolerance`.

## Command Analysis

Commands have different fault tolerance needs based on their workload:

| Command               | API Calls | File Downloads | Needs retry | Needs resume |
| --------------------- | --------- | -------------- | ----------- | ------------ |
| `colors`              | 1-3       | 0              | Yes         | No           |
| `typography`          | 1-2       | 0              | Yes         | No           |
| `icons`               | 2-3       | Many (SVG)     | Yes         | Yes          |
| `images`              | 2-3       | Many (N×M)     | Yes         | Yes          |
| `fetch`               | 2-3       | Many           | Yes         | Yes          |
| `download colors`     | 1-2       | 0              | Yes         | No           |
| `download typography` | 1-2       | 0              | Yes         | No           |
| `download icons`      | 2-3       | 0              | Yes         | No           |
| `download images`     | 2-3       | 0              | Yes         | No           |

## What Changes

### All Commands

- Add `--max-retries` flag (default: 4)
- Add `--rate-limit` flag (default: 10 req/min)
- Refactor to use `RateLimitedClient` instead of plain `FigmaClient`
- Create shared `FaultToleranceOptions` option group

### Heavy Download Commands (`icons`, `images`, `fetch`)

- Add `--fail-fast` flag to stop on first download error
- Add `--resume` flag to continue from checkpoint after interruption
- Implement checkpoint tracking for downloaded files

## Impact

- Affected specs: `reliability` (extend existing)
- Affected code:
  - `Sources/ExFig/Input/FaultToleranceOptions.swift` (new)
  - `Sources/ExFig/Subcommands/ExportColors.swift`
  - `Sources/ExFig/Subcommands/ExportIcons.swift`
  - `Sources/ExFig/Subcommands/ExportImages.swift`
  - `Sources/ExFig/Subcommands/ExportTypography.swift`
  - `Sources/ExFig/Subcommands/DownloadImages.swift` (fetch command)
  - `Sources/ExFig/Subcommands/Download.swift` (download subcommands)
- Documentation updates:
  - `README.md` - Add fault tolerance options to CLI reference
  - `CLAUDE.md` - Add fault tolerance patterns section
  - Command `--help` text
- New files:
  - `Sources/ExFig/Cache/CheckpointTracker.swift` - Actor for checkpoint management
  - `Tests/ExFigTests/Cache/CheckpointTrackerTests.swift` - Tests for checkpoint tracking
