# Android Export Guide

ExFig exports design resources from Figma to Android Studio projects, supporting both XML-based views and Jetpack
Compose.

## Overview

ExFig integrates with your Android project to:

- Generate XML resource files (`colors.xml`, `typography.xml`)
- Export vector drawables and raster images
- Generate Kotlin code for Jetpack Compose
- Support Light and Dark Mode (day/night)
- Support High Contrast variants

## Configuration

Basic Android configuration in `exfig.yaml`:

```yaml
android:
  # Resource directory path
  mainRes: "./app/src/main/res"

  # Package name for R class (required for Compose code generation)
  resourcePackage: "com.example.app"

  # Source directory path (required for Compose code generation)
  mainSrc: "./app/src/main/java"

  # Icons output directory (relative to mainRes)
  icons:
    output: "exfig-icons"

  # Images output directory (relative to mainRes)
  images:
    output: "exfig-images"
```

## Export Types

### Colors

Export color styles from Figma to Android XML resources and Jetpack Compose code.

- **XML**: `values/colors.xml` with day/night variants
- **Jetpack Compose**: Kotlin extension functions for type-safe color access
- **High Contrast**: Separate resources for high contrast mode

[→ Learn more about Colors](colors.md)

### Icons

Export vector icons from Figma components to Android vector drawables.

- **Vector XML**: Resolution-independent drawable resources
- **Jetpack Compose**: Composable icon functions
- **Dark Mode**: Separate drawables for day and night modes
- **Tinting**: Support for runtime color tinting

[→ Learn more about Icons](icons.md)

### Images

Export raster images from Figma to Android drawable resources.

- **Formats**: PNG or WebP with multiple DPI variants
- **Density support**: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi
- **Vector images**: SVG to VectorDrawable conversion
- **Dark Mode**: Night mode image variants

[→ Learn more about Images](images.md)

### Typography

Export text styles from Figma to Android XML styles and Jetpack Compose.

- **XML styles**: TextAppearance styles for traditional views
- **Jetpack Compose**: TextStyle definitions
- **Font families**: Custom font support
- **Scalable text**: Support for scaled text (sp)

[→ Learn more about Typography](typography.md)

## Generated Files

ExFig generates the following files for Android:

```
app/src/main/
├── res/
│   ├── values/
│   │   ├── colors.xml          # Color definitions
│   │   └── typography.xml      # Text style definitions
│   ├── values-night/
│   │   ├── colors.xml          # Dark mode colors
│   │   └── typography.xml      # Dark mode text styles (if needed)
│   ├── exfig-icons/
│   │   ├── drawable/           # Light mode icons
│   │   └── drawable-night/     # Dark mode icons
│   └── exfig-images/
│       ├── drawable/           # Vector and universal images
│       ├── drawable-night/     # Dark mode images
│       ├── drawable-mdpi/      # @1x density
│       ├── drawable-hdpi/      # @1.5x density
│       ├── drawable-xhdpi/     # @2x density
│       ├── drawable-xxhdpi/    # @3x density
│       └── drawable-xxxhdpi/   # @4x density
└── java/com/example/app/ui/exfig/
    ├── Colors.kt               # Compose color extensions
    ├── Icons.kt                # Compose icon functions
    └── Typography.kt           # Compose text styles
```

## Gradle Configuration

**Important:** Before first use, add generated resource directories to your `build.gradle`:

```gradle
android {
    sourceSets {
        main {
            res.srcDirs += "src/main/res/exfig-icons"
            res.srcDirs += "src/main/res/exfig-images"
        }
    }
}
```

This tells Gradle to include the generated resources in your app.

## XML Views vs Jetpack Compose

### XML Views Usage

```xml
<!-- colors.xml usage -->
<TextView
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:text="Hello"
    android:textColor="@color/text_primary"
    android:background="@color/background_primary" />

<!-- icons usage -->
<ImageView
    android:layout_width="24dp"
    android:layout_height="24dp"
    android:src="@drawable/ic_24_arrow_right"
    android:tint="@color/icon_primary" />

<!-- typography usage -->
<TextView
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:text="Heading"
    android:textAppearance="@style/TextAppearance.Heading.Large" />
```

### Jetpack Compose Usage

```kotlin
import com.example.app.ui.exfig.*

@Composable
fun MyScreen() {
    Column(
        modifier = Modifier
            .background(ExFigColors.backgroundPrimary())
    ) {
        Text(
            text = "Hello",
            style = ExFigTypography.body,
            color = ExFigColors.textPrimary()
        )

        ExFigIcons.Ic24ArrowRight(
            contentDescription = "Navigate",
            tint = ExFigColors.iconPrimary()
        )
    }
}
```

## Jetpack Compose Configuration

To generate Kotlin code for Jetpack Compose, configure package names:

```yaml
android:
  mainSrc: "./app/src/main/java"
  resourcePackage: "com.example.app"

  colors:
    composePackageName: "com.example.app.ui.exfig"

  icons:
    composePackageName: "com.example.app.ui.exfig"

  typography:
    composePackageName: "com.example.app.ui.exfig"
```

Without `mainSrc` and `resourcePackage`, only XML resources will be generated.

## Directory Management

**Warning:** ExFig **clears** icon and image output directories before each export:

- Running `exfig icons` deletes everything in `{mainRes}/{icons.output}/`
- Running `exfig images` deletes everything in `{mainRes}/{images.output}/`

**Never manually add files to these directories.** They will be deleted on the next export.

## Tips and Best Practices

1. **Use semantic names**: Name colors by purpose (e.g., `background_primary`) not appearance (e.g., `blue_color`)
2. **Add to Gradle first**: Configure `sourceSets` before running ExFig
3. **Use Compose for new projects**: Jetpack Compose provides better type safety
4. **Test day/night modes**: Always verify resources in both light and dark themes
5. **Optimize image formats**: Use WebP for better compression
6. **Use vectors when possible**: Vector drawables scale better and are smaller

## Example Projects

See the example Android projects for working configurations:

- [AndroidExample](../../../Examples/AndroidExample/) - XML views example
- [AndroidComposeExample](../../../Examples/AndroidComposeExample/) - Jetpack Compose example

## See Also

- [Getting Started](../getting-started.md) - Installation and setup
- [Usage Guide](../usage.md) - CLI commands
- [Configuration Reference](../../../CONFIG.md) - All Android options
- [Design Requirements](../design-requirements.md) - Figma file structure
- [Custom Templates](../custom-templates.md) - Customize generated code

______________________________________________________________________

[← Back: Usage](../usage.md) | [Up: Documentation Index](../index.md) | [Next: Colors →](colors.md)
