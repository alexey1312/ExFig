# Change: Add SVG Gradient Support for Android Export

## Why

SVGKit currently only supports solid colors. Many design assets use gradients (linear and radial), which are lost during
export. Android VectorDrawable supports gradients since API 24, and Compose has Brush API for gradients.

## What Changes

- **ADDED**: Gradient types in SVGKit (SVGLinearGradient, SVGRadialGradient, SVGGradientStop, SVGFill)
- **MODIFIED**: SVGParser to parse `<defs>`, `<linearGradient>`, `<radialGradient>`, `<stop>` elements
- **MODIFIED**: SVGParser to resolve `url(#gradientId)` fill references
- **MODIFIED**: VectorDrawableXMLGenerator to output `<aapt:attr>` gradient format
- **MODIFIED**: ImageVectorGenerator to output `Brush.linearGradient()` and `Brush.radialGradient()`

## Impact

- Affected specs: svgkit
- Affected code:
  - `Sources/SVGKit/SVGTypes.swift`
  - `Sources/SVGKit/SVGParser.swift`
  - `Sources/SVGKit/VectorDrawableXMLGenerator.swift`
  - `Sources/SVGKit/ImageVectorGenerator.swift`
- API compatibility:
  - Vector Drawable: Requires `minSdkVersion 24` (Android 7.0)
  - Compose: All versions (Brush API is stable)

## Research Sources

- [usvg gradient spec](https://github.com/linebender/resvg/blob/main/crates/usvg/docs/spec.adoc)
- [FigX image_vector](https://github.com/tonykolomeytsev/figx/blob/master/crates/lib/image_vector/src/usvg.rs)
- [FigX svg2drawable](https://github.com/tonykolomeytsev/figx/blob/master/crates/lib/svg2drawable/src/lib.rs)
