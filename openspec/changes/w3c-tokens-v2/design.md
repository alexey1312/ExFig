# Design: W3C Design Tokens v2025.10 Compliance

## Context

ExFig already exports design tokens via `W3CTokensExporter`, but the implementation targets an early Community Group
draft. The W3C Design Tokens Community Group (DTCG) specification reached stable v2025.10 (October 2025), and all major
competitors (Tokens Studio, Style Dictionary v4, Supernova) are already compliant.

The v2025.10 spec is composed of three modules: **Format** (token structure, groups, aliases), **Color** (color
spaces, component representation), and **Resolver** (theming, modes, multi-brand). This design targets all three.

Current divergences from the spec:

| Issue             | Current Behavior                  | W3C v2025.10 Spec                                              |
| ----------------- | --------------------------------- | -------------------------------------------------------------- |
| Color `$value`    | `{mode: hex}` dict (non-standard) | Object with `colorSpace`, `components`, optional `alpha`/`hex` |
| Multi-mode colors | Embedded in `$value`              | Resolver module (separate file) or `$extensions` vendor data   |
| Asset type        | `$type: "asset"` (invented)       | No `asset` type in spec                                        |
| Extensions        | Not emitted                       | `$extensions` for vendor metadata (reverse-domain keys)        |
| Aliases           | Not supported                     | `{Group.Token}` reference syntax + JSON Pointer `$ref`         |
| Descriptions      | Partial (colors only)             | `$description` on any token                                    |
| Number types      | Not supported                     | `dimension` (object: value+unit), `number` (plain numeric)     |
| Typography        | Composite only                    | Individual sub-tokens alongside composite                      |
| Dimension format  | N/A                               | Object: `{"value": 16, "unit": "px"}`, not plain number       |
| Group features    | N/A                               | `$deprecated`, `$extends` (group inheritance), `$root` tokens  |

The exporter uses `JSONSerialization` (Foundation) for output, producing `[String: Any]` dictionaries that are
type-unsafe and harder to test.

`ColorsVariablesLoader` currently resolves variable aliases internally to produce flat `[Color]` arrays. Alias
information (which semantic token references which primitive) is discarded before reaching the exporter.

## Goals / Non-Goals

**Goals:**

- Achieve W3C DTCG v2025.10 compliance for exported `.tokens.json` files
- Expand token type support: `dimension`, `number`, individual typography sub-tokens
- Preserve token alias relationships in output (`{Group.Token}` references)
- Support importing `.tokens.json` files as an alternative source to Figma API
- Maintain backward compatibility for existing export consumers via version flag
- Each phase (compliance, types, import) delivers independently useful value

**Non-Goals:**

- Building a full design token management system (CRUD, versioning, merging)
- Supporting non-W3C formats as import sources (Figma Tokens v1, Style Dictionary v3)
- Real-time sync between Figma and token files
- Token transformation pipelines (color space conversion, unit conversion)
- Token validation beyond structural conformance (no semantic lint rules)

## Decisions

### Decision 1: Color Format & Modes via `$extensions.com.exfig.modes`

**Choice:** Use the v2025.10 Color Module object format for `$value` with `colorSpace`, `components`, optional `alpha`
and `hex`. Represent multi-mode colors using `$extensions.com.exfig.modes` within a single token.

```json
{
  "Background": {
    "Primary": {
      "$type": "color",
      "$value": {
        "colorSpace": "srgb",
        "components": [1, 1, 1],
        "hex": "#ffffff"
      },
      "$extensions": {
        "com.exfig": {
          "modes": {
            "Light": { "colorSpace": "srgb", "components": [1, 1, 1], "hex": "#ffffff" },
            "Dark": { "colorSpace": "srgb", "components": [0.102, 0.102, 0.102], "hex": "#1a1a1a" }
          }
        }
      }
    }
  }
}
```

The `$value` field holds the default mode value (first/light mode) as a color object. Additional modes are in
`$extensions.com.exfig.modes`, each value being a color object with the same structure.

The `hex` field is an optional 6-digit sRGB fallback (per spec: "6 digit CSS hex color notation"). Alpha transparency
is represented via the `alpha` field (0–1), not in the hex string.

**Rationale:** The v2025.10 Color Module requires structured color objects to support modern color spaces (Display P3,
OKLCH, etc.) beyond sRGB. Single-file output with modes in `$extensions` is simpler to consume and version-control.

The W3C spec includes a separate Resolver module for theming/modes (separate resolver JSON file), but it requires
multi-file architecture and a resolver document. The `$extensions` approach keeps everything in one file, which is
better for ExFig's primary use case (CI export). Resolver module support can be added later as an option.

