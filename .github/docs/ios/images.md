# iOS Images Export

Export raster images from Figma to Xcode image sets as PNG files with multiple scales.

## Overview

ExFig exports images from Figma components as PNG files to your Xcode Assets catalog. Images support:

- Multiple scales (@1x, @2x, @3x)
- Multi-idiom support (iPhone, iPad, Mac)
- Dark Mode variants
- Type-safe Swift extensions

## Configuration

```yaml
ios:
  images:
    # Folder name in Assets.xcassets
    assetsFolder: Illustrations

    # Naming style: camelCase or snake_case
    nameStyle: camelCase

    # Image scales to export (optional, defaults to [1, 2, 3])
    scales: [1, 2, 3]

    # Swift file paths (optional)
    imageSwift: "./Sources/UIImage+extension_images.swift"
    swiftUIImageSwift: "./Sources/Image+extension_images.swift"
```

## Export Process

### 1. Design in Figma

Create image components in a frame named "Illustrations" (or configure with `common.images.figmaFrameName`):

```
Illustrations frame
├── img-empty-state       (component)
├── img-onboarding-1      (component)
├── img-onboarding-2      (component)
├── img-logo~ipad         (component, iPad-specific)
└── img-background~mac    (component, Mac-specific)
```

**Important:** Images must be components, not plain frames.

### 2. Run Export Command

```bash
# Export all images
exfig images

# Export specific images
exfig images "img-empty-state"

# Export images matching pattern
exfig images "img-onboarding-*"
```

### 3. Generated Output

