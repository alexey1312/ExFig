## 1. W3C v2025.10 Color Format Compliance

- [x] 1.1 Refactor `exportColors()` in `W3CTokensExporter.swift`: `$value` as color object (`colorSpace`, `components`, optional `alpha`/`hex`) instead of hex string
- [x] 1.2 Implement `colorToObject()` helper: RGBA → `{"colorSpace": "srgb", "components": [r,g,b], "alpha": a, "hex": "#rrggbb"}` (omit alpha when 1.0, hex is always 6-digit)
- [x] 1.3 Add `$extensions.com.exfig.modes` object for multi-mode colors (mode name → color object)
- [x] 1.4 Omit modes extension when only one mode is present
- [x] 1.5 Add `--w3c-version v1|v2025` flag to download commands (default: v2025, v1 preserves current hex string format)
- [x] 1.6 Update `W3CTokensExporterTests.swift` for new color object format (colorSpace, components, alpha, hex)
- [x] 1.7 Update `DownloadExportHelpers.swift` for new format and version flag

## 2. Token Extensions & Descriptions

- [x] 2.1 Add `$extensions.com.exfig` (reverse-domain key) with Figma metadata (variableId, fileId, nodeId) to color tokens
- [x] 2.2 Add `$extensions.com.exfig` to asset tokens (nodeId, fileId, assetUrl)
- [x] 2.3 Ensure `$extensions.com.exfig` merges mode data and Figma metadata when both present
- [x] 2.4 Add `$description` field from Figma variable descriptions (skip empty/whitespace-only)
- [x] 2.5 Write tests for extensions and descriptions output

## 3. Token Aliases

- [x] 3.1 Extend `ColorsVariablesLoader` to propagate alias paths alongside resolved values (new field on Color or wrapper type)
- [x] 3.2 Implement `"{Group.Token}"` alias syntax in `W3CTokensExporter.exportColors()` for semantic tokens
- [x] 3.3 Support per-mode aliases in `$extensions.com.exfig.modes` (each mode value can be an alias string)
- [x] 3.4 Disable alias output when `--w3c-version v1` is specified
- [x] 3.5 Write tests for alias output (direct alias, multi-mode aliases, v1 flag)

## 4. Remove Invented Types

- [x] 4.1 Replace `$type: "asset"` with `$extensions.com.exfig.assetUrl` in `exportAssets()`
- [x] 4.2 Preserve `$type: "asset"` behavior under `--w3c-version v1`
- [x] 4.3 Update asset export tests

## 5. Dimension & Number Token Types (Phase 2)

- [x] 5.1 Extend `ColorsVariablesLoader` (or create `DesignTokensLoader`) to load Figma number variables with scopes
- [x] 5.2 Implement scope-to-type mapping: spatial scopes → `dimension`, unitless scopes → `number`
- [x] 5.3 Add `exportDimensions()` method: `$value` as object `{"value": N, "unit": "px"}` (default unit "px")
- [x] 5.4 Add `exportNumbers()` method: `$value` as plain JSON number
- [x] 5.5 Map `FONT_WEIGHT` scope to `number` type (not dimension)
- [x] 5.6 Write tests for dimension and number token export (verify object format for dimension, plain number for number)

## 6. Typography Decomposition (Phase 2)

- [x] 6.1 Modify `exportTypography()` to emit individual sub-tokens alongside composite
- [x] 6.2 Use correct W3C `$type` and `$value` format for each sub-token:
  - `fontFamily`: `$type: "fontFamily"`, `$value`: array of strings (e.g., `["Inter"]`)
  - `fontWeight`: `$type: "fontWeight"`, `$value`: number (1–1000) or string alias
  - `fontSize`: `$type: "dimension"`, `$value`: object `{"value": N, "unit": "px"}`
  - `lineHeight`: `$type: "number"`, `$value`: plain number (ratio, not px)
  - `letterSpacing`: `$type: "dimension"`, `$value`: object `{"value": N, "unit": "px"}`
- [x] 6.3 Convert lineHeight from px to ratio when Figma provides absolute px value (lineHeight / fontSize)
- [x] 6.4 Emit fontFamily as array format in composite `$value` (e.g., `["Inter"]` not `"Inter"`)
- [x] 6.5 Skip optional sub-tokens (lineHeight, letterSpacing) when not set
- [x] 6.6 Preserve composite-only behavior under `--w3c-version v1`
- [x] 6.7 Write tests for typography decomposition (verify dimension objects for fontSize, plain number for lineHeight)

## 7. Unified Download Command (Phase 2)

- [x] 7.1 Add `download tokens` subcommand (or expand existing `download colors --tokens`) for unified export
- [x] 7.2 Wire dimension + number + typography export into unified command
- [x] 7.3 Write integration test for unified token export

## 8. TokensFileSource Parser (Phase 3)

- [ ] 8.1 Create `TokensFileSource.swift` with W3C DTCG JSON parser using JSONCodec (swift-yyjson)
- [ ] 8.2 Implement nested group parsing with `$type` inheritance from parent groups
- [ ] 8.3 Parse color `$value` objects: extract colorSpace, components, alpha, hex → convert to ExFigCore `Color`
- [ ] 8.4 Parse dimension `$value` objects: extract value and unit
- [ ] 8.5 Parse typography composite `$value`: fontFamily (string or array), fontSize (dimension object), fontWeight (number or string alias), lineHeight (number)
- [ ] 8.6 Implement W3C token type → ExFigCore model mapping (color→Color, typography→TextStyle)
- [ ] 8.7 Implement alias resolution with circular reference detection
- [ ] 8.8 Support `$root` tokens within groups (referenced as `{group.$root}`)
- [ ] 8.9 Support `$extends` group inheritance (deep merge from referenced group)
- [ ] 8.10 Support `$deprecated` on tokens and groups (boolean or string, preserved as metadata)
- [ ] 8.11 Handle non-sRGB color spaces: convert to sRGB or warn about gamut clipping
- [ ] 8.12 Map fontWeight string aliases to numeric values ("bold"→700, "normal"→400, etc.)
- [ ] 8.13 Implement validation: missing $value, invalid color object structure, invalid dimension object, malformed JSON
- [ ] 8.14 Emit warnings for unsupported token types (cubicBezier, gradient, strokeStyle, border, transition, shadow, duration)
- [ ] 8.15 Write comprehensive parser tests (flat tokens, nested groups, aliases, $root, $extends, validation errors)

## 9. PKL Schema & Config Integration (Phase 3)

- [ ] 9.1 Add `Common.TokensFile` class to `Sources/ExFigCLI/Resources/Schemas/Common.pkl` with `path` and optional `groupFilter`
- [ ] 9.2 Run `./bin/mise run codegen:pkl` to regenerate Swift types
- [ ] 9.3 Add bridging in platform entry files for new `tokensFile` source type
- [ ] 9.4 Integrate `TokensFileSource` into export pipeline (bypass Figma API when tokensFile source used)
- [ ] 9.5 Write tests for PKL config with tokensFile source (with and without groupFilter)
- [ ] 9.6 Write integration test: export colors from .tokens.json without FIGMA_PERSONAL_TOKEN
