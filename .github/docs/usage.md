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
- [Example Projects](../../Examples/README.md) - Working configurations

______________________________________________________________________

[← Back: Getting Started](getting-started.md) | [Up: Index](index.md) | [Next: iOS Guide →](ios/index.md)
