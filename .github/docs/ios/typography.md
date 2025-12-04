# iOS Typography Export

Export text styles from Figma to Swift font extensions and label classes with Dynamic Type support.

## Overview

ExFig exports Figma text styles to your Xcode project as:

- **UIFont extension** - Type-safe font access for UIKit
- **Font extension** - Font access for SwiftUI
- **LabelStyle** - Reusable text style definitions with line height and letter spacing
- **Label classes** - Pre-configured UILabel subclasses
- **Dynamic Type support** - Automatic font scaling for accessibility

## Configuration

```yaml
ios:
  typography:
    # UIKit font extension path
    fontSwift: "./Sources/UIFont+extension.swift"

    # SwiftUI font extension path
    swiftUIFontSwift: "./Sources/Font+extension.swift"

    # LabelStyle extension path
    labelStyleSwift: "./Sources/LabelStyle+extension.swift"

    # Generate UILabel subclasses
    generateLabels: true

    # Directory for generated labels (required if generateLabels: true)
    labelsDirectory: "./Sources/Labels/"

    # Naming style: camelCase, snake_case, PascalCase, kebab-case, or SCREAMING_SNAKE_CASE
    nameStyle: camelCase
```

## Export Process

### 1. Add Custom Fonts to Xcode

Before exporting typography, add your custom fonts to the Xcode project:

1. Drag & drop font files (`.ttf`, `.otf`) into Xcode
2. Ensure "Copy items if needed" is checked
3. Add fonts to target membership
4. Add font file names to `Info.plist`:

```xml
<key>UIAppFonts</key>
<array>
    <string>PTSans-Regular.ttf</string>
    <string>PTSans-Bold.ttf</string>
    <string>Roboto-Regular.ttf</string>
</array>
```

