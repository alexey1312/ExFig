# Change: Migrate to PKL Configuration

## Why

Current YAML configuration lacks native support for configuration inheritance and composition. Teams need to maintain
multiple config files with duplicated settings, and there's no way to share base configurations across projects.

PKL (Programmable, Scalable, Safe) provides native `amends`/`extends` for config inheritance, built-in type validation,
and support for remote schema imports — solving these problems at the language level.

## What Changes

- **BREAKING**: Remove YAML configuration support completely (no backward compatibility)
- **BREAKING**: Remove Yams dependency from Package.swift
- Add PKL configuration schema files (`ExFig.pkl`, `iOS.pkl`, `Android.pkl`, etc.)
- Add PKL evaluator infrastructure (`PKLLocator`, `PKLEvaluator`)
- Update `ExFigOptions` to use PKL instead of YAML
- Update `ConfigDiscovery` to find `.pkl` files instead of `.yaml`
- Add `pkl` to mise.toml for tooling
- Create comprehensive PKL documentation and migration guide

## Impact

- Affected specs: `configuration` (new capability)
- Affected code:
  - `Sources/ExFig/Input/ExFigOptions.swift` — PKL evaluation instead of Yams
  - `Sources/ExFig/Input/Params.swift` — unchanged (Decodable from JSON)
  - `Sources/ExFig/Batch/ConfigDiscovery.swift` — `.pkl` file discovery
  - `Package.swift` — remove Yams dependency
  - `mise.toml` — add pkl tool
  - `CLAUDE.md` — update configuration examples

## Risks

- PKL CLI must be installed separately via `mise use pkl`
- Users must manually rewrite configs (no auto-migration tool)
- PKL has smaller community than YAML

## Mitigations

- Clear migration guide with YAML-to-PKL syntax mapping
- Typed schemas catch configuration errors at evaluation time
- PKL's `amends` enables gradual adoption with shared base configs
