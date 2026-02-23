## 1. W3C v2025.10 Color Format Compliance

- [ ] 1.1 Refactor `exportColors()` in `W3CTokensExporter.swift`: single `$value` string per token (default mode hex)
- [ ] 1.2 Add `$extensions.modes` object for multi-mode colors (mode name → hex value)
- [ ] 1.3 Add `--w3c-version v1|v2025` flag to download commands (default: v2025, v1 preserves current format)
- [ ] 1.4 Update `W3CTokensExporterTests.swift` for new color format (single $value, $extensions.modes)
- [ ] 1.5 Update `DownloadExportHelpers.swift` for new format and version flag

## 2. Token Extensions & Descriptions

- [ ] 2.1 Add `$extensions.exfig` with Figma metadata (variableId, fileId, nodeId) to color tokens
- [ ] 2.2 Add `$extensions.exfig` to asset tokens (nodeId, fileId)
- [ ] 2.3 Ensure `$extensions` merges mode data and exfig metadata when both present
- [ ] 2.4 Add `$description` field from Figma variable descriptions (skip empty/whitespace-only)
- [ ] 2.5 Write tests for extensions and descriptions output

## 3. Token Aliases

- [ ] 3.1 Extend `ColorsVariablesLoader` to propagate alias paths alongside resolved values (new field on Color or wrapper type)
- [ ] 3.2 Implement `"{Group.Token}"` alias syntax in `W3CTokensExporter.exportColors()` for semantic tokens
- [ ] 3.3 Support per-mode aliases in `$extensions.modes` (each mode value can be an alias string)
- [ ] 3.4 Disable alias output when `--w3c-version v1` is specified
- [ ] 3.5 Write tests for alias output (direct alias, multi-mode aliases, v1 flag)

## 4. Remove Invented Types

- [ ] 4.1 Replace `$type: "asset"` with `$extensions.exfig.assetUrl` in `exportAssets()`
- [ ] 4.2 Preserve `$type: "asset"` behavior under `--w3c-version v1`
- [ ] 4.3 Update asset export tests

## 5. Dimension & Number Token Types (Phase 2)

- [ ] 5.1 Extend `ColorsVariablesLoader` (or create `DesignTokensLoader`) to load Figma number variables with scopes
- [ ] 5.2 Implement scope-to-type mapping: spatial scopes → `dimension`, unitless scopes → `number`
- [ ] 5.3 Add `exportDimensions()` and `exportNumbers()` methods to `W3CTokensExporter`
- [ ] 5.4 Add `$extensions.exfig.unit` for dimension tokens where determinable
- [ ] 5.5 Write tests for dimension and number token export

## 6. Typography Decomposition (Phase 2)

- [ ] 6.1 Modify `exportTypography()` to emit individual sub-tokens (fontFamily, fontWeight, fontSize, lineHeight, letterSpacing) alongside composite
- [ ] 6.2 Use correct W3C `$type` for each sub-token (fontFamily, fontWeight, dimension for sizes)
- [ ] 6.3 Skip optional sub-tokens (lineHeight, letterSpacing) when not set
- [ ] 6.4 Preserve composite-only behavior under `--w3c-version v1`
- [ ] 6.5 Write tests for typography decomposition

## 7. Unified Download Command (Phase 2)

- [ ] 7.1 Add `download tokens` subcommand (or expand existing `download colors --tokens`) for unified export
- [ ] 7.2 Wire dimension + number + typography export into unified command
- [ ] 7.3 Write integration test for unified token export

## 8. TokensFileSource Parser (Phase 3)

- [ ] 8.1 Create `TokensFileSource.swift` with W3C DTCG JSON parser using JSONCodec (swift-yyjson)
- [ ] 8.2 Implement nested group parsing with `$type` inheritance
- [ ] 8.3 Implement W3C token type → ExFigCore model mapping (color→Color, typography→TextStyle)
- [ ] 8.4 Implement alias resolution with circular reference detection
- [ ] 8.5 Implement validation: missing $value, invalid hex, malformed JSON
- [ ] 8.6 Emit warnings for unsupported token types (cubicBezier, gradient, etc.)
- [ ] 8.7 Write comprehensive parser tests (flat tokens, nested groups, aliases, validation errors)

## 9. PKL Schema & Config Integration (Phase 3)

- [ ] 9.1 Add `Common.TokensFile` class to `Sources/ExFigCLI/Resources/Schemas/Common.pkl` with `path` and optional `groupFilter`
- [ ] 9.2 Run `./bin/mise run codegen:pkl` to regenerate Swift types
- [ ] 9.3 Add bridging in platform entry files for new `tokensFile` source type
- [ ] 9.4 Integrate `TokensFileSource` into export pipeline (bypass Figma API when tokensFile source used)
- [ ] 9.5 Write tests for PKL config with tokensFile source (with and without groupFilter)
- [ ] 9.6 Write integration test: export colors from .tokens.json without FIGMA_PERSONAL_TOKEN
