# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Module Purpose

ExFigConfig evaluates PKL configuration files into strongly-typed Swift models and bridges them to ExFigCore domain types. It has three layers:

1. **Generated types** (`Generated/*.pkl.swift`) — structs, protocols, and enums produced by `pkl-gen-swift` from PKL schemas. Never edit manually.
2. **PKL evaluator** (`PKL/`) — async entry point that evaluates `.pkl` files via PklSwift's embedded evaluator (no CLI dependency).
3. **Bridging extensions** — convert PKL types to ExFigCore types (`NameStyleBridging.swift`, `VariablesSourceValidation.swift`).

## Commands

```bash
# Regenerate Generated/*.pkl.swift from PKL schemas
./bin/mise run codegen:pkl

# Run ExFigConfig-related tests
./bin/mise run test:filter PKLEvaluatorTests
./bin/mise run test:filter EnumBridgingTests

# All tests (faster when 3+ targets affected)
./bin/mise run test
```

## Architecture

```
PKL schemas (Sources/ExFigCLI/Resources/Schemas/*.pkl)
    ↓ pkl-gen-swift
Generated/*.pkl.swift (ExFig, Common, Figma, iOS, Android, Flutter, Web)
    ↓ PklSwift evaluator
PKLEvaluator.evaluate(configPath:) → ExFig.ModuleImpl
    ↓ bridging extensions
ExFigCore domain types (NameStyle, ColorsSourceInput, etc.)
```

### Generated Type Hierarchy

- `ExFig.ModuleImpl` — root config container with optional platform sections (`figma`, `common`, `ios`, `android`, `flutter`, `web`)
- `Common_NameProcessing` — base protocol (`nameValidateRegexp`, `nameReplaceRegexp`)
- `Common_VariablesSource` extends `NameProcessing` — colors from Figma Variables API
- `Common_FrameSource` extends `NameProcessing` — icons/images from Figma frames
- Platform entry types (`iOS.ColorsEntry`, `Android.IconsEntry`, etc.) implement these protocols

### Key Public API

| Symbol                                                  | Purpose                                                |
| ------------------------------------------------------- | ------------------------------------------------------ |
| `PKLEvaluator.evaluate(configPath:)`                    | Async evaluation of .pkl → `ExFig.ModuleImpl`          |
| `PKLError.configNotFound` / `.evaluationDidNotComplete` | Error cases                                            |
| `Common.NameStyle.coreNameStyle`                        | Bridge to `ExFigCore.NameStyle` via rawValue match     |
| `Common_VariablesSource.validatedColorsSourceInput()`   | Validates required fields, returns `ColorsSourceInput` |

### PklError Workaround

`PklSwift.PklError` doesn't conform to `LocalizedError`. The `@retroactive` extension in `PKLEvaluator.swift` exposes `.message` — without it, `.localizedDescription` returns a useless generic string.

## Codegen Gotchas

- PKL `"kebab-case"` raw values become `.kebabCase` in Swift (not `.kebab_case`)
- After regeneration, verify bridging switch statements in `Sources/ExFig-*/Config/*Entry.swift`
- New fields in generated inits require updating ALL test call sites with new `nil` parameters
- Generated files are excluded from SwiftLint (`.swiftlint.yml`)

## Consumers

All platform plugins (`ExFig-iOS`, `ExFig-Android`, `ExFig-Flutter`, `ExFig-Web`) and ExFigCLI import this module. Entry types from `Generated/` are extended in platform Config directories with computed properties that bridge to ExFigCore types.
