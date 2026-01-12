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
# Use single worker to avoid libpng memory corruption
swift test --parallel --num-workers 1
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
| libpng tests | Full support | Single worker required   |
| Foundation   | Full         | Some APIs missing/broken |
