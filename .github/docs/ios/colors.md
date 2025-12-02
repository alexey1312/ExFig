# iOS Colors Export

Export color styles from Figma to Xcode color sets and Swift extensions.

## Overview

ExFig exports colors in two modes:

1. **With color assets** (recommended): Creates color sets in `Assets.xcassets` + Swift extensions
2. **Code-only**: Generates Swift extensions with hardcoded color values

Color assets support:

- Automatic Light and Dark Mode
- High Contrast variants
- Device-specific color variants
- Dynamic appearance switching

## Configuration

```yaml
ios:
  colors:
    # Use Assets.xcassets color sets (recommended)
    useColorAssets: true

    # Folder name in Assets.xcassets
    assetsFolder: Colors

    # Naming style: camelCase or snake_case
    nameStyle: camelCase

    # Swift file paths (optional)
    colorSwift: "./Sources/UIColor+extension.swift"
    swiftuiColorSwift: "./Sources/Color+extension.swift"

    # Enable namespace grouping (optional)
    groupUsingNamespace: true
```

## Export Process

### 1. Design in Figma

Create color styles in Figma with descriptive names:

```
Background/Primary
Background/Secondary
Text/Primary
Text/Secondary
Button/Primary
Button/Disabled
```

For Dark Mode support:

- Use separate Figma files for light and dark, OR
- Use single file with dark mode suffix (e.g., `Background/Primary_dark`)

### 2. Run Export Command

```bash
exfig colors
```

### 3. Generated Output

