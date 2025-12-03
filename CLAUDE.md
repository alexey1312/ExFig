<!-- OPENSPEC:START -->

# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:

- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:

- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ExFig is a command-line utility that exports colors, typography, icons, and images from Figma to Xcode, Android Studio,
and Flutter projects. It supports Dark Mode, SwiftUI, UIKit, Jetpack Compose, Flutter/Dart, high contrast colors, and
Figma Variables.

### Key Features

- Export light & dark color palettes
- High contrast color support (iOS)
- Icons and images with Dark Mode variants
- Typography with Dynamic Type support (iOS)
- SwiftUI and UIKit support
- Jetpack Compose support
- Flutter / Dart support
- RTL (Right-to-Left) layout support
- Figma Variables support
- File version tracking (skip exports when unchanged)

## Requirements

- Swift 6.0+
- macOS 12.0+
- Figma Personal Access Token (set as `FIGMA_PERSONAL_TOKEN` environment variable)

## Build and Test Commands

The project uses a self-contained `./bin/mise` bootstrap binary. No global mise installation required. You can use
either `mise run <task>` or `./bin/mise run <task>` — both work identically.

```bash
# Build the project
mise run build

# Run all tests
mise run test

# Run a specific test target
mise run test:filter ExFigTests
mise run test:filter ExFigCoreTests
mise run test:filter XcodeExportTests
mise run test:filter AndroidExportTests
mise run test:filter FigmaAPITests
mise run test:filter SVGKitTests
mise run test:filter FlutterExportTests

# Code coverage
mise run coverage           # Run tests and show coverage report
mise run coverage:badge     # Update coverage badge in README.md

# Lint code
mise run lint

# Format code
mise run format

# Check formatting (CI mode)
mise run format-check

# Format markdown files
mise run format-md

# Check markdown formatting (CI mode)
mise run format-md-check

# Setup pre-commit hooks (run once after cloning)
mise run setup

# Run pre-commit on all files
mise run pre-commit

# Build release binary
mise run build:release

# Run the CLI (after building)
.build/debug/exfig --help
.build/release/exfig colors                    # Auto-detects figma-export.yaml or exfig.yaml
.build/release/exfig colors -i config.yaml     # Use custom config path
.build/release/exfig icons
.build/release/exfig images
.build/release/exfig typography                # Also available as 'text-styles'
.build/release/exfig text-styles               # Alias for typography (figma-export compatibility)

# Run with verbose output (detailed debug information)
.build/release/exfig colors --verbose

# Run with quiet output (errors only)
.build/release/exfig icons --quiet
```

## Architecture

The codebase is organized as a Swift Package with seven main modules:

### Modules

#### ExFig (`Sources/ExFig/`)

Main executable target with CLI commands.

- `ExFigCommand.swift` - Root command using swift-argument-parser
- `Subcommands/` - Individual commands:
  - `ExportColors.swift` - Export color palettes
  - `ExportIcons.swift` - Export icons
  - `ExportImages.swift` - Export images
  - `ExportTypography.swift` - Export text styles
  - `GenerateConfigFile.swift` - Generate starter config (`exfig init`)
  - `checkForUpdate.swift` - Version checking
- `Loaders/` - Load data from Figma API:
  - `Colors/ColorsLoader.swift` - Load color styles
  - `Colors/ColorsVariablesLoader.swift` - Load Figma Variables
  - `ImagesLoader.swift` - Load images
  - `TextStylesLoader.swift` - Load text styles
- `Input/` - Configuration parsing:
  - `ExFigOptions.swift` - YAML configuration model (via Yams)
  - `Params.swift` - Command parameters
  - `GlobalOptions.swift` - Global CLI flags (`--verbose`, `--quiet`)
  - `CacheOptions.swift` - CLI flags for version tracking (`--cache`, `--no-cache`, `--force`)
- `Cache/` - Version tracking for incremental exports:
  - `ImageTrackingCache.swift` - Cache model for storing file versions
  - `ImageTrackingManager.swift` - Manages version checking and cache updates
  - `VersionTrackingHelper.swift` - Shared helper for version tracking in export commands
