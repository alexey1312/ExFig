# Testing Guidelines

## Test Targets

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

## Running Tests

```bash
./bin/mise run test                 # All tests
./bin/mise run test:filter NAME     # Filter by target/class/method
./bin/mise run test:file FILE       # Run tests for specific file
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

## SwiftLint in Tests

- Add `// swiftlint:disable:next force_try` before `try!` in tests
- Use `Data("string".utf8)` not `"string".data(using: .utf8)!`

## Linux Test Considerations

See [Linux Compatibility](linux-compatibility.md) for platform-specific test issues.
