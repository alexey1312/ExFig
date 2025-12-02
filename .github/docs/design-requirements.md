# Design Requirements for Figma

This guide explains how to structure your Figma files so that ExFig can export them correctly.

## General Requirements

### Publish to Team Library

**All styles and components must be published to a Team Library** for ExFig to access them.

### Platform-Specific Resources

Use the **description field** in Figma properties to specify platform targeting:

- **`ios`** - Export only for iOS/Xcode
- **`android`** - Export only for Android
- **`none`** - Don't export (designer-only resource)
- **No description** - Export for all platforms

**Example:**

- Color with description "ios" → Exported only to iOS project
- Icon with description "android" → Exported only to Android project
- Image with description "none" → Not exported

### RTL Support

For icons that support Right-to-Left layouts, add **`rtl`** to the description field.

**Example:**

- Icon with description "rtl" → Will be mirrored for RTL languages
- Icon with description "ios rtl" → iOS-only, with RTL support

______________________________________________________________________

## Colors

### Color Styles vs Variables

ExFig supports two approaches:

1. **Color Styles** (traditional) - Use `colors` in configuration
2. **Color Variables** (modern) - Use `variablesColors` in configuration

**Important:** Use either `colors` or `variablesColors`, not both.

### Option 1: Color Styles

#### File Structure

**Single Platform / No Dark Mode:**

- One Figma file with all color styles

**With Dark Mode:**

- **Separate files**: Light file + Dark file (recommended)
- **Single file**: Add `_dark` suffix to dark colors (requires `useSingleFile: true`)

**With High Contrast:**

- **Light + High Contrast**: 2 files (light + lightHC)
- **Dark + High Contrast**: 2 files (light + darkHC)
- **Full support**: 4 files (light + dark + lightHC + darkHC)

#### Naming Requirements

- Color names **must match** across light/dark/high contrast files
- Light palette can have more colors than dark (light-only colors become universal)
- Dark palette can have more colors than high contrast

#### Example Structure

**Light File:**

```
Color Styles
├── Background/Primary        (#FFFFFF)
├── Background/Secondary      (#F5F5F5)
├── Text/Primary              (#000000)
├── Text/Secondary            (#666666)
└── Button/Primary            (#2196F3)
```

**Dark File:**

```
Color Styles
├── Background/Primary        (#1E1E1E)
├── Background/Secondary      (#2D2D2D)
├── Text/Primary              (#FFFFFF)
├── Text/Secondary            (#B3B3B3)
└── Button/Primary            (#64B5F6)
```

#### Single File Mode

Configure in `exfig.yaml`:

```yaml
common:
  colors:
    useSingleFile: true
    darkModeSuffix: '_dark'
    lightHCModeSuffix: '_lightHC'
    darkHCModeSuffix: '_darkHC'
```

**Figma Color Styles:**

```
Background/Primary
Background/Primary_dark
Background/Primary_lightHC
Background/Primary_darkHC
```

### Option 2: Color Variables (Beta)

**Note:** Figma Variables API is in Beta and may change.

Color variables support nested references (variables can reference other variables).

#### Configuration

Use `variablesColors` instead of `colors`:

```yaml
common:
  variablesColors:
    tokensFileId: abc123
    tokensCollectionName: "Semantic Colors"
    lightModeName: "Light"
    darkModeName: "Dark"
    lightHCModeName: "Light HC"
    darkHCModeName: "Dark HC"
    primitivesModeName: "Value"  # Optional
```

#### Variable Structure

**Tokens Collection (Semantic Colors):**

| Variable Name | Light Mode | Dark Mode | Light HC | Dark HC |
|---------------------|------------|-----------|-----------|-----------| | background/primary | #FFFFFF | #1E1E1E |
#FFFFFF | #000000 | | background/secondary| Gray/90 | Gray/10 | Gray/95 | Gray/5 | | text/primary | Gray/10 | Gray/90 |
#000000 | #FFFFFF |

**Primitives Collection (Optional):**

| Variable Name | Value | |---------------|---------| | Gray/10 | #1A1A1A | | Gray/90 | #E5E5E5 | | Gray/95 | #F2F2F2 |

