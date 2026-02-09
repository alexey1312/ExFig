# Linux Compatibility

This rule covers Linux-specific workarounds and differences from macOS.

The project builds on Linux (Ubuntu 22.04 LTS / Jammy). Key differences from macOS:

## Required Import for Networking

```swift
import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif
```

## Foundation API Workarounds

| API                              | Issue on Linux              | Workaround                                    |
| -------------------------------- | --------------------------- | --------------------------------------------- |
| `XMLElement.elements(forName:)`  | Fails with default xmlns    | Use manual iteration with `localName`         |
| `XMLElement.attribute(forName:)` | Returns nil with xmlns      | Iterate `attributes` manually                 |
| `NSPredicate` with LIKE          | Not supported               | Convert wildcard to regex                     |
| `FileManager.replaceItemAt`      | Requires destination exist  | Use `removeItem` + `copyItem`                 |
| `stdout` global                  | Swift 6 concurrency warning | Use `FileHandle.standardOutput.synchronize()` |

## Running Tests on Linux

```bash
# Build tests separately, then run — avoids hangs from concurrent build + test execution
swift build --build-tests
swift test --skip-build --parallel
```

## Skip Tests on Linux

```swift
func testSomePngOperation() throws {
    #if os(Linux)
        throw XCTSkip("Skipped on Linux due to libpng issues")
    #endif
    // ... test code
}
```

## Platform-Specific Features

| Feature      | macOS        | Linux                    |
| ------------ | ------------ | ------------------------ |
| HEIC encoding| ImageIO      | Falls back to PNG        |
| libpng tests | Full support | Build tests first        |
| Foundation   | Full         | Some APIs missing/broken |
