# ExFig configuration file

Argument `-i` or `-input` specifies path to configuration file where all the properties stores: figma, ios, android.

If no `-i` option is specified, ExFig looks for config files in this order:

1. `figma-export.yaml` (for compatibility with figma-export users)
2. `exfig.yaml`

`./exfig colors`

Specification of `exfig.yaml` file with all the available options:

```yaml
---
figma:
  # [required] Identifier of the file containing light color palette, icons and light images. To obtain a file id, open the file in the browser. The file id will be present in the URL after the word file and before the file name.
  lightFileId: shPilWnVdJfo10YF12345
  # [optional] Identifier of the file containing dark color palette and dark images.
  darkFileId: KfF6DnJTWHGZzC912345
  # [optional] Identifier of the file containing light high contrast color palette.
  lightHighContrastFileId: KfF6DnJTWHGZzC912345
  # [optional] Identifier of the file containing dark high contrast color palette.
  darkHighContrastFileId: KfF6DnJTWHGZzC912345
  # [optional] Figma API request timeout. The default value of this property is 30 (seconds). If you have a lot of resources to export set this value to 60 or more to give Figma API more time to prepare resources for exporting.
  # Note: CLI flag --timeout overrides this config value. Example: exfig colors --timeout 60
  # timeout: 30

# [optional] Common export parameters
common:
  # [optional] Version tracking cache configuration
  # When enabled, ExFig checks the Figma file version before exporting.
  # If the file version hasn't changed since the last export, the export is skipped.
  # This is useful for CI/CD pipelines to avoid unnecessary exports.
  cache:
    # [optional] Enable version tracking. Default: false
    enabled: true
    # [optional] Custom path to cache file. Default: .exfig-cache.json
    path: ".exfig-cache.json"

  # [optional]
  colors:
    # [optional] RegExp pattern for color name validation before exporting. If a name contains "/" symbol it will be replaced by "_" before executing the RegExp
    nameValidateRegexp: '^([a-zA-Z_]+)$' # RegExp pattern for: background, background_primary, widget_primary_background
    # [optional] RegExp pattern for replacing. Supports only $n
    nameReplaceRegexp: 'color_$1'
    # [optional] Extract light and dark mode colors from the lightFileId specified in the figma params. Defaults to false
    useSingleFile: true
    # [optional] If useSingleFile is true, customize the suffix to denote a dark mode color. Defaults to '_dark'
    darkModeSuffix: '_dark'
    # [optional] If useSingleFile is true, customize the suffix to denote a light high contrast color. Defaults to '_lightHC'
    lightHCModeSuffix: '_lightHC'
    # [optional] If useSingleFile is true, customize the suffix to denote a dark high contrast color. Defaults to '_darkHC'
    darkHCModeSuffix: '_darkHC'
  # [optional]
  variablesColors:
    # [required] Identifier of the file containing variables
    tokensFileId: shPilWnVdJfo10YF12345
    # [required] Variables collection name
    tokensCollectionName: Base collection
    # [required] Name of the column containing light color variables in the tokens table
    lightModeName: Light
    # [optional] Name of the column containing dark color variables in the tokens table
    darkModeName: Dark
    # [optional] Name of the column containing light high contrast color variables in the tokens table
    lightHCModeName: Contast Light
    # [optional] Name of the column containing dark high contrast color variables in the tokens table
    darkHCModeName: Contast Dark
    # [optional] Name of the column containing color variables in the primitive table. If a value is not specified, the default values ​​will be taken
    primitivesModeName: Collection_1
    # [optional] RegExp pattern for color name validation before exporting. If a name contains "/" symbol it will be replaced by "_" before executing the RegExp
    nameValidateRegexp: '^([a-zA-Z_]+)$'
    # [optional] RegExp pattern for replacing. Supports only $n
    nameReplaceRegexp: 'color_$1'
  # [optional]
  icons:
    # [optional] Name of the Figma's frame where icons components are located
    figmaFrameName: Icons
    # [optional] RegExp pattern for icon name validation before exporting. If a name contains "/" symbol it will be replaced by "_" before executing the RegExp
    nameValidateRegexp: '^(ic)_(\d\d)_([a-z0-9_]+)$' # RegExp pattern for: ic_24_icon_name, ic_24_icon
    # [optional] RegExp pattern for replacing. Supports only $n
    nameReplaceRegexp: 'icon_$2_$1'
    # [optional] Extract light and dark mode icons from the lightFileId specified in the figma params. Defaults to false
    useSingleFile: true
    # [optional] If useSingleFile is true, customize the suffix to denote a dark mode icons. Defaults to '_dark'
    darkModeSuffix: '_dark'
  # [optional]
  images:
    # [optional]Name of the Figma's frame where image components are located
    figmaFrameName: Illustrations
    # [optional] RegExp pattern for image name validation before exporting. If a name contains "/" symbol it will be replaced by "_" before executing the RegExp
    nameValidateRegexp: '^(img)_([a-z0-9_]+)$' # RegExp pattern for: img_image_name
    # [optional] RegExp pattern for replacing. Supports only $n
    nameReplaceRegexp: 'image_$2'
    # [optional] Extract light and dark mode icons from the lightFileId specified in the figma params. Defaults to false
    useSingleFile: true
    # [optional] If useSingleFile is true, customize the suffix to denote a dark mode icons. Defaults to '_dark'
    darkModeSuffix: '_dark'
  # [optional]
  typography:
    # [optional] RegExp pattern for text style name validation before exporting. If a name contains "/" symbol it will be replaced by "_" before executing the RegExp
    nameValidateRegexp: '^[a-zA-Z0-9_]+$' # RegExp pattern for: h1_regular, h1_medium
    # [optional] RegExp pattern for replacing. Supports only $n
    nameReplaceRegexp: 'font_$1'

# [optional] iOS export parameters
ios:
  # Path to xcodeproj
  xcodeprojPath: "./Example.xcodeproj"
  # Xcode Target containing resources and corresponding swift code
  target: "UIComponents"
  # Absolute or relative path to the Assets.xcassets directory
  xcassetsPath: "./Resources/Assets.xcassets"
  # Is Assets.xcassets located in the main bundle?
  xcassetsInMainBundle: true
  # [optional] Is Assets.xcassets located in a swift package? Default value is false.
  xcassetsInSwiftPackage: false
  # [optional] When `xcassetsInSwiftPackage: true` use this property to specify a resource bundle name for Swift packages containing Assets.xcassets (e.g. ["PackageName_TargetName"]). This is necessary to avoid SwiftUI Preview crashes.
  resourceBundleNames: []
  # [optional] Add @objc attribute to generated properties so that they are accessible in Objective-C. Defaults to false
  addObjcAttribute: false
  # [optional] Path to the Stencil templates used to generate code
  templatesPath: "./Resources/Templates"

  # [optional] Parameters for exporting colors
  colors:
    # How to export colors? Use .xcassets and UIColor/Color extension (useColorAssets = true) or UIColor/Color extension only (useColorAssets = false)
    useColorAssets: true
    # [required if useColorAssets: True] Name of the folder inside Assets.xcassets where to place colors (.colorset directories)
    assetsFolder: Colors
    # Color name style: camelCase, snake_case, PascalCase, kebab-case, or SCREAMING_SNAKE_CASE
    nameStyle: camelCase
    # [optional] Absolute or relative path to swift file where to export UIKit colors (UIColor) for accessing from the code (e.g. UIColor.backgroundPrimary)
    colorSwift: "./Sources/UIColor+extension.swift"
    # [optional] Absolute or relative path to swift file where to export SwiftUI colors (Color) for accessing from the code (e.g. Color.backgroundPrimary)
    swiftuiColorSwift: "./Source/Color+extension.swift"
    # [optional] If true and a color style name contains symbol "/" then "/" symbol indicates grouping by folders, and each folder will have the "Provides Namespace" property enabled. Defaults to `false`.
    groupUsingNamespace: true
    # [optional] Sync generated code names back to Figma Variables codeSyntax.iOS field.
    # When enabled, designers see real code names in Figma Dev Mode.
    # Requires: Figma Enterprise plan, file_variables:write token scope, Edit access.
    syncCodeSyntax: true
    # [optional] Template for codeSyntax.iOS. Use {name} for variable name.
    # Examples: "Color.{name}" → "Color.backgroundAccent", "UIColor.{name}" → "UIColor.primary"
    codeSyntaxTemplate: "Color.{name}"

  # [optional] Parameters for exporting icons (legacy single-object format)
  # Can also be an array of objects — see "Multiple Icons Configuration" section below.
  icons:
    # Image file format: pdf or svg
    format: pdf
    # Name of the folder inside Assets.xcassets where to place icons (.imageset directories)
    assetsFolder: Icons
    # Icon name style: camelCase, snake_case, PascalCase, kebab-case, or SCREAMING_SNAKE_CASE
    nameStyle: camelCase
    # [optional] An array of icon names that will supports Preseve Vecotor Data. Use `- "*"` to enable this option for all icons.
    preservesVectorRepresentation:
    - ic24TabBarMain
    - ic24TabBarEvents
    - ic24TabBarProfile
    # [optional] Absolute or relative path to swift file where to export icons (SwiftUI's Image) for accessing from the code (e.g. Image.illZeroNoInternet)
    swiftUIImageSwift: "./Source/Image+extension_icons.swift"
    # [optional] Absolute or relative path to swift file where to generate extension for UIImage for accessing icons from the code (e.g. UIImage.ic24ArrowRight)
    imageSwift: "./Example/Source/UIImage+extension_icons.swift"
    # [optional] Absolute or relative path to swift file where to generate Figma Code Connect structs
    codeConnectSwift: "./CodeConnect/Icons.figma.swift"
    # Asset render mode: "template", "original" or "default". Default value is "template".
    renderMode: default
    # Configure the suffix for filtering Icons and to denote a asset render mode: "default".
    # It will work when renderMode value is "template". Defaults to nil.
    renderModeDefaultSuffix: '_default'
    # Configure the suffix for filtering Icons and to denote a asset render mode: "original".
    # It will work when renderMode value is "template". Defaults to nil.
    renderModeOriginalSuffix: '_original'
    # Configure the suffix for filtering Icons and to denote a asset render mode: "template".
    # It will work when renderMode value isn't "template". Defaults to nil.
    renderModeTemplateSuffix: '_template'

  # Array format (multiple icons configurations from different Figma frames):
  # icons:
  #   - figmaFrameName: Actions     # Export icons from "Actions" frame
  #     format: svg
  #     assetsFolder: Actions
  #     nameStyle: camelCase
  #     preservesVectorRepresentation: ["*"]
  #     imageSwift: "./Generated/ActionsIcons.swift"
  #     codeConnectSwift: "./CodeConnect/Icons/ActionsIcons.figma.swift"
  #   - figmaFrameName: Navigation  # Export icons from "Navigation" frame
  #     format: svg
  #     assetsFolder: Navigation
  #     nameStyle: camelCase
  #     preservesVectorRepresentation: ["*"]
  #     imageSwift: "./Generated/NavigationIcons.swift"
  #     codeConnectSwift: "./CodeConnect/Icons/NavigationIcons.figma.swift"

  # [optional] Parameters for exporting images (legacy single-object format)
  # Can also be an array of objects — see "Multiple Images Configuration" section below.
  # Note: sourceFormat option is only available in the array format.
  images:
    # Name of the folder inside Assets.xcassets where to place images (.imageset directories)
    assetsFolder: Illustrations
    # Image name style: camelCase, snake_case, PascalCase, kebab-case, or SCREAMING_SNAKE_CASE
    nameStyle: camelCase
    # [optional] An array of asset scales that should be downloaded. The valid values are 1, 2, 3. The deafault value is [1, 2, 3].
    scales: [1, 2, 3]
    # [optional] Absolute or relative path to swift file where to export images (SwiftUI's Image) for accessing from the code (e.g. Image.illZeroNoInternet)
    swiftUIImageSwift: "./Source/Image+extension_illustrations.swift"
    # [optional] Absolute or relative path to swift file where to generate extension for UIImage for accessing illustrations from the code (e.g. UIImage.illZeroNoInternet)
    imageSwift: "./Example/Source/UIImage+extension_illustrations.swift"
    # [optional] Absolute or relative path to swift file where to generate Figma Code Connect structs
    # codeConnectSwift: "./CodeConnect/Images/Illustrations.figma.swift"

  # [optional] Parameters for exporting typography
  typography:
    # [optional] Absolute or relative path to swift file where to export UIKit fonts (UIFont extension).
    fontSwift: "./Source/UIComponents/UIFont+extension.swift"
    # [optional] Absolute or relative path to swift file where to generate LabelStyle extensions for each style (LabelStyle extension).
    labelStyleSwift: "./Source/UIComponents/LabelStyle+extension.swift"
    # [optional] Absolute or relative path to swift file where to export SwiftUI fonts (Font extension).
    swiftUIFontSwift: "./Source/View/Common/Font+extension.swift"
    # Should ExFig generate UILabel for each text style (font)? E.g. HeaderLabel, BodyLabel, CaptionLabel
    generateLabels: true
    # Relative or absolute path to directory where to place UILabel for each text style (font) (Requred if generateLabels = true)
    labelsDirectory: "./Source/UIComponents/"
    # Typography name style: camelCase, snake_case, PascalCase, kebab-case, or SCREAMING_SNAKE_CASE
    nameStyle: camelCase

# [optional] Android export parameters
android:
  # Relative or absolute path to the `main/res` folder including it. The colors/icons/images will be exported to this folder
  mainRes: "./main/res"
  # [optional] The package name, where the android resource constant `R` is located. Must be provided to enable code generation for Jetpack Compose
  resourcePackage: "com.example"
  # [optional] Relative or absolute path to the code source folder including it. The typography for Jetpack Compose will be exported to this folder
  mainSrc: "./main/src/java"
  # [optional] Path to the Stencil templates used to generate code
  templatesPath: "./Resources/Templates"

  # Parameters for exporting colors
  colors:
    # [optional] The package to export the Jetpack Compose color code to. Note: To export Jetpack Compose code, also `mainSrc` and `resourcePackage` above must be set
    composePackageName: "com.example"
    # [optional] Custom output path for Colors.kt file. When set, overrides the automatic path computed from mainSrc + composePackageName
    colorKotlin: "./app/src/main/java/com/example/theme/Ds3Colors.kt"
    # [optional] Theme attributes configuration for generating attrs.xml and styles.xml
    themeAttributes:
      # Enable theme attributes export
      enabled: true
      # Path to attrs.xml (relative to mainRes)
      attrsFile: "../../../values/attrs.xml"
      # Path to styles.xml for light mode (relative to mainRes)
      stylesFile: "../../../values/styles.xml"
      # [optional] Path to styles-night.xml for dark mode (relative to mainRes)
      stylesNightFile: "../../../values-night/styles.xml"
      # Theme name used in markers (e.g., "Theme.MyApp.Main")
      themeName: "Theme.MyApp.Main"
      # [optional] Custom marker start text. Default: "FIGMA COLORS MARKER START"
      markerStart: "FIGMA COLORS MARKER START"
      # [optional] Custom marker end text. Default: "FIGMA COLORS MARKER END"
      markerEnd: "FIGMA COLORS MARKER END"
      # [optional] Auto-create files with markers if missing. Default: false
      autoCreateMarkers: false
      # [optional] Name transformation settings
      nameTransform:
        # Target case style: camelCase, PascalCase, snake_case, etc. Default: PascalCase
        style: PascalCase
        # Prefix to add to attribute names. Default: "color"
        prefix: "color"
        # [optional] Prefixes to strip from color names before transformation
        stripPrefixes: ["extensions_", "information_", "statement_", "additional_"]
  # Parameters for exporting icons (legacy single-object format)
  # Can also be an array of objects — see "Multiple Icons Configuration" section below.
  icons:
    # Where to place icons relative to `mainRes`? ExFig clears this directory every time your execute `exfig icons` command
    output: "figma-import-icons"
    # [optional] The package to export the Jetpack Compose icon code to. Note: To export Jetpack Compose code, also `mainSrc` and `resourcePackage` above must be set
    composePackageName: "com.example"
    # [optional] Icon format: resourceReference (uses painterResource) or imageVector (generates ImageVector code). Default: resourceReference
    composeFormat: resourceReference
    # [optional] Extension target for ImageVector (e.g., "com.example.app.ui.AppIcons")
    composeExtensionTarget: "com.example.app.ui.AppIcons"
    # [optional] Exit with error if pathData exceeds 32,767 bytes (AAPT limit).
    # Default: false (only logs warnings). Can be overridden with --strict-path-validation CLI flag.
    strictPathValidation: false

  # Array format (multiple icons configurations from different Figma frames):
  # icons:
  #   - figmaFrameName: Actions     # Export icons from "Actions" frame
  #     output: "drawable-actions"
  #     composePackageName: "com.example.icons.actions"
  #   - figmaFrameName: Navigation  # Export icons from "Navigation" frame
  #     output: "drawable-nav"
  #     composePackageName: "com.example.icons.nav"
  #     composeFormat: imageVector
  #     composeExtensionTarget: "com.example.NavIcons"

  # Parameters for exporting images (legacy single-object format)
  # Can also be an array of objects — see "Multiple Images Configuration" section below.
  images:
    # Image file format: svg, png, or webp
    format: webp
    # Where to place images relative to `mainRes`? ExFig clears this directory every time your execute `exfig images` command
    output: "figma-import-images"
    # Format options for webp format only
    # [optional] An array of asset scales that should be downloaded. The valid values are 1 (mdpi), 1.5 (hdpi), 2 (xhdpi), 3 (xxhdpi), 4 (xxxhdpi). The deafault value is [1, 1.5, 2, 3, 4].
    scales: [1, 2, 3]
    webpOptions:
      # Encoding type: lossy or lossless
      encoding: lossy
      # Encoding quality in percents. Only for lossy encoding.
      quality: 90
    # [optional] Source format for fetching from Figma API: png or svg. Default: png.
    # When "svg" is specified, images are fetched as SVG and rasterized locally using resvg for higher quality.
    # sourceFormat: svg
  # Parameters for exporting typography
  typography:
    # Typography name style: camelCase, snake_case, PascalCase, kebab-case, or SCREAMING_SNAKE_CASE
    nameStyle: camelCase
    # [optional] The package to export the Jetpack Compose typography code to. Note: To export Jetpack Compose code, also `mainSrc` and `resourcePackage` above must be set
    composePackageName: "com.example"

# [optional] Flutter export parameters
flutter:
  # Relative or absolute path to the Flutter `lib/generated/` folder for Dart files
  output: "./lib/generated"
  # [optional] Path to the Stencil templates used to generate code
  templatesPath: "./templates"

  # Parameters for exporting colors
  colors:
    # [optional] Output file name for colors. Defaults to "colors.dart"
    output: "app_colors.dart"
    # [optional] Class name for generated colors. Defaults to "AppColors"
    className: "AppColors"

  # Parameters for exporting icons (legacy single-object format)
  # Can also be an array of objects — see "Multiple Icons Configuration" section below.
  icons:
    # Where to place SVG icon assets (relative path from project root)
    output: "assets/icons"
    # [optional] Output file name for icon constants. Defaults to "icons.dart"
    dartFile: "app_icons.dart"
    # [optional] Class name for generated icon constants. Defaults to "AppIcons"
    className: "AppIcons"

  # Array format (multiple icons configurations from different Figma frames):
  # icons:
  #   - figmaFrameName: Actions     # Export icons from "Actions" frame
  #     output: "assets/icons/actions"
  #     dartFile: "action_icons.dart"
  #     className: "ActionIcons"
  #   - figmaFrameName: Navigation  # Export icons from "Navigation" frame
  #     output: "assets/icons/nav"
  #     dartFile: "nav_icons.dart"
  #     className: "NavIcons"

  # Parameters for exporting images (legacy single-object format)
  # Can also be an array of objects — see "Multiple Images Configuration" section below.
  images:
    # Where to place image assets (relative path from project root)
    output: "assets/images"
    # [optional] Output file name for image constants. Defaults to "images.dart"
    dartFile: "app_images.dart"
    # [optional] Class name for generated image constants. Defaults to "AppImages"
    className: "AppImages"
    # [optional] Image format: svg, png, or webp. Defaults to "png"
    format: png
    # [optional] An array of asset scales that should be downloaded. Defaults to [1, 2, 3]
    scales: [1, 2, 3]
    # [optional] Format options for webp format only
    webpOptions:
      # Encoding type: lossy or lossless
      encoding: lossy
      # Encoding quality in percents. Only for lossy encoding.
      quality: 90
    # [optional] Source format for fetching from Figma API: png or svg. Default: png.
    # When "svg" is specified, images are fetched as SVG and rasterized locally using resvg for higher quality.
    # sourceFormat: svg

# [optional] Web export parameters (React/TypeScript)
web:
  # Relative or absolute path to the output directory for generated files
  output: "./src/generated"
  # [optional] Path to the Stencil templates used to generate code
  templatesPath: "./templates"

  # Parameters for exporting colors
  colors:
    # [optional] Output file name for CSS variables. Defaults to "theme.css"
    cssFile: "theme.css"
    # [optional] Output file name for TypeScript constants. Defaults to "variables.ts"
    tsFile: "variables.ts"
    # [optional] Output file name for JSON tokens. When specified, exports colors as JSON
    jsonFile: "tokens.json"

  # Parameters for exporting icons (legacy single-object format)
  # Can also be an array of objects — see "Multiple Icons Configuration" section below.
  icons:
    # [optional] Where to place SVG icon assets (relative path)
    assetsDirectory: "assets/icons"
    # [optional] Generate React TSX components for each icon. Defaults to true
    generateReactComponents: true
    # [optional] Export types.ts with TypeScript interfaces. Defaults to true
    exportTypes: true
    # [optional] Icon size in pixels for viewBox. Defaults to 24
    iconSize: 24

  # Array format (multiple icons configurations from different Figma frames):
  # icons:
  #   - figmaFrameName: Actions     # Export icons from "Actions" frame
  #     assetsDirectory: "assets/icons/actions"
  #     generateReactComponents: true
  #     iconSize: 24                # Icon size for viewBox
  #   - figmaFrameName: Navigation  # Export icons from "Navigation" frame
  #     assetsDirectory: "assets/icons/nav"
  #     generateReactComponents: true
  #     iconSize: 20                # Different icon size for navigation

  # Parameters for exporting images (legacy single-object format)
  # Can also be an array of objects — see "Multiple Images Configuration" section below.
  images:
    # [optional] Where to place image assets (relative path)
    assetsDirectory: "assets/images"
    # [optional] Generate React TSX components for each image. Defaults to true
    generateReactComponents: true

  # Array format (multiple images configurations from different Figma frames):
  # images:
  #   - figmaFrameName: Illustrations
  #     assetsDirectory: "assets/images/illustrations"
  #     generateReactComponents: true
  #   - figmaFrameName: Promo
  #     assetsDirectory: "assets/images/promo"
  #     generateReactComponents: true
```

