# Change: Add JSON Export with W3C Design Tokens

## Why

Users need to export Figma design data as JSON for:

- Integration with design token tools and pipelines
- Cross-platform design system synchronization
- Debugging Figma API responses
- Building custom asset pipelines on top of ExFig

Currently, ExFig always processes data through platform-specific exporters (iOS, Android, Flutter). A JSON export mode
would enable interoperability with the broader design tokens ecosystem.

## What Changes

- Add `download` subcommand for fetching Figma data as JSON
- Support two output formats via `--format` flag:
  - `w3c` (default): W3C Design Tokens format — clean hierarchical structure with `$type`, `$value`, `$description`
  - `raw`: Unmodified Figma API response for debugging and custom pipelines
- Support all data types: colors, icons, images, typography
- Handle Figma modes (Light, Dark, etc.) as W3C token value variants

## Impact

- Affected specs: `figma-export` (new capability)
- Affected code:
  - New `Sources/ExFig/Subcommands/Download.swift` - Download command with subcommands
  - New `Sources/ExFig/Output/W3CTokensExporter.swift` - W3C format transformer
  - `Sources/ExFig/Loaders/*.swift` - Return raw data option
