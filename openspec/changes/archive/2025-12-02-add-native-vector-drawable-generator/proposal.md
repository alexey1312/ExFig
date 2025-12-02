# Change: Add Native Vector Drawable XML Generator

## Why

ExFig currently depends on external Java tool `vd-tool` to convert SVG files to Android Vector Drawable XML format. This
creates friction for users who need Java Runtime installed and adds complexity to the build/distribution process. The
project already has a native Swift SVG parser for ImageVector (Compose) generation that can be extended.

## What Changes

- **BREAKING**: Remove dependency on external `vd-tool` Java utility
- Create new `SVGKit` target for SVG parsing and code generation (future library extraction)
- Move existing SVG code from `AndroidExport/ImageVector/` to `SVGKit/`
- Extend `SVGParser` to preserve SVG group structure and transformations
- Add new `VectorDrawableXMLGenerator` for native XML generation
- Replace `VectorDrawableConverter` with `NativeVectorDrawableConverter`
- Support full Vector Drawable specification: groups, clip-paths, transforms

## Impact

- Affected specs: `android-export` (new capability)
- Affected code:
  - `Package.swift` - add SVGKit target
  - `Sources/SVGKit/` - new target with moved and new files
  - `Sources/AndroidExport/` - remove ImageVector/, depend on SVGKit
  - `Sources/ExFig/Output/NativeVectorDrawableConverter.swift` - new file
  - `Sources/ExFig/ExFigCommand.swift` - switch converter
  - `Sources/ExFig/Subcommands/ExportIcons.swift` - integration
  - `Sources/ExFig/Subcommands/ExportImages.swift` - integration
  - `Sources/ExFig/Output/VectorDrawableConverter.swift` - remove
  - `Release/vd-tool/` - remove directory
