# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Module Purpose

SVGKit is a pure Swift SVG-to-native-format converter. It parses SVG files into an intermediate `ParsedSVG` representation and generates two output formats: **Jetpack Compose ImageVector** (Kotlin) and **Android VectorDrawable XML**. It replaces the external `vd-tool` Java dependency.

## Build & Test

```bash
./bin/mise run build                          # Build all (includes SVGKit)
./bin/mise run test:filter SVGKitTests        # Run SVGKit tests only
./bin/mise run test:filter SVGKitTests.SVGParserTests  # Single test class
```

## Architecture

**Pipeline:** SVG Data → `SVGParser` (+ usvg normalization) → `ParsedSVG` → Generator → output string

```
SVGParser.swift          # SVG XML → ParsedSVG (the core parser, ~1500 lines)
SVGPathParser.swift      # SVG path `d` attribute → [SVGPathCommand] (UTF-8 scanner)
SVGTypes.swift           # Domain types: SVGTransform, SVGColor, SVGGradient*, SVGGroup, SVGElement, SVGFill
ImageVectorGenerator.swift       # ParsedSVG → Kotlin ImageVector code (Compose)
VectorDrawableXMLGenerator.swift # ParsedSVG → Android VectorDrawable XML
NativeVectorDrawableConverter.swift  # Batch directory converter (SVG→XML, async parallel)
PathDataValidator.swift  # Android pathData length validation (800 char lint / 32KB AAPT limit)
ResvgPathConverter.swift # resvg Path segments → SVG path data string (for mask/clip-path extraction)
```

## Key Design Decisions

**Dual element representation:** `ParsedSVG` has both a flat `paths` array and structured `elements: [SVGElement]` (an enum of `.path`/`.group`). The `elements` array preserves SVG document order and is the preferred access path. The flat `paths`/`groups` arrays exist for backward compatibility — generators check `elements` first, fall back to legacy arrays.

**usvg normalization:** `SVGParser.parse(_:normalize:)` normalizes SVG via resvg's usvg before XML parsing (resolves `<use>`, inlines CSS, applies defaults). `NativeVectorDrawableConverter` defaults to `normalize: false` to preserve Figma mask/clip-path structure.

**Shape-to-path conversion:** All SVG shapes (`rect`, `circle`, `ellipse`, `line`, `polygon`, `polyline`) are converted to path data using **absolute commands and cubic Bezier curves** (not arcs) for Android VectorDrawable compatibility. Rounded rects use k=0.5523 arc approximation.

**Linux XML compatibility:** `SVGParser` wraps all XML access through `elementName()`, `childElements(of:named:)`, and `attributeValue(_:forName:)` helpers because FoundationXML on Linux has issues with default xmlns namespaces.

## Gotchas

- `SVGParser` is a class with mutable state (gradient/clip/mask/symbol defs) — it resets state at the start of each `parse()` call but is not thread-safe for concurrent parsing. Create separate instances for concurrent use.
- `SVGColor.parse()` supports a limited set of named colors (14 colors). Unknown names return nil.
- Gradient coordinates support both absolute values and percentages; percentage conversion uses `currentViewBox` which is set during parse.
- `<mask>` elements are treated as clip-paths (Figma uses masks for rounded corners on flags).
- `<use>` resolution has a `maxUseDepth = 10` recursion guard.
- `PathDataValidator` thresholds: 800 chars (Android Lint warning), 32,767 bytes (AAPT STRING_TOO_LARGE crash).

## Dependencies

| Package             | Purpose                                             |
| ------------------- | --------------------------------------------------- |
| swift-log           | Logging                                             |
| swift-resvg (Resvg) | SVG normalization via usvg, path segment extraction |
