# Android Images Export

Export raster images from Figma to Android drawable resources in PNG or WebP format with multiple density variants.

## Overview

ExFig exports images as:

- **PNG or WebP**: Raster images with multiple DPI variants
- **Vector images**: SVG to VectorDrawable conversion
- **Multiple densities**: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi

## Configuration

```yaml
android:
  mainRes: "./app/src/main/res"

  images:
    # Image format: png or webp
    format: webp

    # Output directory (relative to mainRes)
    output: "exfig-images"

    # Density scales (optional, defaults to [1, 1.5, 2, 3, 4])
    scales: [1, 1.5, 2, 3, 4]

    # WebP options (for webp format only)
    webpOptions:
      encoding: lossy    # lossy or lossless
      quality: 90        # 0-100 for lossy encoding
```

**Important:** Add to `build.gradle`:

```gradle
android {
    sourceSets {
        main {
            res.srcDirs += "src/main/res/exfig-images"
        }
    }
}
```

## Export Process

Run the export command:

```bash
exfig images
```

### 3. Generated Output

```
exfig-images/
├── drawable/
│   └── img_logo.xml                # Vector (if applicable)
├── drawable-night/
│   └── img_logo.xml                # Dark vector (if applicable)
├── drawable-mdpi/
│   ├── img_splash.webp             # @1x (160 dpi)
│   └── img_background.webp
├── drawable-hdpi/
│   ├── img_splash.webp             # @1.5x (240 dpi)
│   └── img_background.webp
├── drawable-xhdpi/
│   ├── img_splash.webp             # @2x (320 dpi)
│   └── img_background.webp
├── drawable-xxhdpi/
│   ├── img_splash.webp             # @3x (480 dpi)
│   └── img_background.webp
└── drawable-xxxhdpi/
    ├── img_splash.webp             # @4x (640 dpi)
    └── img_background.webp
```

## Density Mapping

| Scale | Android Density | DPI | Use Case | |-------|-----------------|------|-------------------| | 1 | mdpi | 160 |
Low-res devices | | 1.5 | hdpi | 240 | Medium-res | | 2 | xhdpi | 320 | High-res (common) | | 3 | xxhdpi | 480 | Extra
high-res | | 4 | xxxhdpi | 640 | Highest density |

Configure scales:

```yaml
android:
  images:
    scales: [2, 3, 4]  # Skip mdpi and hdpi
```

## Usage

### XML Views

```xml
<ImageView
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:src="@drawable/img_splash"
    android:scaleType="centerCrop" />

<ImageView
    android:layout_width="200dp"
    android:layout_height="200dp"
    android:src="@drawable/img_logo"
    android:scaleType="fitCenter" />
```

### Jetpack Compose

```kotlin
@Composable
fun MyScreen() {
    Image(
        painter = painterResource(id = R.drawable.img_splash),
        contentDescription = "Splash",
        modifier = Modifier.fillMaxWidth(),
        contentScale = ContentScale.Crop
    )

    Image(
        painter = painterResource(id = R.drawable.img_logo),
        contentDescription = "Logo",
        modifier = Modifier.size(200.dp)
    )
}
```

## WebP vs PNG

### WebP (Recommended)

```yaml
android:
  images:
    format: webp
    webpOptions:
      encoding: lossy
      quality: 90
```

**Advantages:**

- Smaller file size (25-35% smaller than PNG)
- Supported on Android 4.0+
- Lossless and lossy compression

**WebP Encoding:**

- **Lossy**: Better compression, slight quality loss
- **Lossless**: Perfect quality, larger than lossy

### PNG

```yaml
android:
  images:
    format: png
```

**Advantages:**

- Universal format
- No additional tools required
- Lossless compression

## Dark Mode Images

### Separate Files

```yaml
figma:
  lightFileId: abc123
  darkFileId: def456
```

Generated structure:

```
drawable-mdpi/
  img_hero.webp         # Light mode
drawable-night-mdpi/
  img_hero.webp         # Dark mode
```

### Single File Mode

```yaml
common:
  images:
    useSingleFile: true
    darkModeSuffix: '_dark'
```

Figma naming:

```
img-hero
img-hero_dark
```

## Vector Images

For SVG exports, ExFig converts to VectorDrawable XML:

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="200dp"
    android:height="200dp"
    android:viewportWidth="200"
    android:viewportHeight="200">
    <path
        android:fillColor="#FF6200"
        android:pathData="M100,50 L150,150 L50,150 Z"/>
</vector>
```

**When to use vectors:**

- Simple illustrations
- Logos and icons
- Graphics that need perfect scaling

## Tips

1. Use WebP for better app size optimization
2. Provide appropriate density variants (usually xhdpi, xxhdpi, xxxhdpi)
3. Use vectors for simple graphics instead of rasters
4. Compress images in Figma before export
5. Provide dark mode variants for better UX
6. Use `drawable-nodpi` for images that shouldn't scale
7. **Post-export optimization**: For PNG format, use [image_optim](https://github.com/toy/image_optim) to further compress:
   ```bash
   gem install image_optim image_optim_pack
   image_optim ./app/src/main/res/exfig-images/**/*.png
   ```

## Troubleshooting

### "WebP conversion failed for file"

- Check if the source PNG is corrupted
- Verify sufficient disk space
- Check file permissions
- Try PNG format as fallback: `format: png`

### Images are low quality

- Increase WebP quality: `quality: 95`
- Use lossless encoding
- Check source image resolution in Figma

### App size too large

- Use lossy WebP with quality 80-90
- Remove unnecessary density variants
- Compress images in Figma

## See Also

- [Android Overview](index.md)
- [Icons Export](icons.md)
- [Configuration Reference](../../../CONFIG.md)

______________________________________________________________________

[← Back: Icons](icons.md) | [Up: Android Guide](index.md) | [Next: Typography →](typography.md)