## Multiple Icons Configuration

ExFig supports exporting icons from multiple Figma frames in a single config file. This is useful when your design
system organizes icons into different categories (e.g., Actions, Navigation, Chart) each in its own Figma frame.

### Benefits

- **Single config file** instead of multiple separate configs
- **Optimized API calls** — Components are fetched once per Figma file, then filtered locally by frame name
- **Shared settings** — Common settings like `nameValidateRegexp` and `darkModeSuffix` from `common.icons` apply to all
  entries
- **Backward compatible** — Existing single-object configs continue to work

### Format

The `icons` section can be either a single object (legacy) or an array of objects (new):

```yaml
# Legacy single-object format
ios:
  icons:
    format: svg
    assetsFolder: Icons
    nameStyle: camelCase

# Array format
ios:
  icons:
    - figmaFrameName: Actions
      format: svg
      assetsFolder: Actions
      nameStyle: camelCase
      imageSwift: "./Generated/ActionsIcons.swift"
      codeConnectSwift: "./CodeConnect/Icons/ActionsIcons.figma.swift"
    - figmaFrameName: Navigation
      format: svg
      assetsFolder: Navigation
      nameStyle: camelCase
      imageSwift: "./Generated/NavigationIcons.swift"
      codeConnectSwift: "./CodeConnect/Icons/NavigationIcons.figma.swift"
```