- `TerminalUI/` - Terminal output and progress indicators:
  - `TerminalUI.swift` - Main facade for terminal output
  - `Spinner.swift` - Animated spinner actor
  - `ProgressBar.swift` - Progress bar with percentage/ETA
  - `MultiProgressManager.swift` - Concurrent progress management
  - `OutputMode.swift` - Output modes (normal, verbose, quiet, plain)
  - `TTYDetector.swift` - TTY detection for CI/pipe fallback
  - `ANSICodes.swift` - ANSI escape sequences for cursor control
  - `ExFigLogHandler.swift` - Custom swift-log handler
- `Output/` - Write exported files to disk:
  - `FileWriter.swift` - Generic file writing
  - `FileDownloader.swift` - Download assets from Figma
  - `XcodeProjectWriter.swift` - Xcode project manipulation
  - `WebpConverter.swift` - Convert images to WebP
- `Resources/` - Default configuration templates

#### ExFigCore (`Sources/ExFigCore/`)

Shared domain models and utilities.

- Core types:
  - `Color.swift` - Color model
  - `Image.swift` - Image model
  - `TextStyle.swift` - Typography model
  - `Asset.swift` - Generic asset model
  - `AssetPair.swift` - Light/dark asset pair
  - `Platform.swift` - Platform enumeration (iOS/Android)
  - `NameStyle.swift` - Naming convention styles
  - `XcodeRenderMode.swift` - Asset rendering modes
- `Processor/` - Transform Figma data to export-ready models:
  - `AssetsProcessor.swift` - Process assets
  - `AssetResult.swift` - Processing results
  - `AssetsValidatorError.swift` - Validation errors
  - `AssetsValidatorWarning.swift` - Validation warnings
  - `AssetsFilter.swift` - Filter assets
- `Extensions/` - Utilities:
  - `StringCase.swift` - String case conversion (camelCase, snake_case, etc.)
  - `SwiftReplace.swift` - Swift identifier sanitization
  - `Array+chunked.swift` - Array chunking
  - `Double+fixFloatingPoint.swift` - Floating point precision
- `Helpers/` - Helper utilities

#### FigmaAPI (`Sources/FigmaAPI/`)

Figma REST API client.

- `Client.swift` - HTTP client implementation
- `FigmaClient.swift` - Figma-specific client
- `GitHubClient.swift` - GitHub releases client
- `Endpoint/` - API endpoint definitions:
  - `BaseEndpoint.swift` - Base endpoint protocol
  - `Endpoint.swift` - Main endpoint implementations
  - `ComponentsEndpoint.swift` - Components API
  - `NodesEndpoint.swift` - Nodes API
  - `StylesEndpoint.swift` - Styles API
  - `ImageEndpoint.swift` - Image export API
  - `VariablesEndpoint.swift` - Variables API
  - `FileMetadataEndpoint.swift` - File metadata API (version tracking)
  - `LatestReleaseEndpoint.swift` - GitHub releases API
- `Model/` - API response models:
  - `Node.swift` - Figma node models
  - `Style.swift` - Figma style models
  - `Variables.swift` - Figma Variables models
  - `FigmaClientError.swift` - Error types

#### XcodeExport (`Sources/XcodeExport/`)

Export to Xcode/iOS projects.

- Generates `.xcassets` colorsets and imagesets
- Generates Swift extensions for UIKit and SwiftUI
- Uses Stencil templates in `Resources/` directory
- Exporters:
  - `XcodeColorExporter.swift` - Color export
  - `XcodeIconsExporter.swift` - Icon export
  - `XcodeImagesExporter.swift` - Image export
  - `XcodeTypographyExporter.swift` - Typography export
  - `XcodeExporterBase.swift` - Base exporter
  - `XcodeImagesExporterBase.swift` - Base image exporter
- Model types:
  - `XcodeColorsOutput.swift` - Color output
  - `XcodeImagesOutput.swift` - Image output
  - `XcodeTypographyOutput.swift` - Typography output
  - `XcodeAssetContents.swift` - Asset catalog contents
  - `XcodeEmptyContents.swift` - Empty asset folder
  - `XcodeFolderNamespaceContents.swift` - Namespace folder
  - `XcodeExportExtensions.swift` - Export extensions