**Assets.xcassets/Colors/**

```
Colors/
├── backgroundPrimary.colorset/
│   └── Contents.json        # Light + Dark variants
├── backgroundSecondary.colorset/
│   └── Contents.json
├── textPrimary.colorset/
│   └── Contents.json
└── buttonPrimary.colorset/
    └── Contents.json
```

Each color set automatically includes:

- **Any Appearance**: Light mode color
- **Dark Appearance**: Dark mode color (if available)
- **High Contrast Light**: High contrast light color (if available)
- **High Contrast Dark**: High contrast dark color (if available)

## Generated Code

### UIKit Extension (useColorAssets: true)

```swift
import UIKit

extension UIColor {
    static var backgroundPrimary: UIColor {
        return UIColor(named: #function)!
    }
    static var backgroundSecondary: UIColor {
        return UIColor(named: #function)!
    }
    static var textPrimary: UIColor {
        return UIColor(named: #function)!
    }
    static var buttonPrimary: UIColor {
        return UIColor(named: #function)!
    }
}
```

### SwiftUI Extension (useColorAssets: true)

```swift
import SwiftUI

extension Color {
    static var backgroundPrimary: Color {
        return Color(#function)
    }
    static var backgroundSecondary: Color {
        return Color(#function)
    }
    static var textPrimary: Color {
        return Color(#function)
    }
    static var buttonPrimary: Color {
        return Color(#function)
    }
}
```

### Code-Only Mode (useColorAssets: false)

When `useColorAssets: false`, colors are hardcoded:

**UIKit:**

```swift
import UIKit

extension UIColor {
    static var backgroundPrimary: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor(red: 0.118, green: 0.118, blue: 0.118, alpha: 1.000)
                } else {
                    return UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
                }
            }
        } else {
            return UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000)
        }
    }
}
```

**SwiftUI:**

```swift
import SwiftUI

public extension ShapeStyle where Self == Color {
    static var backgroundPrimary: Color {
        Color(red: 1.000, green: 1.000, blue: 1.000, opacity: 1.000)
    }
}
```

**Note:** Code-only mode doesn't support automatic Dark Mode switching in SwiftUI.

## Usage in Code

### UIKit

```swift
// Set background color
view.backgroundColor = .backgroundPrimary

// Set text color
label.textColor = .textPrimary

// Set button color
button.setTitleColor(.buttonPrimary, for: .normal)
button.backgroundColor = .backgroundSecondary
```

### SwiftUI

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello, World!")
                .foregroundColor(.textPrimary)

            Button("Press Me") {
                // Action
            }
            .foregroundColor(.buttonPrimary)
        }
        .background(Color.backgroundSecondary)
    }
}
```

## Namespace Grouping

Enable `groupUsingNamespace: true` to organize colors in folders:

**Figma naming:**

```
Background/Primary
Background/Secondary
Button/Primary
Button/Disabled
```

**Assets.xcassets structure:**

```
Colors/
├── Background/              # Folder with "Provides Namespace"
│   ├── Primary.colorset
│   └── Secondary.colorset
└── Button/                  # Folder with "Provides Namespace"
    ├── Primary.colorset
    └── Disabled.colorset
```

**Generated code:**

```swift
extension UIColor {
    enum Background {
        static var primary: UIColor { UIColor(named: "Background/Primary")! }
        static var secondary: UIColor { UIColor(named: "Background/Secondary")! }
    }
    enum Button {
        static var primary: UIColor { UIColor(named: "Button/Primary")! }
        static var disabled: UIColor { UIColor(named: "Button/Disabled")! }
    }
}

// Usage:
view.backgroundColor = .Background.primary
button.setTitleColor(.Button.primary, for: .normal)
```

## High Contrast Support

To support high contrast mode, specify high contrast file IDs in your config:

```yaml
figma:
  lightFileId: abc123
  darkFileId: def456
  lightHighContrastFileId: ghi789
  darkHighContrastFileId: jkl012
```

High contrast colors are automatically added to color sets and used when the system enables high contrast mode.

## Single File Mode

Export light and dark colors from a single Figma file:

```yaml
common:
  colors:
    useSingleFile: true
    darkModeSuffix: '_dark'
    lightHCModeSuffix: '_lightHC'
    darkHCModeSuffix: '_darkHC'

figma:
  lightFileId: abc123  # Contains all color variants
```

**Figma naming:**

```
Background/Primary
Background/Primary_dark
Background/Primary_lightHC
Background/Primary_darkHC
```

ExFig will combine these into a single color set with all variants.

## Color Name Validation

Validate and transform color names:

```yaml
common:
  colors:
    # Only allow alphanumeric and underscore
    nameValidateRegexp: '^([a-zA-Z_]+)$'

    # Add prefix to all colors
    nameReplaceRegexp: 'color_$1'
```

**Example:**

- Figma: `background_primary`
- Validates against: `^([a-zA-Z_]+)$` ✓
- Transforms to: `color_background_primary`
- Swift: `UIColor.color_background_primary`

## Tips and Best Practices

1. **Use semantic names**: Name by purpose (`backgroundPrimary`) not appearance (`whiteColor`)
2. **Use color assets**: Always prefer `useColorAssets: true` for proper Dark Mode support
3. **Test both modes**: Always verify colors in Light and Dark appearance
4. **Organize with folders**: Use `/` in names for better organization
5. **Use High Contrast**: Support accessibility by providing high contrast variants
6. **Consistent naming**: Use a consistent naming convention across your design system

## Troubleshooting

### Colors not appearing in Xcode

- Ensure `xcassetsPath` points to the correct Assets.xcassets folder
- Verify the `assetsFolder` name matches your configuration
- Check that colors are published as styles in Figma

### Dark Mode colors not working

- Verify `darkFileId` is set in your configuration
- Ensure dark colors exist in the dark Figma file
- Check that color names match between light and dark files

### Build errors with generated code

- Ensure Swift file paths are correct
- Verify the target membership for generated files
- Check that the Xcode project is properly configured

## See Also

- [iOS Overview](index.md) - iOS export overview
- [Design Requirements](../design-requirements.md) - Figma color requirements
- [Configuration Reference](../../../CONFIG.md) - Complete configuration options
- [Usage Guide](../usage.md) - Export commands

______________________________________________________________________

[← Back: iOS Overview](index.md) | [Up: iOS Guide](index.md) | [Next: Icons →](icons.md)
