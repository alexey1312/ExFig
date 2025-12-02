# Android Typography Export

Export text styles from Figma to Android XML TextAppearance styles and Jetpack Compose TextStyle definitions.

## Overview

ExFig exports typography to:

- **XML styles**: TextAppearance styles for traditional Android views
- **Jetpack Compose**: TextStyle definitions in Kotlin

## Configuration

```yaml
android:
  mainRes: "./app/src/main/res"
  resourcePackage: "com.example.app"
  mainSrc: "./app/src/main/java"

  typography:
    # Naming style: camelCase or snake_case
    nameStyle: camelCase

    # Package for Compose code (optional)
    composePackageName: "com.example.app.ui.typography"
```

## Export Process

### 1. Add Custom Fonts (Optional)

If using custom fonts, add them to your project:

```
res/
  font/
    ptsans_regular.ttf
    ptsans_bold.ttf
    roboto_medium.ttf
```

### 2. Run Export

```bash
exfig typography
```

### 3. Generated XML Styles

**values/typography.xml**:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="TextAppearance.Heading.Large">
        <item name="android:fontFamily">@font/ptsans_bold</item>
        <item name="android:textSize">32sp</item>
        <item name="android:letterSpacing">0.0</item>
        <item name="android:lineHeight">40sp</item>
    </style>

    <style name="TextAppearance.Body.Regular">
        <item name="android:fontFamily">@font/ptsans_regular</item>
        <item name="android:textSize">16sp</item>
        <item name="android:letterSpacing">0.03</item>
        <item name="android:lineHeight">24sp</item>
    </style>

    <style name="TextAppearance.Caption.Small">
        <item name="android:fontFamily">@font/ptsans_regular</item>
        <item name="android:textSize">12sp</item>
        <item name="android:letterSpacing">0.04</item>
        <item name="android:lineHeight">16sp</item>
    </style>
</resources>
```

### 4. Generated Compose Code

**Typography.kt**:

```kotlin
package com.example.app.ui.typography

import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.example.app.R

object ExFigTypography {
    val headingLarge = TextStyle(
        fontFamily = FontFamily(Font(R.font.ptsans_bold)),
        fontSize = 32.0.sp,
        letterSpacing = 0.0.sp,
        lineHeight = 40.0.sp,
    )

    val bodyRegular = TextStyle(
        fontFamily = FontFamily(Font(R.font.ptsans_regular)),
        fontSize = 16.0.sp,
        letterSpacing = 0.48.sp,  // 0.03em * 16sp
        lineHeight = 24.0.sp,
    )

    val captionSmall = TextStyle(
        fontFamily = FontFamily(Font(R.font.ptsans_regular)),
        fontSize = 12.0.sp,
        letterSpacing = 0.48.sp,  // 0.04em * 12sp
        lineHeight = 16.0.sp,
    )
}
```

## Usage

### XML Views

```xml
<TextView
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:text="Large Heading"
    android:textAppearance="@style/TextAppearance.Heading.Large" />

<TextView
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:text="Body text"
    android:textAppearance="@style/TextAppearance.Body.Regular" />

<TextView
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:text="Small caption"
    android:textAppearance="@style/TextAppearance.Caption.Small" />
```

### Jetpack Compose

```kotlin
import com.example.app.ui.typography.ExFigTypography

@Composable
fun MyScreen() {
    Column(spacing = 16.dp) {
        Text(
            text = "Large Heading",
            style = ExFigTypography.headingLarge
        )

        Text(
            text = "Body text with proper line height and letter spacing",
            style = ExFigTypography.bodyRegular
        )

        Text(
            text = "Small caption",
            style = ExFigTypography.captionSmall
        )
    }
}
```

### Material Theme Integration

Integrate with Material Theme:

```kotlin
import androidx.compose.material3.Typography

val AppTypography = Typography(
    displayLarge = ExFigTypography.headingLarge,
    bodyLarge = ExFigTypography.bodyRegular,
    labelSmall = ExFigTypography.captionSmall,
    // ... other styles
)

@Composable
fun MyApp() {
    MaterialTheme(
        typography = AppTypography
    ) {
        // App content
    }
}
```

## Text Style Properties

ExFig exports the following properties:

| Property | XML | Compose | Description | |----------|-----|---------|-------------| | Font family |
`android:fontFamily` | `fontFamily` | Custom or system font | | Font size | `android:textSize` | `fontSize` | Text size
in sp | | Font weight | `android:textStyle` | `fontWeight` | Bold, normal, etc. | | Letter spacing |
`android:letterSpacing` | `letterSpacing` | Tracking (em or sp) | | Line height | `android:lineHeight` | `lineHeight` |
Line spacing in sp |

## Custom Fonts

### Add Font Resources

1. Place font files in `res/font/`:

```
res/
  font/
    custom_font_regular.ttf
    custom_font_bold.ttf
    custom_font_italic.ttf
```

2. ExFig will automatically reference them:

```xml
<item name="android:fontFamily">@font/custom_font_bold</item>
```

### Font Family XML (Optional)

Create font family XML for variants:

**res/font/custom_font.xml**:

```xml
<?xml version="1.0" encoding="utf-8"?>
<font-family xmlns:android="http://schemas.android.com/apk/res/android">
    <font
        android:fontStyle="normal"
        android:fontWeight="400"
        android:font="@font/custom_font_regular" />
    <font
        android:fontStyle="normal"
        android:fontWeight="700"
        android:font="@font/custom_font_bold" />
    <font
        android:fontStyle="italic"
        android:fontWeight="400"
        android:font="@font/custom_font_italic" />
</font-family>
```

## Text Style Name Validation

```yaml
common:
  typography:
    nameValidateRegexp: '^[a-zA-Z0-9_]+$'
    nameReplaceRegexp: 'text_$1'
```

**Example:**

- Figma: `heading_large`
- Validates: ✓
- Transforms to: `text_heading_large`
- XML: `TextAppearance.Text.Heading.Large`
- Compose: `ExFigTypography.textHeadingLarge`

## Tips

1. Use semantic names (e.g., `body_regular` not `font_16_normal`)
2. Define line height and letter spacing in Figma for consistency
3. Use scaled pixels (sp) for text sizes (accessibility)
4. Integrate with Material Theme for Compose apps
5. Provide font weight variants in Figma
6. Test with different system font sizes
7. Limit number of text styles (8-12 is usually enough)

## Troubleshooting

### Fonts not appearing

- Verify font files are in `res/font/`
- Check font file names match references
- Ensure fonts are added to the correct module

### Wrong font weight

- Check font file contains correct weight
- Verify Figma text style uses correct font weight
- Use font family XML for multiple weights

### Line height not applying

- Verify `lineHeight` is supported (API 28+)
- Check Figma text style has line height defined
- For older APIs, use `lineSpacingMultiplier`

### Letter spacing incorrect

- Figma uses em units, Android uses em
- Verify letter spacing is defined in Figma
- Check conversion in generated code

## See Also

- [Android Overview](index.md)
- [Design Requirements](../design-requirements.md)
- [Configuration Reference](../../../CONFIG.md)

______________________________________________________________________

[← Back: Images](images.md) | [Up: Android Guide](index.md)