#### SVGKit (`Sources/SVGKit/`)

SVG parsing and code generation library.

- `SVGParser.swift` - Parses SVG files into structured models
- `SVGPathParser.swift` - Parses SVG path data commands
- `SVGTypes.swift` - SVG transform and group types
- `ImageVectorGenerator.swift` - Generates Jetpack Compose ImageVector code
- `VectorDrawableXMLGenerator.swift` - Generates Android Vector Drawable XML
- `NativeVectorDrawableConverter.swift` - Converts SVG files to Vector Drawable XML

#### AndroidExport (`Sources/AndroidExport/`)

Export to Android projects.

- Generates XML resources (colors.xml, typography.xml)
- Generates vector drawables and raster images (uses SVGKit for conversion)
- Generates Kotlin code for Jetpack Compose
- Uses Stencil templates in `Resources/` directory
- Exporters:
  - `AndroidColorExporter.swift` - Color export
  - `AndroidTypographyExporter.swift` - Typography export
  - `AndroidComposeIconExporter.swift` - Compose icon export
  - `AndroidExporter.swift` - Main Android exporter
- `Drawable.swift` - Drawable utilities
- Model types:
  - `AndroidOutput.swift` - Export output model

#### FlutterExport (`Sources/FlutterExport/`)

Export to Flutter projects.

- Generates Dart code for colors, icons, and images
- Generates SVG icon assets
- Generates multi-scale PNG/WebP image assets (1x, 2x, 3x)
- Uses Stencil templates in `Resources/` directory
- Exporters:
  - `FlutterColorExporter.swift` - Color export (Color class with hex format)
  - `FlutterIconsExporter.swift` - Icons export (SVG assets + Dart constants)
  - `FlutterImagesExporter.swift` - Images export (multi-scale + Dart constants)
  - `FlutterExporter.swift` - Base exporter class
- Model types:
  - `FlutterOutput.swift` - Export output configuration

### Data Flow

1. CLI command parses `exfig.yaml` configuration (YAML format via Yams)
2. Command validates configuration and checks for required Figma token
3. FigmaAPI fetches design data from Figma REST API (requires `FIGMA_PERSONAL_TOKEN` env var)
4. ExFigCore processes Figma data into platform-agnostic models
5. XcodeExport, AndroidExport, or FlutterExport generates platform-specific assets and code using Stencil templates
6. FileWriter writes generated files to disk
7. XcodeProjectWriter updates Xcode project files (if configured)

### Key Dependencies

All dependencies are managed via Swift Package Manager in `Package.swift`:

- **swift-argument-parser** (1.5.0+): CLI framework for command parsing
- **Yams** (5.3.0+): YAML configuration parsing
- **Stencil** (0.15.1+): Template engine for code generation
- **StencilSwiftKit** (2.10.1+): Swift-specific Stencil extensions
- **XcodeProj** (8.27.0+): Xcode project manipulation
- **swift-log** (1.6.0+): Logging framework
- **swift-custom-dump** (1.3.0+): Test assertions and debugging
- **Rainbow** (4.2.0+): Terminal colors and styling

### Development Tools

Tools are managed via mise and defined in `mise.toml`:

- **swiftformat** (0.58.7): Code formatting
- **swiftlint** (0.62.2): Code linting
- **pre-commit** (4.5.0): Git pre-commit hooks
- **xcsift** (1.0.14): Swift build output formatting
- **mdformat** (0.7.22): Markdown formatting

## Configuration

All export options are configured via `exfig.yaml`. See [CONFIG.md](CONFIG.md) for the full specification. Example
configs are in `Examples/` directory:

- `Examples/Example/` - iOS UIKit project
- `Examples/ExampleSwiftUI/` - iOS SwiftUI project
- `Examples/AndroidExample/` - Android XML views
- `Examples/AndroidComposeExample/` - Android Jetpack Compose
- `Examples/FlutterExample/` - Flutter/Dart project

