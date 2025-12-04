# Change: Add Raw JSON Export

## Why

Users may want to inspect, debug, or process raw Figma API responses without running the full export pipeline. Currently,
ExFig always processes data through exporters. A raw JSON export mode would enable:

- Debugging Figma API responses
- Building custom pipelines on top of ExFig
- Caching API responses for offline processing
- Auditing what data is fetched from Figma

## What Changes

- Add `--raw-json` flag to export commands (colors, icons, images, typography)
- Add `download` subcommand for fetching raw API data without processing
- Save JSON files with structured Figma API responses
- Skip exporter processing when raw mode is enabled

## Impact

- Affected specs: `figma-export` (new capability)
- Affected code:
  - `Sources/ExFig/Subcommands/*.swift` - Add raw-json flag
  - `Sources/ExFig/Input/GlobalOptions.swift` - New CLI option
  - `Sources/ExFig/Loaders/*.swift` - Return raw data option
  - New `Sources/ExFig/Subcommands/Download.swift` - Download command
