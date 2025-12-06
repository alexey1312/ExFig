# iOS / Xcode Export Guide

ExFig exports design resources from Figma to Xcode projects, supporting both UIKit and SwiftUI.

## Overview

ExFig integrates with your Xcode project to:

- Create color sets, image sets, and icon sets in `Assets.xcassets`
- Generate Swift extensions for easy access in code
- Support Light and Dark Mode automatically
- Support High Contrast color variants
- Enable Dynamic Type for typography
- Work with both Swift Packages and traditional Xcode projects

## Configuration

Basic iOS configuration in `exfig.yaml`:

```yaml
ios:
  # Xcode project settings
  xcodeprojPath: "./Example.xcodeproj"
  target: "YourTarget"
  xcassetsPath: "./Resources/Assets.xcassets"
  xcassetsInMainBundle: true

  # Optional: For Swift Packages
  xcassetsInSwiftPackage: false
  resourceBundleNames: []
```

## Export Types

### Colors

Export color styles from Figma to Xcode color sets and Swift extensions.

- **Assets.xcassets**: Color sets with automatic Light/Dark/High Contrast variants
- **UIKit**: `UIColor` extension for programmatic access
- **SwiftUI**: `Color` extension for SwiftUI views
- **Namespace support**: Group colors using folders with "Provides Namespace" enabled

[→ Learn more about Colors](colors.md)

### Icons

Export vector icons from Figma components to Xcode image sets.

- **Formats**: PDF (recommended) or SVG
- **Render modes**: Template, Original, or Default
- **UIKit**: `UIImage` extension with type-safe access
- **SwiftUI**: `Image` extension for SwiftUI
- **Vector preservation**: Maintain vector data for resolution independence

[→ Learn more about Icons](icons.md)

### Images

Export raster images from Figma to Xcode image sets.

- **Formats**: PNG with @1x, @2x, @3x scales
- **Multi-idiom support**: iPhone, iPad, Mac variants using `~ipad`, `~mac` suffixes
- **UIKit**: `UIImage` extension
- **SwiftUI**: `Image` extension
- **Dark Mode**: Separate images for light and dark appearance

[→ Learn more about Images](images.md)

### Typography

Export text styles from Figma to Swift font extensions and label classes.

- **UIFont extension**: Type-safe font access
- **SwiftUI Font extension**: Font access for SwiftUI
- **LabelStyle**: Reusable text style definitions
- **Label classes**: Pre-configured UILabel subclasses
- **Dynamic Type**: Automatic font scaling support

[→ Learn more about Typography](typography.md)

## Generated Files

ExFig generates the following files for iOS:

```
YourProject/
├── Assets.xcassets/
│   ├── Colors/              # Color sets
│   ├── Icons/               # Icon image sets
│   └── Illustrations/       # Image sets
└── Sources/
    ├── UIColor+extension.swift      # UIKit colors
    ├── Color+extension.swift        # SwiftUI colors
    ├── UIImage+extension.swift      # UIKit images/icons
    ├── Image+extension.swift        # SwiftUI images/icons
    ├── UIFont+extension.swift       # UIKit fonts
    ├── Font+extension.swift         # SwiftUI fonts
    ├── LabelStyle.swift             # Base label style
    ├── LabelStyle+extension.swift   # Label style extensions
    └── Labels/                      # UILabel subclasses
        ├── HeaderLabel.swift
        ├── BodyLabel.swift
        └── ...
```

## UIKit vs SwiftUI

### UIKit Usage

```swift
// Colors
view.backgroundColor = UIColor.backgroundPrimary
label.textColor = UIColor.textSecondary

// Images/Icons
imageView.image = UIImage.icArrowRight
imageView.image = UIImage.illEmptyState

// Typography
label.font = UIFont.body()
let headerLabel = HeaderLabel()
```

### SwiftUI Usage

```swift
// Colors
Text("Hello")
    .foregroundColor(.textPrimary)
    .background(Color.backgroundSecondary)

// Images/Icons
Image.icArrowRight
    .foregroundColor(.iconPrimary)

Image.illEmptyState
    .resizable()

// Typography
Text("Headline")
    .font(.headline())
```

## Swift Packages

If your assets are in a Swift Package:

```yaml
ios:
  xcassetsInSwiftPackage: true
  resourceBundleNames: ["PackageName_TargetName"]
```

This ensures SwiftUI Previews work correctly by specifying the resource bundle name.

## Objective-C Support

To make generated properties accessible from Objective-C:

```yaml
ios:
  addObjcAttribute: true
```

This adds `@objc` attributes to all generated Swift extensions.

## Tips and Best Practices

1. **Use semantic names**: Name colors by purpose (e.g., `backgroundPrimary`) rather than appearance (e.g., `blueColor`)
2. **Preserve vectors for icons**: Add icon names to `preservesVectorRepresentation` for resolution independence
3. **Group related colors**: Use `/` in color names to create folder groups in Assets.xcassets
4. **Test with Dark Mode**: Always verify exports work in both light and dark appearance
5. **Use Dynamic Type**: Enable Dynamic Type support for better accessibility

## Example Projects

See the example iOS projects for working configurations:

- [Example (UIKit)](../../../Examples/Example/) - UIKit-based example
- [ExampleSwiftUI](../../../Examples/ExampleSwiftUI/) - SwiftUI-based example

## See Also

- [Getting Started](../getting-started.md) - Installation and setup
- [Usage Guide](../usage.md) - CLI commands
- [Configuration Reference](../../../CONFIG.md) - All iOS options
- [Design Requirements](../design-requirements.md) - Figma file structure
- [Custom Templates](../custom-templates.md) - Customize generated code

______________________________________________________________________

[← Back: Usage](../usage.md) | [Up: Documentation Index](../index.md) | [Next: Colors →](colors.md)
