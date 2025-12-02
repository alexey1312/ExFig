# Development Guide

This guide covers development setup, building, testing, and contributing to ExFig.

## Prerequisites

- **Swift 6.0 or later**
- **macOS 12.0 or later**
- **Xcode Command Line Tools**

## Setup

### 1. Clone Repository

```bash
git clone https://github.com/alexey1312/ExFig.git
cd ExFig
```

### 2. Activate mise Environment

ExFig uses [mise](https://mise.jdx.dev/) for tool management. A bootstrap binary is included, so no global installation
is needed.

```bash
# Activate mise environment (adds tools to PATH)
source Scripts/environment.sh
```

### 3. Install Pre-Commit Hooks

```bash
# Run once after cloning
mise run setup
```

This installs git hooks for code quality checks.

## Available Tasks

ExFig provides several mise tasks for common operations:

```bash
# Build the project
mise run build

# Run all tests
mise run test

# Run linter (SwiftLint)
mise run lint

# Format code (SwiftFormat)
mise run format

# Check formatting (CI mode, doesn't modify files)
mise run format-check

# Run pre-commit hooks on all files
mise run pre-commit
```

## Building

### Debug Build

```bash
swift build
```

Binary location: `.build/debug/exfig`

### Release Build

```bash
swift build -c release
```

Binary location: `.build/release/exfig`

### Run from Source

```bash
# Run directly
swift run exfig --help

# Or build and run
swift build
.build/debug/exfig --help
```

## Testing

### Run All Tests

```bash
mise run test
```

Or using Swift directly:

```bash
swift test
```

### Run Specific Test Target

```bash
# Test individual modules
swift test --filter ExFigTests
swift test --filter ExFigCoreTests
swift test --filter XcodeExportTests
swift test --filter AndroidExportTests
swift test --filter FigmaAPITests
```

### Run Specific Test

```bash
swift test --filter ExFigCoreTests.ColorTests
swift test --filter XcodeExportTests.XcodeColorExporterTests/testColorExport
```

## Code Quality

### Linting

```bash
mise run lint
```

This runs [SwiftLint](https://github.com/realm/SwiftLint) to check code style and potential issues.

### Formatting

```bash
# Format all Swift files
mise run format

# Check formatting without modifying files (CI mode)
mise run format-check
```

This uses [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) to ensure consistent code style.

## Pre-Commit Requirements

Before creating any commit, you **must**:

1. Format code: `mise run format`
2. Pass linting: `mise run lint`

Both commands must pass without errors.

The pre-commit hook (installed via `mise run setup`) will automatically run these checks.

## Project Structure

ExFig is organized as a Swift Package with 5 modules:

### Module Overview

```
ExFig/
├── Sources/
│   ├── ExFig/               # Main executable (CLI)
│   │   ├── ExFigCommand.swift
│   │   ├── Subcommands/     # CLI commands
│   │   ├── Loaders/         # Figma API data loaders
│   │   ├── Input/           # YAML configuration parsing
│   │   └── Output/          # File writing
│   ├── ExFigCore/           # Core domain models
│   │   ├── Models/          # Color, Image, TextStyle, etc.
│   │   ├── Processor/       # Data transformation
│   │   └── Extensions/      # Utilities
│   ├── FigmaAPI/            # Figma REST API client
│   │   ├── Client.swift
│   │   ├── Endpoint/        # API endpoints
│   │   └── Model/           # API response models
│   ├── XcodeExport/         # iOS/Xcode export
│   │   ├── Exporters/       # Color, icon, image, typography exporters
│   │   ├── Resources/       # Stencil templates
│   │   └── Model/           # Xcode-specific models
│   └── AndroidExport/       # Android export
│       ├── Exporters/       # Android exporters
│       ├── Resources/       # Stencil templates
│       └── Model/           # Android-specific models
├── Tests/                   # Test suites for each module
└── Examples/                # Example projects
```

### Data Flow

1. **CLI** (`ExFig`) parses arguments and loads `exfig.yaml`
2. **FigmaAPI** fetches design data from Figma REST API
3. **ExFigCore** processes Figma data into platform-agnostic models
4. **XcodeExport** or **AndroidExport** generates platform-specific files
5. **Output** writes generated files to disk

## Key Dependencies

- **swift-argument-parser** (1.5.0+) - CLI framework
- **Yams** (5.3.0+) - YAML parsing
- **Stencil** (0.15.1+) - Template engine
- **StencilSwiftKit** (2.10.1+) - Stencil extensions
- **XcodeProj** (8.27.0+) - Xcode project manipulation
- **swift-log** (1.6.0+) - Logging
- **swift-custom-dump** (1.3.0+) - Test assertions

## Managed Tools (via mise)

- **pre-commit** - Git hooks for code quality
- **swiftformat** - Swift code formatter
- **swiftlint** - Swift linter
- **xcsift** - Xcode build output formatter

Tools are automatically installed and managed by mise.

## Making Changes

### 1. Create Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Changes

Edit code and add tests for new functionality.

### 3. Run Tests

```bash
mise run test
```

Ensure all tests pass.

### 4. Format and Lint

```bash
mise run format
mise run lint
```

Fix any issues reported by linting.

### 5. Commit Changes

```bash
git add .
git commit -m "Add your feature description"
```

The pre-commit hook will run automatically.

### 6. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a pull request on GitHub.

## Contributing Guidelines

### Code Style

- Follow Swift API Design Guidelines
- Use meaningful variable and function names
- Add doc comments for public APIs
- Keep functions focused and small
- Use SwiftFormat and SwiftLint configurations

### Testing

- Write tests for new features
- Maintain or improve test coverage
- Use descriptive test names
- Test edge cases and error conditions

### Commits

- Write clear, descriptive commit messages
- Use imperative mood ("Add feature" not "Added feature")
- Reference issues in commits (e.g., "Fix #123")
- Keep commits focused and atomic

### Pull Requests

- Provide clear description of changes
- Reference related issues
- Ensure CI passes (tests, linting, formatting)
- Respond to review feedback
- Keep PRs focused on a single concern

## Debugging

### Enable Verbose Logging

```bash
export LOG_LEVEL=trace
.build/debug/exfig colors -i exfig.yaml
```

### Debug in Xcode

```bash
# Generate Xcode project
swift package generate-xcodeproj

# Open in Xcode
open ExFig.xcodeproj
```

Set breakpoints and run the `ExFig` scheme with arguments.

## Common Issues

### Build Failures

- Ensure Swift version is 6.0+: `swift --version`
- Clean build folder: `swift package clean`
- Reset package cache: `swift package reset`

### Test Failures

- Verify `FIGMA_PERSONAL_TOKEN` is set for API tests
- Check network connectivity for integration tests
- Run tests individually to isolate failures

### Tool Issues

- Reactivate mise: `source Scripts/environment.sh`
- Update tools: `mise install`
- Check mise status: `mise doctor`

## CI/CD

ExFig uses GitHub Actions for continuous integration:

- **Build**: Compiles code on every push
- **Test**: Runs full test suite
- **Lint**: Checks code style
- **Format Check**: Verifies code formatting

CI configuration: `.github/workflows/`

## Release Process

1. Update version in `ExFig.swift`
2. Update CHANGELOG.md
3. Create git tag: `git tag v1.2.3`
4. Push tag: `git push origin v1.2.3`
5. GitHub Actions builds and publishes release

## Resources

- [Swift Documentation](https://swift.org/documentation/)
- [Argument Parser](https://github.com/apple/swift-argument-parser)
- [Stencil Documentation](https://stencil.fuller.li/)
- [mise Documentation](https://mise.jdx.dev/)
- [Figma API Reference](https://www.figma.com/developers/api)

## Getting Help

- **Issues**: Open an issue on [GitHub](https://github.com/alexey1312/ExFig/issues)
- **Discussions**: Use GitHub Discussions for questions
- **Contributing**: See [CONTRIBUTING.md](../../CONTRIBUTING.md) (if available)

## License

ExFig is released under the MIT License. See [LICENSE](../../LICENSE) for details.

______________________________________________________________________

[← Back: Documentation Index](index.md)
