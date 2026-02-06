## TOON Format Convention

Use TOON (Token-Oriented Object Notation) for all tabular data in this file. TOON reduces token usage by 30-60% by declaring fields once in array headers.

```toon
format:
  syntax: name[count]{field1,field2,...}:
  indent: 2 spaces for rows
  delimiter: comma between values

example[2]{id,name,status}:
  1,Build command,active
  2,Test command,active
```

When adding lists of items (modules, commands, files, etc.), always use TOON tables instead of markdown tables or lists.

**Exception:** OpenSpec `tasks.md` — task items MUST use markdown checklists (`- [ ]`) for openspec parsing.

## Context7 for External Libraries

**Always use Context7 MCP** to look up documentation for external tools and libraries before implementing:

1. `resolve-library-id` - find the library ID
2. `get-library-docs` with `topic` - get relevant docs (use `mode: code` for API, `mode: info` for concepts)
3. Paginate with `page: 2, 3...` if context insufficient

This applies to: Swift packages, CLI tools (mise, hk, swiftlint, etc.), Figma API, and any third-party dependency.

## swiftindex — Semantic Code Search

**Use swiftindex for ALL code search.** Local, private, Swift-optimized with MLX embeddings.

```bash
# Semantic search (conceptual queries)
./bin/mise exec -- swiftindex search "iOS colors export" Sources

# Exact symbol search (semantic_weight=0.0)
./bin/mise exec -- swiftindex search --semantic-weight 0.0 "FigmaClient"
```

**Query formulation tips:**

| Question Type    | Bad Query    | Good Query                                     |
| ---------------- | ------------ | ---------------------------------------------- |
| Find file/struct | "iOS config" | "iOS colors icons images configuration struct" |
| Find flow        | "export"     | "how images are exported to xcassets"          |
| Find handler     | "error"      | "where errors from Figma API are handled"      |

**Workflow:**

1. Start with swiftindex for any search — replaces Glob + Grep + Read
2. Use `--semantic-weight 0.0` for exact symbol lookup
3. Fall back to Grep/Glob only for regex patterns or non-Swift files

# CLAUDE.md

Agent instructions for ExFig - a CLI tool that exports colors, typography, icons, and images from Figma to iOS, Android,
and Flutter projects.

## Quick Reference

```bash
# Build & Test
./bin/mise run build                # Debug build
./bin/mise run build:release        # Release build
./bin/mise run test                 # All tests
./bin/mise run test:filter NAME     # Filter by target/class/method
./bin/mise run test:file FILE       # Run tests for specific file

# Code Quality (run before commit)
./bin/mise run format               # Format all (Swift + Markdown)
./bin/mise run format:swift         # Format Swift only
./bin/mise run format:md            # Format Markdown only
./bin/mise run format-check         # Check formatting (CI) - fix with format:swift
./bin/mise run lint                 # SwiftLint + actionlint

# Docs & Coverage
./bin/mise run docs                 # Generate DocC documentation
./bin/mise run docs:preview         # Preview docs in browser
./bin/mise run coverage             # Run tests with coverage report

# Maintenance
./bin/mise run setup                # Install required tools
./bin/mise run clean                # Clean build artifacts
./bin/mise run clean:all            # Clean build + derived data

# Run CLI
.build/debug/exfig --help
.build/debug/exfig colors -i exfig.pkl
.build/debug/exfig icons -i exfig.pkl
.build/debug/exfig fetch -f FILE_ID -r "Frame" -o ./output

# Search (swiftindex) — use for ANY code search
./bin/mise exec -- swiftindex search "iOS config struct colors icons" Sources
./bin/mise exec -- swiftindex search "how images exported to xcassets" Sources
./bin/mise exec -- swiftindex search --semantic-weight 0.0 "FigmaClient"  # exact symbol
```

## Project Context

| Aspect          | Details                                                                            |
| --------------- | ---------------------------------------------------------------------------------- |
| Language        | Swift 6.2, macOS 13.0+                                                             |
| Package Manager | Swift Package Manager                                                              |
| CLI Framework   | swift-argument-parser                                                              |
| Config Format   | PKL (Programmable, Scalable, Safe)                                                 |
| Templates       | Stencil                                                                            |
| Required Env    | `FIGMA_PERSONAL_TOKEN`                                                             |
| Config Files    | `exfig.pkl` (PKL configuration)                                                    |
| Tooling         | mise (`./bin/mise` self-contained, no global install needed)                       |
| Platforms       | macOS 13+ (primary), Linux/Ubuntu 22.04 (CI) - see `.claude/rules/linux-compat.md` |

