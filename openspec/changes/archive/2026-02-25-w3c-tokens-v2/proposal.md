## Why

`W3CTokensExporter` exports design tokens in a draft Community Group format, but the W3C Design Tokens Community Group spec reached stable v2025.10 (October 2025). The v2025.10 spec is composed of three modules: **Format** (token structure, groups, aliases), **Color** (structured color objects with color space support), and **Resolver** (theming, modes, multi-brand). All major competitors (Tokens Studio, Style Dictionary v4, Supernova) are already compliant. Current divergences — hex strings instead of color objects for `$value`, non-standard mode dicts, invented `$type: "asset"`, missing `$extensions`, no token aliases, plain numbers instead of dimension objects, no dimension/number types — limit interoperability and prevent round-trip workflows with other design token tools.

## What Changes

**Phase 1 — W3C v2025.10 Compliance (export):**

- Refactor color token `$value` to v2025.10 Color Module object format (`colorSpace`, `components`, optional `alpha`/`hex`) instead of hex strings
- Add multi-mode support via `$extensions.com.exfig.modes` (each mode value is a color object)
- Remove `$type: "asset"` — use custom `$extensions.com.exfig.assetUrl` instead
- Add `$extensions.com.exfig` with Figma metadata (`nodeId`, `fileId`, `variableId`) using reverse-domain key
- Add `$description` from Figma variable descriptions
- Support token aliases (`$value: "{Primitives.Blue.500}"`) for semantic → primitive references

**Phase 2 — Token Types Expansion:**

- Add `dimension` type (spacing, border-radius, sizes) with object `$value` (`{"value": N, "unit": "px"}`)
- Add `number` type (opacity, z-index) from Figma number variables (plain numeric `$value`)
- Add `fontFamily`, `fontWeight` types — split from composite typography tokens
- Decompose typography into sub-tokens with correct v2025.10 types (`fontSize` as dimension object, `lineHeight` as number)
- New unified `download tokens` subcommand (or expand `download colors --tokens`)

**Phase 3 — Import .tokens.json as Source:**

- Parse W3C DTCG `.tokens.json` files as an alternative source (instead of Figma API)
- Support v2025.10 group features: `$root` tokens, `$extends` (group inheritance), `$deprecated`
- New PKL source type `tokensFile` alongside existing `variablesColors`
- Enables: offline workflows, Tokens Studio / Style Dictionary integration, CI without Figma token

## Capabilities

### New Capabilities

- `design-tokens-export`: W3C DTCG v2025.10 compliant token export with extensions, aliases, and expanded type support
- `tokens-file-source`: Import `.tokens.json` files as a design token source, enabling offline and third-party tool workflows

### Modified Capabilities

_(none — existing specs are unaffected; W3C export is currently unspecified)_

## Impact

- `Sources/ExFigCLI/Output/W3CTokensExporter.swift` — core export format changes
- `Sources/ExFigCLI/Output/DownloadExportHelpers.swift` — updated helpers for new format
- `Sources/ExFigCLI/Subcommands/Download.swift` — new `tokens` subcommand
- `Sources/ExFigCLI/Loaders/Colors/ColorsVariablesLoader.swift` — expand to load number/dimension variables
- `Sources/ExFigCLI/Resources/Schemas/Common.pkl` — new `tokensFile` source type
- `Tests/ExFigTests/Output/W3CTokensExporterTests.swift` — updated expected JSON