### Per-Entry Fields

Each entry in the array supports all the same fields as the legacy format, plus:

| Field                | Description                                                                            |
| -------------------- | -------------------------------------------------------------------------------------- |
| `figmaFrameName`     | Figma frame name to export icons from. Overrides `common.icons.figmaFrameName`         |
| `nameValidateRegexp` | RegExp pattern for icon name validation. Overrides `common.icons.nameValidateRegexp`   |
| `nameReplaceRegexp`  | RegExp pattern for name replacement. Overrides `common.icons.nameReplaceRegexp`        |
| `nameStyle`          | Name style (camelCase, snake_case, etc.). Platform-specific default applies if not set |
| `codeConnectSwift`   | (iOS only) Path to Figma Code Connect file for linking assets to Figma components      |

### Fallback Behavior

For `figmaFrameName`, fallback order is:

1. Entry-level `figmaFrameName`
2. `common.icons.figmaFrameName` (if defined)
3. `"Icons"` (default)

For `nameValidateRegexp`, `nameReplaceRegexp`, and `nameStyle`, fallback order is:

1. Entry-level field (if defined)
2. `common.icons.*` field (if defined)
3. Platform default (e.g., `snake_case` for Android/Flutter/Web)

### Per-Entry Regex Example

Use per-entry regex when different icon categories require different naming transformations:

```yaml
common:
  icons:
    # Global fallback regex (optional)
    nameValidateRegexp: "^(.+)$"
    nameReplaceRegexp: "ic_$1"

android:
  icons:
    - figmaFrameName: Actions
      output: "action"
      nameStyle: snake_case
      # Uses global regex from common.icons

    - figmaFrameName: Flags
      output: "flag"
      nameStyle: snake_case
      # Custom regex for flags: strips "flags_" prefix
      nameValidateRegexp: "^flags_(.+)$"
      nameReplaceRegexp: "ic_flag_$1"

    - figmaFrameName: Status
      output: "status"
      # Custom style, uses global regex
      nameStyle: camelCase
```

### Performance

When using multiple entries with the same Figma file:

- **Batch mode**: Components are pre-fetched once per unique file ID across all configs
- **Standalone mode**: Components are fetched once and cached locally for all entries in the same config

This means 17 icon entries with the same `lightFileId` result in only 1 Components API call (plus 1 Images API call per
unique frame), not 17 separate calls.

### Web Icons Array Format

```yaml
web:
  icons:
    - figmaFrameName: Actions
      assetsDirectory: assets/icons/actions
      generateReactComponents: true
      iconSize: 24
    - figmaFrameName: Navigation
      assetsDirectory: assets/icons/nav
      generateReactComponents: true
      exportTypes: true
      iconSize: 20
```

