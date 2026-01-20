# Changelog

All notable changes to this project will be documented in this file.

## [1.2.28] - 2026-01-20

### Bug Fixes

- **batch**: Initialize strictPathValidation in ExportIcons by @alexey1312


### Miscellaneous Tasks

- Add .xcsift.toml by @alexey1312


## [1.2.27] - 2026-01-19

### Features

- **android**: Add xmlDisabled option for Compose-only projects by @alexey1312


## [1.2.26] - 2026-01-19

### Bug Fixes

- **export**: Sort assets alphabetically for stable output by @alexey1312


## [1.2.25] - 2026-01-19

### Features

- **android**: Add colorKotlin config for custom Compose output path by @alexey1312


## [1.2.24] - 2026-01-15

### Features

- **flutter**: Add hc colors supported by @alexey1312

- **flutter**: Update image by @alexey1312

- **flutter**: Add image name style by @alexey1312


## [1.2.23] - 2026-01-15

### Bug Fixes

- **xcode**: Sort CodeConnect assets for stable output by @alexey1312


## [1.2.22] - 2026-01-14

### Bug Fixes

- **xcode**: Sort CodeConnect assets for stable output by @alexey1312


## [1.2.21] - 2026-01-13

### Features

- **android**: Add pathData validation for VectorDrawables by @alexey1312


### Miscellaneous Tasks

- **hooks**: Migrate git hooks to tracked .githooks directory by @alexey1312


## [1.2.20] - 2026-01-13

### Features

- **SVGKit**: Add fill-opacity support and shape transforms by @alexey1312


## [1.2.19] - 2026-01-12

### Documentation

- Split CLAUDE.md into modular rules files by @alexey1312


### Features

- **core**: Add AssetMetadata for Code Connect generation by @alexey1312


## [1.2.18] - 2026-01-11

### Bug Fixes

