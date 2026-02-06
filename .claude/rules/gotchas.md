# Critical Gotchas

This rule covers Swift 6 concurrency, SwiftLint rules, and other common pitfalls.

## Swift 6 Concurrency

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

### Nested TaskLocal.withValue() Crash (Linux)

**Bug:** https://github.com/swiftlang/swift/issues/75501

Deep nesting of `TaskLocal.withValue()` (10+ levels) causes Swift runtime crash on Linux:
`freed pointer was not the last allocation`

**Symptoms:**
- Works fine on macOS
- Crashes on Linux (Ubuntu 22.04) in batch mode with `--experimental-granular-cache`
- Error appears during task-local allocator cleanup

**Root cause:**
Swift runtime on Linux incorrectly manages task-local allocator when:
1. Deep nesting of `TaskLocal.withValue()` (10+ levels)
2. Nested `withValue` for the **same** TaskLocal inside TaskGroup

**Solution: BatchSharedState actor pattern**

Consolidate all batch state into a single actor with ONE `@TaskLocal`:

```swift
// BAD - 10+ nesting levels crashes on Linux
$collector.withValue(c) {
    $progressView.withValue(p) {
        $context.withValue(ctx) {
            $queue.withValue(q) {
                $configId.withValue(id) {
                    ComponentPreFetcher:
                        $context.withValue(localCtx) { // CRASH!
                        }
                }
            }
        }
    }
}

// GOOD - single nesting level
let state = BatchSharedState(
    context: batchContext,
    progressView: progressView,
    downloadQueue: queue
)
BatchSharedState.$current.withValue(state) {
    // Access via state actor, no nested withValue
}
```

**Key principles:**
1. ONE `@TaskLocal` for all batch shared state
2. Per-config data passed via explicit parameters (`ConfigExecutionContext`)
3. Mutable state lives in actor methods, not nested `withValue`
4. Never create nested `withValue` for the same TaskLocal

### @Sendable Closures Crash (Linux)

Adding `@Sendable` to closures passed to TaskLocal `withValue` causes runtime crash on Linux:

```swift
// BAD - crashes on Linux
func withContext<T: Sendable>(operation: @Sendable () async -> T) async -> T

// GOOD - works
func withContext<T>(operation: () async -> T) async -> T
```

## SwiftLint Rules

- Use `Data("string".utf8)` not `"string".data(using: .utf8)!`
- Add `// swiftlint:disable:next force_try` before `try!` in tests
- Add `// swiftlint:disable file_length` for files > 400 lines

### void_function_in_ternary False Positive

SwiftLint flags `NooraUI.format()` calls in ternary operators as `void_function_in_ternary` even though they return `String`.
Fix by extracting into separate `let` variables:

```swift
// BAD - triggers SwiftLint
let icon: String = if useColors {
    success ? NooraUI.format(.success("✓")) : NooraUI.format(.danger("✗"))
} else { ... }

// GOOD
let successIcon = useColors ? NooraUI.format(.success("✓")) : "✓"
let failIcon = useColors ? NooraUI.format(.danger("✗")) : "✗"
let icon = success ? successIcon : failIcon
```

## Test Helpers for Codable Types

```swift
extension SomeType {
    static func make(param: String) -> SomeType {
        let json = "{\"param\": \"\(param)\"}"
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(SomeType.self, from: Data(json.utf8))
    }
}
```

## Figma API Rate Limits

**Official docs:** https://developers.figma.com/docs/rest-api/rate-limits/

- Use `maxConcurrentBatches = 3` for parallel requests
- Tier 1 endpoints (files, images): 10-20 req/min depending on plan (Starter->Enterprise)
- Tier 2 endpoints: 25-100 req/min
- Tier 3 endpoints: 50-150 req/min
- On 429 error: respect `Retry-After` header
