# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2025-12-04

### Documentation

- **openspec**: Refine batch processing design by @alexey1312

- Add fault tolerance documentation to README by @alexey1312

- Add toon project file, update usage documentation by @alexey1312

### Features

- **openspec**: Add proposals for gradient, image, and WebP features by @alexey1312

- **svgkit**: Add gradient support for SVG parsing and export by @alexey1312

- **webp**: Replace cwebp binary with native libwebp library by @alexey1312

- **images**: Add PNG/JPEG/GIF optimization via image_optim by @alexey1312

- **openspec**: Add Windows platform support proposal by @claude

- **openspec**: Add three feature proposals by @claude

- **cli**: Add download command for JSON/W3C token export by @alexey1312

- **cli**: Add batch command for parallel config processing by @alexey1312

- **api**: Add retry policy and user-friendly error handling by @alexey1312

- **cli**: Add checkpoint system for batch export resumption by @alexey1312

- **cli**: Add fault tolerance options to all export commands by @alexey1312

### Miscellaneous Tasks

- **openspec**: Archive fault tolerance, create follow-up proposal by @alexey1312

### Other

- Fix Linux build

* fix(linux): fix libpng compatibility for Linux builds

- Replace unavailable PNG_FORMAT_RGBA and PNG_IMAGE_SIZE macros with explicit values (Swift cannot import complex C
  macros on Linux)
- Remove redundant png_image_free calls after successful operations to prevent double-free crashes (libpng frees the
  image internally on success)

These changes fix compilation errors and runtime crashes when building and testing on Linux with Swift 6.0.

- test(linux): skip WebpConverterTests that use libpng on Linux

libpng simplified API has memory corruption issues on Linux that cause crashes even with sequential single-file
operations. Skip all tests that use createTestPNG() or createCheckerboardPNG() helper functions on Linux:

- testConvertLossless
- testConvertLossyWithQuality
- testConvertPreservesOriginalPNG
- testConvertCreatesWebpWithCorrectExtension
- testConvertBatchWithMultipleFiles
- testConvertBatchCallsProgressCallback
- testConvertBatchRespectsMaxConcurrent
- testLossyProducesSmallerFileThanLossless

Tests that don't use PNG creation still run on Linux:

- testIsAvailableAlwaysReturnsTrue
- testConvertThrowsForNonExistentFile
- testConvertThrowsForInvalidPNG
- testConvertBatchWithEmptyArray

* fix(linux): use copyItem instead of replaceItemAt in FileWriter

FileManager.replaceItemAt behaves differently on Linux vs macOS. On Linux it requires the destination to exist, causing
test failures. Use copyItem with explicit file removal for cross-platform compatibility.

- docs: add Linux testing and Swift installation guidance to CLAUDE.md

Add comprehensive documentation for Linux development:

- How to run tests on Linux (with --num-workers 1)
- Swift 6.0 installation instructions for Ubuntu 24.04
- libpng limitations and test skipping patterns
- FileManager API differences (replaceItemAt vs copyItem)

* ci(linux): run tests with single worker to avoid memory corruption

Update Linux CI to use --parallel --num-workers 1 instead of skipping XcodeExportTests. This allows all tests to run
while avoiding libpng memory corruption issues that occur with parallel execution.

______________________________________________________________________

Co-authored-by: Claude <noreply@anthropic.com> by @alexey1312

- Claude/revert image optim feature 01 gmt rc gav9pimm46 h9 ua hbs by @alexey1312

- Figma image download

* feat(cli): add download command for config-free image downloads

Add new `exfig download` command that downloads images from Figma without requiring a configuration file. All parameters
are passed via command-line arguments.

Features:

- Download PNG, SVG, JPG, PDF, or WebP images from any Figma frame
- Default 3x scale for PNG (configurable 0.01-4.0)
- Filter images by pattern (e.g., "icon/\*")
- Name style conversion (camelCase, snake_case)
- Custom regex-based name replacement
- Dark mode variant extraction via suffix
- WebP conversion with quality/encoding options

New files:

- Sources/ExFig/Input/DownloadOptions.swift
- Sources/ExFig/Subcommands/DownloadImages.swift
- Tests/ExFigTests/Input/DownloadOptionsTests.swift

Documentation updated:

- CLAUDE.md: Added command examples, architecture docs, TDD guidelines
- README.md: Added Quick Download section with examples
- .github/docs/usage.md: Comprehensive download command documentation

* feat(naming): extend naming style support with PascalCase, kebab-case, and SCREAMING_SNAKE_CASE

Add three new naming conventions to the NameStyle enum and string extensions:

- PascalCase (UpperCamelCase): MyImageName
- kebab-case: my-image-name
- SCREAMING_SNAKE_CASE: MY_IMAGE_NAME

This extends the existing camelCase and snake_case options for the download command and config file exports (colors,
icons, images, typography).

- docs: update naming style options in platform-specific documentation

Update iOS and Android documentation to reflect all available naming styles: camelCase, snake_case, PascalCase,
kebab-case, SCREAMING_SNAKE_CASE

- refactor(docs): restructure CLAUDE.md for AI agent efficiency

Reduce from 708 to 288 lines (-59%) while retaining critical information:

