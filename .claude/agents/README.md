# ExFig Agent Documentation

Documentation for AI agents working with the ExFig codebase.

## Documentation Index

### Architecture

- [Project Structure](architecture/project-structure.md) - Module organization, key directories
- [Code Patterns](architecture/code-patterns.md) - Adding CLI commands, API endpoints, templates

### Development

- [Build Commands](development/build-commands.md) - mise tasks, build, test, format, lint
- [Testing](development/testing.md) - Test targets, running tests, test helpers
- [Git Workflow](development/git-workflow.md) - Commit format, pre-commit hooks
- [Linux Compatibility](development/linux-compatibility.md) - Foundation workarounds, test issues

### Features

- [Icons Configuration](features/icons-configuration.md) - Single/multiple icons, per-entry fields
- [Colors Configuration](features/colors-configuration.md) - Single/multiple colors, Figma Variables
- [Images Configuration](features/images-configuration.md) - Images, SVG source, HEIC output
- [Terminal UI](features/terminal-ui.md) - Spinners, progress bars, warnings, errors
- [Fault Tolerance](features/fault-tolerance.md) - Retry, rate limiting, batch optimization
- [Granular Cache](features/granular-cache.md) - Experimental node-level caching

### Integrations

- [Figma API](integrations/figma-api.md) - API endpoints, rate limits, response mapping
- [ExFig Studio](integrations/exfig-studio.md) - macOS GUI app, OAuth, Tuist

## When to Read Documentation

| Task Type | Required Reading |
|-----------|------------------|
| Adding CLI command | [Code Patterns](architecture/code-patterns.md) |
| Adding API endpoint | [Code Patterns](architecture/code-patterns.md), [Figma API](integrations/figma-api.md) |
| Working with icons/colors/images | Relevant [Features](features/) doc |
| Debugging terminal output | [Terminal UI](features/terminal-ui.md) |
| Build/test issues | [Build Commands](development/build-commands.md), [Testing](development/testing.md) |
| Linux-specific issues | [Linux Compatibility](development/linux-compatibility.md) |
| Cache behavior | [Fault Tolerance](features/fault-tolerance.md), [Granular Cache](features/granular-cache.md) |
| GUI app development | [ExFig Studio](integrations/exfig-studio.md) |
