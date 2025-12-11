# Configuration

Complete reference for exfig.yaml configuration options.

## Overview

ExFig uses a YAML configuration file (typically `exfig.yaml`) to define export settings. This document covers all
available options.

## Configuration File

By default, ExFig looks for configuration files in this order:

1. `exfig.yaml`
2. `figma-export.yaml`

Specify a custom path with the `-i` flag:

```bash
exfig colors -i path/to/config.yaml
```

## Figma Section

```yaml
figma:
  # Required: Figma file ID for light mode assets
  lightFileId: "ABC123xyz"

  # Optional: Separate file for dark mode assets
  darkFileId: "DEF456abc"

  # Optional: API request timeout in seconds (default: 30)
  timeout: 60
```

## Common Section

Shared settings across all platforms.

### Colors

```yaml
common:
  colors:
    # Frame name containing color styles (default: null, uses all styles)
    figmaFrameName: "Colors"

    # Regex to validate color names
    nameValidateRegexp: "^[a-z][a-zA-Z0-9]*$"

    # Regex replacement for color names
    nameReplaceRegexp: "$1"

    # Use Figma Variables API instead of styles
    useVariables: false

    # Variable collection name (when useVariables: true)
    variableCollectionName: "Colors"

    # Light mode name in variables
    lightModeName: "Light"

    # Dark mode name in variables
    darkModeName: "Dark"
```

### Icons

```yaml
common:
  icons:
    # Default frame name for icon components (can be overridden per-entry)
    figmaFrameName: "Icons"

    # Regex to validate icon names
    nameValidateRegexp: "^ic/.*$"

    # Regex replacement for icon names
    nameReplaceRegexp: "ic_$1"

    # Use single file for light/dark (default: false)
    useSingleFile: false

    # Suffix for dark mode variants (when useSingleFile: true)
    darkModeSuffix: "_dark"
```

### Images

```yaml
common:
  images:
    # Frame name containing image components
    figmaFrameName: "Illustrations"

    # Regex to validate image names
    nameValidateRegexp: "^img_.*$"

    # Regex replacement for image names
    nameReplaceRegexp: "$1"

    # Use single file for light/dark (default: false)
    useSingleFile: false

    # Suffix for dark mode variants (when useSingleFile: true)
    darkModeSuffix: "_dark"
```

### Typography

```yaml
common:
  typography:
    # Frame name containing text styles
    figmaFrameName: "Typography"

    # Regex to validate style names
    nameValidateRegexp: "^[a-z].*$"
```

## Cache Section

Version tracking for incremental exports.

```yaml
common:
  cache:
    # Enable version tracking
    enabled: true

    # Cache file path (default: .exfig-cache.json)
    path: ".exfig-cache.json"
```

## iOS Section