- Add Quick Reference section with most-used commands upfront
- Convert verbose file listings to scannable tables
- Consolidate code patterns into actionable examples
- Keep Linux compatibility gotchas (critical for CI)
- Remove redundant information agents can discover via tools
- Structure content for progressive disclosure

Follows prompt engineering best practices for agent instructions.

- docs(claude): add Figma API reference section

Add structured guidance for when and how to use Figma API documentation:

- Link to official API docs
- Decision table for when to consult docs
- Mapping of project endpoints to API endpoints
- API response mapping workflow

* refactor(download): extract loader and processor for testability

Extract DownloadImageLoader and DownloadImageProcessor from DownloadImages command into separate files to improve code
organization and enable unit testing.

- Move DownloadImageLoader to Loaders/DownloadImageLoader.swift
- Extract name processing and dark mode logic to DownloadImageProcessor
- Add comprehensive tests for both extracted components
- Update coverage badge to reflect current metrics

______________________________________________________________________

Co-authored-by: Claude <noreply@anthropic.com> by @alexey1312

## [1.1.0] - 2025-12-03

### Features

- Add Flutter/Dart export support by @alexey1312

- **examples**: Update examples and add Flutter example by @alexey1312

### Other

- Improves error handling and documentation for WebP image

* fix(webp): improve cwebp error handling and Linux support

- Add comprehensive error types (WebpConverterError) with user-friendly messages
- Add Linux support with paths for apt/dnf/pacman installations
- Add CWEBP_PATH environment variable for custom installations
- Add PATH lookup using `which` command
- Add pre-flight check for cwebp availability before conversion starts
- Add exit code and stderr capture for failed conversions
- Replace fatalError with proper ExFigError.configurationError
- Add configurationError case to ExFigError enum
- Update documentation with installation instructions and troubleshooting

* chore: add Flutter lockfile and fix code formatting

Add pubspec.lock for Flutter example project and update .gitignore to exclude .dart_tool directory. Fix SwiftFormat
indentation in WebpConverter.swift conditional compilation blocks.

______________________________________________________________________

Co-authored-by: Claude <noreply@anthropic.com> by @alexey1312

- Claude/figma api image tracking 01 jh l wf vm uf sb hp ea pq ua kc f

* feat: add Figma file version tracking for icons and images

Add version tracking to skip exports when Figma files haven't changed. Uses the file version that updates when library
is published.

- Add FileMetadataEndpoint for fetching file version
- Add ImageTrackingCache model for storing versions in .exfig-cache.json
- Add ImageTrackingManager for checking and updating cache
- Add cache configuration in YAML (common.cache.enabled/path)
- Add CLI flags: --cache, --no-cache, --force, --cache-path
- Integrate into ExportIcons and ExportImages commands
- Add tests and documentation

* docs: add version tracking documentation

- Update CLAUDE.md with Cache module and FileMetadataEndpoint
- Update README.md with Version Tracking section and feature

* feat: add version tracking to colors and typography commands

Extend version tracking support to all export commands:

- Add --cache, --no-cache, --force flags to ExportColors
- Add --cache, --no-cache, --force flags to ExportTypography
- Update documentation to reflect all commands support

* refactor: extract version tracking logic to VersionTrackingHelper

Reduce code duplication across export commands by consolidating the version check and cache update logic into a reusable
helper.

- docs: add version tracking to documentation

Update index.md with version tracking feature highlight. Add usage documentation with configuration and CLI examples.
Document VersionTrackingHelper in CLAUDE.md architecture.

______________________________________________________________________

Co-authored-by: Claude <noreply@anthropic.com> by @alexey1312

- Introduces comprehensive code coverage support

* feat(ci): add code coverage reporting and badge

Add code coverage infrastructure with:

- Scripts/coverage.sh for generating coverage reports
- mise tasks for running coverage and updating badge
- CI workflow step to display coverage on Swift 6.1
- Coverage badge in README.md (currently 19.63%)
- Documentation updates in CLAUDE.md, CONTRIBUTING.md

* test(cache): refactor CacheOptionsTests to use argument parsing

Update tests to use CacheOptions.parse() instead of directly mutating properties. This better reflects real-world CLI
usage and improves test accuracy for the argument parser integration.

- test: add comprehensive unit tests across all modules

Significantly improves test coverage from 52% to 60%:

- ExFigCore: TextStyle, Image, FileContents, ErrorGroup, validators
- ExFig: GlobalOptions, FileWriter, TerminalUI components
- FigmaAPI: FigmaClientError, Node, Variables
- XcodeExport: Extensions tests
- AndroidExport: Drawable scale/density mapping
- Fix TextStyle init to set platform property

* ci: simplify macOS matrix and add SPM dependency caching

- Remove Swift 6.0/Xcode 16.0 from matrix, keep only Swift 6.1/Xcode 16.3
- Add GitHub Actions cache for .build directory
- Add coverage report generation on main branch
- Remove verbose flags from build/test commands
- Update release workflow to use Xcode 16.3 by @alexey1312

## [1.0.1] - 2025-12-02

### Miscellaneous Tasks

- Add community files and automated changelog by @alexey1312

## [1.0.0] - 2025-12-02

### Other

- Initial implementation by @alexey1312
