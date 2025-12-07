# Usage Guide

This guide covers the ExFig command-line interface and common usage patterns.

## Basic Commands

ExFig provides four main export commands:

```bash
# Export colors
exfig colors

# Export icons
exfig icons

# Export images
exfig images

# Export typography (text styles)
exfig typography
```

## Configuration File

By default, ExFig looks for `exfig.yaml` in the current directory. To specify a different location:

```bash
exfig colors -i path/to/exfig.yaml
exfig colors --input path/to/exfig.yaml
```

## Filtering Exports

Export specific items by name using the last argument:

### Single Item

```bash
exfig icons "ic/24/edit"
```

### Multiple Items

Separate names with commas:

```bash
exfig icons "ic/24/edit, ic/16/notification"
```

### Wildcard Patterns

Use `*` to match multiple items:

```bash
# Export all icons starting with "ic/24/videoplayer/"
exfig icons "ic/24/videoplayer/*"

# Export all colors starting with "common/"
exfig colors "common/*"

# Export all typography styles starting with "heading/"
exfig typography "heading/*"
```

**Note:** Wildcard patterns don't work on Linux systems.

## Platform-Specific Usage

### iOS / Xcode Projects

For iOS projects, ExFig integrates directly with your Xcode project and Assets catalog:

```yaml
# exfig.yaml
ios:
  xcodeprojPath: "./Example.xcodeproj"
  target: "UIComponents"
  xcassetsPath: "./Resources/Assets.xcassets"
```

When you run export commands:

- Color sets, image sets, and icon sets are created in `Assets.xcassets`
- Swift extensions are generated for UIKit and SwiftUI
- Generated files are automatically added to your Xcode target

**Learn more:** [iOS Export Guide](ios/index.md)

### Android Studio Projects

For Android projects, you must configure resource directories in your `exfig.yaml`:

```yaml
# exfig.yaml
android:
  mainRes: "./app/src/main/res"
  resourcePackage: "com.example.app"
  mainSrc: "./app/src/main/java"
  icons:
    output: "exfig-icons"
  images:
    output: "exfig-images"
```

#### Important: Gradle Configuration

Before first use, add the generated resource directories to your `build.gradle`:

```gradle
android {
  sourceSets {
    main {
      res.srcDirs += "src/main/res/exfig-icons"
      res.srcDirs += "src/main/res/exfig-images"
    }
  }
}
```

#### Directory Structure

ExFig creates the following structure for Android:

```
main/
  res/
    exfig-icons/
      drawable/              # Light mode icons
      drawable-night/        # Dark mode icons
    exfig-images/
      drawable/              # Light mode images
      drawable-night/        # Dark mode images
      drawable-mdpi/         # Scale-specific images
      drawable-hdpi/
      drawable-xhdpi/
      drawable-xxhdpi/
      drawable-xxxhdpi/
    values/
      colors.xml             # Color definitions
      typography.xml         # Text style definitions
```

**Important:** When you run `exfig icons` or `exfig images`, ExFig **clears** the corresponding output directory before
exporting. Make sure not to manually place files in these directories.

**Learn more:** [Android Export Guide](android/index.md)

### Jetpack Compose Code Generation

To generate Kotlin code for Jetpack Compose:

1. Configure `mainSrc` and `resourcePackage` in your `exfig.yaml`
2. Set `composePackageName` for each resource type:

```yaml
android:
  mainSrc: "./app/src/main/java"
  resourcePackage: "com.example.app"
  colors:
    composePackageName: "com.example.app.ui.theme"
  icons:
    composePackageName: "com.example.app.ui.icons"
  typography:
    composePackageName: "com.example.app.ui.typography"
```

ExFig will generate:

- `Colors.kt` - Color definitions for Jetpack Compose
- `Icons.kt` - Icon composables
- `Typography.kt` - Text style definitions

**Learn more:** [Android Compose Guide](android/index.md)

## Generating Configuration Files

Create a starter configuration file:

```bash
# For iOS projects
exfig init --platform ios

# For Android projects
exfig init --platform android
```