Generate a starter config:

```bash
exfig init -p ios
exfig init -p android
```

## Environment

- **FIGMA_PERSONAL_TOKEN** (required): Figma personal access token for API access
  - Get your token from [Figma developer settings](https://www.figma.com/developers/api#access-tokens)

## Recommended: Post-Export Image Optimization

For optimal file sizes, consider using [image_optim](https://github.com/toy/image_optim) to compress exported PNG, JPEG,
GIF, and SVG files after export:

```bash
# Install image_optim (Ruby gem)
gem install image_optim image_optim_pack

# Or via mise
mise use -g gem:image_optim gem:image_optim_pack

# Optimize exported images (lossless by default)
image_optim path/to/exported/images/**/*.png

# Enable lossy compression for smaller files
image_optim --allow-lossy path/to/exported/images/**/*.png
```

This is an optional post-processing step that can significantly reduce image file sizes without quality loss.

## Commit Message Format

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automatic changelog generation.

**Format:** `<type>(<scope>): <description>`

**Types:**

| Type | Description | |------|-------------| | `feat` | New feature | | `fix` | Bug fix | | `docs` | Documentation only
| | `refactor` | Code refactoring | | `perf` | Performance improvement | | `test` | Adding or updating tests | | `chore`
| Maintenance tasks | | `ci` | CI/CD changes |

**Examples:**

```bash
feat: add WebP image export support
fix(icons): handle SVG with missing viewBox
docs: update installation instructions
refactor(api): simplify Figma client error handling
```

**Common scopes:** `colors`, `icons`, `images`, `typography`, `api`, `cli`, `ios`, `android`

## Pre-Commit Requirements

Before creating any commit, the following must pass without errors:

```bash
mise run format      # Format Swift code with SwiftFormat
mise run format-md   # Format markdown files with mdformat
mise run lint        # Check for linting errors with SwiftLint
```

All commands must pass without errors before committing. Pre-commit hooks are configured in `.pre-commit-config.yaml`
and can be installed with `mise run setup`.

## Testing

Tests are organized by module:

- `Tests/ExFigTests/` - CLI command tests
- `Tests/ExFigCoreTests/` - Core model and processor tests
- `Tests/XcodeExportTests/` - Xcode export tests
- `Tests/AndroidExportTests/` - Android export tests
- `Tests/FlutterExportTests/` - Flutter export tests
- `Tests/SVGKitTests/` - SVG parsing and generation tests

Run tests with `mise run test` or target specific test suites with `swift test --filter <TargetName>`.

### Code Coverage

Use `mise run coverage` to view the current test coverage report. The coverage badge in README.md is updated manually
(not by CI). When test coverage changes significantly, update the badge locally:

```bash
mise run coverage:badge   # Updates README.md with current coverage percentage
```

**Important**: CI only displays coverage reports. Badge updates are done locally and committed with your changes.

## Code Style

- Swift code follows `.swiftformat` and `.swiftlint.yml` configurations
- Use SwiftFormat for automatic formatting
- Use SwiftLint for static analysis
- Follow Swift 6.0 concurrency and strict typing conventions
- Use meaningful variable names and avoid abbreviations
- Keep functions focused and modular

## Common Patterns

### Adding a New Export Platform

1. Create new module in `Sources/` (e.g., `FlutterExport`)
2. Implement exporter classes extending base protocols
3. Add Stencil templates in module's `Resources/` directory
4. Add configuration options to `ExFigOptions.swift`
5. Add new command to `Subcommands/`
6. Update `Package.swift` with new target
7. Add tests in `Tests/`

### Adding a New Figma API Endpoint

1. Create endpoint in `FigmaAPI/Endpoint/`
2. Extend `Endpoint` protocol
3. Add response models in `FigmaAPI/Model/`
4. Add client method in `FigmaClient.swift`
5. Add unit tests

### Modifying Generated Code

1. Locate Stencil template in `XcodeExport/Resources/`, `AndroidExport/Resources/`, or `FlutterExport/Resources/`
2. Modify template using Stencil syntax
3. Update corresponding output model if needed
4. Update tests with expected output
5. Run tests to verify changes

## Documentation

Full documentation is available in `.github/docs/`:

- Getting Started Guide
- Usage Guide
- iOS Export Documentation
- Android Export Documentation
- Design Requirements
- Configuration Reference
- Custom Templates Guide
- Development Guide

## Troubleshooting

- If builds fail, clean with `swift package clean` and rebuild
- If tests fail, check that `FIGMA_PERSONAL_TOKEN` is set
- If formatting fails, ensure SwiftFormat and mdformat are installed via `mise run setup`
- For Xcode project issues, verify XcodeProj dependency version
- For template issues, check Stencil syntax and context variables

## Contributing

See `.github/docs/development.md` for complete contribution guidelines.

## SwiftLint Rules

Common rules to remember:

- **`non_optional_string_data_conversion`**: Use `Data("string".utf8)` instead of `"string".data(using: .utf8)!`
- **`force_try`**: In tests, add `// swiftlint:disable:next force_try` before `try!` when needed

## Swift 6 Concurrency

When using `withThrowingTaskGroup`:

- Structs captured in `group.addTask` must conform to `Sendable`
- Use `[self]` capture for class methods and `[value]` for local variables
- Example pattern:

```swift
try await withThrowingTaskGroup(of: (Key, Value).self) { [self] group in
    for item in items {
        group.addTask { [item] in
            (item.key, try await self.process(item))
        }
    }
    var results: [Key: Value] = [:]
    for try await (key, value) in group {
        results[key] = value
    }
    return results
}
```

## Figma API Rate Limits

When making parallel requests to Figma API, respect rate limits:

- **Tier 1 endpoints** (Images, Components): 10-20 requests/minute depending on plan
- Use `maxConcurrentBatches = 3` for parallel batch requests (conservative default)
- Loaders use `withThrowingTaskGroup` with sliding window pattern for batch parallelization

## Test Helpers

For Codable-only structs without public init, create factory methods via JSON:

```swift
extension SomeType {
    static func make(param: String) -> SomeType {
        let json = "{\"param\": \"\(param)\"}"
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(SomeType.self, from: Data(json.utf8))
    }
}
```

## Linux Compatibility

The project builds and tests on Linux (CI uses GitHub Actions with Ubuntu). Key differences from macOS:

### FoundationNetworking Import

On Linux, networking types (`URLRequest`, `URLSession`, `URLResponse`, `HTTPURLResponse`) require importing
`FoundationNetworking`:

```swift
import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif
```

All files in `Sources/FigmaAPI/` already have this import. When adding new test files that use `URLRequest`, add the
conditional import.

### Unavailable or Different Foundation APIs

Some Foundation APIs behave differently or are unavailable on Linux:

- **`XMLDocument`** - Use conditional compilation in tests:

  ```swift
  #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
      XCTAssertNoThrow(try XMLDocument(xmlString: xml, options: []))
  #else
      // Fallback validation for Linux
      XCTAssertTrue(xml.hasPrefix("<?xml"))
  #endif
  ```

- **`XMLElement.elements(forName:)`** - Does not work correctly with default XML namespaces (`xmlns`) on Linux. Use
  manual iteration with `localName` instead:

  ```swift
  // Cross-platform helper function
  private func elementName(_ element: XMLElement) -> String? {
      element.localName ?? element.name
  }

  private func childElements(of element: XMLElement, named name: String) -> [XMLElement] {
      (element.children ?? []).compactMap { child -> XMLElement? in
          guard let childElement = child as? XMLElement,
                elementName(childElement) == name
          else { return nil }
          return childElement
      }
  }

  // Use instead of: element.elements(forName: "path")
  childElements(of: element, named: "path")
  ```

- **`XMLElement.attribute(forName:)`** - Returns `nil` when document has default `xmlns` namespace on Linux
  ([Issue #4943](https://github.com/swiftlang/swift-corelibs-foundation/issues/4943)). Use manual iteration:

  ```swift
  private func attributeValue(_ element: XMLElement, forName name: String) -> String? {
      // First try the standard method (works on macOS)
      if let value = element.attribute(forName: name)?.stringValue {
          return value
      }
      // Fallback: iterate through attributes manually (workaround for Linux)
      for attribute in element.attributes ?? [] {
          if attribute.name == name || attribute.localName == name {
              return attribute.stringValue
          }
      }
      return nil
  }
  ```

- **`stdout` global variable** - Direct access triggers Swift 6 concurrency warnings. Use `FileHandle` instead:

  ```swift
  // Instead of: fflush(stdout)
  try? FileHandle.standardOutput.synchronize()
  ```

- **`NSPredicate` with `LIKE` format** - Does not work on Linux. For wildcard pattern matching (e.g., `button/*`),
  convert to regex instead:

  ```swift
  // Instead of:
  // let pred = NSPredicate(format: "self LIKE %@", pattern)

  // Convert wildcard to regex:
  var regexPattern = NSRegularExpression.escapedPattern(for: pattern)
  regexPattern = regexPattern.replacingOccurrences(of: "\\*", with: ".*")
  regexPattern = "^" + regexPattern + "$"
  let regex = try? NSRegularExpression(pattern: regexPattern, options: [])
  let range = NSRange(string.startIndex..., in: string)
  return regex?.firstMatch(in: string, options: [], range: range) != nil
  ```

### Safe POSIX APIs

These work on both macOS and Linux:

- `isatty(STDOUT_FILENO)` - TTY detection
- `STDOUT_FILENO`, `STDERR_FILENO` - File descriptors
- `ProcessInfo.processInfo.environment` - Environment variables

### Running Tests on Linux

On Linux, run tests with parallelization disabled to avoid memory corruption issues:

```bash
# Recommended: run tests with single worker
swift test --parallel --num-workers 1

# Alternative: run tests without parallelization
swift test
```

**Why single worker?** Some tests involving libpng or concurrent Swift actors can cause memory corruption when running
in parallel on Linux. Using `--num-workers 1` ensures sequential execution within the parallel test framework.

### Installing Swift on Linux

To install Swift 6.0 on Ubuntu 24.04:

```bash
# Download Swift
wget -q https://download.swift.org/swift-6.0.3-release/ubuntu2404/swift-6.0.3-RELEASE/swift-6.0.3-RELEASE-ubuntu24.04.tar.gz -O /tmp/swift.tar.gz

# Extract and install
tar -xzf /tmp/swift.tar.gz -C /tmp
mv /tmp/swift-6.0.3-RELEASE-ubuntu24.04 ~/.local/swift

# Add to PATH (add to ~/.bashrc for persistence)
export PATH="$HOME/.local/swift/usr/bin:$PATH"

# Set SourceKit library path for SwiftLint
export LINUX_SOURCEKIT_LIB_PATH="$HOME/.local/swift/usr/lib"

# Verify installation
swift --version

# Configure mise environment (installs swiftformat, swiftlint, pre-commit, xcsift)
source Scripts/environment.sh
```

### libpng Limitations on Linux

The libpng simplified API has memory corruption issues on Linux when used in rapid succession. Tests that create PNG
files using libpng are skipped on Linux with `XCTSkip`:

```swift
func testSomePngOperation() throws {
    #if os(Linux)
        throw XCTSkip("Skipped on Linux due to libpng memory corruption issues")
    #endif
    // ... test code
}
```

**Affected tests:** WebpConverterTests that use `createTestPNG()` or `createCheckerboardPNG()` helpers.

### FileManager API Differences

- **`FileManager.replaceItemAt(_:withItemAt:)`** - Behaves differently on Linux (requires destination to exist). Use
  `copyItem(at:to:)` with explicit file removal instead:

  ```swift
  // Instead of:
  // try FileManager.default.replaceItemAt(destURL, withItemAt: sourceURL)

  // Use:
  if FileManager.default.fileExists(atPath: destURL.path) {
      try FileManager.default.removeItem(at: destURL)
  }
  try FileManager.default.copyItem(at: sourceURL, to: destURL)
  ```