## Architecture

Twelve modules in `Sources/`:

| Module          | Purpose                                                   |
| --------------- | --------------------------------------------------------- |
| `ExFig`         | CLI commands, loaders, file I/O, terminal UI              |
| `ExFigCore`     | Domain models (Color, Image, TextStyle), processors       |
| `ExFigConfig`   | PKL config parsing, evaluation, locator                   |
| `FigmaAPI`      | Figma REST API client, endpoints, response models         |
| `ExFig-iOS`     | iOS platform plugin (ColorsExporter, IconsExporter, etc.) |
| `ExFig-Android` | Android platform plugin                                   |
| `ExFig-Flutter` | Flutter platform plugin                                   |
| `ExFig-Web`     | Web platform plugin                                       |
| `XcodeExport`   | iOS export (.xcassets, Swift extensions)                  |
| `AndroidExport` | Android export (XML resources, Compose, Vector Drawables) |
| `FlutterExport` | Flutter export (Dart code, SVG/PNG assets)                |
| `WebExport`     | Web/React export (CSS variables, JSX icons)               |
| `SVGKit`        | SVG parsing, ImageVector/VectorDrawable generation        |

**Data flow:** CLI -> PKL config parsing -> FigmaAPI fetch -> ExFigCore processing -> Platform plugin -> Export module -> File write

## Key Directories

```
Sources/ExFig/
├── Subcommands/     # CLI commands (ExportColors, ExportIcons, DownloadImages, etc.)
│   └── Export/      # Platform-specific export logic (iOSIconsExport, AndroidImagesExport, etc.)
├── Loaders/         # Figma data loaders (ColorsLoader, ImagesLoader, etc.)
├── Input/           # Config & CLI options (ExFigOptions, DownloadOptions, etc.)
├── Output/          # File writers, converters, factories (WebpConverterFactory, HeicConverterFactory)
├── TerminalUI/      # Progress bars, spinners, logging, output coordination
├── Cache/           # Version tracking, granular cache (GranularCacheHelper, GranularCacheManager)
├── Pipeline/        # Cross-config download pipelining (SharedDownloadQueue)
├── Batch/           # Batch processing (executor, runner, checkpoint)
├── Sync/            # Figma sync functionality (state tracking, diff detection)
├── Plugin/          # Plugin registry, Params-to-Plugin adapters
├── Context/         # Export context implementations (ColorsExportContextImpl, etc.)
└── Shared/          # Cross-cutting helpers (PlatformExportResult, HashMerger, EntryProcessor)

Sources/ExFig-{iOS,Android,Flutter,Web}/
├── Config/          # Entry types (iOSColorsEntry, AndroidIconsEntry, etc.)
└── Export/          # Exporters (iOSColorsExporter, AndroidImagesExporter, etc.)

Sources/ExFigConfig/
└── PKL/             # PKL locator, evaluator, error types

Sources/*/Resources/ # Stencil templates for code generation
Tests/               # Test targets mirror source structure
```

## Code Patterns

### Adding a CLI Command

1. Create `Sources/ExFig/Subcommands/NewCommand.swift` implementing `AsyncParsableCommand`
2. Register in `ExFigCommand.swift` subcommands array
3. Use `@OptionGroup` for shared options (`GlobalOptions`, `CacheOptions`)
4. Use `TerminalUI` for progress: `try await ui.withSpinner("Loading...") { ... }`

### Adding a Figma API Endpoint

1. Create endpoint in `Sources/FigmaAPI/Endpoint/`
2. Add response models in `Sources/FigmaAPI/Model/`
3. Add method to `FigmaClient.swift`

### Adding a Platform Plugin Exporter

1. Create entry type in `Sources/ExFig-{Platform}/Config/` (e.g., `iOSColorsEntry.swift`)
2. Implement exporter in `Sources/ExFig-{Platform}/Export/` conforming to protocol (e.g., `ColorsExporter`)
3. Register exporter in plugin's `exporters()` method
4. Create adapter in `Sources/ExFig/Plugin/ParamsToPluginAdapter.swift` for Params -> Entry conversion
5. Add export method in `Sources/ExFig/Subcommands/Export/Plugin*Export.swift`