See
[Apple's documentation](https://developer.apple.com/documentation/uikit/text_display_and_fonts/adding_a_custom_font_to_your_app)
for details.

### 2. Design in Figma

Create text styles in Figma:

```
Text Styles
├── Heading/Large
├── Heading/Medium
├── Body/Regular
├── Body/Bold
├── Caption/Small
└── Button/Label
```

Each text style should define:

- Font family
- Font weight
- Font size
- Line height
- Letter spacing (tracking)

### 3. Run Export Command

```bash
# Export all text styles
exfig typography

# Export specific styles
exfig typography "Heading/*"
```

### 4. Generated Output

ExFig generates multiple files:

```
Sources/
├── UIFont+extension.swift       # UIKit fonts
├── Font+extension.swift         # SwiftUI fonts
├── LabelStyle.swift             # Base label style struct
├── LabelStyle+extension.swift   # Style definitions
└── Labels/                      # UILabel subclasses
    ├── HeadingLargeLabel.swift
    ├── HeadingMediumLabel.swift
    ├── BodyRegularLabel.swift
    ├── BodyBoldLabel.swift
    └── CaptionSmallLabel.swift
```

## Generated Code

### UIFont Extension

```swift
import UIKit

extension UIFont {
    static func headingLarge() -> UIFont {
        customFont("PTSans-Bold", size: 32.0)
    }

    static func headingMedium() -> UIFont {
        customFont("PTSans-Bold", size: 24.0)
    }

    static func bodyRegular() -> UIFont {
        customFont("PTSans-Regular", size: 16.0)
    }

    static func bodyBold() -> UIFont {
        customFont("PTSans-Bold", size: 16.0)
    }

    static func captionSmall() -> UIFont {
        customFont("PTSans-Regular", size: 12.0)
    }

    private static func customFont(_ name: String, size: CGFloat) -> UIFont {
        guard let font = UIFont(name: name, size: size) else {
            print("Warning: Font '\(name)' not found")
            return UIFont.systemFont(ofSize: size)
        }
        return font
    }
}
```

### SwiftUI Font Extension

```swift
import SwiftUI

extension Font {
    static func headingLarge() -> Font {
        return Font.custom("PTSans-Bold", size: 32.0)
    }

    static func headingMedium() -> Font {
        return Font.custom("PTSans-Bold", size: 24.0)
    }

    static func bodyRegular() -> Font {
        return Font.custom("PTSans-Regular", size: 16.0)
    }

    static func bodyBold() -> Font {
        return Font.custom("PTSans-Bold", size: 16.0)
    }

    static func captionSmall() -> Font {
        return Font.custom("PTSans-Regular", size: 12.0)
    }
}
```

### LabelStyle Extension

```swift
import UIKit

extension LabelStyle {
    static func headingLarge() -> LabelStyle {
        return LabelStyle(
            font: UIFont.headingLarge(),
            lineHeight: 40.0,
            tracking: 0.0
        )
    }

    static func bodyRegular() -> LabelStyle {
        return LabelStyle(
            font: UIFont.bodyRegular(),
            lineHeight: 24.0,
            tracking: 0.5
        )
    }

    // ... other styles
}
```

### Label Subclasses

```swift
import UIKit

class HeadingLargeLabel: Label {
    override var style: LabelStyle {
        return .headingLarge()
    }
}

class BodyRegularLabel: Label {
    override var style: LabelStyle {
        return .bodyRegular()
    }
}

// Base Label class (in LabelStyle.swift)
class Label: UILabel {
    var style: LabelStyle { fatalError("Override style") }

    override func awakeFromNib() {
        super.awakeFromNib()
        font = style.font
    }

    override var text: String? {
        didSet {
            guard let text = text else {
                attributedText = nil
                return
            }
            attributedText = style.attributedString(from: text, alignment: textAlignment)
        }
    }
}
```

## Usage in Code

### UIKit with Fonts

```swift
// Direct font assignment
label.font = .headingLarge()
label.text = "Welcome"

// Button title
button.titleLabel?.font = .bodyBold()
```

### UIKit with Label Classes

```swift
// In code
let headerLabel = HeadingLargeLabel()
headerLabel.text = "Title"

// In Interface Builder
// Set Custom Class to "HeadingLargeLabel" in Identity Inspector
```

### UIKit with LabelStyle

```swift
// For attributed text with line height and tracking
let style = LabelStyle.bodyRegular()
label.attributedText = style.attributedString(
    from: "Long text with proper line height",
    alignment: .left
)
```

### SwiftUI

```swift
struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Welcome")
                .font(.headingLarge())

            Text("This is a body text")
                .font(.bodyRegular())

            Text("Small caption")
                .font(.captionSmall())

            Button("Press Me") {
                // Action
            }
            .font(.bodyBold())
        }
    }
}
```

## Dynamic Type Support

ExFig supports Dynamic Type for better accessibility:

### Configure in Figma

For Dynamic Type support, text styles should follow iOS's standard text styles:

- Large Title
- Title 1, 2, 3
- Headline
- Body
- Callout
- Subheadline
- Footnote
- Caption 1, 2

### Generated Code with Dynamic Type

```swift
extension UIFont {
    static func body() -> UIFont {
        let font = UIFont(name: "PTSans-Regular", size: 16.0)!
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
    }

    static func headline() -> UIFont {
        let font = UIFont(name: "PTSans-Bold", size: 20.0)!
        return UIFontMetrics(forTextStyle: .headline).scaledFont(for: font)
    }
}
```

Fonts automatically scale based on user's Dynamic Type settings in iOS.

## Text Style Name Validation

Validate and transform text style names:

```yaml
common:
  typography:
    # Validation regex
    nameValidateRegexp: '^[a-zA-Z0-9_]+$'

    # Transform names
    nameReplaceRegexp: 'font_$1'
```

**Example:**

- Figma: `body_regular`
- Validates: ✓
- Transforms to: `font_body_regular`
- Swift: `UIFont.font_body_regular()`

## Tips and Best Practices

1. **Use semantic names**: Name by purpose (e.g., `headingLarge`) not appearance (e.g., `font32Bold`)
2. **Follow iOS conventions**: Use standard text style names for Dynamic Type
3. **Test with accessibility**: Verify fonts scale correctly with larger text sizes
4. **Provide line height**: Always set line height in Figma for consistent spacing
5. **Use LabelStyle for complex text**: Use LabelStyle for proper line height and tracking
6. **Organize by hierarchy**: Group styles by hierarchy (Heading, Body, Caption)
7. **Limit the number**: Don't create too many text styles (8-12 is usually enough)

## Troubleshooting

### Fonts not appearing

- Verify fonts are added to Xcode project
- Check target membership for font files
- Ensure font names in `Info.plist` match actual file names
- Verify font family name matches what's used in code

### Wrong font family

- Check the exact font family name using Font Book.app
- Figma font family names may differ from installed font names
- Use `UIFont.familyNames` to list available fonts

### Dynamic Type not working

- Ensure text styles match iOS standard text styles
- Verify `UIFontMetrics` is used in generated code
- Check that labels respond to `UIContentSizeCategory` changes

### Line height not applying

- Verify you're using `LabelStyle.attributedString()` method
- Check that label's `attributedText` is set, not `text`
- Ensure line height is defined in Figma text style

### Label classes not working in Interface Builder

- Verify class name matches generated class
- Check that files are added to target
- Ensure module is set correctly

## See Also

- [iOS Overview](index.md) - iOS export overview
- [Design Requirements](../design-requirements.md) - Figma typography requirements
- [Configuration Reference](../../../CONFIG.md) - Complete typography options
- [Example Project](../../../Examples/Example/) - Working iOS example

______________________________________________________________________

[← Back: Images](images.md) | [Up: iOS Guide](index.md)
