# Migration from figma-export

This guide helps users migrate from [figma-export](https://github.com/RedMadRobot/figma-export) to ExFig.

## Quick Start

ExFig v2 uses PKL configuration instead of YAML. To migrate:

1. **Generate a new PKL config** for your platform:
   ```bash
   exfig init -p ios       # or android, flutter, web
   ```
2. **Copy your settings** from `figma-export.yaml` into the generated `exfig.pkl`
3. **Run exports** as before:
   ```bash
   exfig colors -i exfig.pkl
   exfig icons -i exfig.pkl
   exfig images -i exfig.pkl
   ```

## Command Mapping

| figma-export                       | ExFig               | Notes                             |
| ---------------------------------- | ------------------- | --------------------------------- |
| `figma-export colors`              | `exfig colors`      | Same functionality                |
| `figma-export icons`               | `exfig icons`       | Same functionality                |
| `figma-export images`              | `exfig images`      | Same functionality                |
| `figma-export typography`          | `exfig typography`  | Same functionality                |
| `figma-export init --platform ios` | `exfig init -p ios` | Generates PKL config              |
| —                                  | `exfig batch`       | **New**: Process multiple configs |
| —                                  | `exfig download`    | **New**: JSON export (W3C tokens) |

## Configuration Migration

ExFig v2 uses [PKL](https://pkl-lang.org/) (Programmable, Scalable, Safe) instead of YAML. YAML configs are no longer supported.

**Config discovery:** ExFig looks for `exfig.pkl` in the current directory. Use `-i` to specify a custom path.

### Version Tracking Cache

Skip exports when Figma file hasn't changed:

```pkl
import ".exfig/schemas/Common.pkl"

common = new Common.CommonConfig {
  cache = new Common.Cache {
    enabled = true
    path = ".exfig-cache.json"
  }
}
```

CLI flags:

- `--cache` — Enable version tracking
- `--force` — Ignore cache, always export
- `--experimental-granular-cache` — Track per-node changes (even more efficient)

### Flutter Platform

```pkl
import ".exfig/schemas/Flutter.pkl"

flutter = new Flutter.FlutterConfig {
  output = "./lib/generated"

  colors = new Listing {
    new Flutter.ColorsEntry {
      colorDart = "colors.dart"
      className = "AppColors"
    }
  }

  icons = new Listing {
    new Flutter.IconsEntry {
      output = "assets/icons"
      dartFile = "icons.dart"
      className = "AppIcons"
    }
  }

  images = new Listing {
    new Flutter.ImagesEntry {
      output = "assets/images"
      dartFile = "images.dart"
      className = "AppImages"
      format = "png"
      scales = new Listing { 1; 2; 3 }
    }
  }
}
```

### Web Platform (React/TypeScript)

```pkl
import ".exfig/schemas/Web.pkl"

web = new Web.WebConfig {
  output = "./src/tokens"

  colors = new Listing {
    new Web.ColorsEntry {
      cssFileName = "theme.css"
      tsFileName = "variables.ts"
      jsonFileName = "tokens.json"
    }
  }

  icons = new Listing {
    new Web.IconsEntry {
      outputDirectory = "./src/icons"
      svgDirectory = "assets/icons"
      generateReactComponents = true
    }
  }

  images = new Listing {
    new Web.ImagesEntry {
      outputDirectory = "./src/images"
      assetsDirectory = "assets/images"
      generateReactComponents = true
    }
  }
}
```

## New Features

### Multiple Icons/Images/Colors from Different Frames

Export assets from multiple Figma frames in a single config using PKL `Listing`:

```pkl
import ".exfig/schemas/iOS.pkl"

ios = new iOS.iOSConfig {
  xcodeprojPath = "MyApp.xcodeproj"
  target = "MyApp"
  xcassetsPath = "MyApp/Resources/Assets.xcassets"

  icons = new Listing {
    new iOS.IconsEntry {
      figmaFrameName = "Actions"
      format = "svg"
      assetsFolder = "Actions"
      nameStyle = "camelCase"
      imageSwift = "./Generated/ActionsIcons.swift"
    }
    new iOS.IconsEntry {
      figmaFrameName = "Navigation"
      format = "svg"
      assetsFolder = "Navigation"
      nameStyle = "camelCase"
      imageSwift = "./Generated/NavigationIcons.swift"
    }
  }
}
```

Same pattern works for `colors`:

```pkl
ios = new iOS.iOSConfig {
  // ...
  colors = new Listing {
    new iOS.ColorsEntry {
      tokensFileId = "abc123"
      tokensCollectionName = "Base Palette"
      lightModeName = "Light"
      darkModeName = "Dark"
      useColorAssets = true
      assetsFolder = "BaseColors"
      colorSwift = "./Generated/BaseColors.swift"
    }
    new iOS.ColorsEntry {
      tokensFileId = "def456"
      tokensCollectionName = "Theme Colors"
      lightModeName = "Light"
      useColorAssets = true
      assetsFolder = "ThemeColors"
      colorSwift = "./Generated/ThemeColors.swift"
    }
  }
}
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

1. Run `exfig init -p <platform>` to generate a fresh `exfig.pkl`
2. Copy your Figma file IDs, frame names, and other settings from `figma-export.yaml` into `exfig.pkl`
3. Add new sections as needed (cache, additional platforms)
4. Verify with `pkl eval --format json exfig.pkl` (requires local schemas via `exfig schemas`)
5. Run your export commands and compare output

## Breaking Changes

- **YAML configs removed** — ExFig v2 uses PKL exclusively. Migrate your `figma-export.yaml` / `exfig.yaml` to `exfig.pkl`.
- **`exfig migrate` command removed** — use `exfig init` to generate a fresh PKL config and manually transfer your settings.
- **Config discovery changed** — ExFig no longer searches for `figma-export.yaml` or `exfig.yaml`. Only `exfig.pkl` is auto-detected.

## Getting Help

- Configuration reference: [CONFIG.md](CONFIG.md)
- PKL guide: [docs/PKL.md](docs/PKL.md)
- Migration guide (YAML to PKL): [MIGRATION.md](MIGRATION.md)
- Issues: [GitHub Issues](https://github.com/alexey1312/ExFig/issues)
