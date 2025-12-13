## 1. Core Infrastructure

- [ ] 1.1 Add `.web` case to `Sources/ExFigCore/Platform.swift`
- [ ] 1.2 Add WebExport target to `Package.swift`
- [ ] 1.3 Create `Sources/WebExport/WebExporter.swift` base class
- [ ] 1.4 Create `Sources/WebExport/Model/WebOutput.swift` configuration model
- [ ] 1.5 Create `Sources/WebExport/Resources/header.stencil`

## 2. Colors Export (TDD)

- [ ] 2.1 Add `Web` struct with `ColorsConfiguration` to `Sources/ExFig/Input/Params.swift`
- [ ] 2.2 Create `Tests/WebExportTests/WebColorExporterTests.swift`
- [ ] 2.3 Create `Sources/WebExport/Resources/theme.css.stencil`
- [ ] 2.4 Create `Sources/WebExport/Resources/variables.ts.stencil`
- [ ] 2.5 Create `Sources/WebExport/Resources/theme.json.stencil`
- [ ] 2.6 Create `Sources/WebExport/WebColorExporter.swift`
- [ ] 2.7 Update `Sources/ExFig/Subcommands/ExportColors.swift` with web export section

## 3. Icons Export (TDD)

- [ ] 3.1 Add `IconsConfiguration` to `Web` struct in `Params.swift`
- [ ] 3.2 Create `Tests/WebExportTests/WebIconsExporterTests.swift`
- [ ] 3.3 Create `Sources/WebExport/Resources/Icon.tsx.stencil`
- [ ] 3.4 Create `Sources/WebExport/Resources/types.ts.stencil`
- [ ] 3.5 Create `Sources/WebExport/Resources/IconIndex.ts.stencil`
- [ ] 3.6 Create `Sources/WebExport/WebIconsExporter.swift` with SVG-to-TSX transform
- [ ] 3.7 Update `Sources/ExFig/Subcommands/ExportIcons.swift` with web export section

## 4. Images Export (TDD)

- [ ] 4.1 Add `ImagesConfiguration` to `Web` struct in `Params.swift`
- [ ] 4.2 Create `Tests/WebExportTests/WebImagesExporterTests.swift`
- [ ] 4.3 Create `Sources/WebExport/Resources/Image.tsx.stencil`
- [ ] 4.4 Create `Sources/WebExport/Resources/ImageIndex.ts.stencil`
- [ ] 4.5 Create `Sources/WebExport/WebImagesExporter.swift`
- [ ] 4.6 Update `Sources/ExFig/Subcommands/ExportImages.swift` with web export section

## 5. Documentation

- [ ] 5.1 Add `web:` config section to `CONFIG.md`
- [ ] 5.2 Add web config template to `Sources/ExFig/Subcommands/GenerateConfigFile.swift` (`exfig init -p web`)
- [ ] 5.3 Create `Sources/ExFig/ExFig.docc/Web.md` article
- [ ] 5.4 Update `README.md` — add Web to platform list and features
- [ ] 5.5 Update `CLAUDE.md` with WebExport module documentation
- [ ] 5.6 Update `.claude/EXFIG.toon` — add WebExport module and templates
- [ ] 5.7 Run `mise run format-md` — format markdown files

## 6. Final Verification

- [ ] 6.1 Run `mise run test` — all tests pass
- [ ] 6.2 Run `mise run lint` — no lint errors
- [ ] 6.3 Manual test with web-ui project config
- [ ] 6.4 Verify generated CSS matches web-ui/packages/yrel format
- [ ] 6.5 Verify generated TSX matches web-ui/packages/mireska format
