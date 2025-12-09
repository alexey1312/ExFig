# Custom Templates

Customize generated code using Stencil templates.

## Overview

ExFig uses [Stencil](https://stencil.fuller.li/) templates to generate platform-specific code. You can customize the
output by providing your own templates.

## Setting Up Custom Templates

### 1. Create Templates Directory

```bash
mkdir -p ./templates
```

### 2. Configure Template Path

```yaml
ios:
  templatesPath: "./templates"

android:
  templatesPath: "./templates"

flutter:
  templatesPath: "./templates"
```

### 3. Copy Default Templates

Copy the default templates from ExFig source to use as a starting point. Templates are located in:

- `Sources/XcodeExport/Resources/` - iOS templates
- `Sources/AndroidExport/Resources/` - Android templates
- `Sources/FlutterExport/Resources/` - Flutter templates

## iOS Templates

### Available Templates

| Template                | Output            | Description               |
| ----------------------- | ----------------- | ------------------------- |
| `UIColor.swift.stencil` | UIColor extension | UIKit color definitions   |
| `Color.swift.stencil`   | Color extension   | SwiftUI color definitions |
| `UIImage.swift.stencil` | UIImage extension | UIKit image accessors     |
| `Image.swift.stencil`   | Image extension   | SwiftUI image accessors   |
| `UIFont.swift.stencil`  | UIFont extension  | UIKit font definitions    |
| `Font.swift.stencil`    | Font extension    | SwiftUI font definitions  |
| `UILabel.swift.stencil` | UILabel extension | UIKit label styles        |
| `header.stencil`        | File header       | Common header comment     |

### Context Variables (Colors)

```swift
// Available in color templates
colors: [
    {
        name: "primaryBlue",           // Formatted name
        originalName: "primary/blue",  // Original Figma name
        red: 0.0,                       // RGB components (0-1)
        green: 0.478,
        blue: 1.0,
        alpha: 1.0,
        hex: "#007AFF"                  // Hex string
    }
]
darkColors: [...]  // Same structure for dark mode
```

### Context Variables (Icons)

```swift
// Available in icon templates
icons: [
    {
        name: "icArrowRight",          // Formatted name
        originalName: "ic/24/arrow-right"
    }
]
```

### Context Variables (Typography)

```swift
// Available in typography templates
textStyles: [
    {
        name: "bodyRegular",
        fontFamily: "Inter",
        fontWeight: "regular",         // regular, medium, semibold, bold
        fontWeightValue: 400,          // Numeric weight
        fontSize: 16.0,
        lineHeight: 24.0,              // nil if not set
        letterSpacing: 0.0
    }
]
```

### Example: Custom UIColor Template

```stencil
{% include "header.stencil" %}

import UIKit

public extension UIColor {
    {% for color in colors %}
    /// {{ color.originalName }}
    static let {{ color.name }} = UIColor(
        red: {{ color.red }},
        green: {{ color.green }},
        blue: {{ color.blue }},
        alpha: {{ color.alpha }}
    )
    {% endfor %}
}
```

## Android Templates

### Available Templates

| Template                 | Output         | Description               |
| ------------------------ | -------------- | ------------------------- |
| `colors.xml.stencil`     | colors.xml     | XML color resources       |
| `Colors.kt.stencil`      | Colors.kt      | Compose color definitions |
| `typography.xml.stencil` | typography.xml | XML text styles           |
| `Typography.kt.stencil`  | Typography.kt  | Compose typography        |
| `Icons.kt.stencil`       | Icons.kt       | Compose icon composables  |
| `header.stencil`         | File header    | Common header comment     |

### Context Variables (Colors)

```kotlin
// Available in color templates
colors: [
    {
        name: "primary_blue",          // snake_case name
        hex: "#007AFF",                // With alpha: "#FF007AFF"
        hexARGB: "FF007AFF"            // ARGB without #
    }
]
```

### Context Variables (Typography)

```kotlin
// Available in typography templates
textStyles: [
    {
        name: "body_regular",
        fontFamily: "inter",           // Lowercase
        fontWeightName: "Normal",      // FontWeight constant name
        fontSize: 16,                  // In sp
        lineHeight: 24,                // In sp, nil if not set
        letterSpacing: 0.0             // In em
    }
]
```

### Example: Custom Colors.kt Template

```stencil
{% include "header.stencil" %}

package {{ packageName }}

import androidx.compose.ui.graphics.Color

object AppColors {
    {% for color in colors %}
    val {{ color.name|camelcase }} = Color(0x{{ color.hexARGB }})
    {% endfor %}
}

object AppColorsDark {
    {% for color in darkColors %}
    val {{ color.name|camelcase }} = Color(0x{{ color.hexARGB }})
    {% endfor %}
}
```

## Flutter Templates

### Available Templates

| Template              | Output      | Description           |
| --------------------- | ----------- | --------------------- |
| `colors.dart.stencil` | colors.dart | Dart color constants  |
| `icons.dart.stencil`  | icons.dart  | Dart icon paths       |
| `images.dart.stencil` | images.dart | Dart image paths      |
| `header.stencil`      | File header | Common header comment |

### Context Variables

```dart
// Available in Flutter templates
colors: [
    {
        name: "primaryBlue",
        hex: "0xFF007AFF"              // Dart Color format
    }
]

icons: [
    {
        name: "icArrowRight",
        path: "assets/icons/ic_arrow_right.svg"
    }
]

images: [
    {
        name: "imgHero",
        path: "assets/images/img_hero.png"
    }
]
```

### Example: Custom colors.dart Template

```stencil
{% include "header.stencil" %}

import 'package:flutter/material.dart';

class {{ className }} {
  {{ className }}._();

  {% for color in colors %}
  /// {{ color.originalName }}
  static const Color {{ color.name }} = Color({{ color.hex }});
  {% endfor %}
}

class {{ className }}Dark {
  {{ className }}Dark._();

  {% for color in darkColors %}
  static const Color {{ color.name }} = Color({{ color.hex }});
  {% endfor %}
}
```

## Stencil Syntax Reference

### Variables

```stencil
{{ variableName }}
{{ object.property }}
```

### Loops

```stencil
{% for item in items %}
{{ item.name }}
{% endfor %}
```

### Conditionals

```stencil
{% if condition %}
...
{% elif otherCondition %}
...
{% else %}
...
{% endif %}
```

### Filters

```stencil
{{ name|uppercase }}
{{ name|lowercase }}
{{ name|capitalize }}
{{ name|camelcase }}
```

### Including Templates

```stencil
{% include "header.stencil" %}
```

### Comments

```stencil
{# This is a comment #}
```

## Best Practices

1. **Start from defaults**: Copy default templates as a starting point
2. **Use includes**: Put common code (headers) in shared templates
3. **Validate output**: Test generated code compiles correctly
4. **Document changes**: Add comments explaining customizations
5. **Version control**: Keep templates in your repository

## See Also

- <doc:Configuration>
- <doc:iOS>
- <doc:Android>
- <doc:Flutter>
- [Stencil Documentation](https://stencil.fuller.li/en/latest/)
