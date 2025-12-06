<!-- OPENSPEC:START -->

# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:

- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:

- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# CLAUDE.md

Agent instructions for ExFig - a CLI tool that exports colors, typography, icons, and images from Figma to iOS, Android,
and Flutter projects.

## Quick Reference

```bash
# Build & Test
mise run build              # Debug build
mise run test               # All tests
mise run test:filter NAME   # Specific test target

# Code Quality (run before commit)
mise run format             # Format Swift
mise run format-md          # Format Markdown
mise run lint               # SwiftLint

# Run CLI
.build/debug/exfig --help
.build/debug/exfig colors -i config.yaml
.build/debug/exfig fetch -f FILE_ID -r "Frame" -o ./output
```

## Project Context

| Aspect          | Details                                                       |
| --------------- | ------------------------------------------------------------- |
| Language        | Swift 6.0, macOS 12.0+                                        |
| Package Manager | Swift Package Manager                                         |
| CLI Framework   | swift-argument-parser                                         |
| Config Format   | YAML (via Yams)                                               |
| Templates       | Stencil                                                       |
| Required Env    | `FIGMA_PERSONAL_TOKEN`                                        |
| Config Files    | `exfig.yaml` or `figma-export.yaml` (auto-detected)           |
| Tooling         | mise (`./bin/mise` self-contained, no global install needed)  |
| Platforms       | macOS (primary), Linux (CI) - see Linux Compatibility section |

## Architecture

Seven modules in `Sources/`:

| Module          | Purpose                                                   |
| --------------- | --------------------------------------------------------- |
| `ExFig`         | CLI commands, loaders, file I/O, terminal UI              |
| `ExFigCore`     | Domain models (Color, Image, TextStyle), processors       |
| `FigmaAPI`      | Figma REST API client, endpoints, response models         |
| `XcodeExport`   | iOS export (.xcassets, Swift extensions)                  |
| `AndroidExport` | Android export (XML resources, Compose, Vector Drawables) |
| `FlutterExport` | Flutter export (Dart code, SVG/PNG assets)                |
| `SVGKit`        | SVG parsing, ImageVector/VectorDrawable generation        |

**Data flow:** CLI → Config parsing → FigmaAPI fetch → ExFigCore processing → Platform export → File write

## Key Directories

