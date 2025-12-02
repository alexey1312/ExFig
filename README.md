# ExFig

<img src="images/logo.png"/><br/>

[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Falexey1312%2FExFig%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/alexey1312/ExFig)
[![Swift-versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Falexey1312%2FExFig%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/alexey1312/ExFig)
[![CI](https://github.com/alexey1312/ExFig/actions/workflows/ci.yml/badge.svg)](https://github.com/alexey1312/ExFig/actions/workflows/ci.yml)
[![Release](https://github.com/alexey1312/ExFig/actions/workflows/release.yml/badge.svg)](https://github.com/alexey1312/ExFig/actions/workflows/release.yml)
[![License](https://img.shields.io/github/license/alexey1312/ExFig.svg)](LICENSE)

Command-line utility to export colors, typography, icons, and images from Figma to Xcode, Android Studio, and Flutter
projects.

Automatically sync your design system from Figma to code with support for Dark Mode, SwiftUI, UIKit, Jetpack Compose,
and Flutter.

## Why ExFig?

- **Eliminate manual export**: Figma doesn't natively export colors and images to Xcode/Android Studio
- **Keep design and code in sync**: Automate updates to your component library
- **Save time**: No more manual color palette management or icon exports

## Features

- ✨ Export light & dark color palettes
- 🎨 High contrast color support (iOS)
- 🖼️ Icons and images with Dark Mode variants
- 📝 Typography with Dynamic Type support (iOS)
- 📱 SwiftUI and UIKit support
- 🤖 Jetpack Compose support
- 🦋 Flutter / Dart support
- 🔄 RTL (Right-to-Left) layout support
- 🎯 Figma Variables support
- 📊 Rich progress indicators with ETA
- 🔇 Verbose and quiet output modes

> **Note:** Exporting icons and images requires a Figma Professional/Organization plan (uses Shareable Team Libraries).

## Quick Start

### 1. Install ExFig

```bash
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

## Documentation

**Complete documentation is available at [.github/docs/](.github/docs/index.md)**

### Quick Links

- **[Getting Started](.github/docs/getting-started.md)** - Installation and first export
- **[Usage Guide](.github/docs/usage.md)** - CLI commands and workflows
- **[iOS Export](.github/docs/ios/index.md)** - Xcode, SwiftUI, and UIKit
- **[Android Export](.github/docs/android/index.md)** - Android Studio and Jetpack Compose
- **[Flutter Export](.github/docs/flutter/index.md)** - Flutter and Dart
- **[Design Requirements](.github/docs/design-requirements.md)** - How to structure Figma files
- **[Configuration Reference](CONFIG.md)** - All available options
- **[Custom Templates](.github/docs/custom-templates.md)** - Customize generated code
- **[Development Guide](.github/docs/development.md)** - Contributing to ExFig

## Example Projects

Working example projects are available in the [Examples](./Examples) directory:

- **[Example](./Examples/Example/)** - iOS UIKit project
- **[ExampleSwiftUI](./Examples/ExampleSwiftUI/)** - iOS SwiftUI project
- **[AndroidExample](./Examples/AndroidExample/)** - Android XML views
- **[AndroidComposeExample](./Examples/AndroidComposeExample/)** - Android Jetpack Compose

Each example includes a configured `exfig.yaml` file and demonstrates best practices.

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

We welcome contributions! See the [Development Guide](.github/docs/development.md) for:

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
[documentation](.github/docs/index.md).

______________________________________________________________________

**[📖 Read the full documentation](.github/docs/index.md)**

______________________________________________________________________

<sub>Originally inspired by [figma-export](https://github.com/RedMadRobot/figma-export).</sub>
