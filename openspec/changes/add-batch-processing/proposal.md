# Change: Add Batch Processing

## Why

Teams often manage multiple Figma files for different projects, brands, or platforms. Currently, users must run ExFig
separately for each config file. This is inefficient and doesn't optimize API usage across configs.

Batch processing would enable:

- Processing multiple configs in a single command
- Shared rate limiting across all configs
- Parallel execution with resource management
- Unified progress reporting and error summary

## What Changes

- Add `--config-dir` option to specify directory containing multiple configs
- Add `exfig batch` command for explicit batch processing
- Implement parallel execution with shared rate limiter
- Add unified progress UI for multi-config exports
- Aggregate results and errors across all configs

## Impact

- Affected specs: `batch-processing` (new capability)
- Affected code:
  - New `Sources/ExFig/Subcommands/Batch.swift` - Batch command
  - `Sources/ExFig/Input/` - Multi-config loading
  - `Sources/FigmaAPI/` - Shared rate limiter
  - `Sources/ExFig/TerminalUI/` - Multi-progress display
