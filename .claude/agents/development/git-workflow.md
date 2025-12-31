# Git Workflow

## Commit Format

Format: `<type>(<scope>): <description>`

**Types:** `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `chore`, `ci`

**Scopes:** `colors`, `icons`, `images`, `typography`, `api`, `cli`, `ios`, `android`, `flutter`

Examples:

```bash
feat(cli): add download command for config-free image downloads
fix(icons): handle SVG with missing viewBox
docs: update naming style documentation
```

## Pre-commit Requirements

```bash
./bin/mise run setup       # Install hk git hooks (one-time)
./bin/mise run format      # Run all formatters (hk fix --all)
./bin/mise run lint        # Must pass (may have issues on Linux)
```

## Pre-commit Hooks

The project uses `hk` for git hooks. After running `./bin/mise run setup`, hooks will:

1. Format Swift code
2. Format Markdown
3. Run SwiftLint
4. Run actionlint (for GitHub Actions)
