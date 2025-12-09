# Android Icons Export

Export vector icons from Figma to Android VectorDrawable XML resources.

## Overview

ExFig exports icons as:

- **VectorDrawable XML** files for Android
- **Kotlin composables** for Jetpack Compose (optional)

## Configuration

```yaml
android:
  mainRes: "./app/src/main/res"
  mainSrc: "./app/src/main/java"
  resourcePackage: "com.example.app"

  icons:
    # Output directory (relative to mainRes)
    output: "exfig-icons"

    # Naming style: camelCase, snake_case, PascalCase, kebab-case, SCREAMING_SNAKE_CASE
    nameStyle: snake_case

    # Jetpack Compose package name (optional)
    composePackageName: "com.example.app.ui.icons"

    # Use native VectorDrawable generator (experimental)
    useNativeVectorDrawable: false
```

**Important:** Add to `build.gradle`:

```gradle
android {
    sourceSets {
        main {
            res.srcDirs += "src/main/res/exfig-icons"
        }
    }
}
```

## Export Process

### 1. Design in Figma

Create icon components in a frame named "Icons":

```
Icons frame
├── ic/24/arrow-right     (component)
├── ic/24/arrow-left      (component)
├── ic/16/close           (component)
└── ic/32/menu            (component)
```

**Important:** Icons must be components, not plain frames.

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

**exfig-icons/drawable/ic_24_arrow_right.xml**

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#000000"
        android:pathData="M8,4 L16,12 L8,20"/>
</vector>
```

**exfig-icons/drawable-night/ic_24_arrow_right.xml** (dark mode)

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFF"
        android:pathData="M8,4 L16,12 L8,20"/>
</vector>
```

## Generated Directory Structure

```
exfig-icons/
├── drawable/
│   ├── ic_24_arrow_right.xml
│   ├── ic_24_arrow_left.xml
│   ├── ic_16_close.xml
│   └── ic_32_menu.xml
└── drawable-night/
    ├── ic_24_arrow_right.xml
    ├── ic_24_arrow_left.xml
    ├── ic_16_close.xml
    └── ic_32_menu.xml
```

## Usage in Code

### XML Views

```xml
<ImageView
    android:layout_width="24dp"
    android:layout_height="24dp"
    android:src="@drawable/ic_24_arrow_right"
    android:tint="@color/primary"/>

<ImageButton
    android:layout_width="48dp"
    android:layout_height="48dp"
    android:src="@drawable/ic_24_close"
    android:background="?attr/selectableItemBackgroundBorderless"/>
```

### Kotlin Views

```kotlin
// ImageView
imageView.setImageResource(R.drawable.ic_24_arrow_right)
imageView.imageTintList = ColorStateList.valueOf(
    ContextCompat.getColor(context, R.color.primary)
)

// MenuItem
menuItem.icon = ContextCompat.getDrawable(context, R.drawable.ic_24_menu)
```

### Jetpack Compose

```kotlin
@Composable
fun MyScreen() {
    Icon(
        painter = painterResource(R.drawable.ic_24_arrow_right),
        contentDescription = "Next",
        tint = AppColors.Primary
    )

    IconButton(onClick = { }) {
        Icon(
            painter = painterResource(R.drawable.ic_24_close),
            contentDescription = "Close"
        )
    }
}
```

## VectorDrawable Features

### Supported SVG Features

| Feature      | Support |
| ------------ | ------- |
| Paths        | Full    |
| Groups       | Full    |
| Fill color   | Full    |
| Stroke color | Full    |
| Stroke width | Full    |
| Opacity      | Full    |
| Gradients    | Partial |
| Clip paths   | Partial |
| Masks        | Limited |

### Unsupported Features

- Text elements (convert to paths in Figma)
- Filters and effects
- Complex gradients
- External images

## Dark Mode Icons

### Separate Files

```yaml
figma:
  lightFileId: abc123
  darkFileId: def456
```

Creates:

- `drawable/` - Light mode icons
- `drawable-night/` - Dark mode icons

### Single File Mode

```yaml
common:
  icons:
    useSingleFile: true
    darkModeSuffix: "_dark"
```

Figma naming:

```
ic/24/logo
ic/24/logo_dark
```

## Tips

1. **Keep icons simple**: Complex paths may not convert well
2. **Convert text to paths**: Text in SVG won't render
3. **Use consistent sizes**: Organize by size (16dp, 24dp, etc.)
4. **Test dark mode**: Ensure contrast in both themes
5. **Flatten boolean operations**: Union, subtract before export

## See Also

- <doc:Android>
- <doc:DesignRequirements>
- <doc:Configuration>
