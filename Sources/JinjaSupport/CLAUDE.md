# CLAUDE.md

## Module Overview

JinjaSupport is a **thin wrapper** around [swift-jinja](https://github.com/maiqingqiang/swift-jinja) that provides template loading, rendering, and error handling for all export modules. It is consumed by `XcodeExporterBase`, `AndroidExporterBase`, `FlutterExporterBase`, and `WebExporterBase`.

## Build & Test

```bash
./bin/mise run test:filter JinjaSupportTests
```

## Architecture

Two files:

| File                          | Purpose                                                                       |
| ----------------------------- | ----------------------------------------------------------------------------- |
| `JinjaTemplateRenderer.swift` | Template loading (custom path → bundle fallback), rendering, header injection |
| `TemplateLoadError.swift`     | Error types: `notFound`, `renderFailed`, `contextConversionFailed`            |

### Template Loading Order

`loadTemplate(named:templatesPath:)` searches in order:

1. `templatesPath` (custom user templates) — any read failure falls through
2. `bundle.resourcePath/Resources/` — SPM resource subdirectory
3. `bundle.resourcePath/` — flat bundle root

First successful read wins. If all fail → `TemplateLoadError.notFound` with all searched paths.

### Context Conversion

`renderTemplate(source:context:)` converts `[String: Any]` to `[String: Value]` via `Value(any:)`. Supported types: `String`, `Bool`, `Int`, `Double`, arrays, dictionaries. Unsupported types throw `contextConversionFailed`.

## swift-jinja Whitespace Gotchas

- `{% if false %}...{% endif %}\n` renders `"\n"` (newline after `endif` preserved), NOT `""`
- Empty arrays `[]` are **falsy** in conditions
- Partial templates (`.jinja.include`) rendered into context variables may produce whitespace-only strings — callers must strip if needed (see `XcodeExporterBase.contextWithHeaderAndBundle`)

## Key Conventions

- `@unchecked Sendable` — renderer is immutable after init, safe to share across tasks
- Custom path errors **always** fall through to bundle (including permission errors, Linux non-CocoaError types)
- `contextWithHeader` is a convenience that loads `header.jinja` and merges into context dict

## Modification Checklist

When adding a new public method:

1. Add to `JinjaTemplateRenderer.swift`
2. Expose through `XcodeExporterBase` / other base classes if needed
3. Add test in `JinjaSupportTests/JinjaTemplateRendererTests.swift`

When changing error types:

1. Update `TemplateLoadError` enum case
2. Update `errorDescription` computed property
3. Update tests that pattern-match on error cases
