let flutterConfigFileContents = #"""
---
figma:
  # Identifier of the file containing light color palette, icons and light images.
  # Required for icons, images, typography export. Optional when using only variablesColors for colors.
  # To obtain a file id, open the file in the browser. The file id will be present in the URL after the word file and before the file name.
  lightFileId: shPilWnVdJfo10YF12345
  # [optional] Identifier of the file containing dark color palette and dark images.
  darkFileId: KfF6DnJTWHGZzC912345
  # [optional] Figma API request timeout. The default value of this property is 30 (seconds). If you have a lot of resources to export set this value to 60 or more to give Figma API more time to prepare resources for exporting.
  # timeout: 30

# [optional] Common export parameters
common:
  # [optional]
  colors:
    # [optional] RegExp pattern for color name validation before exporting. If a name contains "/" symbol it will be replaced by "_" before executing the RegExp
    nameValidateRegexp: '^([a-zA-Z_]+)$' # RegExp pattern for: background, background_primary, widget_primary_background
    # [optional] RegExp pattern for replacing. Supports only $n
    nameReplaceRegexp: 'color_$1'
    # [optional] Extract light and dark mode colors from the lightFileId specified in the figma params. Defaults to false
    useSingleFile: false
    # [optional] If useSingleFile is true, customize the suffix to denote a dark mode color. Defaults to '_dark'
    darkModeSuffix: '_dark'
  # [optional] Use variablesColors instead of colors to export colors from Figma Variables. Cannot be used together with colors.
  # variablesColors:
  #   # [required] Identifier of the file containing variables
  #   tokensFileId: shPilWnVdJfo10YF12345
  #   # [required] Variables collection name
  #   tokensCollectionName: Base collection
  #   # [required] Name of the column containing light color variables in the tokens table
  #   lightModeName: Light
  #   # [optional] Name of the column containing dark color variables in the tokens table
  #   darkModeName: Dark
  #   # [optional] Name of the column containing color variables in the primitive table. If a value is not specified, the default values will be taken
  #   primitivesModeName: Collection_1
  #   # [optional] RegExp pattern for color name validation before exporting.
  #   nameValidateRegexp: '^([a-zA-Z_]+)$'
  #   # [optional] RegExp pattern for replacing. Supports only $n
  #   nameReplaceRegexp: 'color_$1'
  # [optional]
  icons:
    # [optional] Name of the Figma's frame where icons components are located
    figmaFrameName: Icons
    # [optional] RegExp pattern for icon name validation before exporting. If a name contains "/" symbol it will be replaced by "_" before executing the RegExp
    nameValidateRegexp: '^(ic)_(\d\d)_([a-z0-9_]+)$' # RegExp pattern for: ic_24_icon_name, ic_24_icon
    # [optional] RegExp pattern for replacing. Supports only $n
    nameReplaceRegexp: 'icon_$2_$1'
    # [optional] Extract light and dark mode icons from the lightFileId specified in the figma params. Defaults to false
    useSingleFile: false
    # [optional] If useSingleFile is true, customize the suffix to denote a dark mode icons. Defaults to '_dark'
    darkModeSuffix: '_dark'
  # [optional]
  images:
    # [optional] Name of the Figma's frame where image components are located
    figmaFrameName: Illustrations
    # [optional] RegExp pattern for image name validation before exporting. If a name contains "/" symbol it will be replaced by "_" before executing the RegExp
    nameValidateRegexp: '^(img)_([a-z0-9_]+)$' # RegExp pattern for: img_image_name
    # [optional] RegExp pattern for replacing. Supports only $n
    nameReplaceRegexp: 'image_$2'
    # [optional] Extract light and dark mode images from the lightFileId specified in the figma params. Defaults to false
    useSingleFile: false
    # [optional] If useSingleFile is true, customize the suffix to denote a dark mode images. Defaults to '_dark'
    darkModeSuffix: '_dark'

# Flutter export parameters
flutter:
  # Output directory for generated Dart files
  output: "./lib/generated"
  # [optional] Path to the Stencil templates used to generate code
  # templatesPath: "./Resources/Templates"

  # Parameters for exporting colors
  colors:
    # Output filename for colors Dart file
    output: "colors.dart"
    # Class name for colors
    className: "AppColors"

  # Parameters for exporting icons
  icons:
    # Output directory for SVG icon files
    output: "assets/icons"
    # Dart file output
    dartFile: "icons.dart"
    # Class name for icons
    className: "AppIcons"

  # Parameters for exporting images
  images:
    # Output directory for image files
    output: "assets/images"
    # Dart file output
    dartFile: "images.dart"
    # Class name for images
    className: "AppImages"
    # Image file format: svg, png, or webp
    format: png
    # [optional] An array of asset scales that should be downloaded. The valid values are 1, 2, 3. The default value is [1, 2, 3].
    scales: [1, 2, 3]
    # [optional] Format options for webp format only
    # webpOptions:
    #   # Encoding type: lossy or lossless
    #   encoding: lossy
    #   # Encoding quality in percents. Only for lossy encoding.
    #   quality: 90

"""#
