# Change: Add Web Platform Export

## Why

ExFig currently supports iOS, Android, and Flutter platforms. Web/React projects use a separate toolchain with different patterns and output formats. Adding native Web support to ExFig enables:

- Unified Figma-to-code pipeline across all platforms
- Consistent asset naming and structure
- Single source of truth for design tokens and icons
- Reduced maintenance burden (one tool instead of two)

## What Changes

### New Module: WebExport

Add `Sources/WebExport/` module following established patterns from FlutterExport:

- **Colors Export**: CSS variables (`.theme-light { --name: #hex; }`), TypeScript constants (`var(--name)`), JSON tokens
- **Icons Export**: React TSX components via SVGR pattern, raw SVG files, barrel `index.ts`
- **Images Export**: React TSX components, raw PNG/SVG files, barrel `index.ts`

### Stencil Templates

Default templates in `Sources/WebExport/Resources/` generate web-ui compatible output:

- `theme.css.stencil` — CSS with class-based selectors (`.theme-light`, `.theme-dark`)
- `variables.ts.stencil` — TypeScript with `export const variables = {...} as const`
- `Icon.tsx.stencil` — React component with `SVGProps`, `color`, `size`, `style` props
- `types.ts.stencil` — TypeScript interface extending `SVGAttributes<SVGElement>`
- `index.ts.stencil` — Barrel exports (`export * from './component-name'`)

Custom templates can be specified via `web.templatesPath` configuration option.

### Configuration

New `web:` section in YAML config with platform-specific output options:

```yaml
web:
  colors:
    - tokensFileId: "xxx"
      outputDirectory: "src/tokens"
      cssFileName: "theme.css"
      tsFileName: "variables.ts"
  icons:
    - figmaFrameName: "Icons"
      outputDirectory: "src/icons"
      svgDirectory: "assets/icons"
      generateReactComponents: true
```

### CLI Integration

Existing commands (`exfig colors`, `exfig icons`, `exfig images`) will automatically process web config when present,
following the same pattern as other platforms.

## Impact

- Affected specs: None (new capability)
- Affected code:
  - `Package.swift` - new target
  - `Sources/ExFigCore/Platform.swift` - new `.web` case
  - `Sources/ExFig/Input/Params.swift` - new `Web` struct
  - `Sources/ExFig/Subcommands/*.swift` - web export sections
- **BREAKING**: None. Additive change only.
