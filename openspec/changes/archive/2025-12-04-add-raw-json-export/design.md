# Design: JSON Export with W3C Design Tokens

## Context

ExFig fetches data from Figma API and transforms it through platform-specific exporters. Users have no way to access
design data in a platform-agnostic JSON format for integration with design token tools.

### Stakeholders

- Design systems teams needing cross-platform token synchronization
- Developers integrating with design token pipelines (Style Dictionary, Tokens Studio)
- Teams building custom asset pipelines
- Developers debugging Figma integration issues

## Goals / Non-Goals

### Goals

- Export Figma design data in W3C Design Tokens format (default)
- Export raw Figma API responses for debugging
- Support all data types (colors, icons, images, typography)
- Handle Figma modes (Light, Dark, etc.) as token value variants

### Non-Goals

- Full Figma API client replacement
- GraphQL or custom query support
- Real-time sync with Figma
- Token transformation/theming logic

## Decisions

### Decision 1: Output Format

**Options considered**:

| Option                    | Pros                      | Cons                        |
| ------------------------- | ------------------------- | --------------------------- |
| Raw Figma JSON only       | Simple, no transformation | Hard to use, Figma-specific |
| W3C Design Tokens only    | Industry standard, clean  | Loses some Figma metadata   |
| Both with `--format` flag | Maximum flexibility       | More code to maintain       |

**Decision**: Support both formats via `--format w3c|raw` flag, with **W3C as default**.

```bash
exfig download colors -o tokens.json              # W3C format (default)
exfig download colors -o tokens.json --format w3c # Explicit W3C
exfig download colors -o raw.json --format raw    # Raw Figma API
```

### Decision 2: W3C Design Tokens Structure

**Decision**: Follow [W3C Design Tokens Format](https://design-tokens.github.io/community-group/format/) specification.

```json
{
  "Statement": {
    "Background": {
      "PrimaryPressed": {
        "$type": "color",
        "$value": {
          "Light": "#022c8c",
          "Dark": "#99bbff",
          "Contrast Light": "#001c59",
          "Contrast Dark": "#ccdeff"
        },
        "$description": "For pressed backgrounds on statements"
      }
    }
  }
}
```

Key mappings:

| Figma Concept            | W3C Token                          |
| ------------------------ | ---------------------------------- |
| Variable name hierarchy  | Nested object path (slash → depth) |
| Variable resolvedType    | `$type` (color, number, string)    |
| Variable description     | `$description`                     |
| Variable valuesByMode    | `$value` object with mode keys     |
| RGBA color (0-1 range)   | Hex string (#RRGGBB or #RRGGBBAA)  |
| VARIABLE_ALIAS reference | Resolved to final value            |

### Decision 3: Command Structure

**Decision**: Implement `download` command with subcommands.

```bash
exfig download colors -o ./tokens/colors.json
exfig download icons -o ./tokens/icons.json
exfig download images -o ./tokens/images.json
exfig download typography -o ./tokens/typography.json
exfig download all -o ./tokens/           # All types to directory
```

### Decision 4: Raw Format Structure

**Decision**: For `--format raw`, preserve Figma API structure with metadata wrapper.

```json
{
  "source": {
    "name": "Design System",
    "fileId": "abc123",
    "exportedAt": "2024-01-15T10:30:00Z",
    "exfigVersion": "1.0.0"
  },
  "data": {
    "status": 200,
    "meta": {
      "variableCollections": { ... },
      "variables": { ... }
    }
  }
}
```

### Decision 5: Token Type Mapping

| Data Type  | W3C $type    | Notes                                 |
| ---------- | ------------ | ------------------------------------- |
| Colors     | `color`      | Hex format, mode variants             |
| Typography | `typography` | Composite: fontFamily, fontSize, etc. |
| Icons      | `asset`      | Figma export URL in selected format   |
| Images     | `asset`      | Figma export URL in selected format   |

### Decision 6: Asset Export Format

**Decision**: Support `--asset-format` flag for icons and images with Figma export URLs. Default: PNG @3x.

```bash
exfig download icons -o icons.json                      # PNG @3x (default)
exfig download icons -o icons.json --asset-format svg   # SVG
exfig download icons -o icons.json --asset-format pdf   # PDF
exfig download images -o images.json --scale 2          # PNG @2x
```

Supported formats: `svg`, `png` (default), `pdf`, `jpg`

Asset token structure:

```json
{
  "Icons": {
    "Navigation": {
      "ArrowLeft": {
        "$type": "asset",
        "$value": "https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/...",
        "$description": "Left arrow navigation icon"
      }
    }
  }
}
```

For raster formats (PNG, JPG), support `--scale` option (1, 2, 3, 4). Default: 3.

## Risks / Trade-offs

| Risk                      | Impact | Mitigation                               |
| ------------------------- | ------ | ---------------------------------------- |
| W3C spec still evolving   | Low    | Follow current draft, document version   |
| Variable alias resolution | Medium | Resolve all aliases to final values      |
| Large token files         | Medium | Add `--compact` flag for minified output |

## Open Questions

1. ~~Should we support filtering in raw mode?~~ — Deferred to future enhancement
2. ~~Should raw JSON include computed values?~~ — Yes, resolve all aliases