```yaml
ios:
  # Path to Xcode project
  xcodeprojPath: "./MyApp.xcodeproj"

  # Target name for adding generated files
  target: "MyApp"

  # Path to Assets.xcassets
  xcassetsPath: "./Resources/Assets.xcassets"

  # Colors - single object (legacy) or array format
  colors:
    # Use color assets in xcassets
    useColorAssets: true

    # Folder in xcassets for colors
    assetsFolder: "Colors"

    # Naming style: camelCase, snake_case, PascalCase, kebab-case, SCREAMING_SNAKE_CASE
    nameStyle: camelCase

    # Group colors in subfolders by prefix
    groupUsingNamespace: true

    # UIKit extension output path
    colorSwift: "./Sources/Generated/UIColor+Colors.swift"

    # SwiftUI extension output path
    swiftuiColorSwift: "./Sources/Generated/Color+Colors.swift"

  # Colors - array format for multiple color collections
  # colors:
  #   - tokensFileId: "ABC123"
  #     tokensCollectionName: "Base Palette"
  #     lightModeName: "Light"
  #     darkModeName: "Dark"
  #     useColorAssets: true
  #     assetsFolder: "BaseColors"
  #     nameStyle: camelCase
  #     colorSwift: "./Sources/Generated/BaseColors.swift"
  #   - tokensFileId: "DEF456"
  #     tokensCollectionName: "Theme Colors"
  #     lightModeName: "Light"
  #     darkModeName: "Dark"
  #     useColorAssets: true
  #     assetsFolder: "ThemeColors"
  #     nameStyle: camelCase
  #     colorSwift: "./Sources/Generated/ThemeColors.swift"

  # Icons - single object (legacy) or array format
  icons:
    # Folder in xcassets for icons
    assetsFolder: "Icons"

    # Naming style
    nameStyle: camelCase

    # Icon format: pdf or svg
    format: pdf

    # Rendering mode: original or template
    renderingMode: template

    # Preserve vector data
    preservesVectorData: true

    # UIKit extension output path
    imageSwift: "./Sources/Generated/UIImage+Icons.swift"

    # SwiftUI extension output path
    swiftUIImageSwift: "./Sources/Generated/Image+Icons.swift"

  # Icons - array format for multiple icon sets
  # icons:
  #   - figmaFrameName: "Actions"
  #     format: svg
  #     assetsFolder: "Actions"
  #     nameStyle: camelCase
  #     imageSwift: "./Sources/Generated/ActionsIcons.swift"
  #   - figmaFrameName: "Navigation"
  #     format: pdf
  #     assetsFolder: "Navigation"
  #     nameStyle: camelCase
  #     imageSwift: "./Sources/Generated/NavIcons.swift"

  # Images - single object (legacy) or array format
  images:
    # Folder in xcassets for images
    assetsFolder: "Images"

    # Naming style
    nameStyle: camelCase

    # Scales to export (default: [1, 2, 3])
    scales: [1, 2, 3]

    # UIKit extension output path
    imageSwift: "./Sources/Generated/UIImage+Images.swift"

    # SwiftUI extension output path
    swiftUIImageSwift: "./Sources/Generated/Image+Images.swift"

  # Images - array format for multiple image sets
  # images:
  #   - figmaFrameName: "Onboarding"
  #     assetsFolder: "Onboarding"
  #     nameStyle: camelCase
  #     scales: [1, 2, 3]
  #     imageSwift: "./Sources/Generated/OnboardingImages.swift"
  #   - figmaFrameName: "Promo"
  #     assetsFolder: "Promo"
  #     nameStyle: camelCase
  #     scales: [2, 3]
  #     imageSwift: "./Sources/Generated/PromoImages.swift"

  typography:
    # Generate labels with predefined styles
    generateLabels: true

    # Font extension output path
    fontSwift: "./Sources/Generated/UIFont+Typography.swift"

    # SwiftUI font extension output path
    swiftUIFontSwift: "./Sources/Generated/Font+Typography.swift"

    # UIKit label extension output path
    labelStyleSwift: "./Sources/Generated/UILabel+Typography.swift"

    # SwiftUI label extension output path
    swiftUILabelStyleSwift: "./Sources/Generated/LabelStyle+Typography.swift"
```

## Android Section

```yaml
android:
  # Path to main res directory
  mainRes: "./app/src/main/res"

  # Package for R class references
  resourcePackage: "com.example.app"

  # Path to main source directory (for Compose)
  mainSrc: "./app/src/main/java"

  # Colors - single object (legacy) or array format
  colors:
    # Output filename
    xmlOutputFileName: "colors.xml"

    # Jetpack Compose package name
    composePackageName: "com.example.app.ui.theme"

  # Colors - array format for multiple color collections
  # colors:
  #   - tokensFileId: "ABC123"
  #     tokensCollectionName: "Base Palette"
  #     lightModeName: "Light"
  #     xmlOutputFileName: "base_colors.xml"
  #   - tokensFileId: "DEF456"
  #     tokensCollectionName: "Theme Colors"
  #     lightModeName: "Light"
  #     darkModeName: "Dark"
  #     xmlOutputFileName: "theme_colors.xml"
  #     composePackageName: "com.example.theme"

  # Icons - single object (legacy) or array format
  icons:
    # Output directory (relative to mainRes)
    output: "exfig-icons"

    # Naming style
    nameStyle: snake_case

    # Jetpack Compose package name
    composePackageName: "com.example.app.ui.icons"

    # Use native VectorDrawable generator
    useNativeVectorDrawable: false

  # Icons - array format for multiple icon sets
  # icons:
  #   - figmaFrameName: "Actions"
  #     output: "drawable-actions"
  #     composePackageName: "com.example.app.ui.actions"
  #   - figmaFrameName: "Navigation"
  #     output: "drawable-nav"
  #     composePackageName: "com.example.app.ui.nav"
  #     composeFormat: imageVector
  #     composeExtensionTarget: "com.example.NavIcons"

  # Images - single object (legacy) or array format
  images:
    # Output directory (relative to mainRes)
    output: "exfig-images"

    # Image format: svg, png, or webp
    format: webp

    # WebP encoding options
    webpOptions:
      encoding: lossy  # lossy or lossless
      quality: 90      # 0-100 for lossy

    # Density scales (default: [1, 1.5, 2, 3, 4])
    scales: [1, 1.5, 2, 3, 4]

  # Images - array format for multiple image sets
  # images:
  #   - figmaFrameName: "Illustrations"
  #     output: "drawable-illustrations"
  #     format: svg
  #   - figmaFrameName: "Photos"
  #     output: "drawable-photos"
  #     format: webp
  #     scales: [1, 1.5, 2, 3, 4]
  #     webpOptions:
  #       encoding: lossy
  #       quality: 80

  typography:
    # Output filename
    output: "typography.xml"

    # Naming style
    nameStyle: snake_case

    # Jetpack Compose package name
    composePackageName: "com.example.app.ui.typography"
```

