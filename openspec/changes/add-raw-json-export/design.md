# Design: Raw JSON Export

## Context

ExFig fetches data from Figma API and transforms it through platform-specific exporters. Users have no way to access
the raw API responses for debugging or custom processing.

### Stakeholders

- Developers debugging Figma integration issues
- Teams building custom asset pipelines
- CI/CD systems needing data inspection

## Goals / Non-Goals

### Goals

- Export raw Figma API responses as JSON files
- Support all data types (colors, icons, images, typography)
- Maintain existing export behavior as default
- Provide structured, well-formatted JSON output

### Non-Goals

- Full Figma API client replacement
- GraphQL or custom query support
- Real-time sync with Figma

## Decisions

### Decision 1: Command Structure

**Options considered**:

| Option | Pros | Cons |
|--------|------|------|
| `--raw-json` flag on existing commands | Familiar UX, single entry point | Mixes concerns |
| Separate `download` command | Clear separation, focused | Another command to learn |
| Both approaches | Maximum flexibility | More code to maintain |

**Decision**: Implement **separate `download` command** with subcommands.

```bash
exfig download colors -o ./raw/colors.json
exfig download icons -o ./raw/icons.json
exfig download images -o ./raw/images.json
exfig download typography -o ./raw/typography.json
exfig download all -o ./raw/           # Downloads all types
```

### Decision 2: JSON Structure

**Decision**: Preserve Figma API structure with metadata wrapper.

```json
{
  "meta": {
    "exportedAt": "2024-01-15T10:30:00Z",
    "figmaFileKey": "abc123",
    "figmaFileVersion": "123456789",
    "exfigVersion": "1.0.0",
    "dataType": "colors"
  },
  "data": {
    // Raw Figma API response
  }
}
```

### Decision 3: Output Location

**Decision**: Support both file and directory output.

- Single type: `-o ./colors.json` (file path)
- All types: `-o ./raw/` (directory, creates `colors.json`, `icons.json`, etc.)

## Risks / Trade-offs

| Risk | Impact | Mitigation |
|------|--------|------------|
| Large JSON files | Medium | Add `--pretty` flag (default) and `--compact` option |
| API response changes | Low | Document that raw format follows Figma API |

## Open Questions

1. Should we support filtering in raw mode (e.g., specific frames)?
2. Should raw JSON include computed values (resolved variables)?
