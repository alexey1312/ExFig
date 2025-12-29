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

## Context7 for External Libraries

**Always use Context7 MCP** to look up documentation for external tools and libraries before implementing:

1. `resolve-library-id` — find the library ID
2. `get-library-docs` with `topic` — get relevant docs (use `mode: code` for API, `mode: info` for concepts)
3. Paginate with `page: 2, 3...` if context insufficient

This applies to: Swift packages, CLI tools (mise, hk, swiftlint, etc.), Figma API, and any third-party dependency.

# CLAUDE.md

Agent instructions for ExFig - a CLI tool and macOS app that exports colors, typography, icons, and images from Figma to
iOS, Android, and Flutter projects.

## Quick Reference

```bash
# Build & Test
./bin/mise run build                # Debug build
./bin/mise run build:release        # Release build
./bin/mise run test                 # All tests
./bin/mise run test:filter NAME     # Filter by target/class/method

# Code Quality (run before commit)
./bin/mise run format               # Format all (Swift + Markdown)
./bin/mise run lint                 # SwiftLint + actionlint

# Run CLI
.build/debug/exfig --help
.build/debug/exfig colors -i config.yaml
```

## Project Context

| Aspect          | Details                                             |
| --------------- | --------------------------------------------------- |
| Language        | Swift 6.2, macOS 13.0+                              |
| Package Manager | Swift Package Manager                               |
| CLI Framework   | swift-argument-parser                               |
| Config Format   | YAML (via Yams)                                     |
| Templates       | Stencil                                             |
| Required Env    | `FIGMA_PERSONAL_TOKEN`                              |
| Config Files    | `exfig.yaml` or `figma-export.yaml` (auto-detected) |
| Tooling         | mise (`./bin/mise` self-contained)                  |
| Platforms       | macOS 13+ (primary), Linux/Ubuntu 22.04 (CI)        |

## Architecture

Eight SPM modules in `Sources/`:

| Module          | Purpose                                                            |
| --------------- | ------------------------------------------------------------------ |
| `ExFig`         | CLI commands, loaders, file I/O, terminal UI                       |
| `ExFigKit`      | Shared library: config models (Params), errors, progress reporting |
| `ExFigCore`     | Domain models (Color, Image, TextStyle), processors                |
| `FigmaAPI`      | Figma REST API client, endpoints, OAuth 2.0 authentication         |
| `XcodeExport`   | iOS export (.xcassets, Swift extensions)                           |
| `AndroidExport` | Android export (XML resources, Compose, Vector Drawables)          |
| `FlutterExport` | Flutter export (Dart code, SVG/PNG assets)                         |
| `SVGKit`        | SVG parsing, ImageVector/VectorDrawable generation                 |

**ExFig Studio** (macOS GUI app) in `Projects/ExFigStudio/` - see [ExFig Studio docs](.claude/agents/integrations/exfig-studio.md).

**Data flow:**

- CLI: Config parsing → FigmaAPI fetch → ExFigCore processing → Platform export → File write
- GUI: OAuth login → Visual config → FigmaAPI fetch → ExFigCore processing → Export with progress

## Documentation Index

Detailed documentation in `.claude/agents/`:

### Architecture

- [Project Structure](.claude/agents/architecture/project-structure.md) - Module organization, key directories
- [Code Patterns](.claude/agents/architecture/code-patterns.md) - Adding CLI commands, API endpoints

### Development

- [Build Commands](.claude/agents/development/build-commands.md) - All mise tasks
- [Testing](.claude/agents/development/testing.md) - Test targets, running tests
- [Git Workflow](.claude/agents/development/git-workflow.md) - Commit format, pre-commit hooks
- [Linux Compatibility](.claude/agents/development/linux-compatibility.md) - Foundation workarounds

### Features

- [Icons Configuration](.claude/agents/features/icons-configuration.md) - Single/multiple icons
- [Colors Configuration](.claude/agents/features/colors-configuration.md) - Single/multiple colors
- [Images Configuration](.claude/agents/features/images-configuration.md) - Images, SVG source, HEIC output
- [Terminal UI](.claude/agents/features/terminal-ui.md) - Spinners, progress, warnings, errors
- [Fault Tolerance](.claude/agents/features/fault-tolerance.md) - Retry, rate limiting, batch optimization
- [Granular Cache](.claude/agents/features/granular-cache.md) - Experimental node-level caching

### Integrations

- [Figma API](.claude/agents/integrations/figma-api.md) - API endpoints, rate limits
- [ExFig Studio](.claude/agents/integrations/exfig-studio.md) - macOS GUI app, OAuth

## Critical Gotchas

### Swift 6 Concurrency

```swift
// Captured vars in task groups must be Sendable
try await withThrowingTaskGroup(of: (Key, Value).self) { [self] group in
    for item in items {
        group.addTask { [item] in  // Capture value, not var
            (item.key, try await self.process(item))
        }
    }
}

// Callbacks passed to task groups must be @escaping
func loadImages(
    onBatchProgress: @escaping BatchProgressCallback = { _, _ in }
) async throws -> [ImagePack]
```

### SwiftLint Rules

- Use `Data("string".utf8)` not `"string".data(using: .utf8)!`
- Add `// swiftlint:disable:next force_try` before `try!` in tests
- Add `// swiftlint:disable file_length` for files > 400 lines

### Figma API Rate Limits

- Tier 1 endpoints (files, images): 10-20 req/min depending on plan
- On 429 error: respect `Retry-After` header
- See [Figma API docs](.claude/agents/integrations/figma-api.md)

## Dependencies

| Package               | Version | Purpose                     |
| --------------------- | ------- | --------------------------- |
| swift-argument-parser | 1.5.0+  | CLI framework               |
| swift-collections     | 1.2.x   | Ordered collections         |
| swift-crypto          | 3.0.0+  | Cross-platform cryptography |
| Yams                  | 5.3.0+  | YAML parsing                |
| Stencil               | 0.15.1+ | Template engine             |
| StencilSwiftKit       | 2.10.1+ | Swift Stencil extensions    |
| XcodeProj             | 8.27.0+ | Xcode project manipulation  |
| swift-log             | 1.6.0+  | Logging                     |
| Rainbow               | 4.2.0+  | Terminal colors             |
| libwebp               | 1.4.1+  | WebP encoding               |
| libpng                | 1.6.45+ | PNG decoding                |
| swift-custom-dump     | 1.3.0+  | Test assertions             |

## Troubleshooting

| Problem            | Solution                                       |
| ------------------ | ---------------------------------------------- |
| Build fails        | `swift package clean && swift build`           |
| Tests fail         | Check `FIGMA_PERSONAL_TOKEN` is set            |
| Formatting fails   | Run `./bin/mise run setup` to install tools    |
| Template errors    | Check Stencil syntax and context variables     |
| Linux test crashes | Use `--num-workers 1` for test parallelization |

## Configuration Reference

Full config spec: `CONFIG.md`

Generate starter config:

```bash
exfig init -p ios
exfig init -p android
```

## Project Knowledge File

The `@.claude/EXFIG.toon` file contains a compact machine-readable summary of the project.

**Maintenance rule:** Keep this file updated when:

- Adding new CLI commands or options
- Adding new modules or significant types
- Changing default values for fault tolerance
- Adding new Stencil templates

To validate: `npx @toon-format/cli .claude/EXFIG.toon --decode`