## Flutter Section

```yaml
flutter:
  # Output directory for generated Dart files
  output: "lib/generated"

  # Path to custom Stencil templates
  templatesPath: "./templates"

  # Colors - single object (legacy) or array format
  colors:
    # Output filename
    output: "colors.dart"

    # Class name for colors
    className: "AppColors"

  # Colors - array format for multiple color collections
  # colors:
  #   - tokensFileId: "ABC123"
  #     tokensCollectionName: "Base Palette"
  #     lightModeName: "Light"
  #     output: "base_colors.dart"
  #     className: "BaseColors"
  #   - tokensFileId: "DEF456"
  #     tokensCollectionName: "Theme Colors"
  #     lightModeName: "Light"
  #     darkModeName: "Dark"
  #     output: "theme_colors.dart"
  #     className: "ThemeColors"

  # Icons - single object (legacy) or array format
  icons:
    # Output directory for SVG files
    output: "assets/icons"

    # Dart file output
    dartFile: "icons.dart"

    # Class name for icons
    className: "AppIcons"

  # Icons - array format for multiple icon sets
  # icons:
  #   - figmaFrameName: "Actions"
  #     output: "assets/icons/actions"
  #     dartFile: "action_icons.dart"
  #     className: "ActionIcons"
  #   - figmaFrameName: "Navigation"
  #     output: "assets/icons/nav"
  #     dartFile: "nav_icons.dart"
  #     className: "NavIcons"

  # Images - single object (legacy) or array format
  images:
    # Output directory for images
    output: "assets/images"

    # Dart file output
    dartFile: "images.dart"

    # Class name for images
    className: "AppImages"

    # Image format: svg, png, or webp
    format: png

    # Scales to export (default: [1, 2, 3])
    scales: [1, 2, 3]

    # WebP encoding options
    webpOptions:
      encoding: lossy
      quality: 90

  # Images - array format for multiple image sets
  # images:
  #   - figmaFrameName: "Illustrations"
  #     output: "assets/images/illustrations"
  #     dartFile: "illustrations.dart"
  #     className: "Illustrations"
  #   - figmaFrameName: "Promo"
  #     output: "assets/images/promo"
  #     dartFile: "promo_images.dart"
  #     className: "PromoImages"
  #     format: webp
  #     scales: [1, 2, 3]
```

## Example Configurations

### iOS Project

```yaml
figma:
  lightFileId: "ABC123"
  darkFileId: "DEF456"

common:
  colors:
    figmaFrameName: "Colors"
  icons:
    figmaFrameName: "Icons"
  images:
    figmaFrameName: "Illustrations"

ios:
  xcodeprojPath: "./MyApp.xcodeproj"
  target: "MyApp"
  xcassetsPath: "./Resources/Assets.xcassets"

  colors:
    assetsFolder: "Colors"
    colorSwift: "./Sources/UIColor+Colors.swift"
    swiftUIColorSwift: "./Sources/Color+Colors.swift"

  icons:
    assetsFolder: "Icons"
    format: pdf
    imageSwift: "./Sources/UIImage+Icons.swift"
```

### Android Project

```yaml
figma:
  lightFileId: "ABC123"

common:
  icons:
    figmaFrameName: "Icons"

android:
  mainRes: "./app/src/main/res"
  mainSrc: "./app/src/main/java"
  resourcePackage: "com.example.app"

  colors:
    output: "colors.xml"
    composePackageName: "com.example.app.ui"

  icons:
    output: "exfig-icons"
    composePackageName: "com.example.app.ui"
```

### Multi-Platform Project

```yaml
figma:
  lightFileId: "ABC123"
  darkFileId: "DEF456"

common:
  colors:
    figmaFrameName: "Colors"
  icons:
    figmaFrameName: "Icons"
  images:
    figmaFrameName: "Images"

ios:
  xcodeprojPath: "./ios/MyApp.xcodeproj"
  xcassetsPath: "./ios/Resources/Assets.xcassets"
  colors:
    assetsFolder: "Colors"

android:
  mainRes: "./android/app/src/main/res"
  colors:
    output: "colors.xml"

flutter:
  output: "lib/generated"
  colors:
    output: "colors.dart"
```

## See Also

- <doc:Usage>
- <doc:DesignRequirements>
