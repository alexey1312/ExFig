# Change: Add ExFig Studio GUI Application

## Why

The CONFIG.md documentation has grown to 1252 lines with complex nested YAML options, making it difficult for users to configure ExFig correctly. A native macOS GUI app would provide:

- Visual configuration editor with validation
- Asset preview before export
- Interactive asset selection
- Progress visualization during export
- Export history and quick re-runs

## What Changes

- **NEW**: `ExFigKit` module — extracted reusable library from CLI code (Loaders, Output, Config, Cache)
- **NEW**: `Projects/ExFigStudio/` — SwiftUI macOS 15 application (ExFig Studio) via Tuist
- **NEW**: `Tuist/` — Tuist configuration and external dependencies
- **NEW**: `Workspace.swift` — Tuist workspace combining CLI + GUI app
- **NEW**: `FigmaAPI/OAuth/` — Figma OAuth authentication flow
- **MODIFIED**: `ExFig` CLI module — depends on ExFigKit instead of containing library code
- **MODIFIED**: `Package.swift` — add ExFigKit target
- **MODIFIED**: `mise.toml` — add tuist tool and app:* tasks

## Impact

- Affected specs: None (new capabilities)
- Affected code:
  - `Sources/ExFigKit/` (new module)
  - `Sources/ExFig/` (refactor to use ExFigKit)
  - `Sources/FigmaAPI/` (add OAuth)
  - `Tuist/` (new Tuist config)
  - `Workspace.swift` (new Tuist workspace)
  - `Projects/ExFigStudio/` (new app via Tuist)
  - `Package.swift` (add ExFigKit target)
  - `mise.toml` (add tuist + app tasks)
