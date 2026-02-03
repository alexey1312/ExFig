# Design: Integrate Noora Terminal UI

## Current Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLI Commands                             │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    TerminalUI (facade)                           │
│  • info(), success(), warning(), error(), debug()                │
│  • withSpinner(), withProgress()                                 │
│  • createBatchProgress(), createMultiProgress()                  │
└─────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│    Spinner    │       │  ProgressBar  │       │BatchProgressV │
│  (Braille)    │       │   (w/ ETA)    │       │   (multi)     │
└───────────────┘       └───────────────┘       └───────────────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│               TerminalOutputManager (coordination)               │
│  • Prevents race conditions between animations and logs          │
│  • Manages cursor visibility, line clearing                      │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Rainbow (ANSI colors)                         │
│  • .red, .green, .yellow, .cyan, .lightBlack                     │
└─────────────────────────────────────────────────────────────────┘
```

## Target Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLI Commands                             │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    TerminalUI (facade)                           │
│  • info(), success(), warning(), error(), debug()                │
│  • withSpinner(), withProgress()                                 │
│  • createBatchProgress(), createMultiProgress()                  │
└─────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────┬───────────┼───────────┬───────────┐
        ▼           ▼           ▼           ▼           ▼
┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐
│  NooraUI  │ │  Spinner  │ │ProgressBar│ │BatchProgr │ │ Formatters│
│ (semantic)│ │ (Braille) │ │  (w/ ETA) │ │  (multi)  │ │ (semantic)│
└───────────┘ └───────────┘ └───────────┘ └───────────┘ └───────────┘
      │             │             │             │             │
      │             └─────────────┼─────────────┘             │
      │                           ▼                           │
      │       ┌─────────────────────────────────────┐         │
      │       │     TerminalOutputManager           │         │
      │       │     (coordination layer)            │         │
      │       └─────────────────────────────────────┘         │
      │                           │                           │
      ▼                           ▼                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Noora                                    │
│  • TerminalText (semantic formatting)                            │
│  • .success(), .danger(), .primary(), .muted()                   │
│  • format() -> String with ANSI codes                            │
└─────────────────────────────────────────────────────────────────┘
      │
      ▼ (fallback for custom animations)
┌─────────────────────────────────────────────────────────────────┐
│                    Rainbow (legacy)                              │
│  • Used by Spinner/ProgressBar for animation frames              │
└─────────────────────────────────────────────────────────────────┘
```

## Component Mapping

### Semantic Text (NooraUI)

| ExFig Current          | Noora TerminalText    |
| ---------------------- | --------------------- |
| `"text".cyan`          | `.primary("text")`    |
| `"✓".green`            | `.success("✓")`       |
| `"✗".red`              | `.danger("✗")`        |
| `"⚠".yellow`           | `.accent("⚠")`        |
| `"[DEBUG]".lightBlack` | `.muted("[DEBUG]")`   |
| `"command".bold`       | `.command("command")` |

### Message Formatting

**Before (Rainbow):**

```swift
func success(_ message: String) {
    let icon = useColors ? "✓".green : "✓"
    TerminalOutputManager.shared.print("\(icon) \(message)")
}
```

**After (Noora):**

```swift
func success(_ message: String) {
    let text: TerminalText = "\(.success("✓")) \(message)"
    TerminalOutputManager.shared.print(NooraUI.format(text))
}
```

### Formatter Migration

**Before:**

```swift
struct ExFigWarningFormatter {
    func format(_ warning: ExFigWarning) -> String {
        // String concatenation with manual formatting
    }
}
```

**After:**

```swift
struct ExFigWarningFormatter {
    func format(_ warning: ExFigWarning) -> String {
        NooraUI.format(formatAsTerminalText(warning))
    }

    func formatAsTerminalText(_ warning: ExFigWarning) -> TerminalText {
        // Semantic TerminalText construction
    }
}
```

## Decision Matrix: Noora vs Custom

| Use Case                                | Component  | Rationale              |
| --------------------------------------- | ---------- | ---------------------- |
| Status messages (success/error/warning) | **Noora**  | Semantic, consistent   |
| Debug output                            | **Noora**  | Simple, one-line       |
| Spinner with message                    | **Custom** | Braille animation UX   |
| Progress with ETA                       | **Custom** | Detailed metrics       |
| Batch multi-line progress               | **Custom** | Complex layout         |
| Command highlighting                    | **Noora**  | `.command()` component |

## Trade-offs

### Using Noora for Text Formatting

**Pros:**

- Semantic intent (success vs danger vs muted)
- Consistent theming across CLI
- Standard API from tuist ecosystem
- Future-proof (theme customization)

**Cons:**

- Additional dependency
- Slight overhead for format() call
- Learning curve for TerminalText syntax

### Keeping Custom Animations

**Pros:**

- Proven UX with Braille spinner
- Precise ETA calculation
- Complex BatchProgressView layout

**Cons:**

- More code to maintain
- Rainbow dependency remains
- Not leveraging Noora `progressBarStep`

## Migration Path

### Phase 1: Non-breaking additions

1. Add `NooraUI` adapter (done)
2. Add `formatAsTerminalText()` to formatters
3. Update TerminalUI methods to use NooraUI internally

### Phase 2: Gradual replacement

1. Identify simple progress use cases for `progressBarStep`
2. Migrate one command at a time
3. A/B test UX changes

### Phase 3: Cleanup

1. Remove unused Rainbow patterns
2. Consolidate color logic in NooraUI
3. Update documentation