### Modifying Generated Code

Templates are in `Sources/*/Resources/`. Use Stencil syntax. Update tests after changes.

## Code Conventions

| Area            | Use                               | Instead of                  |
| --------------- | --------------------------------- | --------------------------- |
| JSON parsing    | `JSONCodec` (swift-yyjson)        | `JSONDecoder`/`JSONEncoder` |
| Terminal UI     | Noora (`NooraUI`, `TerminalText`) | Rainbow color methods       |
| Terminal output | `TerminalUI` facade               | Direct `print()` calls      |

**JSONCodec usage:**

```swift
import YYJSON

// Decode
let data = try JSONCodec.decode(MyType.self, from: jsonData)

// Encode
let jsonData = try JSONCodec.encode(myValue)
```

**Noora usage:** See `.claude/rules/terminal-ui.md` for full patterns.

**NooraUI quick reference:**

```swift
// Format a single component (uses format(_ component:) overload)
NooraUI.format(.primary("text"))    // cyan
NooraUI.format(.success("✓"))      // green
NooraUI.format(.danger("✗"))       // red
NooraUI.format(.accent("⚠"))      // yellow
NooraUI.format(.muted("dim"))      // gray
NooraUI.format(.command("bold"))   // bold/secondary
NooraUI.formatLink("url", useColors: true)  // underlined primary
```

## Dependencies

| Package               | Version | Purpose                     |
| --------------------- | ------- | --------------------------- |
| swift-argument-parser | 1.5.0+  | CLI framework               |
| swift-collections     | 1.2.x   | Ordered collections         |
| Stencil               | 0.15.1+ | Template engine             |
| StencilSwiftKit       | 2.10.1+ | Swift Stencil extensions    |
| XcodeProj             | 8.27.0+ | Xcode project manipulation  |
| swift-log             | 1.6.0+  | Logging                     |
| Rainbow               | 4.2.0+  | Terminal colors             |
| libwebp               | 1.4.1+  | WebP encoding               |
| libpng                | 1.6.45+ | PNG decoding                |
| swift-custom-dump     | 1.3.0+  | Test assertions             |
| toon-swift            | 0.3.0+  | TOON format encoding        |
| Noora                 | 0.54.0+ | Terminal UI design system   |
| swift-resvg           | 0.45.1  | SVG parsing/rendering       |
| swift-docc-plugin     | 1.4.5+  | DocC documentation          |
| swift-yyjson          | 0.4.0+  | High-performance JSON codec |

## Troubleshooting

| Problem               | Solution                                            |
| --------------------- | --------------------------------------------------- |
| Build fails           | `swift package clean && swift build`                |
| Tests fail            | Check `FIGMA_PERSONAL_TOKEN` is set                 |
| Formatting fails      | Run `./bin/mise run setup` to install tools         |
| Template errors       | Check Stencil syntax and context variables          |
| Linux test crashes    | Use `--num-workers 1` for test parallelization      |
| Android pathData long | Simplify in Figma or use `--strict-path-validation` |

## Additional Rules

Contextual documentation is in `.claude/rules/`:

| Rule File             | When to Consult                                    |
| --------------------- | -------------------------------------------------- |
| `config-patterns.md`  | Multi-entry Icons/Colors/Images config, codeSyntax |
| `image-formats.md`    | SVG source format, HEIC output                     |
| `terminal-ui.md`      | TerminalUI, warnings, errors systems               |
| `fault-tolerance.md`  | Retry, rate limiting, timeout                      |
| `batch-processing.md` | Batch pre-fetch, pipelined downloads               |
| `cache-granular.md`   | Experimental granular node-level cache             |
| `api-reference.md`    | Figma API endpoints, response mapping              |
| `gotchas.md`          | Swift 6 concurrency, SwiftLint, rate limits        |
| `linux-compat.md`     | Linux-specific workarounds                         |
| `testing-workflow.md` | Testing guidelines, commit format                  |

These rules are loaded lazily when working with related files.

## Session Wrap-Up

After completing a task, call `Skill(claude-md-management:revise-claude-md)` to capture learnings and update CLAUDE.md.
