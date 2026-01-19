---
paths:
  - "Sources/ExFig/Input/Params.swift"
  - "Sources/ExFig/Subcommands/Export/**"
  - "Sources/ExFig/Loaders/**"
---

# Multi-Entry Configuration Patterns

This rule covers Icons, Colors, and Images multi-entry configuration patterns.

## Multiple Icons Configuration

Icons can be configured as a single object (legacy) or array (new format) in `Params.swift`:

```swift
// IconsConfiguration enum handles both formats via custom Decodable
enum IconsConfiguration: Decodable {
    case single(Icons)      // Legacy: icons: { format: svg, ... }
    case multiple([IconsEntry])  // New: icons: [{ figmaFrameName: "Actions", ... }]

    var entries: [IconsEntry]  // Unified access to all entries
    var isMultiple: Bool       // Check format type
}

// IconsLoaderConfig passes frame-specific settings to loader
let config = IconsLoaderConfig.forIOS(entry: entry, params: params)
let loader = IconsLoader(client: client, params: params, platform: .ios, logger: logger, config: config)
```

**Key types:**

| Type                 | Purpose                                                                                                   |
| -------------------- | --------------------------------------------------------------------------------------------------------- |
| `IconsConfiguration` | Enum with `.single`/`.multiple` for backward compat                                                       |
| `IconsEntry`         | Per-frame config (figmaFrameName, format, assetsFolder, nameValidateRegexp, nameReplaceRegexp, nameStyle) |
| `IconsLoaderConfig`  | Sendable struct passed to IconsLoader for frame settings                                                  |

**Per-entry fields with fallback:**

| Field                | Fallback Order                                                           |
| -------------------- | ------------------------------------------------------------------------ |
| `figmaFrameName`     | entry -> `common.icons.figmaFrameName` -> `"Icons"`                      |
| `nameValidateRegexp` | entry -> `common.icons.nameValidateRegexp` -> `nil`                      |
| `nameReplaceRegexp`  | entry -> `common.icons.nameReplaceRegexp` -> `nil`                       |
| `nameStyle`          | entry -> platform default (iOS: `nil`, Android/Flutter/Web: `.snakeCase`) |

**Fallback logic in export files:**

```swift
let processor = ImagesProcessor(
    platform: .android,
    nameValidateRegexp: entry.nameValidateRegexp ?? params.common?.icons?.nameValidateRegexp,
    nameReplaceRegexp: entry.nameReplaceRegexp ?? params.common?.icons?.nameReplaceRegexp,
    nameStyle: entry.nameStyle ?? .snakeCase
)
```

## Multiple Colors Configuration

Colors can be configured as a single object (legacy) or array (new format) in `Params.swift`:

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
// Android: xmlOutputFileName, composePackageName, colorKotlin
// Flutter: output, className
```

**Key types:**

| Type                  | Purpose                                                    |
| --------------------- | ---------------------------------------------------------- |
| `ColorsConfiguration` | Enum with `.single`/`.multiple` for backward compat        |
| `ColorsEntry`         | Per-collection config (tokensFileId, tokensCollectionName) |

**Note:** Colors array format is self-contained - each entry specifies its own Figma Variables source (`tokensFileId`,
`tokensCollectionName`, mode names) and output paths. Legacy format uses `common.variablesColors` for source.

## Figma codeSyntax Sync

The `CodeSyntaxSyncer` writes generated code names back to Figma Variables so designers see real code names in Dev Mode.

**Key files:**

| File                                                      | Purpose                              |
| --------------------------------------------------------- | ------------------------------------ |
| `Sources/ExFig/Sync/CodeSyntaxSyncer.swift`               | Core sync logic with name processing |
| `Sources/FigmaAPI/Model/VariableUpdate.swift`             | Request/response models for POST API |
| `Sources/FigmaAPI/Endpoint/UpdateVariablesEndpoint.swift` | POST endpoint implementation         |

**Integration in iOSColorsExport.swift:**

```swift
// After color export, sync codeSyntax if configured
if entry.syncCodeSyntax == true, let template = entry.codeSyntaxTemplate {
    let syncer = CodeSyntaxSyncer(client: client)
    let count = try await syncer.sync(
        fileId: tokensFileId,
        collectionName: tokensCollectionName,
        template: template,
        nameStyle: entry.nameStyle,
        nameValidateRegexp: entry.nameValidateRegexp,
        nameReplaceRegexp: entry.nameReplaceRegexp
    )
    ui.info("Synced codeSyntax for \(count) variables")
}
```

**Name processing pipeline** (same as ColorsProcessor):

1. Normalize `/` -> `_`, deduplicate `color/color` -> `color`
2. Apply `nameReplaceRegexp` using `nameValidateRegexp` match
3. Apply `nameStyle` (camelCase, snakeCase, etc.)

**Requirements:** Figma Enterprise plan, `file_variables:write` token scope, Edit file access.

## Multiple Images Configuration

Images can be configured as a single object (legacy) or array (new format) in `Params.swift`:

```swift
// ImagesConfiguration enum handles both formats via custom Decodable
enum ImagesConfiguration: Decodable {
    case single(Images)       // Legacy: images: { assetsFolder: "Illustrations", ... }
    case multiple([ImagesEntry])  // New: images: [{ figmaFrameName: "Promo", ... }]

    var entries: [ImagesEntry]  // Unified access to all entries
    var isMultiple: Bool        // Check format type
}

// ImagesLoaderConfig passes frame-specific settings to loader
let config = ImagesLoaderConfig.forIOS(entry: entry, params: params)
let loader = ImagesLoader(client: client, params: params, platform: .ios, logger: logger, config: config)
```

**Key types:**

| Type                  | Purpose                                                   |
| --------------------- | --------------------------------------------------------- |
| `ImagesConfiguration` | Enum with `.single`/`.multiple` for backward compat       |
| `ImagesEntry`         | Per-frame config (figmaFrameName, scales, output paths)   |
| `ImagesLoaderConfig`  | Sendable struct passed to ImagesLoader for frame settings |

**Frame name resolution:** `entry.figmaFrameName` -> `params.common?.images?.figmaFrameName` -> `"Illustrations"`