This creates an `exfig.yaml` file with platform-specific defaults in your current directory.

## Common Workflows

### iOS + UIKit

```bash
# 1. Configure exfig.yaml with Xcode project paths
# 2. Export all resources
exfig colors
exfig icons
exfig images
exfig typography

# 3. Use generated extensions in code:
# - UIColor.backgroundPrimary
# - UIImage.icArrowRight
# - UIFont.body()
```

### iOS + SwiftUI

```bash
# 1. Configure SwiftUI-specific paths in exfig.yaml
# 2. Export all resources
exfig colors
exfig icons
exfig images
exfig typography

# 3. Use generated extensions in code:
# - Color.backgroundPrimary
# - Image.icArrowRight
# - Font.body()
```

### Android + XML Views

```bash
# 1. Configure android.mainRes in exfig.yaml
# 2. Add resource directories to build.gradle
# 3. Export resources
exfig colors
exfig icons
exfig images
exfig typography

# 4. Use in XML and code:
# - @color/background_primary
# - @drawable/ic_arrow_right
# - @style/TextAppearance.Body
```

### Android + Jetpack Compose

```bash
# 1. Configure mainSrc, resourcePackage, and composePackageName
# 2. Export resources
exfig colors
exfig icons
exfig typography

# 3. Use generated Kotlin code:
# - ExFigColors.backgroundPrimary
# - ExFigIcons.IcArrowRight()
# - ExFigTypography.body
```

## Version Tracking

ExFig can track Figma file versions to skip unnecessary exports. This is useful for CI/CD pipelines where you want to
avoid re-exporting unchanged assets.

### Enable via Configuration

```yaml
common:
  cache:
    enabled: true
    path: ".exfig-cache.json" # optional
```

### Enable via CLI

```bash
# Enable version tracking
exfig colors --cache
exfig icons --cache

# Disable version tracking (always export)
exfig icons --no-cache

# Force export and update cache
exfig icons --force

# Custom cache file path
exfig icons --cache-path ./custom-cache.json
```

**Note:** The version changes when a Figma library is **published**, not on every auto-save.

See [Configuration Reference](../../CONFIG.md) for more details.

## Fault Tolerance

All commands support fault tolerance options for reliable exports:

### Basic Options (All Commands)

```bash
# Custom retry count (default: 4)
exfig colors --max-retries 6

# Custom rate limit (default: 10 req/min)
exfig icons --rate-limit 20
```

### Extended Options (Heavy Commands)

Commands that download many files (`icons`, `images`, `fetch`) support additional options:

```bash
# Stop on first error (disable retries)
exfig icons --fail-fast

# Resume from checkpoint after interruption
exfig images --resume

# Increase concurrent CDN downloads (default: 20)
exfig icons --concurrent-downloads 50
```

| Option                   | Description                            | Commands             |
| ------------------------ | -------------------------------------- | -------------------- |
| `--max-retries`          | Maximum retry attempts (default: 4)    | All                  |
| `--rate-limit`           | API requests per minute (default: 10)  | All                  |
| `--fail-fast`            | Stop immediately on error              | icons, images, fetch |
| `--resume`               | Continue from checkpoint               | icons, images, fetch |
| `--concurrent-downloads` | Concurrent CDN downloads (default: 20) | icons, images, fetch |

### Checkpoint System

Long-running exports create checkpoints so you can resume after interruption:

```bash
# Resume interrupted export
exfig icons --resume

# Checkpoints are stored in: .exfig-checkpoint.json
# Checkpoints expire after 24 hours
# Successful completion automatically deletes the checkpoint
```

## Batch Processing

Process multiple configuration files in parallel with shared rate limiting.

> **Note:** Directory scanning is non-recursive. Only YAML files directly in the specified directory are processed. Use
> shell globbing for nested configs (e.g., `./configs/*/*.yaml`).

