# iOS Icons Export

Export vector icons from Figma components to Xcode image sets as PDF or SVG files.

## Overview

ExFig exports icons from Figma components as vector files (PDF or SVG) to your Xcode Assets catalog. Icons are exported
with:

- Template Image render mode by default (for tinting)
- Optional vector preservation for resolution independence
- Dark Mode variants
- Type-safe Swift extensions

## Configuration

```yaml
ios:
  icons:
    # Image format: pdf or svg
    format: pdf

    # Folder name in Assets.xcassets
    assetsFolder: Icons

    # Naming style: camelCase or snake_case
    nameStyle: camelCase

    # Asset render mode: template, original, or default
    renderMode: template

    # Icons to preserve vector representation
    preservesVectorRepresentation:
      - ic24TabBarMain
      - ic24TabBarEvents
      - "*"  # Preserve all icons

    # Swift file paths (optional)
    imageSwift: "./Sources/UIImage+extension_icons.swift"
    swiftUIImageSwift: "./Sources/Image+extension_icons.swift"

    # Render mode suffix overrides (optional)
    renderModeDefaultSuffix: '_default'
    renderModeOriginalSuffix: '_original'
    renderModeTemplateSuffix: '_template'
```

## Export Process

### 1. Design in Figma

Create icon components in a frame named "Icons" (or configure with `common.icons.figmaFrameName`):

```
Icons frame
├── ic/24/arrow-right    (component)
├── ic/24/close          (component)
├── ic/24/menu           (component)
├── ic/16/notification   (component)
└── ic/16/check          (component)
```

For Dark Mode icons, either:

- Use a separate dark Figma file, OR
- Add dark suffix to component names (e.g., `ic/24/arrow-right_dark`)

### 2. Run Export Command

```bash
# Export all icons
exfig icons

# Export specific icons
exfig icons "ic/24/arrow-right"

# Export icons matching pattern
exfig icons "ic/24/*"
```

### 3. Generated Output

