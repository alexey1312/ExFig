---
paths:
  - "Sources/ExFigCLI/Output/Svg*.swift"
  - "Sources/ExFigCLI/Output/*Heic*.swift"
  - "Sources/ExFigCLI/Output/Webp*.swift"
---

# Image Format Patterns

This rule covers SVG source format and HEIC output format for images.

## SVG Source Format

Images can use SVG as the source format from Figma API, with local rasterization using resvg for higher quality results:

```pkl
// iOS example - SVG source with PNG output
ios {
  images = new Listing {
    new iOS.ImagesEntry {
      figmaFrameName = "Illustrations"
      assetsFolder = "Illustrations"
      sourceFormat = "svg"   // Fetch SVG, rasterize locally to PNG
      scales = new Listing { 1; 2; 3 }
    }
  }
}

// Android example - SVG source with WebP output
android {
  images = new Listing {
    new Android.ImagesEntry {
      figmaFrameName = "Illustrations"
      output = "src/main/res/"
      format = "webp"
      sourceFormat = "svg"   // Fetch SVG, rasterize locally to WebP
      webpOptions = new Common.WebpOptions { encoding = "lossless" }
    }
  }
}
```

**How it works:**

1. Figma API returns SVG instead of PNG
2. ExFig uses resvg (Rust library) to rasterize SVG locally
3. Output is encoded to PNG (iOS) or WebP (Android) at configured scales

**Benefits:**

- Higher quality than Figma's server-side PNG rendering
- Consistent results across all scales
- Smaller file sizes with lossless WebP

**Key files:**

| File                                            | Purpose                                             |
| ----------------------------------------------- | --------------------------------------------------- |
| `Sources/ExFigCLI/Output/SvgToWebpConverter.swift` | SVG -> WebP conversion                              |
| `Sources/ExFigCLI/Output/SvgToPngConverter.swift`  | SVG -> PNG conversion                               |
| `swift-resvg` (SPM dependency)                  | Swift wrapper for resvg (managed via Package.swift) |

**Updating resvg:** Update version in `Package.swift` dependencies.

## HEIC Output Format (iOS)

iOS images can be exported in HEIC format for ~40-50% smaller file sizes compared to PNG:

```pkl
// iOS example - PNG source with HEIC output
ios {
  images = new Listing {
    new iOS.ImagesEntry {
      figmaFrameName = "Illustrations"
      assetsFolder = "Illustrations"
      outputFormat = "heic"   // Convert to HEIC after download
      heicOptions = new iOS.HeicOptions {
        encoding = "lossy"    // or "lossless"
        quality = 90          // 0-100, only used for lossy
      }
    }
  }
}

// iOS example - SVG source with HEIC output (best quality)
ios {
  images = new Listing {
    new iOS.ImagesEntry {
      figmaFrameName = "Illustrations"
      assetsFolder = "Illustrations"
      sourceFormat = "svg"    // Fetch SVG from Figma
      outputFormat = "heic"   // Rasterize to HEIC locally
      heicOptions = new iOS.HeicOptions { encoding = "lossless" }
    }
  }
}
```

**How it works:**

1. For PNG source: Download PNGs from Figma, decode to RGBA, encode to HEIC
2. For SVG source: Download SVGs, rasterize with resvg, encode directly to HEIC
3. Asset catalog Contents.json references .heic files

**Requirements:**

- **macOS only** for encoding (uses ImageIO framework)
- iOS 12+ for runtime support (UIKit automatically handles HEIC in asset catalogs)
- On Linux: Falls back to PNG with warning

**Key files:**

| File                                            | Purpose                            |
| ----------------------------------------------- | ---------------------------------- |
| `Sources/ExFigCLI/Output/NativeHeicEncoder.swift`  | RGBA -> HEIC encoding using ImageIO |
| `Sources/ExFigCLI/Output/SvgToHeicConverter.swift` | SVG -> HEIC conversion             |
| `Sources/ExFigCLI/Output/HeicConverter.swift`      | PNG -> HEIC batch conversion       |

**Configuration types (PKL `iOS.pkl`):**

| Type                    | Purpose                                            |
| ----------------------- | -------------------------------------------------- |
| `iOS.ImageOutputFormat` | Typealias: `"png"` (default), `"heic"`             |
| `iOS.HeicOptions`       | Encoding mode (lossy/lossless) and quality (0-100) |

**Important:** Apple ImageIO does not support true lossless HEIC encoding.
The `lossless` option uses quality=1.0 (maximum) but is still technically lossy.
See: https://developer.apple.com/forums/thread/670094