Variables can reference:

- Direct color values (e.g., `#FFFFFF`)
- Other variables (e.g., `Gray/90`)
- Variables from other collections

______________________________________________________________________

## Icons

### File Structure

Your Figma file must contain a **frame named "Icons"** (configurable via `common.icons.figmaFrameName`).

Inside this frame, create **components** for each icon:

```
Icons Frame
├── ic/24/arrow-right    (component)
├── ic/24/close          (component)
├── ic/24/menu           (component)
├── ic/16/notification   (component)
└── ic/16/check          (component)
```

**Important:** Icons must be components, not just frames or groups.

### Dark Mode Icons

**Separate Files:**

- Light file: Contains light mode icons
- Dark file: Contains matching dark mode icons
- Icon names must match between files

**Single File Mode:**

```yaml
common:
  icons:
    useSingleFile: true
    darkModeSuffix: '_dark'
```

**Figma components:**

```
ic/24/arrow-right
ic/24/arrow-right_dark
```

### Icon Design Guidelines

- **Use vectors**: Ensure icons are vector-based, not rasterized
- **Single color**: Icons should be monochrome (for tinting support)
- **Consistent sizing**: Use consistent canvas sizes (16px, 24px, 32px, etc.)
- **Center aligned**: Icons should be centered on their canvas
- **Export-ready**: Flatten complex groups and remove unnecessary layers

### RTL Icons

For icons that need to be mirrored in RTL languages, add `rtl` to the description:

```
Component: ic/24/arrow-right
Description: rtl
```

______________________________________________________________________

## Images

### File Structure

Your Figma file must contain a **frame named "Illustrations"** (configurable via `common.images.figmaFrameName`).

Inside this frame, create **components** for each image:

```
Illustrations Frame
├── img-empty-state      (component)
├── img-onboarding-1     (component)
├── img-onboarding-2     (component)
└── img-hero-background  (component)
```

**Important:** Images must be components, not frames.

### Dark Mode Images

Same rules as colors and icons:

**Separate Files:**

- Light file + Dark file with matching names

**Single File Mode:**

```yaml
common:
  images:
    useSingleFile: true
    darkModeSuffix: '_dark'
```

**Figma components:**

```
img-hero
img-hero_dark
```

### Multi-Idiom Images (iOS Only)

For device-specific images, use `~` suffix:

**Figma components:**

```
img-logo~iphone    → iPhone-specific
img-logo~ipad      → iPad-specific
img-logo~mac       → Mac-specific
```

ExFig will combine these into a single image set with idiom variants.

**Example:**

```
Illustrations
├── img-hero~iphone
├── img-hero~ipad
└── img-hero~mac
```

Generates:

```
imgHero.imageset/
├── imgHero~iphone.png
├── imgHero~iphone@2x.png
├── imgHero~ipad.png
├── imgHero~ipad@2x.png
├── imgHero~mac.png
└── Contents.json  (with idiom metadata)
```

### Image Design Guidelines

- **Use appropriate resolution**: Design at @2x or @3x resolution
- **Optimize file size**: Compress images in Figma before export
- **Use vectors when possible**: For simple graphics, use icons instead
- **Consistent naming**: Use a prefix (e.g., `img-` or `ill-`)

______________________________________________________________________

## Typography

### Text Styles

Your Figma file must contain **published Text Styles**.

**Example structure:**

```
Text Styles
├── Heading/Large
├── Heading/Medium
├── Heading/Small
├── Body/Regular
├── Body/Bold
├── Caption/Small
└── Button/Label
```

### Required Properties

Each text style should define:

- **Font family** - The font name
- **Font weight** - Regular, Bold, etc.
- **Font size** - In points (pt)
- **Line height** - For consistent spacing
- **Letter spacing** (optional) - Tracking

### Dynamic Type Support (iOS)

To support iOS Dynamic Type, add the native iOS text style name to the **description field**:

**iOS Text Style Names:**

- Large Title
- Title 1, Title 2, Title 3
- Headline
- Body
- Callout
- Subheadline
- Footnote
- Caption 1, Caption 2