- **ci**: Add xcsift install path to PATH on Linux  by @alexey1312 in [#45](https://github.com/alexey1312/ExFig/pull/45)


### Features

- **ios**: Add codeSyntax sync to Figma Variables by @alexey1312

- **core**: Add Hashable conformance to ImagePack by @alexey1312


### Miscellaneous Tasks

- **mise**: Update to 2026.1.1 by @alexey1312

- **ci**: Update workflow by @alexey1312


## [1.2.17] - 2026-01-09

### Features

- **cli**: Improve init command next steps guidance  by @google-labs-jules[bot] in [#24](https://github.com/alexey1312/ExFig/pull/24)

- Add confirmation prompt before overwriting config file in `exfig init`  by @google-labs-jules[bot] in [#26](https://github.com/alexey1312/ExFig/pull/26)

- **ios**: Add Figma Code Connect generation for icons and images  by @alexey1312 in [#44](https://github.com/alexey1312/ExFig/pull/44)


### Miscellaneous Tasks

- **tooling**: Simplify mise tool definitions by @alexey1312

- Remove unused .jules agent journal files by @alexey1312


### Other

- 🎨 Palette: Improve Update Notification UX 

* feat(cli): ✨ improve update notification UX

Enhanced the update notification message with a colorful box design using box-drawing characters. The new design highlights the new version and download link, making it more noticeable and pleasant. Falls back to plain text when colors are disabled.

- Updated `Sources/ExFig/Subcommands/checkForUpdate.swift` to use `Rainbow` and `TTYDetector`.
- Updated `.Jules/palette.md` with critical learnings.

* feat(cli): ✨ improve update notification UX

Enhanced the update notification message with a colorful box design using box-drawing characters. The new design highlights the new version and download link, making it more noticeable and pleasant. Falls back to plain text when colors are disabled.

- Updated `Sources/ExFig/Subcommands/checkForUpdate.swift` to use `Rainbow` and `TTYDetector`.
- Updated `.Jules/palette.md` with critical learnings.

* feat(cli): ✨ improve update notification UX

Enhanced the update notification message with a colorful box design using box-drawing characters. The new design highlights the new version and download link, making it more noticeable and pleasant. Falls back to plain text when colors are disabled.

- Updated `Sources/ExFig/Subcommands/checkForUpdate.swift` to use `Rainbow` and `TTYDetector`.
- Updated `.Jules/palette.md` with critical learnings.

* feat(cli): ✨ improve update notification UX

Enhanced the update notification message with a colorful box design using box-drawing characters. The new design highlights the new version and download link, making it more noticeable and pleasant. Falls back to plain text when colors are disabled.

- Updated `Sources/ExFig/Subcommands/checkForUpdate.swift` to use `Rainbow` and `TTYDetector`.
- Updated `.Jules/palette.md` with critical learnings.

---------

Co-authored-by: google-labs-jules[bot] <161369871+google-labs-jules[bot]@users.noreply.github.com> by @google-labs-jules[bot] in [#22](https://github.com/alexey1312/ExFig/pull/22)

- ⚡ Bolt: Optimize SVG path parsing using UTF8View 

* feat: Optimize SVG path parsing performance

- Replaced `String` character iteration with `String.UTF8View` in `PathScanner` to avoid Unicode overhead.
- Implemented byte-level scanning for SVG commands, numbers, and whitespace.
- Reduced parsing time by approximately 25% in benchmark tests.
- Maintained existing functionality and test coverage.
- Optimized for ASCII-based SVG path data processing.

* feat: Optimize SVG path parsing performance

- Replaced `String` character iteration with `String.UTF8View` in `PathScanner` to avoid Unicode overhead.
- Implemented byte-level scanning for SVG commands, numbers, and whitespace.
- Reduced parsing time by approximately 25% in benchmark tests.
- Maintained existing functionality and test coverage.
- Optimized for ASCII-based SVG path data processing.

* feat: Optimize SVG path parsing performance

---------

Co-authored-by: google-labs-jules[bot] <161369871+google-labs-jules[bot]@users.noreply.github.com>
Co-authored-by: alexey1312 <alexey1312ru@gmail.com> by @google-labs-jules[bot] in [#25](https://github.com/alexey1312/ExFig/pull/25)


## [1.2.16] - 2025-12-30

### Bug Fixes

- **svg**: Preserve element order and support gradientTransform by @alexey1312


### Documentation

- **openspec**: Add ExFig Studio GUI app proposal by @alexey1312


### Features

- **svg**: Add Tree Traversal API support via swift-resvg upgrade  by @alexey1312 in [#19](https://github.com/alexey1312/ExFig/pull/19)


### Other

- ⚡ Bolt: Implement dynamic concurrency in SharedDownloadQueue  by @google-labs-jules[bot] in [#18](https://github.com/alexey1312/ExFig/pull/18)

- 🛡️ Sentinel: Fix XXE vulnerability in SVG parser 

* feat(security): disable external entity loading in SVG parser

- Initializes `XMLDocument` with `.nodeLoadExternalEntitiesNever` in `SVGParser.swift`.
- Prevents XML External Entity (XXE) attacks when parsing untrusted SVG files.
- Hardens the codebase against local file inclusion and SSRF vulnerabilities via malicious SVGs.

* feat(security): disable external entity loading in SVG parser

- Initializes `XMLDocument` with `.nodeLoadExternalEntitiesNever` in `SVGParser.swift`.
- Prevents XML External Entity (XXE) attacks when parsing untrusted SVG files.
- Hardens the codebase against local file inclusion and SSRF vulnerabilities via malicious SVGs.
- Verified `XMLDocument` usage across the codebase; `FileWriter.swift` only writes XML and is safe.

* feat(security): disable external entity loading in SVG parser

- Initializes `XMLDocument` with `.nodeLoadExternalEntitiesNever` in `SVGParser.swift`.
- Prevents XML External Entity (XXE) attacks when parsing untrusted SVG files.
- Hardens the codebase against local file inclusion and SSRF vulnerabilities via malicious SVGs.
- Verified `XMLDocument` usage across the codebase; `FileWriter.swift` only writes XML and is safe.

* feat(security): disable external entity loading in SVG parser

- Initializes `XMLDocument` with `.nodeLoadExternalEntitiesNever` in `SVGParser.swift`.
- Prevents XML External Entity (XXE) attacks when parsing untrusted SVG files.
- Hardens the codebase against local file inclusion and SSRF vulnerabilities via malicious SVGs.
- Verified `XMLDocument` usage across the codebase; `FileWriter.swift` only writes XML and is safe.
- Verified `parse(contentsOf:)` delegates to the patched method.

---------

Co-authored-by: google-labs-jules[bot] <161369871+google-labs-jules[bot]@users.noreply.github.com> by @google-labs-jules[bot] in [#21](https://github.com/alexey1312/ExFig/pull/21)


### Performance

- **cache**: Parallelize hash computation + improve Sendable safety by @alexey1312


### Refactor

- **queue**: Add LRU eviction for unclaimed results + MigrateTests by @alexey1312

- **colors**: Decompose ExportColors.swift into platform files by @alexey1312


### Testing

- **cache**: Add tests for parallel hashing and LRU eviction by @alexey1312


## [1.2.15] - 2025-12-27

### Bug Fixes

- **svg**: Preserve fill on shape elements in groups by @alexey1312


### Documentation

- Use portable ./bin/mise paths in CLAUDE.md by @alexey1312


## [1.2.14] - 2025-12-26

### Bug Fixes

- **android**: Skip SVG conversion for missing temp dirs by @alexey1312

- **svg**: Handle missing fill default and clip-path inheritance by @alexey1312

- **svg**: Convert mask elements to clip-path for Figma flags by @alexey1312


### Documentation

- Update Swift version and clarify platform support by @alexey1312


### Features

- **icons**: Add per-entry regex and nameStyle fields by @alexey1312

- **svg**: Add usvg normalization before parsing by @alexey1312

- **android**: Parallelize SVG to vector drawable conversion by @alexey1312


### Miscellaneous Tasks

- Use mise-action for environment setup by @alexey1312

- Bump minimum macOS version from 12.0 to 13.0 by @alexey1312

- Add xcsift filtering and fix shell quoting by @alexey1312

- **dev**: Add actionlint for GitHub Actions linting by @alexey1312

- Pipe Linux build/test output through xcsift by @alexey1312

- Pipe Linux build/test output through xcsift by @alexey1312

- Pipe Linux build/test output through xcsift by @alexey1312

- Pipe Linux build/test output through xcsift by @alexey1312


### Testing

- **icons**: Add nameStyle to iOS IconsEntry test fixtures by @alexey1312

- **ci**: Relax timing thresholds and image size for CI stability by @alexey1312


## [1.2.13] - 2025-12-24

### Miscellaneous Tasks

- Use swift:6.2-jammy image and fix tar archive paths by @alexey1312


## [1.2.12] - 2025-12-24

### Miscellaneous Tasks

- **release**: Use swift:6.2-jammy image for Linux builds by @alexey1312


## [1.2.11] - 2025-12-24

### Bug Fixes

- **batch**: Clear node hashes for all files with --force flag by @alexey1312


## [1.2.10] - 2025-12-24

### Bug Fixes

- **core**: Preserve number placement in case conversions by @alexey1312


### Miscellaneous Tasks

- **mise**: Forward GitHub token to avoid API rate limits by @alexey1312


### Other

- Merge branch 'main' of github.com:alexey1312/ExFig by @alexey1312


## [1.2.9] - 2025-12-24

### Documentation

- Fix installation instructions  by @alexey1312 in [#17](https://github.com/alexey1312/ExFig/pull/17)


### Features

- **ios**: Add renderMode support and fix case mismatch by @alexey1312

- **batch**: Add incremental progress reporting for downloads by @alexey1312


## [1.2.8] - 2025-12-21

### Bug Fixes

- **ios**: Handle HEIC export for large SVG files by @alexey1312

- **ios**: Clean up old format files when switching PNG/HEIC by @alexey1312

- **heic**: Use straight alpha and document lossless limitation by @alexey1312


### Documentation

- Update key directories after export refactoring by @alexey1312


### Refactor

- **icons**: Extract iOS export and shared helpers by @alexey1312

- **exports**: Extract platform-specific export files by @alexey1312

- **images**: Extract WebP converter factory by @alexey1312

- **images**: Extract HEIC converter factory by @alexey1312


## [1.2.7] - 2025-12-20

### Bug Fixes

- **ios**: Write PNG files before HEIC conversion by @alexey1312

- **android**: Delete source PNGs after WebP/HEIC conversion by @alexey1312

- **core**: Handle URL type differences in Destination.url by @alexey1312


### Refactor

- **ios**: Use destination.directory for imageset path by @alexey1312


## [1.2.6] - 2025-12-20

### Documentation

- **config**: Document SVG source format and clarify config formats by @alexey1312


### Miscellaneous Tasks

- **release**: Fix universal binary build for macOS by @alexey1312


### Other

- Replace vendored resvg with swift-resvg package 

* build(swift): update to Swift 6.2.3

- Bump swift-tools-version to 6.2
- Add .swift-version file for tooling
- Remove unnecessary await on actor-isolated method

* ci: use swiftly-action for Swift toolchain management

Replace hardcoded Xcode paths and manual Swift version selection with vapor/swiftly-action for consistent Swift 6.2.3 toolchain across macOS workflows. Update Linux container to swift:6.2.

* build(deps): replace vendored resvg with swift-resvg package

* ci: improve SPM cache and add clean tasks

Add Package.swift to cache key for better invalidation when
dependencies change. Add SPM cache step to Linux build job.
Add mise tasks for cleaning build artifacts and all caches.

* build(deps): update mise to 2025.12.12

* Disable GitHub attestations in mise.toml by @alexey1312 in [#15](https://github.com/alexey1312/ExFig/pull/15)

- Add HEIC output format for iOS images 

* docs(images): add HEIC conversion research and implementation plan

Research findings for iOS HEIC image export:
- Xcode asset catalogs support HEIC since Xcode 10.1
- Apple ImageIO provides native encoding on macOS (not Linux)
- libheif is cross-platform but has GPL licensing (x265)
- Recommended: Phase 1 with macOS-only ImageIO approach

* docs(web): archive web spec

* docs(images): add HEIC conversion research and implementation plan

* docs(images): add HEIC conversion research and implementation plan

* feat(images): add HEIC output format for iOS images

Add HEIC encoding support for iOS image exports using native ImageIO.
HEIC provides ~40-50% smaller file sizes than PNG while maintaining
full transparency support.

- Add NativeHeicEncoder for RGBA → HEIC encoding (macOS only)
- Add SvgToHeicConverter for SVG → HEIC pipeline via resvg
- Add HeicConverter for batch PNG → HEIC conversion
- Support both lossy and lossless encoding modes with quality control
- Gracefully fall back to PNG on Linux with warning
- Update Xcode asset catalog export to reference .heic files
- Add outputFormat and heicOptions config parameters for iOS images

---------

Co-authored-by: Claude <noreply@anthropic.com> by @alexey1312 in [#16](https://github.com/alexey1312/ExFig/pull/16)


## [1.2.6-beta.2] - 2025-12-19

### Other

- **resvg**: Switch from dynamic to static library linking by @alexey1312


## [1.2.6-beta.1] - 2025-12-19

### Features

- **images**: Add SVG source format with local rasterization via resvg  by @alexey1312 in [#13](https://github.com/alexey1312/ExFig/pull/13)


### Miscellaneous Tasks

- **release**: Add pre-release tag support by @alexey1312


## [1.2.5] - 2025-12-18

### Bug Fixes

- **cli**: Keep numbers with letters in case conversion by @alexey1312


### Testing

- **timing**: Increase delays and thresholds for CI stability by @alexey1312


## [1.2.4] - 2025-12-18

### Bug Fixes

- **images**: Use native libwebp for lossless WebP encoding by @alexey1312


## [1.2.3] - 2025-12-16

### Bug Fixes

- **android**: Standardize theme attrs file paths with ".." components by @alexey1312

- **android**: Standardize theme attrs file paths with ".." components by @alexey1312


## [1.2.2] - 2025-12-16

### Features

- **android**: Expose Kotlin hex values in Compose color template by @alexey1312


## [1.2.1] - 2025-12-16

### Features

- **android**: Add theme attributes export for colors by @alexey1312


### Miscellaneous Tasks

- **templates**: Remove trailing newlines from stencil files by @alexey1312


## [1.2.0] - 2025-12-14

### Features

- **cli**: Add migrate command for figma-export configs by @alexey1312


### Miscellaneous Tasks

- **tooling**: Reorganize format tasks with parallel execution by @alexey1312

- **tooling**: Migrate from pre-commit to hk for git hooks by @alexey1312


### Other

- Modify CI workflow for Swift and Markdown formatting

Updated CI workflow to check formatting for Swift and Markdown, removed separate markdown formatting check. by @alexey1312

- Add web 

* feat(openspec): add web platform export proposal

Proposal to extend ExFig with native Web/React support:
- CSS variables and TypeScript constants for colors
- React TSX components via SVGR pattern for icons
- Raw SVG/PNG asset export with barrel index files
- New WebExport module following FlutterExport patterns

* feat(web): add web platform export support

* feat(web): add SVG to JSX converter for React components

* feat(web): add SVG to JSX converter for React components by @alexey1312


## [1.1.3] - 2025-12-11

### Documentation

- **docc**: Migrate documentation from GitHub docs to DocC by @alexey1312


### Features

- **batch**: Add nodes and components pre-fetch for granular cache by @alexey1312


## [1.1.2] - 2025-12-09

### Bug Fixes

- **cache**: Sort children by name for stable granular cache hashing by @alexey1312


### Miscellaneous Tasks

- **release**: Add static Swift stdlib for Linux builds by @alexey1312


## [1.1.1] - 2025-12-09

### Features

- **icons**: Ensure light/dark pairs export together with granular cache by @alexey1312


## [1.1.0] - 2025-12-09

### Other

- Update batch 

* feat(batch): add pipelined download queue for parallelism

Introduce SharedDownloadQueue to coordinate CDN downloads across
parallel configs in batch mode. Downloads are prioritized by config
submission order and processed with shared concurrency pool.

- Add DownloadJob/DownloadJobResult for batch coordination
- Add PipelinedDownloader helper with TaskLocal injection
- Add SharedDownloadQueueStorage for config-level context
- Update BatchConfigRunner to inject queue and priority
- Update ExportIcons/ExportImages to use PipelinedDownloader
- Scale total download slots by parallel workers count

Benefits: eliminates per-config download bottlenecks, improves
throughput in multi-config batch runs, maintains FIFO ordering.

* feat(batch): add rich progress view with ETA and status

- Add BatchProgressView integration with per-config status tracking
- Calculate and display ETA based on export progress
- Coordinate UI suppression via BatchProgressViewStorage TaskLocal
- Clear/redraw progress display for log/error output
- Update rate limiter status every 500ms during execution
- Suppress spinners and progress bars in batch mode to prevent corruption

* feat(batch): centralize update check to end of batch

Suppress individual update checks during batch exports and check once
after all configs complete. by @alexey1312


## [1.0.8] - 2025-12-09

### Documentation

- **batch**: Clarify granular cache merge sequence by @alexey1312


### Features

- **batch**: Add shared granular cache for parallel configs by @alexey1312


## [1.0.7] - 2025-12-08

### Bug Fixes

- **release**: Use v-prefixed version format consistently by @alexey1312


## [1.0.6] - 2025-12-08

### Features

- **svg**: Add CSS styles, use/symbol refs, stroke-dasharray parsing by @alexey1312

- **cli**: Add --timeout flag for API request timeout override by @alexey1312

- **cache**: Add granular node-level cache tracking  by @alexey1312


## [1.0.5] - 2025-12-07

### Features

- **terminal**: Add unified warning types with TOON formatting by @alexey1312

- **terminal**: Add unified error formatting with recovery suggestions by @alexey1312

- **batch**: Pre-fetch file versions for cache-enabled batch runs by @alexey1312


## [1.0.4] - 2025-12-07

### Bug Fixes

- **batch**: Skip unconfigured asset types and simplify output by @alexey1312


### Miscellaneous Tasks

- **release**: Use git-cliff for release notes generation by @alexey1312


## [1.0.3] - 2025-12-07

### Bug Fixes

- **api**: Increase default retry base delay to 3 seconds by @alexey1312


### Documentation

- **oxipng**: Update doc to oxipng by @alexey1312


### Features

- **batch**: Add cache and concurrency options to batch command by @alexey1312


## [1.0.2] - 2025-12-06

### Bug Fixes

- **cli**: Improve help text and add version to main command by @alexey1312


### Miscellaneous Tasks

- **release**: Use v-prefixed tags for mise/ubi compatibility by @alexey1312


## [1.0.1] - 2025-12-06

### Miscellaneous Tasks

- **release**: Rename binary from exfig to ExFig in dist by @alexey1312


## [1.0.0] - 2025-12-06

### Features

- Complete ExFig implementation by @alexey1312