```bash
# Process all configs in a directory (non-recursive)
exfig batch ./configs/

# Process specific config files
exfig batch ios-app.yaml android-app.yaml flutter-app.yaml

# Process nested configs via shell glob
exfig batch ./configs/*/*.yaml

# With custom parallelism (default: 3)
exfig batch ./configs/ --parallel 5

# Stop on first error
exfig batch ./configs/ --fail-fast

# Generate JSON report
exfig batch ./configs/ --report batch-results.json

# Resume from checkpoint
exfig batch ./configs/ --resume
```

### Batch Options

| Option          | Description                                | Default |
| --------------- | ------------------------------------------ | ------- |
| `--parallel`    | Maximum concurrent configs                 | 3       |
| `--fail-fast`   | Stop processing on first error             | false   |
| `--rate-limit`  | Figma API requests per minute              | 10      |
| `--max-retries` | Maximum retry attempts for failed requests | 4       |
| `--resume`      | Resume from previous checkpoint            | false   |
| `--report`      | Path to write JSON report                  |         |

## JSON Export (Design Tokens)

Export Figma design data as JSON for integration with design token tools and pipelines:

```bash
# Export colors as W3C Design Tokens (default format)
exfig download colors -o tokens/colors.json

# Export raw Figma API response for debugging
exfig download colors -o debug/colors.json --format raw

# Export icons with SVG URLs
exfig download icons -o tokens/icons.json --asset-format svg

# Export typography
exfig download typography -o tokens/typography.json

# Export all token types to a directory
exfig download all -o ./tokens/
```

### Download Subcommands

| Subcommand   | Description                     |
| ------------ | ------------------------------- |
| `colors`     | Export colors as JSON           |
| `icons`      | Export icon metadata with URLs  |
| `images`     | Export image metadata with URLs |
| `typography` | Export text styles as JSON      |
| `all`        | Export all types to a directory |

### Download Options

| Option           | Short | Description                      | Default |
| ---------------- | ----- | -------------------------------- | ------- |
| `--output`       | `-o`  | Output file path (required)      | -       |
| `--format`       | `-f`  | Output format: w3c, raw          | w3c     |
| `--compact`      |       | Output minified JSON             | false   |
| `--asset-format` |       | Image format: svg, png, pdf, jpg | svg     |
| `--scale`        |       | Scale for raster formats         | 3       |

