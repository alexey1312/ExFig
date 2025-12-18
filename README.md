# ExFig

[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Falexey1312%2FExFig%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/alexey1312/ExFig)
[![Swift-versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Falexey1312%2FExFig%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/alexey1312/ExFig)
[![CI](https://github.com/alexey1312/ExFig/actions/workflows/ci.yml/badge.svg)](https://github.com/alexey1312/ExFig/actions/workflows/ci.yml)
[![Release](https://github.com/alexey1312/ExFig/actions/workflows/release.yml/badge.svg)](https://github.com/alexey1312/ExFig/actions/workflows/release.yml)
[![Docs](https://github.com/alexey1312/ExFig/actions/workflows/deploy-docc.yml/badge.svg)](https://alexey1312.github.io/ExFig/documentation/exfig)
![Coverage](https://img.shields.io/badge/coverage-49.42%25-yellow)
[![License](https://img.shields.io/github/license/alexey1312/ExFig.svg)](LICENSE)

Command-line utility to export colors, typography, icons, and images from Figma to Xcode, Android Studio, Flutter, and
Web (React/TypeScript) projects.

Automatically sync your design system from Figma to code with support for Dark Mode, SwiftUI, UIKit, Jetpack Compose,
Flutter, and React/TypeScript.

## Why ExFig?

- **Eliminate manual export**: Figma doesn't natively export colors and images to Xcode/Android Studio
- **Keep design and code in sync**: Automate updates to your component library
- **Save time**: No more manual color palette management or icon exports

## Features

### Design Assets

- ✨ Export light & dark color palettes
- 🎨 High contrast color support (iOS)
- 🖼️ Icons and images with Dark Mode variants
- 📄 PDF vector icons (resolution-independent, iOS)
- 🖥️ iPad-specific asset variants
- 📝 Typography with Dynamic Type support (iOS)
- 🔄 RTL (Right-to-Left) layout support
- 🎯 Figma Variables support

### Platform Support

- 📱 SwiftUI and UIKit (iOS/macOS)
- 🤖 Jetpack Compose and XML resources (Android)
- 🦋 Flutter / Dart
- 🌐 React / TypeScript (CSS variables, TSX components)
- 🔧 Customizable code templates (Stencil)

### Export Formats

- 🖼️ PNG, SVG, PDF, JPEG, WebP (with quality control)
- 📊 W3C Design Tokens (JSON export)
- ⚡ Quick fetch mode (no config file needed)

### Performance & Reliability

- ⚡ Parallel downloads & writes
- 📦 Batch processing with shared rate limiting
- 🔁 Automatic retries with exponential backoff
- 💾 Checkpoint/resume for interrupted exports
- 🕐 Version tracking (skip unchanged files)
- 🧬 Granular cache (per-node change detection, experimental)

### Developer Experience

- 🤖 CI/CD ready (quiet mode, exit codes, JSON reports)
- 🔄 [GitHub Action](https://github.com/alexey1312/exfig-action) for automated exports
- 📊 Rich progress indicators with ETA
- 🔇 Verbose, normal, and quiet output modes
- 🚀 Swift 6 / Strict Concurrency

> **Note:** Exporting icons and images requires a Figma Professional/Organization plan (uses Shareable Team Libraries).

> **Tip:** For optimal PNG sizes, use oxipng (`ubi:shssoichiro/oxipng@9.1.5` via `mise use -g`) to compress exported PNG
> files after export.

## Quick Start

### 1. Install ExFig

```bash
# Using Homebrew (recommended)
brew install alexey1312/exfig/exfig

# Using Mint
mint install alexey1312/ExFig

# Using mise
mise use -g ubi:alexey1312/ExFig

# Or build from source
git clone https://github.com/alexey1312/ExFig.git
cd ExFig
swift build -c release
cp .build/release/exfig /usr/local/bin/
```

### 2. Set Figma Token

```bash
export FIGMA_PERSONAL_TOKEN=your_token_here
```

Get your token from [Figma's developer settings](https://www.figma.com/developers/api#access-tokens).

### 3. Generate Configuration

```bash
# For iOS projects
exfig init -p ios

# For Android projects
exfig init -p android

# For Flutter projects
exfig init -p flutter
```

### 4. Configure File IDs

Edit `exfig.yaml` and add your Figma file IDs:

```yaml
figma:
  lightFileId: YOUR_FIGMA_FILE_ID
```

### 5. Export Resources

```bash
# Migrate from figma-export (optional)
exfig migrate figma-export.yaml -o exfig.yaml

# Export colors
exfig colors

# Export icons
exfig icons

# Export images
exfig images

# Export typography
exfig typography

# Export with verbose output (detailed debug information)
exfig colors -v

# Export silently (errors only, suitable for CI/scripts)
exfig icons -q
```

## GitHub Action

Use [exfig-action](https://github.com/alexey1312/exfig-action) to automate design exports in your CI/CD pipeline:

```yaml
- uses: alexey1312/exfig-action@v1
  with:
    figma_token: ${{ secrets.FIGMA_TOKEN }}
    command: icons
    cache: true
```

See the [action repository](https://github.com/alexey1312/exfig-action) for full documentation and examples.

## Output Modes

ExFig supports different output modes for various use cases:

- **Normal** (default): Progress spinners and bars with colors
- **Verbose** (`-v`/`--verbose`): Detailed debug output including API calls and timing
- **Quiet** (`-q`/`--quiet`): Only errors, suitable for scripts and CI
- **Plain** (auto): No animations when output is piped or in CI

```bash
# Detailed output for debugging
exfig icons -v

# Silent mode for CI/scripts
exfig colors -q
```

## Version Tracking

ExFig can track Figma file versions to skip unnecessary exports. This is useful for CI/CD pipelines where you want to
avoid re-exporting unchanged assets. Works for all commands: `colors`, `icons`, `images`, and `typography`.

### Enable via Configuration

```yaml
common:
  cache:
    enabled: true
    path: ".exfig-cache.json" # optional, defaults to .exfig-cache.json
```

### Enable via CLI

```bash
# Enable version tracking (works for all commands)
exfig colors --cache
exfig icons --cache
exfig images --cache
exfig typography --cache

# Disable version tracking (always export)
exfig icons --no-cache

# Force export and update cache
exfig icons --force
```

**Note:** The version changes when a Figma library is **published**, not on every auto-save. This means exports are
skipped only when designers intentionally publish their changes.

### Experimental: Granular Cache

When `--cache` is enabled, you can add `--experimental-granular-cache` to track per-node content hashes. This allows
skipping unchanged assets even when the file version changes (useful when only some icons/images were modified):

```bash
exfig icons --cache --experimental-granular-cache
exfig images --cache --experimental-granular-cache
exfig batch --cache --experimental-granular-cache

# Force full re-export and update hashes
exfig icons --cache --experimental-granular-cache --force
```

**How it works:** Computes FNV-1a hash of each node's visual properties (fills, strokes, effects, rotation, children).
Only exports nodes whose hashes differ from the cached values.

**Known limitations:**

- Config changes (output path, format, scale) are not detected - use `--force` when config changes
- First run with granular cache populates hashes, subsequent runs benefit from tracking
- Output directory is not cleared - only changed files are overwritten

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
```

| Option                   | Description                            | Commands             |
| ------------------------ | -------------------------------------- | -------------------- |
| `--max-retries`          | Maximum retry attempts (default: 4)    | All                  |
| `--rate-limit`           | API requests per minute (default: 10)  | All                  |
| `--fail-fast`            | Stop immediately on error              | icons, images, fetch |
| `--resume`               | Continue from checkpoint               | icons, images, fetch |
| `--concurrent-downloads` | Concurrent CDN downloads (default: 20) | icons, images, fetch |

## Quick Fetch (No Config File)

For quick, one-off downloads without creating a configuration file, use the `fetch` command:

```bash
# Download PNG images at 3x scale (default)
exfig fetch --file-id abc123 --frame "Illustrations" --output ./images

# Download SVG icons
exfig fetch -f abc123 -r "Icons" -o ./icons --format svg

# Download PDF icons
exfig fetch -f abc123 -r "Icons" -o ./icons --format pdf

# Download with filtering and name conversion
exfig fetch -f abc123 -r "Images" -o ./images --filter "logo/*" --name-style camelCase

# Download at specific scale
exfig fetch -f abc123 -r "Images" -o ./images --scale 2

# Download as WebP with quality settings
exfig fetch -f abc123 -r "Images" -o ./images --format webp --webp-quality 90

# Download with dark mode variants
exfig fetch -f abc123 -r "Images" -o ./images --dark-mode-suffix "_dark"
```

### Fetch Options

| Option                   | Short | Description                                                                     | Default     |
| ------------------------ | ----- | ------------------------------------------------------------------------------- | ----------- |
| `--file-id`              | `-f`  | Figma file ID (required)                                                        | -           |
| `--frame`                | `-r`  | Figma frame name (required)                                                     | -           |
| `--output`               | `-o`  | Output directory (required)                                                     | -           |
| `--format`               |       | Image format: png, svg, jpg, pdf, webp                                          | png         |
| `--scale`                |       | Scale factor (0.01-4.0)                                                         | 3 (for PNG) |
| `--filter`               |       | Filter pattern (e.g., "icon/\*")                                                | -           |
| `--name-style`           |       | Name style: camelCase, snake_case, PascalCase, kebab-case, SCREAMING_SNAKE_CASE | -           |
| `--dark-mode-suffix`     |       | Suffix for dark variants (e.g., "\_dark")                                       | -           |
| `--webp-encoding`        |       | WebP encoding: lossy, lossless                                                  | lossy       |
| `--webp-quality`         |       | WebP quality (0-100)                                                            | 80          |
| `--max-retries`          |       | Maximum retry attempts                                                          | 4           |
| `--rate-limit`           |       | API requests per minute                                                         | 18          |
| `--fail-fast`            |       | Stop on first error                                                             | false       |
| `--resume`               |       | Resume from checkpoint                                                          | false       |
| `--concurrent-downloads` |       | Concurrent CDN downloads                                                        | 20          |

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

The W3C format follows the [W3C Design Tokens](https://design-tokens.github.io/community-group/format/) specification.
See [CONFIG.md](CONFIG.md#json-export-download-command) for full documentation.

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
```

### Batch Options

| Option                   | Description                                | Default |
| ------------------------ | ------------------------------------------ | ------- |
| `--parallel`             | Maximum concurrent configs                 | 3       |
| `--fail-fast`            | Stop processing on first error             | false   |
| `--rate-limit`           | Figma API requests per minute              | 10      |
| `--max-retries`          | Maximum retry attempts for failed requests | 4       |
| `--resume`               | Resume from previous checkpoint            | false   |
| `--report`               | Path to write JSON report                  |         |
| `--cache`                | Enable version tracking cache              | false   |
| `--no-cache`             | Disable version tracking cache             | false   |
| `--force`                | Force export and update cache              | false   |
| `--cache-path`           | Custom cache file path                     |         |
| `--concurrent-downloads` | Maximum concurrent CDN downloads           | 20      |

### Batch Report Format

The JSON report includes timing, success/failure counts, and per-config results:

```json
{
  "startTime": "2025-01-15T10:30:00Z",
  "endTime": "2025-01-15T10:32:15Z",
  "duration": 135.5,
  "totalConfigs": 5,
  "successCount": 4,
  "failureCount": 1,
  "results": [
    {
      "name": "ios-app.yaml",
      "path": "/configs/ios-app.yaml",
      "success": true,
      "stats": { "colors": 45, "icons": 120, "images": 30, "typography": 12 }
    },
    {
      "name": "android-app.yaml",
      "path": "/configs/android-app.yaml",
      "success": false,
      "error": "Invalid Figma file ID"
    }
  ]
}
```

### Rate Limiting

Batch processing shares a single rate limit budget across all configs to respect Figma API limits. The rate limiter uses
fair round-robin scheduling to ensure all configs get equal access.

```bash
# Increase rate limit for paid Figma plans
exfig batch ./configs/ --rate-limit 20

# Reduce rate limit if hitting 429 errors
exfig batch ./configs/ --rate-limit 5
```

### Fault Tolerance

ExFig automatically handles transient failures to ensure reliable exports:

**Automatic Retries**

- Server errors (500, 502, 503, 504) and timeouts are retried automatically
- Uses exponential backoff with jitter (2s → 4s → 8s → 16s)
- Rate limit errors (429) respect the `Retry-After` header
- Maximum 4 retry attempts by default (configurable with `--max-retries`)

```bash
# Disable retries for faster failure
exfig batch ./configs/ --fail-fast

# Increase retries for unreliable connections
exfig batch ./configs/ --max-retries 6
```

**Checkpoint System**

Long-running batch exports create checkpoints so you can resume after interruption:

```bash
# Resume interrupted batch export
exfig batch ./configs/ --resume

# Checkpoints are stored in: .exfig-batch-checkpoint.json
# Checkpoints expire after 24 hours
# Successful completion automatically deletes the checkpoint
```

**User-Friendly Error Messages**

ExFig provides clear error messages with recovery suggestions:

```
⚠️ Figma API returned error 429 (Rate Limited)
   Retrying in 30s... (attempt 2/4)

❌ Export failed after 4 retries
   Suggestion: Check https://status.figma.com or try again later
```

### Troubleshooting

**Rate Limit Errors (429)**

If you're seeing frequent rate limit errors:

1. Reduce the rate limit: `--rate-limit 5`
2. Reduce parallelism: `--parallel 2`
3. Check your Figma plan limits at [Figma API Rate Limits](https://developers.figma.com/docs/rest-api/rate-limits/)

**Server Errors (500-504)**

These are typically transient Figma issues:

1. ExFig retries automatically with exponential backoff
2. Check [Figma Status](https://status.figma.com) for outages
3. If persistent, try again later

**Interrupted Exports**

If an export is interrupted (Ctrl+C, crash, etc.):

1. Run with `--resume` to continue from the last checkpoint
2. Checkpoint validates config hashes — if configs changed, export restarts
3. Delete `.exfig-batch-checkpoint.json` to force a fresh start

## Documentation

**Complete documentation is available at
[alexey1312.github.io/ExFig](https://alexey1312.github.io/ExFig/documentation/exfig)**

### Quick Links

- **[Getting Started](https://alexey1312.github.io/ExFig/documentation/exfig/gettingstarted)** - Installation and first
  export
- **[Usage Guide](https://alexey1312.github.io/ExFig/documentation/exfig/usage)** - CLI commands and workflows
- **[iOS Export](https://alexey1312.github.io/ExFig/documentation/exfig/ios)** - Xcode, SwiftUI, and UIKit
- **[Android Export](https://alexey1312.github.io/ExFig/documentation/exfig/android)** - Android Studio and Jetpack
  Compose
- **[Flutter Export](https://alexey1312.github.io/ExFig/documentation/exfig/flutter)** - Flutter and Dart
- **[Design Requirements](https://alexey1312.github.io/ExFig/documentation/exfig/designrequirements)** - How to
  structure Figma files
- **[Configuration Reference](CONFIG.md)** - All available options
- **[Custom Templates](https://alexey1312.github.io/ExFig/documentation/exfig/customtemplates)** - Customize generated
  code
- **[Development Guide](https://alexey1312.github.io/ExFig/documentation/exfig/development)** - Contributing to ExFig

## What Gets Generated

### iOS

```
YourProject/
├── Assets.xcassets/
│   ├── Colors/              # Color sets with Light/Dark variants
│   ├── Icons/               # PDF/SVG vector icons
│   └── Images/              # PNG images with @1x, @2x, @3x
└── Sources/
    ├── UIColor+extension.swift      # Type-safe color access
    ├── Color+extension.swift        # SwiftUI colors
    ├── UIImage+extension.swift      # Image access
    ├── UIFont+extension.swift       # Typography
    └── Labels/                      # Pre-configured UILabel classes
```

### Android

```
app/src/main/
├── res/
│   ├── values/
│   │   ├── colors.xml               # Color definitions
│   │   └── typography.xml           # Text styles
│   ├── values-night/
│   │   └── colors.xml               # Dark mode colors
│   ├── drawable/                    # Vector icons/images
│   └── drawable-xxxhdpi/            # Raster images (multiple DPIs)
└── java/.../ui/exfig/
    ├── Colors.kt                    # Compose colors
    ├── Icons.kt                     # Compose icons
    └── Typography.kt                # Compose text styles
```

### Flutter

```
flutter_project/
├── assets/
│   ├── icons/
│   │   ├── ic_add.svg               # Light icons
│   │   └── ic_add_dark.svg          # Dark icons
│   └── images/
│       ├── logo.png                 # 1x scale
│       ├── 2.0x/logo.png            # 2x scale
│       └── 3.0x/logo.png            # 3x scale
└── lib/
    └── generated/
        ├── colors.dart              # Color constants
        ├── icons.dart               # Icon path constants
        └── images.dart              # Image path constants
```

## Requirements

- **Swift 6.0+** (for building from source)
- **macOS 12.0+**
- **Figma Personal Access Token**

## Contributing

We welcome contributions! See the
[Development Guide](https://alexey1312.github.io/ExFig/documentation/exfig/development) for:

- Setting up your development environment
- Running tests
- Code style guidelines
- Submitting pull requests

## Resources

- **[Figma API](https://www.figma.com/developers/api)** - Figma API documentation
- **[GitHub Issues](https://github.com/alexey1312/ExFig/issues)** - Report bugs or request features

## License

ExFig is available under the MIT License. See [LICENSE](LICENSE) for details.

## Feedback

Have questions or feedback? Open an issue on [GitHub](https://github.com/alexey1312/ExFig/issues) or check out the
[documentation](https://alexey1312.github.io/ExFig/documentation/exfig).

---

**[📖 Read the full documentation](https://alexey1312.github.io/ExFig/documentation/exfig)**

---

<sub>Originally inspired by [figma-export](https://github.com/RedMadRobot/figma-export).</sub>
