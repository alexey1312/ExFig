# image-export Specification

## Purpose

TBD - created by archiving change add-image-optimization. Update Purpose after archive.

## Requirements

### Requirement: Image Optimization

The system SHALL support optional image optimization using the `image_optim` CLI tool.

#### Scenario: Optimization enabled with lossless mode

- **GIVEN** configuration has `optimize: true` and `optimizeOptions.allowLossy: false`
- **WHEN** images are exported
- **THEN** the system SHALL optimize PNG, JPEG, GIF, and SVG files using lossless compression
- **AND** original image quality SHALL be preserved exactly

#### Scenario: Optimization enabled with lossy mode

- **GIVEN** configuration has `optimize: true` and `optimizeOptions.allowLossy: true`
- **WHEN** images are exported
- **THEN** the system SHALL optimize images using both lossless and lossy compression tools
- **AND** lossy tools like pngquant and mozjpeg MAY reduce file size further with minimal quality loss

#### Scenario: image_optim not installed

- **GIVEN** `image_optim` CLI is not available in PATH or configured paths
- **WHEN** optimization is requested
- **THEN** the system SHALL display a warning with installation instructions
- **AND** the system SHALL continue export without optimization (non-blocking)

#### Scenario: Custom binary path

- **GIVEN** environment variable `IMAGE_OPTIM_PATH` is set
- **WHEN** the system searches for image_optim binary
- **THEN** the system SHALL use the path from environment variable first

### Requirement: Optimization Configuration

The system SHALL provide configuration options for image optimization on all platforms.

#### Scenario: iOS configuration

- **GIVEN** iOS image export configuration
- **WHEN** user adds `optimize: true` under `ios.images`
- **THEN** PNG images in xcassets SHALL be optimized after export

#### Scenario: Android configuration

- **GIVEN** Android image export with `format: png` or `format: jpg`
- **WHEN** user adds `optimize: true` under `android.images`
- **THEN** raster images SHALL be optimized after export

#### Scenario: Flutter configuration

- **GIVEN** Flutter image export with `format: png` or `format: jpg`
- **WHEN** user adds `optimize: true` under `flutter.images`
- **THEN** raster images SHALL be optimized after export

#### Scenario: WebP format excluded

- **GIVEN** image export with `format: webp`
- **WHEN** optimization is configured
- **THEN** optimization SHALL be skipped (WebP is already optimized by cwebp)

### Requirement: Optimization Progress

The system SHALL display progress during image optimization.

#### Scenario: Batch optimization progress

- **GIVEN** multiple images to optimize
- **WHEN** optimization is running
- **THEN** the system SHALL display a progress indicator with current/total count
- **AND** the system SHALL process images in parallel (default: 4 concurrent)
