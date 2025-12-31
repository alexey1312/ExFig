# Images Configuration

Images can be configured as a single object (legacy) or array (new format) in `Params.swift`.

## Configuration Types

```swift
// ImagesConfiguration enum handles both formats via custom Decodable
enum ImagesConfiguration: Decodable {
    case single(Images)       // Legacy: images: { assetsFolder: "Illustrations", ... }
    case multiple([ImagesEntry])  // New: images: [{ figmaFrameName: "Promo", ... }]

    var entries: [ImagesEntry]  // Unified access to all entries
    var isMultiple: Bool        // Check format type
}

// ImagesLoaderConfig passes frame-specific settings to loader
let config = ImagesLoaderConfig.forIOS(entry: entry, params: params)
let loader = ImagesLoader(client: client, params: params, platform: .ios, logger: logger, config: config)
```

## Key Types

| Type                  | Purpose                                                   |
| --------------------- | --------------------------------------------------------- |
| `ImagesConfiguration` | Enum with `.single`/`.multiple` for backward compat       |
| `ImagesEntry`         | Per-frame config (figmaFrameName, scales, output paths)   |
| `ImagesLoaderConfig`  | Sendable struct passed to ImagesLoader for frame settings |

**Frame name resolution:** `entry.figmaFrameName` → `params.common?.images?.figmaFrameName` → `"Illustrations"`

---

## SVG Source Format

Images can use SVG as the source format from Figma API, with local rasterization using resvg for higher quality results.

### How It Works

1. Figma API returns SVG instead of PNG
2. ExFig uses resvg (Rust library) to rasterize SVG locally
3. Output is encoded to PNG (iOS) or WebP (Android) at configured scales

### Benefits

- Higher quality than Figma's server-side PNG rendering
- Consistent results across all scales
- Smaller file sizes with lossless WebP

### YAML Example

```yaml
# iOS example - SVG source with PNG output
ios:
  images:
    - figmaFrameName: "Illustrations"
      assetsFolder: "Illustrations"
      sourceFormat: svg  # Fetch SVG, rasterize locally to PNG
      scales: [1, 2, 3]

# Android example - SVG source with WebP output
android:
  images:
    - figmaFrameName: "Illustrations"
      output: "src/main/res/"
      format: webp
      sourceFormat: svg  # Fetch SVG, rasterize locally to WebP
      webpOptions:
        encoding: lossless
```

### Key Files

| File                                            | Purpose                                             |
| ----------------------------------------------- | --------------------------------------------------- |
| `Sources/ExFig/Output/SvgToWebpConverter.swift` | SVG → WebP conversion                               |
| `Sources/ExFig/Output/SvgToPngConverter.swift`  | SVG → PNG conversion                                |
| `swift-resvg` (SPM dependency)                  | Swift wrapper for resvg (managed via Package.swift) |

**Updating resvg:** Update version in `Package.swift` dependencies.

---

## HEIC Output Format (iOS)

iOS images can be exported in HEIC format for ~40-50% smaller file sizes compared to PNG.

### How It Works

1. For PNG source: Download PNGs from Figma, decode to RGBA, encode to HEIC
2. For SVG source: Download SVGs, rasterize with resvg, encode directly to HEIC
3. Asset catalog Contents.json references .heic files

### Requirements

- **macOS only** for encoding (uses ImageIO framework)
- iOS 12+ for runtime support (UIKit automatically handles HEIC in asset catalogs)
- On Linux: Falls back to PNG with warning

### YAML Example

```yaml
# iOS example - PNG source with HEIC output
ios:
  images:
    - figmaFrameName: "Illustrations"
      assetsFolder: "Illustrations"
      outputFormat: heic  # Convert to HEIC after download
      heicOptions:
        encoding: lossy   # or lossless
        quality: 90       # 0-100, only used for lossy

# iOS example - SVG source with HEIC output (best quality)
ios:
  images:
    - figmaFrameName: "Illustrations"
      assetsFolder: "Illustrations"
      sourceFormat: svg   # Fetch SVG from Figma
      outputFormat: heic  # Rasterize to HEIC locally
      heicOptions:
        encoding: lossless
```

### Key Files

| File                                            | Purpose                            |
| ----------------------------------------------- | ---------------------------------- |
| `Sources/ExFig/Output/NativeHeicEncoder.swift`  | RGBA → HEIC encoding using ImageIO |
| `Sources/ExFig/Output/SvgToHeicConverter.swift` | SVG → HEIC conversion              |
| `Sources/ExFig/Output/HeicConverter.swift`      | PNG → HEIC batch conversion        |

### Configuration Types

| Type                       | Purpose                                            |
| -------------------------- | -------------------------------------------------- |
| `Params.ImageOutputFormat` | Enum: `.png` (default), `.heic`                    |
| `Params.HeicOptions`       | Encoding mode (lossy/lossless) and quality (0-100) |

### Important Note

Apple ImageIO does not support true lossless HEIC encoding.
The `lossless` option uses quality=1.0 (maximum) but is still technically lossy.
See: https://developer.apple.com/forums/thread/670094