**Alternatives considered:**

| Approach                        | Pros                                       | Cons                                                           |
| ------------------------------- | ------------------------------------------ | -------------------------------------------------------------- |
| Resolver module (spec-native)   | Fully spec-compliant theming, fallback chains | Multi-file, complex architecture, overkill for simple L/D    |
| `$extensions` modes (chosen)    | Single file, mode relationship explicit    | Vendor extension, requires ExFig-aware tool support            |
| Separate file per mode          | Clean separation, each file is spec-pure   | Multiple files to manage, harder to diff                       |
| `$value` as mode dict (current) | Compact                                    | Violates spec (`$value` must be a color object)                |

### Decision 2: Asset References via `$extensions.com.exfig.assetUrl`

**Choice:** Replace `$type: "asset"` with asset URL stored in `$extensions.com.exfig.assetUrl`. The token itself gets
no `$type` (or uses a future W3C-defined type if one emerges).

```json
{
  "Icons": {
    "Search": {
      "$extensions": {
        "com.exfig": {
          "assetUrl": "https://figma.com/images/...",
          "nodeId": "1:23",
          "fileId": "abc123"
        }
      }
    }
  }
}
```

**Rationale:** The W3C spec defines a closed set of `$type` values. Using `"asset"` causes validation failures in
compliant tools. The `$extensions` namespace is the designated escape hatch for vendor data. Keys use reverse-domain
notation (`com.exfig`) per the spec recommendation.

**Alternatives considered:**

- Keep `$type: "asset"`: Breaks validation in Tokens Studio and Style Dictionary v4.
- Use `$type: "link"` or `$type: "url"`: Also not in spec; equally non-compliant.
- Omit asset tokens entirely: Loses valuable metadata for downstream consumers.

### Decision 3: Token Aliases Using W3C Reference Syntax

**Choice:** Semantic tokens that reference primitives use `$value: "{Group.Token}"` alias syntax per the W3C spec.

```json
{
  "Primitives": {
    "Blue": {
      "500": {
        "$type": "color",
        "$value": { "colorSpace": "srgb", "components": [0.231, 0.510, 0.965], "hex": "#3b82f6" }
      }
    }
  },
  "Semantic": {
    "Primary": { "$type": "color", "$value": "{Primitives.Blue.500}" }
  }
}
```

**Rationale:** The W3C spec defines alias syntax as `{path.to.token}` using dot-separated group paths. This enables
round-trip workflows: export from Figma with aliases, import into Style Dictionary, re-export. The spec also supports
JSON Pointer (`$ref`) syntax for property-level access, but curly-brace aliases are sufficient for token-level
references and are more widely supported by tools.

**Impact on ColorsVariablesLoader:** Currently, `handleColorMode` resolves `variableAlias` cases recursively and
discards the reference. To preserve aliases, the loader must propagate `variableAlias.id` alongside resolved values.
A new `ResolvedColor` type (or extending `Color` with optional `aliasPath`) carries this information to the exporter.

**Alternatives considered:**

- Resolved values only (current): Simpler but loses relationship data; no round-trip possible.
- Custom alias syntax: Non-standard; breaks interop with other token tools.

### Decision 4: Figma Variable Scope to W3C Token Type Mapping

**Choice:** Map Figma number variables to W3C types based on their `scopes` array. Dimension tokens use the v2025.10
object format `{"value": N, "unit": "px"}` — the unit is part of the value, not in `$extensions`.

| Figma Variable Scope       | W3C Token Type | `$value` Format                      |
| -------------------------- | -------------- | ------------------------------------ |
| `WIDTH_HEIGHT`, `GAP`      | `dimension`    | `{"value": 16, "unit": "px"}`       |
| `CORNER_RADIUS`            | `dimension`    | `{"value": 8, "unit": "px"}`        |
| `OPACITY`                  | `number`       | `0.5`                                |
| `FONT_SIZE`, `LINE_HEIGHT` | `dimension`    | `{"value": 16, "unit": "px"}`       |
| `FONT_WEIGHT`              | `number`       | `400`                                |
| (no scope / unknown)       | `number`       | Raw numeric value                    |

The dimension `$value` is an object with `value` (number) and `unit` (`"px"` or `"rem"` per spec). Figma variables
don't carry unit information, so ExFig defaults to `"px"`. The number `$value` is a plain JSON number.

**Rationale:** Figma's `scopes` array (from Variables API) encodes design intent. Spacing, sizing, and radius are
dimensional values (need units in rendering context). Opacity and z-index are unitless numbers. The v2025.10 spec
requires dimension values to be objects — unit is NOT separate metadata but part of the value itself.

