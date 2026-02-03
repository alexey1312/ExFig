---
paths:
  - "Sources/ExFig/TerminalUI/**"
---

# Terminal UI Patterns

This rule covers TerminalUI usage, Noora design system, warnings, and errors.

**Design system:** Use [Noora](https://github.com/tuist/Noora) (tuist/Noora) for semantic terminal text formatting.

## TerminalUI Usage

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

| Class                      | Purpose                                               |
| -------------------------- | ----------------------------------------------------- |
| `TerminalUI`               | Main facade for all terminal operations               |
| `TerminalOutputManager`    | Singleton coordinating output between animations/logs |
| `Spinner`                  | Animated spinner with message updates                 |
| `ProgressBar`              | Progress bar with percentage and ETA                  |
| `BatchProgressView`        | Multi-line per-config progress display for batch mode |
| `BatchProgressViewStorage` | `@TaskLocal` injection for batch progress view        |
| `BatchProgressCallback`    | `@Sendable (Int, Int) -> Void` for batch progress     |
| `Lock<T>`                  | Thread-safe state wrapper (NSLock-based, Sendable)    |
| `ExFigWarning`             | Enum of all warning types for consistent messaging    |
| `ExFigWarningFormatter`    | Formats warnings as compact or multiline strings      |
| `ExFigErrorFormatter`      | Formats errors with recovery suggestions              |
| `NooraUI`                  | Adapter for Noora design system (semantic text)       |
| `ConflictFormatter`        | Formats batch output path conflicts for display       |

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
- `Lock<T>` wrapper provides thread-safe state with NSLock (compatible with macOS 13.0+)

**Batch Mode Progress Display:**

The `BatchProgressView` actor provides rich multi-line progress display for batch processing:

```swift
// In Batch.swift
let progressView = BatchProgressView(useColors: !quiet, useAnimations: isTTY)

// Register all configs
for config in configs {
    await progressView.registerConfig(name: config.name)
}

// Inject via @TaskLocal to suppress individual export UI
await BatchProgressViewStorage.$progressView.withValue(progressView) {
    // Process configs in parallel
}

// Progress view automatically displays:
// - Per-config progress bars with ETA
// - Asset counts (colors/icons/images/typography)
// - Status indicators: circle pending, circle running, checkmark success, x failed
// - Rate limiter status
```

**Batch mode UI suppression:**

- Individual export commands detect `BatchProgressViewStorage.progressView` via `@TaskLocal`
- Spinners and progress bars are automatically suppressed in batch mode
- Critical logs (errors/warnings) coordinate with progress display via `clearForLog()` -> print -> `render()`

## Noora Design System

Use `NooraUI` adapter for semantic terminal text formatting with ANSI colors.

**Convenience methods** (preferred for common patterns):

```swift
// Status messages with icons
NooraUI.formatSuccess("Build completed", useColors: true)  // ✓ Build completed
NooraUI.formatError("Build failed", useColors: true)       // ✗ Build failed
NooraUI.formatWarning("Deprecated API", useColors: true)   // ⚠ Deprecated API
NooraUI.formatInfo("Loading config", useColors: true)      // Loading config (primary)
NooraUI.formatDebug("Cache hit", useColors: true)          // [DEBUG] Cache hit

// Multi-line messages with proper indentation
NooraUI.formatMultilineError("Line 1\nLine 2", useColors: true)
// ✗ Line 1
//   Line 2
```

**Low-level TerminalText API** (for custom formatting):

```swift
import Noora

// Format semantic text
let text: TerminalText = "Status: \(.success("OK")) for \(.primary("MyProject"))"
print(NooraUI.format(text))

// Available components:
// .raw(String)       - No formatting
// .command(String)   - System commands (highlighted)
// .primary(String)   - Theme primary color
// .secondary(String) - Theme secondary color
// .muted(String)     - Dimmed text
// .accent(String)    - Accent color
// .danger(String)    - Error/danger color
// .success(String)   - Success color
```

**NooraUI adapter** (`Sources/ExFig/TerminalUI/NooraUI.swift`):

| Method                                      | Purpose                           |
| ------------------------------------------- | --------------------------------- |
| `format(_ text: TerminalText)`              | Convert TerminalText to ANSI str  |
| `formatSuccess(_ msg, useColors:)`          | Success with ✓ icon               |
| `formatError(_ msg, useColors:)`            | Error with ✗ icon                 |
| `formatWarning(_ msg, useColors:)`          | Warning with ⚠ icon               |
| `formatInfo(_ msg, useColors:)`             | Info with primary color           |
| `formatDebug(_ msg, useColors:)`            | Debug with [DEBUG] prefix         |
| `formatMultilineError(_ msg, useColors:)`   | Multi-line error with indentation |
| `formatMultilineWarning(_ msg, useColors:)` | Multi-line warning with indent    |

**When to use Noora vs custom components:**

| Use Case                    | Approach                              |
| --------------------------- | ------------------------------------- |
| Status messages             | `NooraUI.formatSuccess/Error/etc.`    |
| Commands in output          | `.command("exfig colors")`            |
| Custom formatted text       | `NooraUI.format(terminalText)`        |
| Spinner/Progress animations | Custom `Spinner`/`ProgressBar`        |
| Batch multi-line progress   | Custom `BatchProgressView`            |
| Warnings/errors via UI      | `ui.warning()` / `ui.error()` (uses Noora internally) |

## Warnings System

Use `ExFigWarning` enum for all CLI warnings to ensure consistent formatting:

```swift
// Typed warnings - preferred
ui.warning(.configMissing(platform: "ios", assetType: "icons"))
ui.warning(.noAssetsFound(assetType: "images", frameName: "Frame"))
ui.warning(.xcodeProjectUpdateFailed)

// Formatted retry messages via RetryLogger (for rate-limited clients)
RetryLogger.formatRetryMessage(context)
```

**Warning types:**

| Category        | Cases                                                                                                                                |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| Configuration   | `configMissing`, `composeRequirementMissing`                                                                                         |
| Asset Discovery | `noAssetsFound`                                                                                                                      |
| Xcode           | `xcodeProjectUpdateFailed`                                                                                                           |
| Batch           | `noConfigsFound`, `invalidConfigsSkipped`, `noValidConfigs`, `checkpointExpired`, `checkpointPathMismatch`, `preFetchPartialFailure` |
| Theme Attrs     | `themeAttributesFileNotFound`, `themeAttributesMarkerNotFound`, `themeAttributesNameCollision`                                       |
| Retry           | `retrying(attempt:maxAttempts:error:delay:)`                                                                                         |

**Adding new warnings:**

1. Add case to `ExFigWarning` enum in `Sources/ExFig/TerminalUI/ExFigWarning.swift`
2. Add formatting in `ExFigWarningFormatter.format(_:)` - use compact `key=value` for simple warnings, multiline for complex
3. Call via `ui.warning(.yourNewCase)`

## Errors System

All errors implement `LocalizedError` with `errorDescription` and optional `recoverySuggestion`:

```swift
// Display errors with recovery suggestions
ui.error(ExFigError.accessTokenNotFound)
// Output:
// x FIGMA_PERSONAL_TOKEN not set
//   -> Run: export FIGMA_PERSONAL_TOKEN=your_token

// For any Error type
ui.error(someError)  // Auto-formats LocalizedError or falls back to localizedDescription
```

**Key error types:**

| Module          | Error Type                        | Purpose                           |
| --------------- | --------------------------------- | --------------------------------- |
| `ExFig`         | `ExFigError`                      | Main CLI errors                   |
| `ExFig`         | `ConfigDiscoveryError`            | Config file discovery errors      |
| `ExFig`         | `BatchExecutorError`              | Batch processing errors           |
| `ExFig`         | `WebpConverterError`              | WebP conversion errors            |
| `ExFig`         | `PngDecoderError`                 | PNG decoding errors               |
| `ExFigCore`     | `AssetsValidatorError`            | Asset validation errors           |
| `SVGKit`        | `SVGParseError`, `SVGParserError` | SVG parsing errors                |
| `AndroidExport` | `ImageVectorExportError`          | Android ImageVector export errors |
| `XcodeExport`   | `XcodeImagesExporterBase.Error`   | iOS asset catalog errors          |
| `FigmaAPI`      | `FigmaAPIError`                   | Figma API errors (reference impl) |

**Error formatting classes:**

| Class                 | Purpose                                                |
| --------------------- | ------------------------------------------------------ |
| `ExFigErrorFormatter` | Formats `LocalizedError` with recovery suggestion line |

**Adding new errors:**

1. Create enum conforming to `LocalizedError`
2. Implement `errorDescription` with compact TOON format (`key=value`)
3. Implement `recoverySuggestion` with actionable fix (or `nil` for simple errors)
4. Call via `ui.error(yourError)` - formatter handles display
