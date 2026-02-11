# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Module Role

WebExport is the output/rendering layer for Web platform exports. It receives processed domain models (`Color`, `ImagePack`) from ExFigCore and generates web-ready files: CSS variables, TypeScript constants, React TSX components, JSON theme tokens, and SVG/PNG assets. It does **not** fetch data from Figma or parse configs — those responsibilities belong to FigmaAPI and ExFigCLI respectively.

**Dependency chain:** ExFigCLI → ExFig-Web (platform plugin) → **WebExport** → ExFigCore

## Architecture

All exporters inherit from `WebExporter` base class, which provides Stencil template environment setup and `FileContents` creation. Each exporter produces `FileContents` objects — the CLI layer writes them to disk.

| Exporter            | Input                    | Output Files                                                       |
| ------------------- | ------------------------ | ------------------------------------------------------------------ |
| `WebColorExporter`  | `[AssetPair<Color>]`     | `theme.css`, `variables.ts`, optional `theme.json`                 |
| `WebIconsExporter`  | `[AssetPair<ImagePack>]` | SVG assets, React `.tsx` components, `types.ts`, `index.ts` barrel |
| `WebImagesExporter` | `[AssetPair<ImagePack>]` | Image assets (SVG/PNG), React `.tsx` components, `index.ts` barrel |

`SVGToJSXConverter` — stateless converter (enum with static methods) that parses raw SVG data, extracts viewBox, and converts HTML attributes to JSX camelCase format (e.g., `stroke-width` → `strokeWidth`).

## Template System

9 Stencil templates in `Resources/`. Custom templates can override defaults via `WebOutput.templatesPath`. Templates use `StencilSwiftKit` extensions. All templates include `header.stencil` as a "do not edit" comment.

Template context variables are plain `[[String: String]]` arrays — color names are pre-formatted as `cssName` (kebab-case) and `camelName` (lowerCamelCase) before passing to Stencil.

## Key Conventions

- **File URLs:** All exporters create file URLs via `URL(string:)` (not `URL(fileURLWithPath:)`), preserving subdirectory paths. `FileWriter` creates intermediate directories from the destination URL.
- **Naming:** Icons use `snake_case` for asset files, `CamelCase` for React component file names. Dark variants get `_dark` suffix.
- **Granular cache support:** `export()` methods accept optional `allIconNames`/`allImageNames` parameter — when only a subset of assets is re-exported (cache hit), the barrel file still lists all entries.
- **Two-phase icon components:** `makeReactComponents()` generates placeholders; `generateReactComponentsFromSVGData()` generates real components from downloaded SVG data with diagnostic info (`ComponentGenerationResult`).
- **Color format:** Opaque colors → `#RRGGBB` hex; transparent → `rgba(r, g, b, a)`. Logic in private `Color.cssValue` extension.

## Running Tests

```bash
./bin/mise run test:filter WebExportTests    # Unit tests for this module
./bin/mise run test:filter ExFig_WebTests    # Integration tests (ExFig-Web plugin)
```
