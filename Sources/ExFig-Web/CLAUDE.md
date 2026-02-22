# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Module Overview

`ExFig-Web` is a platform plugin that exports Figma assets (colors, icons, images) to web/React projects. It produces CSS variables, TypeScript constants, JSON files, SVG assets, and React TSX components.

## Architecture

Two layers work together:

- **ExFig-Web** (this module) — plugin registration + entry config bridging + orchestration (load -> process -> export cycle)
- **WebExport** (sibling module) — file generation logic (CSS/TS/JSON output, SVG-to-JSX conversion, React component templates)

Each exporter follows the same 3-step pattern:

1. Load assets from Figma via `context.loadColors/loadIcons/loadImages`
2. Process with platform-specific naming (kebab-case for CSS, snake_case for icons/images)
3. Generate files via `WebExport` module and write through `context.writeFiles`

## Key Differences from Other Platform Plugins

- **`outputDirectory` field**: Web entry types use `outputDirectory` (not `output` like Android/Flutter). This is validated as `!isEmpty` in PKL schema.
- **URL construction**: Web entries use `URL(fileURLWithPath:)` for paths, so `lastPathComponent` gives just the filename (not subdirectory-preserving like Flutter).
- **React component generation**: Icons and images exporters generate TSX components via `SVGToJSXConverter`, which maps HTML attributes to JSX (e.g., `fill-rule` -> `fillRule`).
- **SVG download + component generation**: Icons export downloads SVGs first, then generates TSX components from real SVG data (not placeholders).

## Files

| File                             | Role                                                                          |
| -------------------------------- | ----------------------------------------------------------------------------- |
| `WebPlugin.swift`                | Plugin registration (identifier: `"web"`, configKeys: `["web"]`)              |
| `Config/*Entry.swift`            | PKL-generated type extensions, enum bridging, URL resolution                  |
| `Config/WebPlatformConfig.swift` | Platform-level config (output dir + templates path)                           |
| `Export/Web*Exporter.swift`      | Orchestrators conforming to `ColorsExporter`/`IconsExporter`/`ImagesExporter` |

## Entry Override Resolution

All entries support per-entry overrides that take priority over platform config:

- `entry.resolvedOutput(fallback:)` — output directory
- `entry.resolvedTemplatesPath(fallback:)` — Jinja2 templates path

Colors uses `output` + `outputDirectory` (two levels), while icons/images use only `outputDirectory` appended to `platformConfig.output`.

## Related Files Outside This Module

- PKL schema: `Sources/ExFigCLI/Resources/Schemas/Web.pkl`
- Generated types: `Sources/ExFigConfig/Generated/Web.pkl.swift`
- WebExport module: `Sources/WebExport/` (file generation, SVG-to-JSX)
- CLI export commands: `Sources/ExFigCLI/Subcommands/Export/WebColorsExport.swift`, `WebImagesExport.swift`
- Tests: `Tests/ExFig-WebTests/`, `Tests/WebExportTests/`

## Testing

```bash
./bin/mise run test:filter ExFig_WebTests    # Plugin-level tests (note: underscore, not hyphen)
./bin/mise run test:filter WebExportTests     # File generation tests
```