**Assets.xcassets/Illustrations/**

```
Illustrations/
├── imgEmptyState.imageset/
│   ├── imgEmptyState.png       # @1x
│   ├── imgEmptyState@2x.png    # @2x
│   ├── imgEmptyState@3x.png    # @3x
│   ├── imgEmptyState_dark.png  # @1x dark (if available)
│   ├── imgEmptyState_dark@2x.png
│   ├── imgEmptyState_dark@3x.png
│   └── Contents.json
├── imgLogo.imageset/
│   ├── imgLogo~iphone.png
│   ├── imgLogo~iphone@2x.png
│   ├── imgLogo~iphone@3x.png
│   ├── imgLogo~ipad.png        # iPad variant
│   ├── imgLogo~ipad@2x.png
│   └── Contents.json
└── imgOnboarding1.imageset/
    └── ...
```

## Generated Code

### UIKit Extension

```swift
import UIKit

extension UIImage {
    static var imgEmptyState: UIImage {
        return UIImage(named: #function)!
    }
    static var imgOnboarding1: UIImage {
        return UIImage(named: #function)!
    }
    static var imgLogo: UIImage {
        return UIImage(named: #function)!
    }
}
```

### SwiftUI Extension

```swift
import SwiftUI

extension Image {
    static var imgEmptyState: Image {
        return Image(#function)
    }
    static var imgOnboarding1: Image {
        return Image(#function)
    }
    static var imgLogo: Image {
        return Image(#function)
    }
}
```

## Usage in Code

### UIKit

```swift
// Simple usage
let imageView = UIImageView(image: .imgEmptyState)

// With content mode
let logoView = UIImageView(image: .imgLogo)
logoView.contentMode = .scaleAspectFit

// Set image on button
let button = UIButton()
button.setImage(.imgOnboarding1, for: .normal)
```

### SwiftUI

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            // Simple image
            Image.imgEmptyState

            // Resizable image
            Image.imgLogo
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 100)

            // Background image
            ZStack {
                Image.imgBackground
                    .resizable()
                    .ignoresSafeArea()

                Text("Content")
            }
        }
    }
}
```

## Image Scales

Configure which scales to export:

```yaml
ios:
  images:
    scales: [1, 2, 3]  # @1x, @2x, @3x
```

**Scale options:**

- `1` - @1x (base resolution)
- `2` - @2x (Retina)
- `3` - @3x (Retina HD)

**Recommendations:**

- **All apps**: Include `[2, 3]` at minimum
- **Supporting non-Retina**: Include `[1, 2, 3]`
- **App size optimization**: Use `[2, 3]` only (skip @1x)

## Multi-Idiom Support

Export device-specific image variants using suffixes:

### iPad-Specific Images

Append `~ipad` to the component name in Figma:

```
Figma: img-logo~ipad
Swift: UIImage.imgLogo
```

The image set will contain:

- Universal/iPhone images (if available)
- iPad-specific images

```json
{
  "images": [
    { "idiom": "universal", "filename": "imgLogo~iphone.png", "scale": "1x" },
    { "idiom": "universal", "filename": "imgLogo~iphone@2x.png", "scale": "2x" },
    { "idiom": "ipad", "filename": "imgLogo~ipad.png", "scale": "1x" },
    { "idiom": "ipad", "filename": "imgLogo~ipad@2x.png", "scale": "2x" }
  ]
}
```

### Mac-Specific Images

Append `~mac` to the component name:

```
Figma: img-sidebar~mac
Swift: UIImage.imgSidebar
```

### iPhone-Specific Images

Append `~iphone` to explicitly mark iPhone images:

```
Figma: img-splash~iphone
Swift: UIImage.imgSplash
```

### Combining Idioms

Create separate components for each idiom:

```
Illustrations frame
├── img-hero~iphone
├── img-hero~ipad
└── img-hero~mac
```

ExFig will combine these into a single image set with all idiom variants.

## Dark Mode Images

### Separate Figma Files

```yaml
figma:
  lightFileId: abc123
  darkFileId: def456
```

Create matching components in both files:

- Light file: `img-empty-state`
- Dark file: `img-empty-state`

ExFig merges both into a single image set with light and dark appearance variants.

### Single File Mode

```yaml
common:
  images:
    useSingleFile: true
    darkModeSuffix: '_dark'

figma:
  lightFileId: abc123
```

**Figma naming:**

```
img-empty-state
img-empty-state_dark
```

## Image Name Validation

Validate and transform image names:

```yaml
common:
  images:
    # Frame name in Figma
    figmaFrameName: Illustrations

    # Validation regex
    nameValidateRegexp: '^(img)_([a-z0-9_]+)$'

    # Transform names
    nameReplaceRegexp: 'image_$2'
```

**Example:**

- Figma: `img_empty_state`
- Validates: ✓
- Transforms to: `image_empty_state`
- Swift: `UIImage.image_empty_state`

## Tips and Best Practices

1. **Use consistent naming**: Follow a prefix pattern (e.g., `img-` or `ill-`)
2. **Optimize file sizes**: Use appropriate compression in Figma
3. **Provide dark variants**: Create dark mode versions for better UX
4. **Use idiom suffixes**: Leverage `~ipad`, `~mac` for device-specific designs
5. **Avoid huge images**: Large images increase app size and memory usage
6. **Consider vectors**: For simple graphics, use [Icons](icons.md) (PDF/SVG) instead
7. **Name by purpose**: Use semantic names (e.g., `imgEmptyState` not `imgPicture1`)
8. **Post-export optimization**: Use [image_optim](https://github.com/toy/image_optim) to further compress exported PNGs:
   ```bash
   gem install image_optim image_optim_pack
   image_optim ./Resources/Assets.xcassets/**/*.png
   ```

## When to Use Images vs Icons

### Use Images for:

- Photographs
- Complex illustrations with gradients
- Raster artwork
- Device-specific designs

### Use Icons for:

- UI elements (buttons, toolbar items)
- Simple vector graphics
- Monochrome symbols
- Scalable graphics

See [Icons Export](icons.md) for vector icon export.

## Troubleshooting

### Images not appearing

- Verify images are components, not plain frames
- Check the `figmaFrameName` matches your Figma file
- Ensure components are in the specified frame

### Low-quality images

- Check source image resolution in Figma
- Verify scales are configured correctly
- Ensure Figma export settings are appropriate

### Dark mode images not showing

- Verify `darkFileId` is configured or dark suffix is used
- Check image names match between light and dark variants
- Ensure image set has "Any Appearance" and "Dark" variants

### Wrong idiom selected

- Verify suffix matches exactly (`~ipad`, `~iphone`, `~mac`)
- Check Contents.json in the image set
- Ensure component names don't have typos

### App size too large

- Reduce `scales` to only necessary ones (typically `[2, 3]`)
- Optimize images in Figma before export
- Consider using vector formats for suitable graphics

## See Also

- [iOS Overview](index.md) - iOS export overview
- [Icons Export](icons.md) - Vector icon export
- [Design Requirements](../design-requirements.md) - Figma image requirements
- [Configuration Reference](../../../CONFIG.md) - Complete configuration options

______________________________________________________________________

[← Back: Icons](icons.md) | [Up: iOS Guide](index.md) | [Next: Typography →](typography.md)