```
Sources/ExFig/
├── Subcommands/     # CLI commands (ExportColors, ExportIcons, DownloadImages, etc.)
├── Loaders/         # Figma data loaders (ColorsLoader, ImagesLoader, etc.)
├── Input/           # Config & CLI options (ExFigOptions, DownloadOptions, etc.)
├── Output/          # File writers (FileWriter, WebpConverter, etc.)
├── TerminalUI/      # Progress bars, spinners, logging, output coordination
└── Cache/           # Version tracking for incremental exports

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

### Modifying Generated Code

Templates are in `Sources/*/Resources/`. Use Stencil syntax. Update tests after changes.

### TerminalUI Usage

```swift
// Spinner for indeterminate tasks
try await ui.withSpinner("Loading data...") {
    try await fetchData()
}

// Spinner with batch progress (shows "Loading... (3/15)")
try await ui.withSpinnerProgress("Fetching images from Figma...") { onProgress in
    try await loader.load(onBatchProgress: onProgress)
}

// Progress bar for counted items
try await ui.withProgress("Downloading", total: files.count) { progress in
    for file in files {
        try await download(file)
        await progress.increment()
    }
}
```

**Key TerminalUI classes:**

| Class                   | Purpose                                               |
| ----------------------- | ----------------------------------------------------- |
| `TerminalUI`            | Main facade for all terminal operations               |
| `TerminalOutputManager` | Singleton coordinating output between animations/logs |
| `Spinner`               | Animated spinner with message updates                 |
| `ProgressBar`           | Progress bar with percentage and ETA                  |
| `BatchProgressCallback` | `@Sendable (Int, Int) -> Void` for batch progress     |
| `Lock<T>`               | Thread-safe state wrapper (NSLock-based, Sendable)    |

**TerminalOutputManager API:**

| Method                          | Purpose                                       |
| ------------------------------- | --------------------------------------------- |
| `startAnimation(initialFrame:)` | Atomic animation start with first frame       |
| `writeAnimationFrame(_:)`       | Update animation line (stores for redraw)     |
| `writeDirect(_:)`               | Raw output (cursor show/hide, final messages) |
| `clearAnimationState()`         | Reset stored frame on animation stop          |
| `print(_:)`                     | Log message with animation coordination       |

**Concurrency patterns:**

- `Spinner` and `ProgressBar` use `DispatchQueue` (not Swift actors) for smooth 12 FPS rendering
- All terminal output routes through `TerminalOutputManager` to prevent race conditions
- `Lock<T>` wrapper provides thread-safe state with NSLock (compatible with macOS 12.0+)

### Fault Tolerance for API Commands

All commands support configurable retry and rate limiting via CLI flags:

```bash
# Light commands (colors, typography, download subcommands)
exfig colors --max-retries 6 --rate-limit 15

# Heavy commands (icons, images, fetch) also support fail-fast and concurrent downloads
exfig icons --max-retries 4 --rate-limit 18 --fail-fast
exfig icons --concurrent-downloads 50  # Increase CDN parallelism (default: 20)
exfig fetch -f FILE_ID -r "Frame" -o ./out --fail-fast
```

When implementing new commands that make API calls:

```swift
// 1. Add appropriate options group
@OptionGroup
var faultToleranceOptions: FaultToleranceOptions  // For light commands

@OptionGroup
var faultToleranceOptions: HeavyFaultToleranceOptions  // For heavy download commands

// 2. Create rate-limited client in run()
let baseClient = FigmaClient(accessToken: token, timeout: timeout)
let rateLimiter = faultToleranceOptions.createRateLimiter()
let client = faultToleranceOptions.createRateLimitedClient(
    wrapping: baseClient,
    rateLimiter: rateLimiter,
    onRetry: { attempt, error in
        ui.warning("Retry \(attempt) after error: \(error.localizedDescription)")
    }
)

// 3. Use the wrapped client for all API calls
let data = try await client.request(endpoint)
```

**Key files:**

- `Sources/ExFig/Input/FaultToleranceOptions.swift` - CLI options for retry/rate limit/concurrent downloads
- `Sources/ExFig/Output/FileDownloader.swift` - CDN download with configurable concurrency
- `Sources/FigmaAPI/Client/RateLimitedClient.swift` - Rate-limiting wrapper
- `Sources/FigmaAPI/Client/RetryPolicy.swift` - Retry with exponential backoff
- `Sources/ExFig/Cache/CheckpointTracker.swift` - Checkpoint management for resumable exports

## Figma API Reference

**Official Documentation:** <https://www.figma.com/developers/api>

### When to Consult Figma API Docs

| Scenario                      | What to Look For                        |
| ----------------------------- | --------------------------------------- |
| Adding new endpoint           | Request/response schema, authentication |
| Debugging API errors          | Error codes, rate limits, permissions   |
| Understanding node structure  | GET file nodes, component properties    |
| Working with Variables/Styles | Variables API, Styles API endpoints     |
| Image export options          | GET image endpoint, format/scale params |
| Unexpected response format    | Response schema changes, API versioning |

### Key API Endpoints Used

| Endpoint                        | Purpose                       | File in Project            |
| ------------------------------- | ----------------------------- | -------------------------- |
| `GET /v1/files/:key`            | File structure, nodes, styles | `NodesEndpoint.swift`      |
| `GET /v1/images/:key`           | Export images (PNG/SVG/PDF)   | `ImageEndpoint.swift`      |
| `GET /v1/files/:key/components` | Components list               | `ComponentsEndpoint.swift` |
| `GET /v1/files/:key/styles`     | Styles (colors, text)         | `StylesEndpoint.swift`     |
| `GET /v1/files/:key/variables`  | Figma Variables               | `VariablesEndpoint.swift`  |

### API Response Mapping

When Figma API response structure differs from project models, check:

1. `Sources/FigmaAPI/Model/` — current response models
2. Figma API docs — actual response schema
3. Create/update `Decodable` structs to match API response

## Critical Gotchas

### Swift 6 Concurrency

```swift
// Captured vars in task groups must be Sendable
try await withThrowingTaskGroup(of: (Key, Value).self) { [self] group in
    for item in items {
        group.addTask { [item] in  // Capture value, not var
            (item.key, try await self.process(item))
        }
    }
    // ...
}

// Callbacks passed to task groups must be @escaping
func loadImages(
    onBatchProgress: @escaping BatchProgressCallback = { _, _ in }
) async throws -> [ImagePack] {
    // onBatchProgress is captured in task group closures
}
```

### SwiftLint Rules

- Use `Data("string".utf8)` not `"string".data(using: .utf8)!`
- Add `// swiftlint:disable:next force_try` before `try!` in tests
- Add `// swiftlint:disable file_length` for files > 400 lines

### Figma API Rate Limits

**Official docs:** <https://developers.figma.com/docs/rest-api/rate-limits/>

- Use `maxConcurrentBatches = 3` for parallel requests
- Tier 1 endpoints (files, images): 10-20 req/min depending on plan (Starter→Enterprise)
- Tier 2 endpoints: 25-100 req/min
- Tier 3 endpoints: 50-150 req/min
- On 429 error: respect `Retry-After` header

### Test Helpers for Codable Types

```swift
extension SomeType {
    static func make(param: String) -> SomeType {
        let json = "{\"param\": \"\(param)\"}"
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(SomeType.self, from: Data(json.utf8))
    }
}
```

## Linux Compatibility

The project builds on Linux (Ubuntu). Key differences from macOS:

### Required Import for Networking

```swift
import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif
```

### Foundation API Workarounds

| API                              | Issue on Linux              | Workaround                                    |
| -------------------------------- | --------------------------- | --------------------------------------------- |
| `XMLElement.elements(forName:)`  | Fails with default xmlns    | Use manual iteration with `localName`         |
| `XMLElement.attribute(forName:)` | Returns nil with xmlns      | Iterate `attributes` manually                 |
| `NSPredicate` with LIKE          | Not supported               | Convert wildcard to regex                     |
| `FileManager.replaceItemAt`      | Requires destination exist  | Use `removeItem` + `copyItem`                 |
| `stdout` global                  | Swift 6 concurrency warning | Use `FileHandle.standardOutput.synchronize()` |

### Running Tests on Linux

```bash
# Use single worker to avoid libpng memory corruption
swift test --parallel --num-workers 1
```

### Skip Tests on Linux

```swift
func testSomePngOperation() throws {
    #if os(Linux)
        throw XCTSkip("Skipped on Linux due to libpng issues")
    #endif
    // ... test code
}
```

## Testing Guidelines

Test targets mirror source modules:

| Target               | Tests for                      |
| -------------------- | ------------------------------ |
| `ExFigTests`         | CLI commands, loaders, writers |
| `ExFigCoreTests`     | Domain models, processors      |
| `XcodeExportTests`   | iOS export output              |
| `AndroidExportTests` | Android export output          |
| `FlutterExportTests` | Flutter export output          |
| `FigmaAPITests`      | API client, endpoints          |
| `SVGKitTests`        | SVG parsing, code generation   |

Run specific tests: `mise run test:filter ExFigTests`

## Commit Guidelines

Format: `<type>(<scope>): <description>`

**Types:** `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `chore`, `ci`

**Scopes:** `colors`, `icons`, `images`, `typography`, `api`, `cli`, `ios`, `android`, `flutter`

```bash
feat(cli): add download command for config-free image downloads
fix(icons): handle SVG with missing viewBox
docs: update naming style documentation
```

**Pre-commit requirements:**

```bash
mise run format      # Must pass
mise run format-md   # Must pass
mise run lint        # Must pass (may have issues on Linux)
```

## Configuration Reference

Full config spec: `CONFIG.md`

Example projects in `Examples/`:

- `Example/` - iOS UIKit
- `ExampleSwiftUI/` - iOS SwiftUI
- `AndroidExample/` - Android XML
- `AndroidComposeExample/` - Jetpack Compose
- `FlutterExample/` - Flutter/Dart

Generate starter config:

```bash
exfig init -p ios
exfig init -p android
```

## Dependencies

| Package               | Version | Purpose                    |
| --------------------- | ------- | -------------------------- |
| swift-argument-parser | 1.5.0+  | CLI framework              |
| Yams                  | 5.3.0+  | YAML parsing               |
| Stencil               | 0.15.1+ | Template engine            |
| StencilSwiftKit       | 2.10.1+ | Swift Stencil extensions   |
| XcodeProj             | 8.27.0+ | Xcode project manipulation |
| swift-log             | 1.6.0+  | Logging                    |
| Rainbow               | 4.2.0+  | Terminal colors            |
| libwebp               | 1.4.1+  | WebP encoding              |
| libpng                | 1.6.45+ | PNG decoding               |
| swift-custom-dump     | 1.3.0+  | Test assertions            |

## Troubleshooting

| Problem            | Solution                                       |
| ------------------ | ---------------------------------------------- |
| Build fails        | `swift package clean && swift build`           |
| Tests fail         | Check `FIGMA_PERSONAL_TOKEN` is set            |
| Formatting fails   | Run `mise run setup` to install tools          |
| Template errors    | Check Stencil syntax and context variables     |
| Linux test crashes | Use `--num-workers 1` for test parallelization |

## Project Knowledge File

The `.claude/EXFIG.toon` file contains a compact machine-readable summary of the project.

**Maintenance rule:** Keep this file updated when:

- Adding new CLI commands or options
- Adding new modules or significant types
- Changing default values for fault tolerance
- Adding new Stencil templates

To validate: `npx @toon-format/cli .claude/EXFIG.toon --decode`