**Alternatives considered:**

- Export all as `number`: Loses dimensional semantics; tools like Style Dictionary cannot apply unit transforms.
- Require explicit mapping in PKL config: Too much user burden; Figma already provides the semantic signal.
- Put unit in `$extensions`: Would violate spec; dimension `$value` MUST include unit.

### Decision 5: New `TokensFileSource` Using JSONCodec (swift-yyjson)

**Choice:** Implement the `.tokens.json` parser using `JSONCodec` (swift-yyjson) for high-performance JSON parsing,
with strongly-typed Swift models for the W3C token schema.

```swift
struct TokenDocument: Decodable {
    // Top-level groups, recursively nested
    let groups: [String: TokenGroup]
}

struct TokenGroup: Decodable {
    let type: String?          // $type (inherited by children)
    let description: String?   // $description
    let deprecated: Deprecated? // $deprecated (bool or string)
    let extends: String?       // $extends (reference to another group)
    let extensions: [String: Any]? // $extensions
    let root: TokenValue?      // $root (root token alongside child tokens)
    let tokens: [String: TokenValue]
    let groups: [String: TokenGroup]
}
```

The parser must handle v2025.10 group features:
- **`$root`**: Groups may contain a root token (`$root`) alongside child tokens, referenced as `{group.$root}`
- **`$extends`**: Groups may inherit tokens/properties from another group via deep merge
- **`$deprecated`**: Tokens and groups may be marked deprecated (boolean `true` or explanation string)

**Rationale:** The project already uses `JSONCodec` (swift-yyjson) as its standard JSON codec. `JSONSerialization`
produces untyped `[String: Any]` dictionaries requiring unsafe casts. Typed models enable compile-time validation and
easier testing.

**Alternatives considered:**

- Foundation `JSONSerialization`: Already used in current exporter; untyped, error-prone.
- `JSONDecoder`: Standard but significantly slower than yyjson for large token files.
- Third-party token parser: No Swift library exists for W3C DTCG format.

### Decision 6: Phased Rollout

**Choice:** Deliver in three independent phases, each providing standalone value:

| Phase   | Scope                                                      | Value                                        |
| ------- | ---------------------------------------------------------- | -------------------------------------------- |
| Phase 1 | Export compliance (format, extensions, aliases)            | Interop with Tokens Studio, Style Dictionary |
| Phase 2 | Token type expansion (dimension, number, typography split) | Richer design system export                  |
| Phase 3 | Import `.tokens.json` as source                            | Offline workflows, CI without Figma token    |

**Rationale:** Each phase can be shipped, tested, and validated independently. Phase 1 fixes the most critical
interoperability issues. Phase 3 is the most complex (new data path) and benefits from Phase 1/2 stabilization.

### Decision 7: Backward Compatibility via `--w3c-version` Flag

**Choice:** Add `--w3c-version v1|v2025` flag (default: `v2025`) to `download` commands. `v1` preserves current
format for consumers not yet migrated.

**Rationale:** Existing CI pipelines may parse the current non-standard format. A flag provides a migration path
without breaking changes.

**Alternatives considered:**

- No flag, always v2025: Cleanest but breaks existing consumers without warning.
- Auto-detect from existing output: Fragile; output file may not exist on first run.
- Separate command (`download tokens-v2`): Confusing; two commands doing nearly the same thing.

## Risks / Trade-offs

| Risk                                                            | Impact | Likelihood | Mitigation                                                                                                                    |
| --------------------------------------------------------------- | ------ | ---------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Breaking change for existing W3C export consumers               | High   | Medium     | `--w3c-version v1` flag preserves old format; document migration                                                              |
| Token alias resolution requires variable collection access      | Medium | High       | Extend `ColorsVariablesLoader` return type to carry alias paths; existing `VariablesEndpoint` already returns collection data |
| `.tokens.json` import creates alternative code path to maintain | Medium | Certain    | Converge both paths to shared `ExFigCore` domain models; test parity between Figma and file sources                           |
| Figma Variables API scope data may be incomplete                | Low    | Medium     | Fall back to `number` type when scope is unknown; allow PKL config override                                                   |
| W3C spec may evolve further                                     | Low    | Low        | `$extensions.com.exfig` namespace isolates vendor data; core format tracks spec                                               |
| Large token files (1000+ tokens) may slow JSON parsing          | Low    | Low        | swift-yyjson handles multi-MB JSON in milliseconds; not a bottleneck                                                          |
