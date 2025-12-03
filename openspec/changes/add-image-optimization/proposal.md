# Change: Add Image Optimization via image_optim

## Why

Exported images (PNG, JPEG, GIF, SVG) can be significantly reduced in size without quality loss. Currently, ExFig only
supports WebP conversion via cwebp, but users who need PNG/JPEG output have no optimization option. The image_optim Ruby
gem provides a unified CLI for multiple optimization tools (oxipng, pngquant, mozjpeg, jpegoptim, gifsicle, svgo).

## What Changes

- **ADDED**: `ImageOptimizer` class for invoking `image_optim` CLI (similar to `WebpConverter`)
- **ADDED**: `optimize` and `optimizeOptions` configuration fields for iOS/Android/Flutter image export
- **MODIFIED**: `ExportImages` command to run optimization after writing image files
- **ADDED**: Documentation for `IMAGE_OPTIM_PATH` environment variable and installation instructions

## Impact

- Affected specs: image-export
- Affected code:
  - `Sources/ExFig/Output/ImageOptimizer.swift` (new)
  - `Sources/ExFig/Input/Params.swift`
  - `Sources/ExFig/Subcommands/ExportImages.swift`
  - `CLAUDE.md`, `CONFIG.md`
- External dependency: `image_optim` + `image_optim_pack` (Ruby gem, optional)
- Supported formats: PNG, JPEG, GIF, SVG
- Compression types: Lossless (default), Lossy (opt-in via `allowLossy`)

## Installation

```bash
# Via mise (recommended)
mise use -g gem:image_optim@0.31.4 gem:image_optim_pack@0.12.2.20251130

# Via gem
gem install image_optim image_optim_pack

# Custom path
export IMAGE_OPTIM_PATH=/path/to/image_optim
```

## Example Configuration

```yaml
ios:
  images:
    output: "Resources/Images.xcassets"
    optimize: true
    optimizeOptions:
      allowLossy: false # Safe lossless compression

android:
  images:
    format: png
    optimize: true
    optimizeOptions:
      allowLossy: true # Enable pngquant/mozjpeg
```
