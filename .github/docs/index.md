# ExFig Documentation

Welcome to the ExFig documentation. ExFig is a command-line utility that exports colors, typography, icons, and images
from Figma to Xcode and Android Studio projects.

## Table of Contents

### Getting Started

- [Installation & Quick Start](getting-started.md)
- [Basic Usage](usage.md)

### Platform-Specific Guides

#### iOS / Xcode Export

- [iOS Overview](ios/index.md)
- [Exporting Colors](ios/colors.md)
- [Exporting Icons](ios/icons.md)
- [Exporting Images](ios/images.md)
- [Exporting Typography](ios/typography.md)

#### Android / Jetpack Compose Export

- [Android Overview](android/index.md)
- [Exporting Colors](android/colors.md)
- [Exporting Icons](android/icons.md)
- [Exporting Images](android/images.md)
- [Exporting Typography](android/typography.md)

#### Flutter / Dart Export

- [Flutter Overview](flutter/index.md)

### Advanced Topics

- [Design Requirements](design-requirements.md) - How to structure your Figma files
- [Custom Templates](custom-templates.md) - Customize code generation with Stencil templates
- [Development Guide](development.md) - Contributing to ExFig

### Reference

- [Configuration Reference](../../CONFIG.md) - Complete YAML configuration options

## Key Features

- **Light & Dark Mode**: Export separate color palettes and images for light and dark themes
- **High Contrast**: Support for high contrast color variants
- **SwiftUI & UIKit**: Generate code for both SwiftUI and UIKit
- **Jetpack Compose**: Generate Kotlin code for Jetpack Compose
- **Flutter / Dart**: Generate Dart code for Flutter
- **RTL Support**: Right-to-left layout support for both platforms
- **Multiple Formats**: PDF, SVG, PNG, WebP
- **Dynamic Type**: iOS Dynamic Type support for typography
- **Figma Variables**: Support for Figma's new variables feature
- **Version Tracking**: Skip exports when Figma files haven't changed (ideal for CI/CD)
- **Batch Processing**: Process multiple configs in parallel with shared rate limiting
- **JSON Export**: Export as W3C Design Tokens for design system tools
- **Fault Tolerance**: Automatic retries with exponential backoff
- **Checkpoint/Resume**: Continue interrupted exports from last checkpoint

## Quick Links

- [GitHub Repository](https://github.com/alexey1312/ExFig)
- [Issue Tracker](https://github.com/alexey1312/ExFig/issues)

## Need Help?

- Check the [Usage Guide](usage.md) for common commands
- Review [Design Requirements](design-requirements.md) if exports aren't working as expected
- Open an issue on GitHub if you encounter bugs

______________________________________________________________________

[Back to Main README](../../README.md)