**Example:**

- Text Style: `Heading/Large` (20pt Bold)
- Description: `Title 3`
- Result: Font scales with user's Dynamic Type settings

**Note:** Don't use Dynamic Type for tab bar and navigation bar text.

### Typography Guidelines

- **Use semantic names**: Name by purpose (e.g., `Body/Regular`) not size (e.g., `16pt Regular`)
- **Limit styles**: Keep to 8-12 text styles for consistency
- **Define line height**: Always set line height for proper spacing
- **Set letter spacing**: Define tracking for optical adjustment
- **Use font families**: Group font weights under the same family

______________________________________________________________________

## Team Library Publishing

### Why Publish?

ExFig uses the Figma API, which can only access **published styles and components** from Team Libraries.

### How to Publish

1. Open your Figma file
2. Click the book icon in the toolbar
3. Select all styles/components to publish
4. Click "Publish"

### What to Publish

- ✅ Color styles
- ✅ Color variables (if using)
- ✅ Text styles
- ✅ Icon components
- ✅ Image components
- ❌ Don't publish internal/designer-only assets (use `none` in description)

______________________________________________________________________

## Icon and Image Export Limitations

**Professional/Organization Figma Plan Required**

Exporting icons and images requires a **Figma Professional or Organization plan** because ExFig uses **Shareable Team
Libraries**.

Color and typography export works on all Figma plans.

______________________________________________________________________

## Validation and Name Transformation

### RegExp Validation

Configure validation rules to enforce naming conventions:

```yaml
common:
  colors:
    nameValidateRegexp: '^([a-z_]+)$'
  icons:
    nameValidateRegexp: '^(ic)_(\d\d)_([a-z0-9_]+)$'
  images:
    nameValidateRegexp: '^(img)_([a-z0-9_]+)$'
  typography:
    nameValidateRegexp: '^[a-zA-Z0-9_]+$'
```

Names that don't match the regex will be skipped with a warning.

### Name Transformation

Transform names during export:

```yaml
common:
  colors:
    nameReplaceRegexp: 'color_$1'
  icons:
    nameReplaceRegexp: 'icon_$2_$3'
  images:
    nameReplaceRegexp: 'image_$2'
```

**Example:**

- Figma: `ic_24_arrow_right`
- Validates: `^(ic)_(\d\d)_([a-z0-9_]+)$` ✓ → Groups: `ic`, `24`, `arrow_right`
- Transforms: `icon_$2_$3` → `icon_24_arrow_right`
- Output: `icon_24_arrow_right.pdf`

______________________________________________________________________

## Best Practices

1. **Organize with folders**: Use `/` in style names for hierarchy
2. **Use consistent naming**: Follow a naming convention across all resources
3. **Publish frequently**: Update Team Library after changes
4. **Document standards**: Create a design system doc for your team
5. **Test exports**: Run ExFig locally before committing
6. **Use semantic names**: Name by purpose, not appearance
7. **Provide variants**: Always provide light/dark variants when supporting dark mode
8. **Optimize assets**: Compress images and simplify vectors before export

______________________________________________________________________

## Troubleshooting

### "No colors/icons/images found"

- Ensure styles/components are published to Team Library
- Verify frame names match configuration
- Check name validation regex

### "Failed to fetch from Figma"

- Verify `FIGMA_PERSONAL_TOKEN` is set
- Check file IDs are correct
- Ensure your token has access to the file

### Dark mode resources not matching

- Verify names match exactly between light and dark files
- Check suffixes if using single file mode
- Ensure both files are published

### Components not exporting

- Components must be published, not just instances
- Verify components are inside the specified frame
- Check component names pass validation regex

______________________________________________________________________

## See Also

- [Getting Started](getting-started.md) - Installation and setup
- [iOS Colors](ios/colors.md) - iOS color export details
- [Android Colors](android/colors.md) - Android color export details
- [Configuration Reference](../../CONFIG.md) - Complete configuration options
- [Example Projects](../../Examples/README.md) - Working Figma examples

______________________________________________________________________

[← Back: Documentation Index](index.md)