## Multiple Colors Configuration

ExFig supports exporting colors from multiple Figma Variable collections in a single config file. This is useful when
your design system has separate color collections (e.g., Base Palette, Theme Colors, Brand Colors).

### Benefits

- **Single config file** instead of multiple separate configs
- **Self-contained entries** — Each entry specifies its own Figma Variables source and output paths
- **Backward compatible** — Existing single-object configs with `common.variablesColors` continue to work

### Format

The `colors` section can be either a single object (legacy) or an array of objects (new):

```yaml
# Legacy single-object format (uses common.variablesColors for source)
ios:
  colors:
    useColorAssets: true
    assetsFolder: Colors
    nameStyle: camelCase

# Array format (self-contained source per entry)
ios:
  colors:
    - tokensFileId: abc123
      tokensCollectionName: Base Palette
      lightModeName: Light
      darkModeName: Dark
      useColorAssets: true
      assetsFolder: BaseColors
      nameStyle: camelCase
      colorSwift: "./Generated/BaseColors.swift"
    - tokensFileId: def456
      tokensCollectionName: Theme Colors
      lightModeName: Light
      darkModeName: Dark
      useColorAssets: true
      assetsFolder: ThemeColors
      nameStyle: camelCase
      colorSwift: "./Generated/ThemeColors.swift"
```

### Per-Entry Fields (iOS)

Each entry in the array includes both source and output fields:

| Field                  | Description                                             |
| ---------------------- | ------------------------------------------------------- |
| `tokensFileId`         | Figma file ID containing the Variables                  |
| `tokensCollectionName` | Name of the Variables collection                        |
| `lightModeName`        | Column name for light mode values                       |
| `darkModeName`         | Column name for dark mode values (optional)             |
| `lightHCModeName`      | Column name for light high contrast (optional)          |
| `darkHCModeName`       | Column name for dark high contrast (optional)           |
| `primitivesModeName`   | Column name for primitives (optional)                   |
| `nameValidateRegexp`   | RegExp for name validation (optional)                   |
| `nameReplaceRegexp`    | RegExp for name replacement (optional)                  |
| `useColorAssets`       | Export to .xcassets (true) or Swift only (false)        |
| `assetsFolder`         | Folder name inside Assets.xcassets                      |
| `nameStyle`            | camelCase, snake_case, PascalCase, etc.                 |
| `groupUsingNamespace`  | Enable namespace grouping for "/" in names (optional)   |
| `colorSwift`           | Path to UIColor extension file (optional)               |
| `swiftuiColorSwift`    | Path to SwiftUI Color extension file (optional)         |
| `syncCodeSyntax`       | Sync code names back to Figma codeSyntax.iOS (optional) |
| `codeSyntaxTemplate`   | Template for codeSyntax, e.g. "Color.{name}" (optional) |

### Android Colors Array Format

```yaml
android:
  colors:
    - tokensFileId: abc123
      tokensCollectionName: Base Palette
      lightModeName: Light
      xmlOutputFileName: base_colors.xml
    - tokensFileId: def456
      tokensCollectionName: Theme Colors
      lightModeName: Light
      darkModeName: Dark
      xmlOutputFileName: theme_colors.xml
      composePackageName: com.example.theme
      colorKotlin: ./app/src/main/java/com/example/theme/Ds3Colors.kt
```

### Flutter Colors Array Format

```yaml
flutter:
  colors:
    - tokensFileId: abc123
      tokensCollectionName: Base Palette
      lightModeName: Light
      output: base_colors.dart
      className: BaseColors
    - tokensFileId: def456
      tokensCollectionName: Theme Colors
      lightModeName: Light
      darkModeName: Dark
      output: theme_colors.dart
      className: ThemeColors
```

### Web Colors Array Format

```yaml
web:
  colors:
    - tokensFileId: abc123
      tokensCollectionName: Base Palette
      lightModeName: Light
      cssFile: base-theme.css
      tsFile: base-variables.ts
    - tokensFileId: def456
      tokensCollectionName: Theme Colors
      lightModeName: Light
      darkModeName: Dark
      cssFile: theme.css
      tsFile: theme-variables.ts
      jsonFile: theme-tokens.json
```

## Figma codeSyntax Sync (iOS)

ExFig can sync generated Swift code names back to Figma Variables, so designers see real code names in Figma Dev Mode.

### What It Does

When enabled, after exporting colors ExFig sends a POST request to update the `codeSyntax.iOS` field for each variable:

```
POST /v1/files/:file_key/variables
{
  "variables": [
    {
      "action": "UPDATE",
      "id": "VariableID:123:456",
      "codeSyntax": {
        "iOS": "Color.backgroundAccent"
      }
    }
  ]
}
```

### Result in Figma Dev Mode

After sync, designers see the real code name when inspecting a layer that uses the variable:

```
Fill: backgroundAccent
┌──────────────────────────────────────────────┐
│ iOS      Color.backgroundAccent        [copy]│
│ Android  (not set)                           │
│ Web      (not set)                           │
└──────────────────────────────────────────────┘
```

### Requirements

| Requirement | Value                  |
| ----------- | ---------------------- |
| Figma Plan  | Enterprise             |
| Token Scope | `file_variables:write` |
| File Access | Edit                   |

