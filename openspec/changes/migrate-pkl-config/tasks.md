## 1. PKL Schemas

- [ ] 1.1 Create `Resources/Schemas/PklProject` manifest
- [ ] 1.2 Create `ExFig.pkl` main abstract schema
- [ ] 1.3 Create `Figma.pkl` with timeout, fileIds
- [ ] 1.4 Create `Common.pkl` with cache, variablesColors, icons, images, typography
- [ ] 1.5 Create `iOS.pkl` with colors, icons, images, typography configurations
- [ ] 1.6 Create `Android.pkl` with colors, icons, images, typography configurations
- [ ] 1.7 Create `Flutter.pkl` with colors, icons, images configurations
- [ ] 1.8 Create `Web.pkl` with colors, icons, images configurations
- [ ] 1.9 Validate schemas compile: `pkl eval ExFig.pkl`

## 2. PKL Infrastructure

- [ ] 2.1 Create `PKL/PKLError.swift` with NotFound, EvaluationFailed cases
- [ ] 2.2 Create `PKL/PKLLocator.swift` with mise shim and PATH detection
- [ ] 2.3 Create `PKL/PKLEvaluator.swift` with subprocess wrapper
- [ ] 2.4 Add `pkl` to `mise.toml` tools section
- [ ] 2.5 Write unit tests for `PKLLocator`
- [ ] 2.6 Write unit tests for `PKLEvaluator`

## 3. ExFig Integration

- [ ] 3.1 Update `ExFigOptions.swift` to use `PKLEvaluator`
- [ ] 3.2 Change default config filename to `exfig.pkl`
- [ ] 3.3 Remove YAML file detection logic
- [ ] 3.4 Update `ConfigDiscovery.swift` to find `.pkl` files
- [ ] 3.5 Remove Yams validation logic from `ConfigDiscovery`
- [ ] 3.6 Update error messages to reference PKL

## 4. Dependency Cleanup

- [ ] 4.1 Remove `Yams` from `Package.swift` dependencies
- [ ] 4.2 Remove `import Yams` from `ExFigOptions.swift`
- [ ] 4.3 Remove `import Yams` from `ConfigDiscovery.swift`
- [ ] 4.4 Search and remove any remaining Yams references

## 5. Test Updates

- [ ] 5.1 Create `Tests/ExFigTests/Fixtures/exfig.pkl` test config
- [ ] 5.2 Create `Tests/ExFigTests/Fixtures/base.pkl` for inheritance tests
- [ ] 5.3 Update existing integration tests to use PKL configs
- [ ] 5.4 Remove YAML fixture files
- [ ] 5.5 Add test for PKL evaluation error handling
- [ ] 5.6 Add test for missing pkl CLI error
- [ ] 5.7 Run full test suite: `mise run test`

## 6. Documentation

- [ ] 6.1 Update `CLAUDE.md` Quick Reference with PKL commands
- [ ] 6.2 Update `CLAUDE.md` config examples to PKL syntax
- [ ] 6.3 Create `docs/PKL.md` — complete PKL configuration guide
- [ ] 6.4 Create `docs/MIGRATION.md` — YAML to PKL migration guide
- [ ] 6.5 Update `README.md` with PKL prerequisites
- [ ] 6.6 Update `openspec/project.md` to reference PKL instead of Yams

## 7. CI/CD

- [ ] 7.1 Update GitHub Actions to install pkl via mise
- [ ] 7.2 Create workflow for publishing PKL schemas on tag `schemas/v*`
- [ ] 7.3 Verify CI passes on macOS and Linux

## 8. Verification

- [ ] 8.1 Build release: `mise run build:release`
- [ ] 8.2 Test basic command: `exfig colors -i exfig.pkl --dry-run`
- [ ] 8.3 Test batch mode: `exfig batch ./configs/ --parallel 2`
- [ ] 8.4 Test config inheritance with `amends`
- [ ] 8.5 Test error when pkl not installed
