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

### @Sendable Closures Crash (Linux)

Adding `@Sendable` to closures passed to TaskLocal `withValue` causes runtime crash on Linux:
`freed pointer was not the last allocation`

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
