# Android Colors Export

Export color styles from Figma to Android XML resources and Jetpack Compose Kotlin code.

## Overview

ExFig exports colors to:

- **XML resources**: `values/colors.xml` and `values-night/colors.xml`
- **Jetpack Compose**: Kotlin extension functions for type-safe access

## Configuration

```yaml
android:
  mainRes: "./app/src/main/res"
  resourcePackage: "com.example.app"  # Required for Compose
  mainSrc: "./app/src/main/java"      # Required for Compose

  colors:
    # Package for Compose code generation (optional)
    composePackageName: "com.example.app.ui.theme"
```

## Export Process

### 1. Run Export Command

```bash
exfig colors
```

### 2. Generated XML Resources

**values/colors.xml** (light mode):

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="background_primary">#FFFFFF</color>
    <color name="background_secondary">#F5F5F5</color>
    <color name="text_primary">#000000</color>
    <color name="text_secondary">#757575</color>
    <color name="button_primary">#2196F3</color>
</resources>
```

**values-night/colors.xml** (dark mode):

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="background_primary">#121212</color>
    <color name="background_secondary">#1E1E1E</color>
    <color name="text_primary">#FFFFFF</color>
    <color name="text_secondary">#B3B3B3</color>
    <color name="button_primary">#64B5F6</color>
</resources>
```

### 3. Generated Jetpack Compose Code

**Colors.kt**:

```kotlin
package com.example.app.ui.theme

import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.colorResource
import com.example.app.R

object ExFigColors

@Composable
@ReadOnlyComposable
fun ExFigColors.backgroundPrimary(): Color =
    colorResource(id = R.color.background_primary)

@Composable
@ReadOnlyComposable
fun ExFigColors.backgroundSecondary(): Color =
    colorResource(id = R.color.background_secondary)

@Composable
@ReadOnlyComposable
fun ExFigColors.textPrimary(): Color =
    colorResource(id = R.color.text_primary)

@Composable
@ReadOnlyComposable
fun ExFigColors.buttonPrimary(): Color =
    colorResource(id = R.color.button_primary)
```

## Usage

### XML Views

```xml
<TextView
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:text="Hello World"
    android:textColor="@color/text_primary"
    android:background="@color/background_primary" />

<Button
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:backgroundTint="@color/button_primary"
    android:text="Press Me" />
```

### Jetpack Compose

```kotlin
import com.example.app.ui.theme.ExFigColors
import com.example.app.ui.theme.backgroundPrimary
import com.example.app.ui.theme.textPrimary

@Composable
fun MyScreen() {
    Column(
        modifier = Modifier
            .background(ExFigColors.backgroundPrimary())
            .padding(16.dp)
    ) {
        Text(
            text = "Hello World",
            color = ExFigColors.textPrimary()
        )

        Button(
            onClick = { },
            colors = ButtonDefaults.buttonColors(
                containerColor = ExFigColors.buttonPrimary()
            )
        ) {
            Text("Press Me")
        }
    }
}
```

## High Contrast Support

Configure high contrast color files:

```yaml
figma:
  lightFileId: abc123
  darkFileId: def456
  lightHighContrastFileId: ghi789
  darkHighContrastFileId: jkl012
```

Generated structure:

```
res/
├── values/colors.xml                    # Light
├── values-night/colors.xml              # Dark
├── values-highcontrast/colors.xml       # Light high contrast
└── values-night-highcontrast/colors.xml # Dark high contrast
```

## Color Name Validation

```yaml
common:
  colors:
    nameValidateRegexp: '^([a-zA-Z_]+)$'
    nameReplaceRegexp: 'color_$1'
```

## Tips

1. Use semantic names (e.g., `background_primary` not `white`)
2. Test in both light and dark modes
3. Use `@Composable` functions for dynamic theme switching
4. Provide high contrast variants for accessibility

## See Also

- [Android Overview](index.md)
- [Design Requirements](../design-requirements.md)
- [Configuration Reference](../../../CONFIG.md)

______________________________________________________________________

[← Back: Android Overview](index.md) | [Up: Android Guide](index.md) | [Next: Icons →](icons.md)
