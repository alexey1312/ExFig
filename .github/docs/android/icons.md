# Android Icons Export

Export vector icons from Figma components to Android vector drawable XML files and Jetpack Compose code.

## Overview

ExFig exports icons as:

- **Vector XML**: Resolution-independent drawable resources
- **Jetpack Compose**: Composable icon functions with tinting support

## Configuration

```yaml
android:
  mainRes: "./app/src/main/res"
  resourcePackage: "com.example.app"
  mainSrc: "./app/src/main/java"

  icons:
    # Output directory (relative to mainRes)
    output: "exfig-icons"

    # Package for Compose code (optional)
    composePackageName: "com.example.app.ui.icons"
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

### 1. Run Export

```bash
exfig icons
```

### 2. Generated Vector Drawables

**drawable/ic_24_arrow_right.xml**:

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FF000000"
        android:pathData="M8.59,16.59L13.17,12L8.59,7.41L10,6l6,6-6,6z"/>
</vector>
```

**drawable-night/ic_24_arrow_right.xml** (if dark variant exists):

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M8.59,16.59L13.17,12L8.59,7.41L10,6l6,6-6,6z"/>
</vector>
```

### 3. Generated Compose Code

**Icons.kt**:

```kotlin
package com.example.app.ui.icons

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.material3.Icon
import com.example.app.R

object ExFigIcons

@Composable
fun ExFigIcons.Ic24ArrowRight(
    contentDescription: String?,
    modifier: Modifier = Modifier,
    tint: Color = Color.Unspecified
) {
    Icon(
        painter = painterResource(id = R.drawable.ic_24_arrow_right),
        contentDescription = contentDescription,
        modifier = modifier,
        tint = tint
    )
}

@Composable
fun ExFigIcons.Ic24Close(
    contentDescription: String?,
    modifier: Modifier = Modifier,
    tint: Color = Color.Unspecified
) {
    Icon(
        painter = painterResource(id = R.drawable.ic_24_close),
        contentDescription = contentDescription,
        modifier = modifier,
        tint = tint
    )
}
```

## Usage

### XML Views

```xml
<ImageView
    android:layout_width="24dp"
    android:layout_height="24dp"
    android:src="@drawable/ic_24_arrow_right"
    android:tint="@color/icon_primary" />

<Button
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    app:icon="@drawable/ic_24_close"
    android:text="Close" />
```

### Jetpack Compose

```kotlin
import com.example.app.ui.icons.ExFigIcons
import com.example.app.ui.icons.Ic24ArrowRight
import com.example.app.ui.icons.Ic24Close

@Composable
fun MyScreen() {
    Row {
        ExFigIcons.Ic24ArrowRight(
            contentDescription = "Navigate",
            tint = MaterialTheme.colorScheme.primary
        )

        IconButton(onClick = { }) {
            ExFigIcons.Ic24Close(
                contentDescription = "Close",
                modifier = Modifier.size(24.dp)
            )
        }
    }
}
```

## Tips

1. Use vector drawables for resolution independence
2. Provide dark mode variants for better contrast
3. Use descriptive content descriptions for accessibility
4. Test icon rendering at different sizes
5. Use tinting for theme-aware icons

## See Also

- [Android Overview](index.md)
- [Images Export](images.md)
- [Configuration Reference](../../../CONFIG.md)

______________________________________________________________________

[← Back: Colors](colors.md) | [Up: Android Guide](index.md) | [Next: Images →](images.md)
