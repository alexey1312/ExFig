# Design Requirements

How to structure your Figma files for optimal export with ExFig.

## Overview

ExFig extracts design resources from Figma files based on specific naming conventions and organizational structures.
This guide explains how to set up your Figma files for seamless export.

## General Principles

### Frame Organization

ExFig looks for resources in specific frames. Configure frame names in your `exfig.yaml`:

```yaml
common:
  colors:
    figmaFrameName: "Colors"
  icons:
    figmaFrameName: "Icons"
  images:
    figmaFrameName: "Illustrations"
  typography:
    figmaFrameName: "Typography"
```

### Naming Conventions

Use consistent naming patterns for all resources. ExFig supports regex validation:

```yaml
common:
  icons:
    nameValidateRegexp: "^ic/[0-9]+/[a-z_]+$"  # e.g., ic/24/arrow_right
```

## Colors

### Using Color Styles

Create color styles in Figma with descriptive names:

```
Colors frame
├── primary
├── secondary
├── background/primary
├── background/secondary
├── text/primary
├── text/secondary
└── border/default
```

### Using Figma Variables

For Figma Variables API support:

```yaml
common:
  colors:
    useVariables: true
    variableCollectionName: "Colors"
    lightModeName: "Light"
    darkModeName: "Dark"
```

Variable structure in Figma:

```
Colors collection
├── Mode: Light
│   ├── primary: #007AFF
│   ├── background: #FFFFFF
│   └── text: #000000
└── Mode: Dark
    ├── primary: #0A84FF
    ├── background: #000000
    └── text: #FFFFFF
```

### Naming Guidelines

- Use lowercase with optional separators: `/`, `-`, `_`
- Group related colors with prefixes: `text/primary`, `background/card`
- Avoid special characters except separators

## Icons

### Component Structure

Icons must be **components** (not plain frames):

```
Icons frame
├── ic/24/arrow-right     (component)
├── ic/24/arrow-left      (component)
├── ic/16/close           (component)
├── ic/16/check           (component)
└── ic/32/menu            (component)
```

### Size Conventions

Organize icons by size:

```
Icons frame
├── ic/16/...   (16pt icons)
├── ic/24/...   (24pt icons)
├── ic/32/...   (32pt icons)
└── ic/48/...   (48pt icons)
```

### Vector Requirements

For optimal vector export:

1. **Use strokes carefully**: Convert strokes to outlines for complex icons
2. **Flatten boolean operations**: Flatten complex boolean operations before export
3. **Remove hidden layers**: Delete unused or hidden elements
4. **Use consistent viewBox**: Keep viewBox dimensions consistent within size groups

### Dark Mode Icons

Two approaches for dark mode support:

**Separate files:**

```yaml
figma:
  lightFileId: "abc123"
  darkFileId: "def456"
```

Create matching component names in both files.

**Single file with suffix:**

```yaml
common:
  icons:
    useSingleFile: true
    darkModeSuffix: "_dark"
```

```
Icons frame
├── ic/24/arrow-right
├── ic/24/arrow-right_dark
├── ic/24/close
└── ic/24/close_dark
```

## Images

### Component Structure

Images must be **components**:

```
Illustrations frame
├── img-empty-state       (component)
├── img-onboarding-1      (component)
├── img-onboarding-2      (component)
└── img-hero-banner       (component)
```

### Size Recommendations

Design at the largest needed scale:

- **iOS**: Design at @3x, ExFig generates @1x, @2x, @3x
- **Android**: Design at xxxhdpi (4x), ExFig generates all densities
- **Flutter**: Design at 3x, ExFig generates 1x, 2x, 3x

### Multi-Idiom Support (iOS)

Use suffixes for device-specific variants:

```
Illustrations frame
├── img-hero~iphone       (iPhone variant)
├── img-hero~ipad         (iPad variant)
├── img-hero~mac          (Mac variant)
└── img-sidebar~ipad
```

### Dark Mode Images

Same approaches as icons:

**Separate files** or **suffix-based**:

```
Illustrations frame
├── img-empty-state
├── img-empty-state_dark
├── img-hero
└── img-hero_dark
```

## Typography

### Text Style Structure

Create text styles with hierarchical names:

```
Typography frame
├── heading/h1
├── heading/h2
├── heading/h3
├── body/regular
├── body/bold
├── caption/regular
└── caption/small
```

### Required Properties

Each text style should define:

- **Font family**: e.g., "SF Pro Text"
- **Font weight**: e.g., Regular, Bold, Semibold
- **Font size**: in pixels
- **Line height**: in pixels or percentage
- **Letter spacing**: in pixels or percentage

### Font Mapping

Map Figma fonts to platform fonts in your config:

```yaml
ios:
  typography:
    fontMapping:
      "Inter": "Inter"
      "SF Pro Text": ".AppleSystemUIFont"

android:
  typography:
    fontMapping:
      "Inter": "inter"
      "Roboto": "roboto"
```

## Validation Regex Patterns

### Common Patterns

```yaml
common:
  colors:
    # Allow: primary, text/primary, background_card
    nameValidateRegexp: "^[a-z][a-z0-9_/]*$"

  icons:
    # Require: ic/SIZE/name format
    nameValidateRegexp: "^ic/[0-9]+/[a-z][a-z0-9_-]*$"

  images:
    # Require: img- prefix
    nameValidateRegexp: "^img-[a-z][a-z0-9_-]*$"
```

### Transform Patterns

Transform names during export:

```yaml
common:
  icons:
    nameValidateRegexp: "^ic/([0-9]+)/(.+)$"
    nameReplaceRegexp: "ic$1_$2"  # ic/24/arrow -> ic24_arrow
```

## File Organization Tips

### Recommended Figma Structure

```
Design System
├── 📁 Colors
│   ├── Primary palette
│   ├── Secondary palette
│   ├── Semantic colors
│   └── Dark mode colors
├── 📁 Icons
│   ├── 16pt icons
│   ├── 24pt icons
│   └── 32pt icons
├── 📁 Illustrations
│   ├── Empty states
│   ├── Onboarding
│   └── Marketing
└── 📁 Typography
    ├── Headings
    ├── Body text
    └── Captions
```

### Light and Dark Mode Files

For complex theming, use separate files:

- `Design-System-Light.fig`: Light mode resources
- `Design-System-Dark.fig`: Dark mode resources

Ensure component names match exactly between files.

## Troubleshooting

### Resources Not Found

- Verify frame names match `figmaFrameName` in config
- Check that resources are **components**, not plain frames
- Ensure names pass validation regex

### Missing Dark Mode

- Verify `darkFileId` is set correctly
- Check component names match between light and dark files
- For single-file mode, verify suffix is correct

### Export Quality Issues

- Design at highest needed resolution
- Use vector graphics when possible
- Avoid raster effects in vector icons
- Flatten complex boolean operations

## See Also

- <doc:Configuration>
- <doc:iOS>
- <doc:Android>
- <doc:Flutter>
