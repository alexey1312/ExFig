# Migration from figma-export

This guide helps users migrate from [figma-export](https://github.com/RedMadRobot/figma-export) to ExFig.

## Quick Start

ExFig is fully compatible with figma-export configuration files. You can:

1. **Use your existing config** — ExFig automatically detects `figma-export.yaml`
2. **Run the migration command** — `exfig migrate` adds new features to your config

```bash
# Option 1: Just use ExFig (works immediately)
exfig colors
exfig icons
exfig images

# Option 2: Migrate config with new features
exfig migrate figma-export.yaml -o exfig.yaml
```

## Command Mapping

| figma-export                       | ExFig               | Notes                             |
| ---------------------------------- | ------------------- | --------------------------------- |
| `figma-export colors`              | `exfig colors`      | Identical                         |
| `figma-export icons`               | `exfig icons`       | Identical                         |
| `figma-export images`              | `exfig images`      | Identical                         |
| `figma-export typography`          | `exfig typography`  | Identical                         |
| `figma-export init --platform ios` | `exfig init -p ios` | Identical                         |
| —                                  | `exfig batch`       | **New**: Process multiple configs |
| —                                  | `exfig download`    | **New**: JSON export (W3C tokens) |
| —                                  | `exfig migrate`     | **New**: Config migration         |

## Configuration Compatibility

ExFig uses the same YAML structure as figma-export. All existing fields are supported.

**Auto-detected config files (in order):**

1. `figma-export.yaml` (for compatibility)
2. `exfig.yaml`

### New Sections in ExFig

#### Version Tracking Cache

Skip exports when Figma file hasn't changed:

```yaml
common:
  cache:
    enabled: true
    path: ".exfig-cache.json"
```

CLI flags:

- `--cache` — Enable version tracking
- `--force` — Ignore cache, always export
- `--experimental-granular-cache` — Track per-node changes (even more efficient)

#### Flutter Platform

```yaml
flutter:
  output: "./lib/generated"

  colors:
    output: "colors.dart"
    className: "AppColors"

  icons:
    output: "assets/icons"
    dartFile: "icons.dart"
    className: "AppIcons"

  images:
    output: "assets/images"
    dartFile: "images.dart"
    className: "AppImages"
    format: png
    scales: [1, 2, 3]
```

#### Web Platform (React/TypeScript)

```yaml
web:
  output: "./src/tokens"

  colors:
    cssFileName: "theme.css"
    tsFileName: "variables.ts"
    jsonFileName: "tokens.json"

  icons:
    outputDirectory: "./src/icons"
    svgDirectory: "assets/icons"
    generateReactComponents: true

  images:
    outputDirectory: "./src/images"
    assetsDirectory: "assets/images"
    generateReactComponents: true
```

## New Features

### Multiple Icons/Images/Colors from Different Frames

Export assets from multiple Figma frames in a single config:

```yaml
# Legacy format (still supported)
ios:
  icons:
    format: svg
    assetsFolder: Icons
    nameStyle: camelCase

# New array format
ios:
  icons:
    - figmaFrameName: Actions
      format: svg
      assetsFolder: Actions
      nameStyle: camelCase
      imageSwift: "./Generated/ActionsIcons.swift"

    - figmaFrameName: Navigation
      format: svg
      assetsFolder: Navigation
      nameStyle: camelCase
      imageSwift: "./Generated/NavigationIcons.swift"
```

Same pattern works for `images` and `colors`:

```yaml
ios:
  colors:
    - tokensFileId: abc123
      tokensCollectionName: Base Palette
      lightModeName: Light
      darkModeName: Dark
      useColorAssets: true
      assetsFolder: BaseColors
      colorSwift: "./Generated/BaseColors.swift"

    - tokensFileId: def456
      tokensCollectionName: Theme Colors
      lightModeName: Light
      useColorAssets: true
      assetsFolder: ThemeColors
      colorSwift: "./Generated/ThemeColors.swift"
```

### Batch Processing

Process multiple config files in parallel:

```bash
exfig batch ./configs/
exfig batch ./configs/ --parallel 4
exfig batch ./configs/ --cache --experimental-granular-cache
```

### JSON Export (W3C Design Tokens)

Export Figma data as JSON for custom pipelines:

```bash
exfig download colors -o tokens/colors.json
exfig download icons -o tokens/icons.json --asset-format svg
exfig download all -o ./tokens/
```

Output follows [W3C Design Tokens](https://design-tokens.github.io/community-group/format/) specification:

```json
{
  "Background": {
    "Primary": {
      "$type": "color",
      "$value": {
        "Light": "#ffffff",
        "Dark": "#1a1a1a"
      }
    }
  }
}
```

### Additional Name Styles

ExFig adds more `nameStyle` options:

| Style                  | Example        |
| ---------------------- | -------------- |
| `camelCase`            | `myIconName`   |
| `snake_case`           | `my_icon_name` |
| `PascalCase`           | `MyIconName`   |
| `kebab-case`           | `my-icon-name` |
| `SCREAMING_SNAKE_CASE` | `MY_ICON_NAME` |

### Fault Tolerance Options

All commands support retry and rate limiting:

```bash
exfig icons --max-retries 6 --rate-limit 15 --timeout 90
exfig icons --concurrent-downloads 50  # Increase CDN parallelism
```

## Migration Steps

### Automatic Migration

```bash
# Migrate with new cache feature
exfig migrate figma-export.yaml -o exfig.yaml

# Or migrate and overwrite
exfig migrate figma-export.yaml -o exfig.yaml --force
```

### Manual Migration

1. Rename `figma-export.yaml` to `exfig.yaml` (optional)
2. Add cache section:
   ```yaml
   common:
     cache:
       enabled: true
       path: ".exfig-cache.json"
   ```
3. Add platform sections as needed (`flutter:`, `web:`)

## Breaking Changes

**None.** ExFig is designed as a drop-in replacement for figma-export.

## Getting Help

- Documentation: [CONFIG.md](CONFIG.md)
- Issues: [GitHub Issues](https://github.com/alexey1312/ExFig/issues)
