# CLAUDE.md

## Module Overview

JinjaSupport is a **thin wrapper** around [swift-jinja](https://github.com/maiqingqiang/swift-jinja) that provides template loading, rendering, and error handling for all export modules. It is consumed by `XcodeExporterBase`, `AndroidExporter`, `FlutterExporter`, and `WebExporter`.

## Build & Test

```bash
./bin/mise run test:filter JinjaSupportTests
```

## Architecture

Two files:

| File                          | Purpose                                                                                |
| ----------------------------- | -------------------------------------------------------------------------------------- |
| `JinjaTemplateRenderer.swift` | Template loading (custom path → bundle fallback), rendering, header injection          |
| `TemplateLoadError.swift`     | Error types: `notFound`, `renderFailed`, `contextConversionFailed`, `customPathFailed` |

### Template Loading Order

`loadTemplate(named:templatesPath:)` searches in order:

1. `templatesPath` (custom user templates) — only file-not-found falls through; other errors (permissions, I/O) throw `customPathFailed`
2. `bundle.resourcePath/Resources/` — SPM resource subdirectory
3. `bundle.resourcePath/` — flat bundle root

First successful read wins. If all fail → `TemplateLoadError.notFound` with all searched paths.

### Context Conversion

`renderTemplate(source:context:templateName:)` converts `[String: Any]` to `[String: Value]` via `Value(any:)`. Supported types: `String`, `Bool`, `Int`, `Double`, `Float`, arrays, dictionaries, `nil`/`NSNull`. Unsupported types throw `contextConversionFailed`. When `templateName` is provided, Jinja render errors are wrapped with `renderFailed(name:underlyingError:)` for diagnostics.

## swift-jinja Whitespace Gotchas

- `{% if false %}...{% endif %}\n` renders `"\n"` (newline after `endif` preserved), NOT `""`
- Empty arrays `[]` are **falsy** in conditions
- Partial templates (`.jinja.include`) rendered into context variables may produce whitespace-only strings — callers must strip if needed (see `XcodeExporterBase.contextWithHeaderAndBundle`)
- Do not add Jinja comments (`{# #}` or `{#- -#}`) to `.jinja.include` files — even whitespace-trimming syntax alters rendering and breaks append-mode tests

## Key Conventions

- `@unchecked Sendable` — renderer is immutable after init, safe to share across tasks
- Custom path: only `CocoaError` file-not-found falls through to bundle; other errors (permissions, I/O) throw `customPathFailed` to surface real problems
- Bundle path: all errors fall through (catch-all with `continue`) for Linux compat — Foundation on Linux may throw non-CocoaError for missing files
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
