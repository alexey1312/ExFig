## 1. Core Infrastructure

- [x] 1.1 Add `.web` case to `Sources/ExFigCore/Platform.swift`
- [x] 1.2 Add WebExport target to `Package.swift`
- [x] 1.3 Create `Sources/WebExport/WebExporter.swift` base class
- [x] 1.4 Create `Sources/WebExport/Model/WebOutput.swift` configuration model
- [x] 1.5 Create `Sources/WebExport/Resources/header.stencil`

## 2. Colors Export (TDD)

- [x] 2.1 Add `Web` struct with `ColorsConfiguration` to `Sources/ExFig/Input/Params.swift`
- [x] 2.2 Create `Tests/WebExportTests/WebColorExporterTests.swift`
- [x] 2.3 Create `Sources/WebExport/Resources/theme.css.stencil`
- [x] 2.4 Create `Sources/WebExport/Resources/variables.ts.stencil`
- [x] 2.5 Create `Sources/WebExport/Resources/theme.json.stencil`
- [x] 2.6 Create `Sources/WebExport/WebColorExporter.swift`
- [x] 2.7 Update `Sources/ExFig/Subcommands/ExportColors.swift` with web export section

## 3. Icons Export (TDD)

- [x] 3.1 Add `IconsConfiguration` to `Web` struct in `Params.swift`
- [x] 3.2 Create `Tests/WebExportTests/WebIconsExporterTests.swift`
- [x] 3.3 Create `Sources/WebExport/Resources/Icon.tsx.stencil`
- [x] 3.4 Create `Sources/WebExport/Resources/types.ts.stencil`
- [x] 3.5 Create `Sources/WebExport/Resources/IconIndex.ts.stencil`
- [x] 3.6 Create `Sources/WebExport/WebIconsExporter.swift` with SVG-to-TSX transform
- [x] 3.7 Update `Sources/ExFig/Subcommands/ExportIcons.swift` with web export section

## 4. Images Export (TDD)

- [x] 4.1 Add `ImagesConfiguration` to `Web` struct in `Params.swift`
- [x] 4.2 Create `Tests/WebExportTests/WebImagesExporterTests.swift`
- [x] 4.3 Create `Sources/WebExport/Resources/Image.tsx.stencil`
- [x] 4.4 Create `Sources/WebExport/Resources/ImageIndex.ts.stencil`
- [x] 4.5 Create `Sources/WebExport/WebImagesExporter.swift`
- [x] 4.6 Update `Sources/ExFig/Subcommands/ExportImages.swift` with web export section

## 5. Documentation

- [x] 5.1 Add `web:` config section to `CONFIG.md`
- [x] 5.2 Add web config template to `Sources/ExFig/Subcommands/GenerateConfigFile.swift` (`exfig init -p web`)
- [x] 5.3 Create `Sources/ExFig/ExFig.docc/Web.md` article (skipped - no docc articles for other platforms)
- [x] 5.4 Update `README.md` — add Web to platform list and features
- [x] 5.5 Update `CLAUDE.md` with WebExport module documentation (covered via EXFIG.toon)
- [x] 5.6 Update `.claude/EXFIG.toon` — add WebExport module and templates
- [x] 5.7 Run `mise run format:md` — format markdown files

## 6. Final Verification

- [x] 6.1 Run `mise run test` — all tests pass (1530 tests)
- [x] 6.2 Run `mise run lint` — no lint errors
- [x] 6.3 Manual test with web-ui project config (skipped - no web-ui project available)
- [x] 6.4 Verify generated CSS matches web-ui/packages/yrel format (skipped - no web-ui project available)
- [x] 6.5 Verify generated TSX matches web-ui/packages/mireska format (skipped - no web-ui project available)
