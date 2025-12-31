# Colors Configuration

Colors can be configured as a single object (legacy) or array (new format) in `Params.swift`.

## Configuration Types

```swift
// ColorsConfiguration enum handles both formats via custom Decodable
enum ColorsConfiguration: Decodable {
    case single(Colors)      // Legacy: colors: { useColorAssets: true, ... }
    case multiple([ColorsEntry])  // New: colors: [{ tokensFileId: "...", ... }]

    var entries: [ColorsEntry]  // Unified access to all entries
    var isMultiple: Bool        // Check format type
}

// Each platform has its own ColorsEntry with platform-specific output fields
// iOS: useColorAssets, assetsFolder, colorSwift, swiftuiColorSwift
// Android: xmlOutputFileName, composePackageName
// Flutter: output, className
```

## Key Types

| Type                  | Purpose                                                    |
| --------------------- | ---------------------------------------------------------- |
| `ColorsConfiguration` | Enum with `.single`/`.multiple` for backward compat        |
| `ColorsEntry`         | Per-collection config (tokensFileId, tokensCollectionName) |

## Figma Variables Source

Colors array format is self-contained—each entry specifies its own Figma Variables source:

- `tokensFileId` - Figma file containing variables
- `tokensCollectionName` - Variable collection name
- Mode names (platform-specific)

Legacy format uses `common.variablesColors` for source.

## YAML Examples

```yaml
# Legacy single format
ios:
  colors:
    useColorAssets: true
    assetsFolder: "Colors"

# New multiple format
ios:
  colors:
    - tokensFileId: "abc123"
      tokensCollectionName: "Brand Colors"
      assetsFolder: "BrandColors"
    - tokensFileId: "def456"
      tokensCollectionName: "Semantic Colors"
      assetsFolder: "SemanticColors"
```