### Configuration

```yaml
# Legacy single-object format
ios:
  colors:
    useColorAssets: true
    assetsFolder: Colors
    nameStyle: camelCase
    syncCodeSyntax: true
    codeSyntaxTemplate: "Color.{name}"

# Array format (per-entry)
ios:
  colors:
    - tokensFileId: abc123
      tokensCollectionName: Base Palette
      lightModeName: Light
      useColorAssets: true
      assetsFolder: BaseColors
      nameStyle: camelCase
      syncCodeSyntax: true
      codeSyntaxTemplate: "ThemeCompatable.colors.{name}"
```

### Template Examples

| Template                        | Result (for "backgroundAccent")           |
| ------------------------------- | ----------------------------------------- |
| `Color.{name}`                  | `Color.backgroundAccent`                  |
| `UIColor.{name}`                | `UIColor.backgroundAccent`                |
| `ThemeCompatable.colors.{name}` | `ThemeCompatable.colors.backgroundAccent` |
| `InDriveColors.{name}`          | `InDriveColors.backgroundAccent`          |

### Name Processing

The `{name}` placeholder is replaced with the processed variable name. Processing follows the same pipeline as color export:

1. **Normalize**: Replace `/` with `_`, remove duplications like `color/color` → `color`
2. **Regex**: Apply `nameValidateRegexp` and `nameReplaceRegexp` if configured
3. **Style**: Apply `nameStyle` (camelCase, snakeCase, etc.)

This ensures the code syntax matches the generated Swift code exactly.

## Multiple Images Configuration

ExFig supports exporting images from multiple Figma frames in a single config file. This is useful when your design
system organizes illustrations into categories (e.g., Onboarding, Promo, Empty States).

### Benefits

- **Single config file** instead of multiple separate configs
- **Per-frame scales** — Each entry can specify its own scale factors
- **Optimized API calls** — Components are fetched once per Figma file
- **Backward compatible** — Existing single-object configs continue to work

### Format

The `images` section can be either a single object (legacy) or an array of objects (new):

```yaml
# Legacy single-object format
ios:
  images:
    assetsFolder: Illustrations
    nameStyle: camelCase

# Array format
ios:
  images:
    - figmaFrameName: Onboarding
      assetsFolder: Onboarding
      nameStyle: camelCase
      imageSwift: "./Generated/OnboardingImages.swift"
      codeConnectSwift: "./CodeConnect/Images/OnboardingImages.figma.swift"
    - figmaFrameName: Promo
      assetsFolder: Promo
      nameStyle: camelCase
      scales: [1, 2, 3]
      imageSwift: "./Generated/PromoImages.swift"
      codeConnectSwift: "./CodeConnect/Images/PromoImages.figma.swift"
```

### Per-Entry Fields (iOS)

| Field               | Description                                                                       |
| ------------------- | --------------------------------------------------------------------------------- |
| `figmaFrameName`    | Figma frame name to export images from. Overrides `common.images.figmaFrameName`  |
| `assetsFolder`      | Folder name inside Assets.xcassets                                                |
| `nameStyle`         | camelCase, snake_case, PascalCase, etc.                                           |
| `scales`            | Array of scale factors [1, 2, 3] (optional)                                       |
| `imageSwift`        | Path to UIImage extension file (optional)                                         |
| `swiftUIImageSwift` | Path to SwiftUI Image extension file (optional)                                   |
| `codeConnectSwift`  | Path to Figma Code Connect file for linking assets to Figma components (optional) |
| `sourceFormat`      | Source format from Figma API: `png` (default) or `svg` (optional)                 |
| `outputFormat`      | Output format: `png` (default) or `heic` (optional, macOS only for encoding)      |
| `heicOptions`       | HEIC encoding options (optional, see below)                                       |

#### HEIC Options (iOS only)

When `outputFormat: heic` is specified:

| Field      | Description                                     |
| ---------- | ----------------------------------------------- |
| `encoding` | `lossy` (default) or `lossless`*                |
| `quality`  | Quality for lossy encoding: 0-100 (default: 90) |

\*Note: Apple ImageIO does not support true lossless HEIC encoding.
The `lossless` option uses maximum quality (quality=1.0) which produces
near-lossless results but is still technically lossy. For true lossless,
use PNG format. See: https://developer.apple.com/forums/thread/670094

```yaml
# iOS example - HEIC output with SVG source (best quality)
ios:
  images:
    - figmaFrameName: Illustrations
      assetsFolder: Illustrations
      sourceFormat: svg      # Fetch SVG from Figma
      outputFormat: heic     # Rasterize to HEIC locally
      heicOptions:
        encoding: lossy
        quality: 90
```

**Requirements:**

- **macOS only** for encoding (uses ImageIO framework)
- iOS 12+ for runtime support
- On Linux: Falls back to PNG with warning

### Android Images Array Format

```yaml
android:
  images:
    - figmaFrameName: Illustrations
      output: drawable-illustrations
      format: svg
    - figmaFrameName: Photos
      output: drawable-photos
      format: webp
      scales: [1, 1.5, 2, 3, 4]
      webpOptions:
        encoding: lossy
        quality: 80
```

### Flutter Images Array Format

```yaml
flutter:
  images:
    - figmaFrameName: Illustrations
      output: assets/images/illustrations
      dartFile: illustrations.dart
      className: Illustrations
    - figmaFrameName: Promo
      output: assets/images/promo
      dartFile: promo_images.dart
      className: PromoImages
      format: webp
      scales: [1, 2, 3]
```

### Web Images Array Format

```yaml
web:
  images:
    - figmaFrameName: Illustrations
      assetsDirectory: assets/images/illustrations
      generateReactComponents: true
    - figmaFrameName: Promo
      assetsDirectory: assets/images/promo
      generateReactComponents: true
```

### Fallback Behavior

If `figmaFrameName` is not specified in an entry, it falls back to:

1. `common.images.figmaFrameName` (if defined)
2. `"Illustrations"` (default)

## SVG Source Format

ExFig supports fetching images as SVG from Figma API and rasterizing them locally using the resvg library. This produces
higher quality results compared to Figma's server-side PNG rendering.

### Configuration

Add `sourceFormat: svg` to your images configuration:

```yaml
# iOS (array format only)
ios:
  images:
    - figmaFrameName: Illustrations
      assetsFolder: Illustrations
      nameStyle: camelCase
      scales: [1, 2, 3]
      sourceFormat: svg  # Fetch SVG, rasterize locally to PNG

# Android (both formats)
android:
  images:
    format: webp
    output: "drawable-illustrations"
    sourceFormat: svg  # Fetch SVG, rasterize locally to WebP
    webpOptions:
      encoding: lossless

# Flutter (both formats)
flutter:
  images:
    output: "assets/images"
    format: png
    sourceFormat: svg  # Fetch SVG, rasterize locally to PNG
```