The W3C format follows the [W3C Design Tokens](https://design-tokens.github.io/community-group/format/) specification.

## Quick Fetch (No Config File)

For quick, one-off downloads without creating a configuration file, use the `fetch` command. This is useful when you
need to quickly grab images from Figma without setting up a full export pipeline.

### Basic Usage

```bash
# Download PNG images at 3x scale (default)
exfig fetch --file-id YOUR_FILE_ID --frame "Illustrations" --output ./images

# Using short options
exfig fetch -f YOUR_FILE_ID -r "Icons" -o ./icons
```

### Format Options

```bash
# Download as SVG (vector format)
exfig fetch -f abc123 -r "Icons" -o ./icons --format svg

# Download as PDF (vector format)
exfig fetch -f abc123 -r "Icons" -o ./icons --format pdf

# Download as JPG
exfig fetch -f abc123 -r "Photos" -o ./photos --format jpg

# Download as WebP with quality settings
exfig fetch -f abc123 -r "Images" -o ./images --format webp --webp-quality 90

# Download WebP lossless
exfig fetch -f abc123 -r "Images" -o ./images --format webp --webp-encoding lossless
```

### Scale Options

```bash
# Download PNG at 2x scale
exfig fetch -f abc123 -r "Images" -o ./images --scale 2

# Download PNG at 1x scale
exfig fetch -f abc123 -r "Images" -o ./images --scale 1

# Note: Scale is ignored for vector formats (SVG, PDF)
```

### Filtering and Naming

```bash
# Filter specific images
exfig fetch -f abc123 -r "Images" -o ./images --filter "logo/*"

# Filter multiple patterns
exfig fetch -f abc123 -r "Images" -o ./images --filter "logo/*, banner/*"

# Convert names to camelCase
exfig fetch -f abc123 -r "Images" -o ./images --name-style camelCase

# Convert names to snake_case
exfig fetch -f abc123 -r "Images" -o ./images --name-style snake_case

# Convert names to PascalCase
exfig fetch -f abc123 -r "Images" -o ./images --name-style PascalCase

# Convert names to kebab-case
exfig fetch -f abc123 -r "Images" -o ./images --name-style kebab-case

# Convert names to SCREAMING_SNAKE_CASE
exfig fetch -f abc123 -r "Images" -o ./images --name-style SCREAMING_SNAKE_CASE

# Custom regex replacement
exfig fetch -f abc123 -r "Images" -o ./images \
  --name-validate-regexp "^icon/(.*)$" \
  --name-replace-regexp "ic_$1"
```

### Dark Mode Support

```bash
# Extract dark mode variants (images ending with "_dark" suffix)
exfig fetch -f abc123 -r "Images" -o ./images --dark-mode-suffix "_dark"
```

### All Download Options

| Option                   | Short | Description                                                                     | Default      |
| ------------------------ | ----- | ------------------------------------------------------------------------------- | ------------ |
| `--file-id`              | `-f`  | Figma file ID (required)                                                        | -            |
| `--frame`                | `-r`  | Figma frame name (required)                                                     | -            |
| `--output`               | `-o`  | Output directory (required)                                                     | -            |
| `--format`               |       | Image format: png, svg, jpg, pdf, webp                                          | png          |
| `--scale`                |       | Scale factor (0.01-4.0)                                                         | 3 (PNG only) |
| `--filter`               |       | Filter pattern (e.g., "icon/\*")                                                | -            |
| `--name-style`           |       | Name style: camelCase, snake_case, PascalCase, kebab-case, SCREAMING_SNAKE_CASE | -            |
| `--name-validate-regexp` |       | Regex pattern for validation                                                    | -            |
| `--name-replace-regexp`  |       | Regex replacement pattern                                                       | -            |
| `--dark-mode-suffix`     |       | Suffix for dark variants                                                        | -            |
| `--webp-encoding`        |       | WebP encoding: lossy, lossless                                                  | lossy        |
| `--webp-quality`         |       | WebP quality (0-100)                                                            | 80           |
| `--timeout`              |       | API request timeout in seconds                                                  | 30           |
| `--max-retries`          |       | Maximum retry attempts                                                          | 4            |
| `--rate-limit`           |       | API requests per minute                                                         | 10           |
| `--fail-fast`            |       | Stop on first error                                                             | false        |
| `--resume`               |       | Resume from checkpoint                                                          | false        |
| `--verbose`              | `-v`  | Show detailed output                                                            | false        |
| `--quiet`                | `-q`  | Show only errors                                                                | false        |

## Help and Version Info

```bash
# Show help
exfig --help
exfig colors --help

# Show version
exfig --version
```

## Troubleshooting

### "Failed to load configuration"

- Check that `exfig.yaml` exists in the current directory or use `-i` to specify its path
- Verify YAML syntax is correct (use a YAML validator)

### "Figma API error"

- Verify `FIGMA_PERSONAL_TOKEN` environment variable is set
- Check that your token has access to the specified Figma file
- Ensure file IDs are correct in your configuration

### "No resources found to export"

- Review [Design Requirements](design-requirements.md) for proper Figma file structure
- Check that frame names match your configuration (e.g., `common.icons.figmaFrameName`)
- Verify color/component names pass validation regexes in your config

### Android: "Resource directory not found"

- Ensure `android.mainRes` path is correct
- Create the directory if it doesn't exist
- Add the generated resource directories to `build.gradle` before running ExFig

## See Also

- [Getting Started](getting-started.md) - Installation and setup
- [Configuration Reference](../../CONFIG.md) - All available options
- [iOS Export Guide](ios/index.md) - iOS-specific details
- [Android Export Guide](android/index.md) - Android-specific details
- [Design Requirements](design-requirements.md) - Figma file structure

______________________________________________________________________

[← Back: Getting Started](getting-started.md) | [Up: Index](index.md) | [Next: iOS Guide →](ios/index.md)
