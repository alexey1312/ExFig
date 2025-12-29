# Icons Configuration

Icons can be configured as a single object (legacy) or array (new format) in `Params.swift`.

## Configuration Types

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

## Key Types

| Type                 | Purpose                                                                                                   |
| -------------------- | --------------------------------------------------------------------------------------------------------- |
| `IconsConfiguration` | Enum with `.single`/`.multiple` for backward compat                                                       |
| `IconsEntry`         | Per-frame config (figmaFrameName, format, assetsFolder, nameValidateRegexp, nameReplaceRegexp, nameStyle) |
| `IconsLoaderConfig`  | Sendable struct passed to IconsLoader for frame settings                                                  |

## Per-entry Fields with Fallback

| Field                | Fallback Order                                                           |
| -------------------- | ------------------------------------------------------------------------ |
| `figmaFrameName`     | entry → `common.icons.figmaFrameName` → `"Icons"`                        |
| `nameValidateRegexp` | entry → `common.icons.nameValidateRegexp` → `nil`                        |
| `nameReplaceRegexp`  | entry → `common.icons.nameReplaceRegexp` → `nil`                         |
| `nameStyle`          | entry → platform default (iOS: `nil`, Android/Flutter/Web: `.snakeCase`) |

## Fallback Logic in Export Files

```swift
let processor = ImagesProcessor(
    platform: .android,
    nameValidateRegexp: entry.nameValidateRegexp ?? params.common?.icons?.nameValidateRegexp,
    nameReplaceRegexp: entry.nameReplaceRegexp ?? params.common?.icons?.nameReplaceRegexp,
    nameStyle: entry.nameStyle ?? .snakeCase
)
```

## YAML Examples

```yaml
# Legacy single format
ios:
  icons:
    format: svg
    assetsFolder: "Icons"

# New multiple format
ios:
  icons:
    - figmaFrameName: "Actions"
      format: svg
      assetsFolder: "ActionIcons"
    - figmaFrameName: "Navigation"
      format: pdf
      assetsFolder: "NavIcons"
```
