---
paths:
  - "Sources/ExFigCLI/Input/PKLConfig*.swift"
  - "Sources/ExFigCLI/Subcommands/Export/**"
  - "Sources/ExFigCLI/Loaders/**"
---

# Multi-Entry Configuration Patterns

This rule covers Icons, Colors, and Images multi-entry configuration patterns using PKL.

## PKL Entry Types

Each platform defines entry types in PKL schemas (`Sources/ExFigCLI/Resources/Schemas/`):

| PKL Type             | Extends              | Platform fields                                              |
| -------------------- | -------------------- | ------------------------------------------------------------ |
| `iOS.IconsEntry`     | `Common.FrameSource` | format, assetsFolder, nameStyle, renderMode, codeConnectSwift |
| `iOS.ColorsEntry`    | `Common.VariablesSource` | useColorAssets, assetsFolder, colorSwift, swiftuiColorSwift |
| `iOS.ImagesEntry`    | `Common.FrameSource` | assetsFolder, scales, sourceFormat, outputFormat, heicOptions |
| `Android.IconsEntry` | `Common.FrameSource` | format, output, nameStyle, composeIconFormat                 |
| `Android.ColorsEntry`| `Common.VariablesSource` | xmlOutputFileName, composePackageName, colorKotlin        |
| `Android.ImagesEntry`| `Common.FrameSource` | format, output, scales, webpOptions                          |
| `Flutter.IconsEntry` | `Common.FrameSource` | output, nameStyle, className                                 |
| `Flutter.ColorsEntry`| `Common.VariablesSource` | output, className                                        |
| `Flutter.ImagesEntry`| `Common.FrameSource` | output, scales, format                                       |
| `Web.IconsEntry`     | `Common.FrameSource` | outputDirectory, nameStyle, className                        |
| `Web.ColorsEntry`    | `Common.VariablesSource` | outputDirectory, cssFileName, jsonFileName               |

Consumer configs declare entries as `Listing<Entry>`:

```pkl
ios {
  icons = new Listing {
    new iOS.IconsEntry { figmaFrameName = "Actions"; assetsFolder = "Actions" }
    new iOS.IconsEntry { figmaFrameName = "Nav"; assetsFolder = "Nav" }
  }
}
```

## Per-Entry Field Fallback

Entry fields override `common` settings. Fallback order in Swift export code:

| Field                | Fallback Order                                                            |
| -------------------- | ------------------------------------------------------------------------- |
| `figmaFrameName`     | entry -> `common.icons.figmaFrameName` -> `"Icons"` / `"Illustrations"`   |
| `figmaPageName`      | entry -> `common.icons.figmaPageName` -> `nil`                            |
| `nameValidateRegexp` | entry -> `common.icons.nameValidateRegexp` -> `nil`                       |
| `nameReplaceRegexp`  | entry -> `common.icons.nameReplaceRegexp` -> `nil`                        |
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

**Loader config construction:**

```swift
// IconsLoaderConfig passes per-entry settings to loader
let config = IconsLoaderConfig.forIOS(entry: entry, params: params)
let loader = IconsLoader(client: client, params: params, platform: .ios, logger: logger, config: config)
```

**Key types:**

| Type                | Purpose                                                  |
| ------------------- | -------------------------------------------------------- |
| `IconsLoaderConfig` | Sendable struct passed to IconsLoader for frame settings |
| `ImagesLoaderConfig`| Sendable struct passed to ImagesLoader for frame settings|

## Colors Entry Pattern

Each colors entry is self-contained — specifies its own Figma Variables source and output paths:

```pkl
ios {
  colors = new Listing {
    new iOS.ColorsEntry {
      tokensFileId = "FILE_ID"
      tokensCollectionName = "Design Tokens"
      lightModeName = "Light"
      darkModeName = "Dark"
      colorSwift = "Colors.swift"
    }
  }
}
```

When entries omit source fields, they fall back to `common.variablesColors`.

## Figma codeSyntax Sync

The `CodeSyntaxSyncer` writes generated code names back to Figma Variables so designers see real code names in Dev Mode.

**Key files:**

| File                                                      | Purpose                              |
| --------------------------------------------------------- | ------------------------------------ |
| `Sources/ExFigCLI/Sync/CodeSyntaxSyncer.swift`            | Core sync logic with name processing |
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

## Images Frame Name Resolution

`entry.figmaFrameName` -> `params.common?.images?.figmaFrameName` -> `"Illustrations"`