**Assets.xcassets/Icons/**

```
Icons/
├── ic24ArrowRight.imageset/
│   ├── ic24ArrowRight.pdf      # Light mode
│   ├── ic24ArrowRight_dark.pdf # Dark mode (if available)
│   └── Contents.json
├── ic24Close.imageset/
│   ├── ic24Close.pdf
│   └── Contents.json
└── ic16Notification.imageset/
    ├── ic16Notification.pdf
    └── Contents.json
```

## Generated Code

### UIKit Extension

```swift
import UIKit

extension UIImage {
    static var ic24ArrowRight: UIImage {
        return UIImage(named: #function)!
    }
    static var ic24Close: UIImage {
        return UIImage(named: #function)!
    }
    static var ic24Menu: UIImage {
        return UIImage(named: #function)!
    }
    static var ic16Notification: UIImage {
        return UIImage(named: #function)!
    }
}
```

### SwiftUI Extension

```swift
import SwiftUI

extension Image {
    static var ic24ArrowRight: Image {
        return Image(#function)
    }
    static var ic24Close: Image {
        return Image(#function)
    }
    static var ic24Menu: Image {
        return Image(#function)
    }
    static var ic16Notification: Image {
        return Image(#function)
    }
}
```

## Usage in Code

### UIKit

```swift
// Simple usage
let imageView = UIImageView(image: .ic24ArrowRight)

// With tint color (Template render mode)
let iconView = UIImageView(image: .ic24Close)
iconView.tintColor = .systemBlue

// Button with icon
let button = UIButton()
button.setImage(.ic24Menu, for: .normal)
button.tintColor = .label
```

### SwiftUI

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            // Simple icon
            Image.ic24Close

            // With foreground color
            Image.ic24ArrowRight
                .foregroundColor(.blue)

            // Resizable icon
            Image.ic24Menu
                .resizable()
                .frame(width: 32, height: 32)

            // Button with icon
            Button(action: {}) {
                Image.ic24Close
            }
        }
    }
}
```

## Render Modes

ExFig supports three render modes for icons:

### Template Mode (Default, Recommended)

Icons are rendered as template images, allowing tinting with any color.

```yaml
ios:
  icons:
    renderMode: template
```

**Use case:** Most icons (UI controls, toolbar buttons, navigation)

```swift
// UIKit
imageView.image = .ic24Close
imageView.tintColor = .systemRed

// SwiftUI
Image.ic24Close
    .foregroundColor(.red)
```

### Original Mode

Icons preserve their original colors from Figma.

```yaml
ios:
  icons:
    renderMode: original
```

**Use case:** Icons with specific colors (brand logos, colored illustrations)

### Default Mode

System decides the render mode.

```yaml
ios:
  icons:
    renderMode: default
```

### Mixed Render Modes

Use different render modes for different icons with suffixes:

```yaml
ios:
  icons:
    renderMode: template  # Default for most icons

    # Override for specific icons
    renderModeOriginalSuffix: '_original'
    renderModeDefaultSuffix: '_default'
```

**Figma naming:**

```
ic/24/logo_original      → Render Mode: Original
ic/24/close              → Render Mode: Template (default)
ic/24/special_default    → Render Mode: Default
```

## Vector Preservation

Preserve vector data for resolution-independent scaling:

```yaml
ios:
  icons:
    preservesVectorRepresentation:
      - ic24TabBarMain
      - ic24TabBarEvents
      - ic16Notification
      - "*"  # All icons
```

**Benefits:**

- Icons scale perfectly at any size
- Smaller app size
- Better for accessibility (Dynamic Type)

**When to use:**

- Tab bar icons
- Navigation bar icons
- Icons that may need to scale dynamically

## PDF vs SVG

### PDF (Recommended)

```yaml
ios:
  icons:
    format: pdf
```

**Advantages:**

- Better Xcode integration
- Preserve Vector Data support
- Single-resolution asset

### SVG

```yaml
ios:
  icons:
    format: svg
```

**Advantages:**

- Smaller file size
- Web compatibility
- Industry standard

**Note:** SVG support in Xcode is available since Xcode 12.

## Icon Name Validation

Validate and transform icon names:

```yaml
common:
  icons:
    # Frame name in Figma
    figmaFrameName: Icons

    # Validation regex (must pass)
    nameValidateRegexp: '^(ic)_(\d\d)_([a-z0-9_]+)$'

    # Transform names (supports $1, $2, etc.)
    nameReplaceRegexp: 'icon_$2_$3'
```

**Example:**

- Figma: `ic_24_arrow_right`
- Validates: ✓ (matches pattern)
- Transforms to: `icon_24_arrow_right`
- Swift: `UIImage.icon_24_arrow_right`

## Dark Mode Icons

### Separate Figma Files

```yaml
figma:
  lightFileId: abc123
  darkFileId: def456
```

Figma file structure:

- Light file: `ic/24/arrow-right`
- Dark file: `ic/24/arrow-right`

ExFig merges both into a single image set with light and dark variants.

### Single File Mode

```yaml
common:
  icons:
    useSingleFile: true
    darkModeSuffix: '_dark'

figma:
  lightFileId: abc123
```

Figma naming:

```
ic/24/arrow-right
ic/24/arrow-right_dark
```

## Tips and Best Practices

1. **Use consistent naming**: Follow a naming convention (e.g., `ic_{size}_{name}`)
2. **Use template mode**: Most icons should use template mode for flexibility
3. **Preserve vectors**: Enable for icons that need to scale
4. **Organize by size**: Group icons by size (16px, 24px, 32px)
5. **Test with tinting**: Verify icons work with different tint colors
6. **Provide dark variants**: Create dark mode versions for better contrast
7. **Use semantic names**: Name by purpose (e.g., `ic24Close`) not appearance

## Troubleshooting

### Icons not appearing

- Verify icons are in a component (not just frames)
- Check the `figmaFrameName` matches your Figma file
- Ensure components are in the specified frame

### Icons are pixelated

- Use `preservesVectorRepresentation` to maintain vector data
- Verify icons are exported as vectors, not rasterized

### Dark mode icons not showing

- Verify `darkFileId` is configured
- Check icon names match between light and dark files
- Ensure image set has "Any Appearance" and "Dark" variants

### Tint color not working

- Verify `renderMode: template` is set
- Check that icons don't have fills that override tinting
- Ensure the icon is monochrome in Figma

## See Also

- [iOS Overview](index.md) - iOS export overview
- [Images Export](images.md) - Similar workflow for raster images
- [Design Requirements](../design-requirements.md) - Figma icon requirements
- [Configuration Reference](../../../CONFIG.md) - Complete configuration options

______________________________________________________________________

[← Back: Colors](colors.md) | [Up: iOS Guide](index.md) | [Next: Images →](images.md)
