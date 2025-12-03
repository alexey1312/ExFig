# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Changed

- **webp**: Replace external cwebp binary with native libwebp library
  - WebP conversion now works out of the box with no external tools required
  - `CWEBP_PATH` environment variable is deprecated and no longer used
  - Improved cross-platform support (macOS, Linux)

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
