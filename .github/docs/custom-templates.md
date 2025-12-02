# Custom Code Generation Templates

ExFig uses [Stencil](https://stencil.fuller.li/en/latest/) and
[StencilSwiftKit](https://github.com/SwiftGen/StencilSwiftKit) for code generation. You can customize the generated code
by providing your own templates.

## Overview

By default, ExFig uses built-in templates for code generation. To customize:

1. Copy default templates to your project
2. Modify them to fit your needs
3. Configure ExFig to use your custom templates
4. Run export commands

## Template Locations

### iOS Default Templates

Located in ExFig source: `./Sources/XcodeExport/Resources/`

```
XcodeExport/Resources/
├── UIColor+extension.swift.stencil
├── Color+extension.swift.stencil
├── UIImage+extension.swift.stencil
├── Image+extension.swift.stencil
├── UIFont+extension.swift.stencil
├── Font+extension.swift.stencil
├── Label.swift.stencil
├── LabelStyle.swift.stencil
└── LabelStyle+extension.swift.stencil
```

### Android Default Templates

Located in ExFig source: `./Sources/AndroidExport/Resources/`

```
AndroidExport/Resources/
├── colors.xml.stencil
├── Colors.kt.stencil
├── Icons.kt.stencil
├── typography.xml.stencil
└── Typography.kt.stencil
```

## Configuration

### iOS

```yaml
ios:
  templatesPath: "./Resources/Templates"
```

ExFig will look for template files in this directory. Only the templates you provide will be overridden; others will use
defaults.

### Android

```yaml
android:
  templatesPath: "./Resources/Templates"
```

## iOS Template Files

### Required Template Names

If you customize iOS templates, use these exact names:

**Colors:**

- `UIColor+extension.swift.stencil` - UIKit color extension
- `Color+extension.swift.stencil` - SwiftUI color extension

**Images/Icons:**

- `UIImage+extension.swift.stencil` - UIKit image extension
- `Image+extension.swift.stencil` - SwiftUI image extension

**Typography:**

- `UIFont+extension.swift.stencil` - UIFont extension
- `Font+extension.swift.stencil` - SwiftUI Font extension
- `Label.swift.stencil` - UILabel subclass template
- `LabelStyle.swift.stencil` - Base LabelStyle struct
- `LabelStyle+extension.swift.stencil` - LabelStyle extensions

### Example: Custom UIColor Template

**UIColor+extension.swift.stencil:**

```swift
// Generated using ExFig — https://github.com/alexey1312/ExFig
// swiftlint:disable all

import UIKit

public extension UIColor {
{% for color in colors %}
    /// {{ color.name }} color
    /// Light: {{ color.light.hex }}{% if color.dark %}, Dark: {{ color.dark.hex }}{% endif %}
    static var {{ color.name }}: UIColor {
        {% if color.dark %}
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return UIColor(red: {{ color.dark.red }}, green: {{ color.dark.green }}, blue: {{ color.dark.blue }}, alpha: {{ color.dark.alpha }})
                } else {
                    return UIColor(red: {{ color.light.red }}, green: {{ color.light.green }}, blue: {{ color.light.blue }}, alpha: {{ color.light.alpha }})
                }
            }
        }
        {% endif %}
        return UIColor(red: {{ color.light.red }}, green: {{ color.light.green }}, blue: {{ color.light.blue }}, alpha: {{ color.light.alpha }})
    }
{% endfor %}
}
```

### Available Template Variables

#### Colors

```swift
colors: [Color]

Color:
  - name: String              // Color name (e.g., "backgroundPrimary")
  - platform: String          // "ios", "android", or "universal"
  - light: ColorValue         // Light mode color
  - dark: ColorValue?         // Dark mode color (optional)
  - lightHC: ColorValue?      // Light high contrast (optional)
  - darkHC: ColorValue?       // Dark high contrast (optional)

ColorValue:
  - red: Float                // 0.0 - 1.0
  - green: Float              // 0.0 - 1.0
  - blue: Float               // 0.0 - 1.0
  - alpha: Float              // 0.0 - 1.0
  - hex: String               // "#RRGGBB"
```

#### Images/Icons

```swift
images: [Image]

Image:
  - name: String              // Image name (e.g., "icArrowRight")
  - platform: String          // "ios", "android", or "universal"
```

#### Typography

```swift
textStyles: [TextStyle]

TextStyle:
  - name: String              // Style name (e.g., "headingLarge")
  - fontName: String          // Font name (e.g., "PTSans-Bold")
  - fontSize: Float           // Font size in points
  - lineHeight: Float?        // Line height (optional)
  - letterSpacing: Float?     // Letter spacing (optional)
  - fontWeight: String?       // "regular", "bold", etc.
```

## Android Template Files

### Required Template Names

**Colors:**

- `colors.xml.stencil` - XML color resources
- `Colors.kt.stencil` - Jetpack Compose color code

**Icons:**

- `Icons.kt.stencil` - Jetpack Compose icon code

**Typography:**

- `typography.xml.stencil` - XML text appearance styles
- `Typography.kt.stencil` - Jetpack Compose text styles

### Example: Custom Colors.kt Template

**Colors.kt.stencil:**

```kotlin
// Generated using ExFig — https://github.com/alexey1312/ExFig
// Do not edit directly

package {{ packageName }}

import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.colorResource
import {{ resourcePackage }}.R

/**
 * Application color palette
 * Auto-generated from Figma
 */
object AppColors

{% for color in colors %}
/**
 * {{ color.name }}
 * Light: {{ color.light.hex }}{% if color.dark %}, Dark: {{ color.dark.hex }}{% endif %}
 */
@Composable
@ReadOnlyComposable
fun AppColors.{{ color.name }}(): Color = colorResource(id = R.color.{{ color.name|snakecase }})

{% endfor %}
```

### Available Template Variables

#### Colors

```kotlin
packageName: String           // Compose package name
resourcePackage: String       // R class package name
colors: [Color]

Color:
  - name: String              // Color name (camelCase)
  - light: ColorValue         // Light mode color
  - dark: ColorValue?         // Dark mode color (optional)
```

#### Icons

```kotlin
packageName: String
resourcePackage: String
icons: [Icon]

Icon:
  - name: String              // Icon name (PascalCase for Compose)
  - resourceName: String      // Resource name (snake_case)
```

#### Typography

```kotlin
packageName: String
resourcePackage: String
textStyles: [TextStyle]

TextStyle:
  - name: String
  - fontFamily: String
  - fontSize: Float
  - letterSpacing: Float?
  - lineHeight: Float?
```

## Stencil Filters

ExFig includes additional filters from StencilSwiftKit:

### Case Conversion

```stencil
{{ "hello_world"|camelCase }}       → helloWorld
{{ "hello_world"|snakeCase }}       → hello_world
{{ "helloWorld"|kebabCase }}        → hello-world
{{ "hello-world"|swiftIdentifier }} → helloWorld
```

### Other Filters

```stencil
{{ value|uppercase }}
{{ value|lowercase }}
{{ value|capitalize }}
```

## Best Practices

1. **Start with defaults**: Copy default templates and modify incrementally
2. **Test thoroughly**: Verify generated code compiles and works correctly
3. **Version control**: Commit custom templates to your repository
4. **Document changes**: Comment your modifications in templates
5. **Keep updated**: Check for template updates when upgrading ExFig
6. **Use semantic names**: Name template variables clearly
7. **Handle optionals**: Always check for nil values in templates

## Example Workflow

### 1. Copy Default Templates

```bash
# For iOS
mkdir -p Resources/Templates
cp .build/checkouts/ExFig/Sources/XcodeExport/Resources/*.stencil Resources/Templates/

# For Android
mkdir -p Resources/Templates
cp .build/checkouts/ExFig/Sources/AndroidExport/Resources/*.stencil Resources/Templates/
```

### 2. Modify Templates

Edit `Resources/Templates/UIColor+extension.swift.stencil`:

```swift
// Add your custom header
// swiftlint:disable all
// swiftformat:disable all

import UIKit

// Custom color palette class
public enum ColorPalette {
{% for color in colors %}
    static var {{ color.name }}: UIColor { ... }
{% endfor %}
}
```

### 3. Configure ExFig

```yaml
ios:
  templatesPath: "./Resources/Templates"
```

### 4. Run Export

```bash
exfig colors
```

### 5. Verify Output

Check generated files and ensure they compile correctly.

## Troubleshooting

### Template not found

- Verify `templatesPath` is correct
- Ensure template file names match exactly
- Check file exists at the specified path

### Syntax errors

- Validate Stencil syntax
- Check for unclosed tags (`{% %}`, `{{ }}`)
- Ensure proper indentation

### Missing variables

- Refer to default templates for available variables
- Check ExFig version for variable compatibility
- Use `{% if variable %}` guards for optional values

## See Also

- [Stencil Documentation](https://stencil.fuller.li/en/latest/)
- [StencilSwiftKit](https://github.com/SwiftGen/StencilSwiftKit)
- [iOS Export Guide](ios/index.md)
- [Android Export Guide](android/index.md)
- [Configuration Reference](../../CONFIG.md)

______________________________________________________________________

[← Back: Documentation Index](index.md)
