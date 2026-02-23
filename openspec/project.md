# Project Context

## Purpose

ExFig is a Swift CLI that exports Figma colors, typography, icons, and images to iOS, Android, and Flutter projects,
keeping design systems in sync across platforms.

## Tech Stack

- Swift 6.2 with Swift Package Manager
- swift-argument-parser for CLI
- PKL (Programmable, Scalable, Safe) for configuration
- swift-jinja (Jinja2) for code generation
- Rainbow and swift-log for terminal output
- Native libwebp and libpng for image conversion

## Project Conventions

### Code Style

- Enforced by SwiftLint; format via `mise run format` and `mise run format-md`
- Naming styles follow `NameStyle` enum; defaults camelCase for iOS, snake_case for Android

### Architecture Patterns

- Core modules: ExFig (CLI), ExFigCore (models/processors), ExFigConfig (PKL parsing), FigmaAPI (HTTP client)
- Platform plugins: ExFig-iOS, ExFig-Android, ExFig-Flutter, ExFig-Web (each implements ColorsExporter, IconsExporter,
  ImagesExporter)
- Export modules: XcodeExport, AndroidExport, FlutterExport, WebExport, SVGKit
- Terminal output coordinated through TerminalOutputManager to avoid race conditions
- Rate limiting shared via SharedRateLimiter and RateLimitedClient

### Testing Strategy

- Test targets mirror modules; run `mise run test` or `mise run test:filter <Target>`
- Linux quirks: prefer single worker for tests touching libpng; skip where noted

### Git Workflow

- Conventional commits: `<type>(<scope>): <description>` with scopes like cli, icons, images, typography, api
- Run format, format-md, lint before committing

## Domain Context

- Supports light/dark/high-contrast color modes, Figma Variables, PDF/SVG icons, WebP/PNG/JPG images, and typography
  exports
- Commands honor version tracking cache to skip unchanged exports

## Important Constraints

- Requires `FIGMA_PERSONAL_TOKEN`
- macOS 13+ primary; Linux (Ubuntu 22.04) supported in CI with FoundationNetworking imports
- Avoid new external binaries; conversions use native libraries

## External Dependencies

- Figma REST API with retry/backoff and rate limiting
- Xcode project manipulation via XcodeProj library