### How It Works

1. ExFig requests SVG format from Figma API instead of PNG
2. SVG is rasterized locally using [resvg](https://github.com/RazrFalcon/resvg) (Rust library)
3. Output is encoded to the target format (PNG for iOS, WebP/PNG for Android, PNG/WebP for Flutter) at configured scales

### Benefits

- **Higher quality** — resvg produces sharper results than Figma's server-side rendering
- **Consistent output** — Same rendering across all scales
- **Smaller file sizes** — Especially with lossless WebP encoding

### Platform Support

| Platform | Legacy Format | Array Format |
| -------- | ------------- | ------------ |
| iOS      | ❌            | ✅           |
| Android  | ✅            | ✅           |
| Flutter  | ✅            | ✅           |
| Web      | ❌            | ❌           |

### Requirements

- resvg library is bundled with ExFig (no additional installation needed)
- Works on macOS (arm64 + x86_64) and Linux (x86_64)

## Android Theme Attributes

ExFig supports generating Android theme attributes (`attrs.xml` and `styles.xml`) that reference exported color
resources. This is useful for creating theme-aware apps where colors are accessed via theme attributes rather than direct
resource references.

### Overview

Theme attributes allow your app to reference colors like `?attr/colorBackgroundPrimary` instead of
`@color/background_primary`. This enables:

- Theme switching at runtime
- Centralized color management through themes
- Separation between design tokens and theme-specific values

### Generated Output

**attrs.xml** (attribute declarations):

```xml
<resources>
    <!-- FIGMA COLORS MARKER START: Theme.MyApp.Main -->
    <attr name="colorBackgroundPrimary" format="color" />
    <attr name="colorBackgroundSecondary" format="color" />
    <attr name="colorTextPrimary" format="color" />
    <!-- FIGMA COLORS MARKER END: Theme.MyApp.Main -->
</resources>
```

**styles.xml** (theme values):

```xml
<resources>
    <style name="Theme.MyApp.Main" parent="Theme.MaterialComponents.DayNight">
        <!-- FIGMA COLORS MARKER START: Theme.MyApp.Main -->
        <item name="colorBackgroundPrimary">@color/background_primary</item>
        <item name="colorBackgroundSecondary">@color/background_secondary</item>
        <item name="colorTextPrimary">@color/text_primary</item>
        <!-- FIGMA COLORS MARKER END: Theme.MyApp.Main -->
    </style>
</resources>
```

### Configuration

```yaml
android:
  mainRes: "./main/res/figma/color/base"
  colors:
    themeAttributes:
      enabled: true
      attrsFile: "../../../values/attrs.xml"
      stylesFile: "../../../values/styles.xml"
      stylesNightFile: "../../../values-night/styles.xml"
      themeName: "Theme.MyApp.Main"
      markerStart: "FIGMA COLORS MARKER START"
      markerEnd: "FIGMA COLORS MARKER END"
      autoCreateMarkers: false
      nameTransform:
        style: PascalCase
        prefix: "color"
        stripPrefixes: ["extensions_", "information_", "statement_", "additional_"]
```

### Configuration Options

| Field               | Required | Default                       | Description                                |
| ------------------- | -------- | ----------------------------- | ------------------------------------------ |
| `enabled`           | No       | `false`                       | Enable theme attributes export             |
| `attrsFile`         | Yes\*    | —                             | Path to attrs.xml (relative to `mainRes`)  |
| `stylesFile`        | Yes\*    | —                             | Path to styles.xml (relative to `mainRes`) |
| `stylesNightFile`   | No       | —                             | Path to styles-night.xml for dark mode     |
| `themeName`         | Yes      | —                             | Theme name used in markers                 |
| `markerStart`       | No       | `"FIGMA COLORS MARKER START"` | Custom marker start text                   |
| `markerEnd`         | No       | `"FIGMA COLORS MARKER END"`   | Custom marker end text                     |
| `autoCreateMarkers` | No       | `false`                       | Auto-create files with markers if missing  |
| `nameTransform`     | No       | —                             | Name transformation settings               |

\* Required when `enabled: true`

### Name Transformation

The `nameTransform` section controls how color names are converted to theme attribute names:

| Setting         | Default      | Description                                     |
| --------------- | ------------ | ----------------------------------------------- |
| `style`         | `PascalCase` | Target case style (camelCase, PascalCase, etc.) |
| `prefix`        | `"color"`    | Prefix added to all attribute names             |
| `stripPrefixes` | `[]`         | Prefixes to remove from color names             |

**Examples:**

| Original Name                 | With `stripPrefixes: ["extensions_"]` | Result                    |
| ----------------------------- | ------------------------------------- | ------------------------- |
| `background_primary`          | No strip                              | `colorBackgroundPrimary`  |
| `extensions_background_error` | Strips `extensions_`                  | `colorBackgroundError`    |
| `text_and_icon_primary`       | No strip                              | `colorTextAndIconPrimary` |

### Marker-Based Updates

ExFig uses XML comment markers to update only specific sections of your files. This allows you to:

- Keep manual content outside markers
- Have multiple themes in the same file (each with its own markers)
- Safely run exports without losing custom code

**Marker format:**

```xml
<!-- MARKER_START: ThemeName -->
... generated content ...
<!-- MARKER_END: ThemeName -->
```

**Multiple themes in one file:**

```xml
<resources>
    <!-- FIGMA COLORS MARKER START: Theme.Light -->
    <attr name="colorBackground" format="color" />
    <!-- FIGMA COLORS MARKER END: Theme.Light -->

    <!-- FIGMA COLORS MARKER START: Theme.Dark -->
    <attr name="colorBackground" format="color" />
    <!-- FIGMA COLORS MARKER END: Theme.Dark -->
</resources>
```

### Batch Mode

When running `exfig batch`, theme attributes from multiple configs can target the same `attrs.xml` and `styles.xml`
files. ExFig automatically:

1. Collects all theme attributes during batch processing
2. Groups by target file
3. Updates each theme's marker section separately
4. Writes merged results after all configs complete

This ensures no race conditions and proper merging of contributions from different configs.

### Error Handling

| Error                | Cause                                  | Solution                                        |
| -------------------- | -------------------------------------- | ----------------------------------------------- |
| File not found       | Target file doesn't exist              | Create file manually or use `autoCreateMarkers` |
| Marker not found     | Markers missing in target file         | Add markers manually or use `autoCreateMarkers` |
| Markers out of order | End marker appears before start marker | Fix marker order in file                        |

When `autoCreateMarkers: true`, ExFig creates missing files with a minimal template containing the markers.

## CLI Options for Version Tracking

In addition to the YAML configuration, you can control version tracking via CLI flags. Version tracking works for all
export commands: `colors`, `icons`, `images`, and `typography`.

```bash
# Enable version tracking (overrides config)
exfig colors --cache
exfig icons --cache
exfig images --cache
exfig typography --cache

# Disable version tracking (ignore cache, always export)
exfig icons --no-cache

# Force export and update cache (ignore cached version)
exfig icons --force

# Use custom cache file path
exfig icons --cache-path ./custom-cache.json

# Enable granular node-level cache (experimental)
# Tracks per-node content hashes to skip unchanged assets even when file version changes
exfig icons --cache --experimental-granular-cache
exfig images --cache --experimental-granular-cache

# Force full re-export (clears node hashes when using granular cache)
exfig icons --cache --experimental-granular-cache --force
```

### Granular Cache (Experimental)

The `--experimental-granular-cache` flag enables per-node change detection using FNV-1a content hashing. When enabled
alongside `--cache`, ExFig computes hashes of each node's visual properties and compares them with cached values.

**Benefits:**

- Skip unchanged assets even when the Figma file version changes
- Export only the 3 icons that changed out of 500, not all 500
- Significant time savings for large design systems with frequent minor updates

**Limitations:**

- Config changes (output path, format, scale) are not detected — use `--force` when config changes
- First run with granular cache populates hashes, subsequent runs benefit from tracking

**Hashed properties:** `name`, `type`, `fills`, `strokes`, `strokeWeight`, `strokeAlign`, `strokeJoin`, `strokeCap`,
`effects`, `opacity`, `blendMode`, `clipsContent`, `rotation`, `children` (recursive)

### Priority Order

1. `--no-cache` flag (highest priority - always disables cache)
2. `--cache` or `--force` flags (enable cache)
3. YAML `common.cache.enabled` configuration
4. Default: disabled

### Cache File Format

The cache file (`.exfig-cache.json`) stores the Figma file versions:

```json
{
  "schemaVersion": 2,
  "files": {
    "abc123LightFileId": {
      "version": "1234567890",
      "lastExport": "2024-01-15T10:30:00Z",
      "fileName": "Design System",
      "nodeHashes": {
        "1:23": "a1b2c3d4e5f67890",
        "4:56": "0987654321fedcba"
      }
    }
  }
}
```

**Schema notes:**

- `schemaVersion: 2` — supports granular node hashes (backward compatible with v1)
- `nodeHashes` — optional field, populated when `--experimental-granular-cache` is used
- The file version changes when a Figma library is published, not on every auto-save

## JSON Export (download command)

The `download` command exports Figma data as JSON for use with design token tools, custom pipelines, or debugging.

### Command Structure

```bash
exfig download <subcommand> [options]
```

Subcommands:

- `colors` - Export color variables/styles
- `typography` - Export text styles
- `icons` - Export icon components with URLs
- `images` - Export image components with URLs
- `all` - Export all types to a directory

### Output Format Options

| Option            | Values       | Default | Description                         |
| ----------------- | ------------ | ------- | ----------------------------------- |
| `--format` / `-f` | `w3c`, `raw` | `w3c`   | Output format                       |
| `--output` / `-o` | path         | varies  | Output file path                    |
| `--compact`       | flag         | false   | Minified JSON output                |
| `--asset-format`  | see below    | `png`   | Format for icons/images             |
| `--scale`         | 1-4          | 3       | Scale for raster formats (PNG, JPG) |

Asset formats: `svg`, `png`, `pdf`, `jpg`

### W3C Design Tokens Format

The default `--format w3c` outputs JSON following the
[W3C Design Tokens](https://design-tokens.github.io/community-group/format/) specification:

```json
{
  "Background": {
    "Primary": {
      "$type": "color",
      "$value": {
        "Light": "#ffffff",
        "Dark": "#1a1a1a"
      },
      "$description": "Primary background color"
    }
  }
}
```

#### Token Type Mapping

| Data Type  | W3C `$type`  | `$value` Format                              |
| ---------- | ------------ | -------------------------------------------- |
| Colors     | `color`      | Mode → hex string (`#RRGGBB` or `#RRGGBBAA`) |
| Typography | `typography` | Object with fontFamily, fontSize, etc.       |
| Icons      | `asset`      | Figma export URL string                      |
| Images     | `asset`      | Figma export URL string                      |

#### Color Token Structure

Colors support multiple modes (Light, Dark, etc.) in the `$value` object:

```json
{
  "Statement": {
    "Background": {
      "PrimaryPressed": {
        "$type": "color",
        "$value": {
          "Light": "#022c8c",
          "Dark": "#99bbff",
          "Contrast Light": "#001c59",
          "Contrast Dark": "#ccdeff"
        }
      }
    }
  }
}
```

#### Typography Token Structure

```json
{
  "Heading": {
    "H1": {
      "$type": "typography",
      "$value": {
        "fontFamily": "Inter-Bold",
        "fontSize": 32,
        "lineHeight": 40,
        "letterSpacing": -0.5
      }
    }
  }
}
```

#### Asset Token Structure

```json
{
  "Icons": {
    "Navigation": {
      "ArrowLeft": {
        "$type": "asset",
        "$value": "https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/...",
        "$description": "Left arrow navigation icon"
      }
    }
  }
}
```

### Raw Format

The `--format raw` option outputs the Figma API response wrapped with metadata:

```json
{
  "source": {
    "name": "Design System",
    "fileId": "abc123",
    "exportedAt": "2024-01-15T10:30:00Z",
    "exfigVersion": "1.0.0"
  },
  "data": {
    "variableCollections": { ... },
    "variables": { ... }
  }
}
```

This format is useful for:

- Debugging Figma API responses
- Building custom processing pipelines
- Understanding the raw data structure

### Examples

```bash
# Export colors as W3C tokens (default)
exfig download colors -o tokens/colors.json

# Export raw Figma API response
exfig download colors -o debug/colors-raw.json --format raw

# Export icons as SVG with W3C format
exfig download icons -o tokens/icons.json --asset-format svg

# Export all types to a directory
exfig download all -o ./tokens/

# Export with compact (minified) output
exfig download colors -o tokens.json --compact
```
