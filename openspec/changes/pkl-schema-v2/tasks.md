# PKL Schema v2 Tasks

## Summary

| Track                       | Description                           | Status  |
| --------------------------- | ------------------------------------- | ------- |
| 1. Defaults                 | PKL default values в схемах           | Done ✓  |
| 2. Entry Overrides — Schema | Новые optional поля в PKL-схемах      | Done ✓  |
| 3. Entry Overrides — Swift  | Resolution logic в Swift-коде         | Pending |
| 4. Constraints              | PKL constraints (!isEmpty, isBetween) | Done ✓  |
| 5. Verification             | Полная верификация                    | Pending |

## Dependency Graph

```
Track 1 (Defaults) ────────────────────┐
                                       │
Track 2 (Overrides — Schema) ──┐       ├── Track 5 (Verification)
                               │       │
Track 3 (Overrides — Swift) ◄──┘───────┘
                               │
Track 4 (Constraints) ─────────┘
```

Track 1 и Track 2 могут выполняться параллельно.
Track 3 зависит от Track 2 (новые поля в сгенерированных типах).
Track 4 может выполняться параллельно с Track 3.
Track 5 зависит от всех треков.

---

## 1. Defaults — PKL Schema Default Values

> PKL defaults применяются при `pkl eval` до Swift. Zero diff в сгенерированных Swift типах.

### 1.1 Common.pkl + Figma.pkl Defaults

- [x] 1.1.1 Add `Cache.enabled` default: `= false`
- [x] 1.1.2 Add `Cache.path` default: `= ".exfig-cache.json"`
- [x] 1.1.3 Add `FigmaConfig.timeout` default: `= 30`
- [x] 1.1.4 Verify: `pkl eval --format json` on example configs shows resolved defaults

### 1.2 iOS.pkl Defaults

- [x] 1.2.1 Add `ColorsEntry.useColorAssets` default: `= true`
- [x] 1.2.2 Add `ColorsEntry.nameStyle` default: `= "camelCase"`
- [x] 1.2.3 Add `IconsEntry.format` default: `= "pdf"`
- [x] 1.2.4 Add `IconsEntry.assetsFolder` default: `= "Icons"`
- [x] 1.2.5 Add `IconsEntry.nameStyle` default: `= "camelCase"`
- [x] 1.2.6 Add `ImagesEntry.nameStyle` default: `= "camelCase"`
- [x] 1.2.7 Add `ImagesEntry.scales` default: `= new Listing { 1; 2; 3 }`
- [x] 1.2.8 Add `ImagesEntry.sourceFormat` default: `= "png"`
- [x] 1.2.9 Add `ImagesEntry.outputFormat` default: `= "png"`
- [x] 1.2.10 Add `iOSConfig.xcassetsInMainBundle` default: `= true`
- [x] 1.2.11 Add `Typography.generateLabels` default: `= false`
- [x] 1.2.12 Add `Typography.nameStyle` default: `= "camelCase"`

### 1.3 Android.pkl Defaults

- [x] 1.3.1 Add `ImagesEntry.format` default: `= "png"`
- [x] 1.3.2 Add `Typography.nameStyle` default: `= "camelCase"`
- [x] 1.3.3 Add `WebpOptions.encoding` default: `= "lossy"`
- [x] 1.3.4 Add `IconsEntry.nameStyle` default: `= "snake_case"`
- [x] 1.3.5 Add `IconsEntry.pathPrecision` default: `= 4`
- [x] 1.3.6 Add `ImagesEntry.scales` default: `= new Listing { 1; 1.5; 2; 3; 4 }`
- [x] 1.3.7 Add `ImagesEntry.nameStyle` default: `= "snake_case"`
- [x] 1.3.8 Add `ThemeAttributes.attrsFile` default: `= "values/attrs.xml"`
- [x] 1.3.9 Add `ThemeAttributes.stylesFile` default: `= "values/styles.xml"`
- [x] 1.3.10 Add `ThemeAttributes.stylesNightFile` default: `= "values-night/styles.xml"`
- [x] 1.3.11 Add `ThemeAttributes.autoCreateMarkers` default: `= false`
- [x] 1.3.12 Add `NameTransform.style` default: `= "PascalCase"`
- [x] 1.3.13 Add `NameTransform.prefix` default: `= "color"`

### 1.4 Flutter.pkl Defaults

- [x] 1.4.1 Add `ColorsEntry.className` default: `= "AppColors"`
- [x] 1.4.2 Add `IconsEntry.className` default: `= "AppIcons"`
- [x] 1.4.3 Add `IconsEntry.nameStyle` default: `= "snake_case"`
- [x] 1.4.4 Add `ImagesEntry.className` default: `= "AppImages"`
- [x] 1.4.5 Add `ImagesEntry.nameStyle` default: `= "snake_case"`
- [x] 1.4.6 Add `ImagesEntry.format` default: `= "png"`
- [x] 1.4.7 Add `ImagesEntry.scales` default: `= new Listing { 1; 2; 3 }`

### 1.5 Web.pkl Defaults

- [x] 1.5.1 Add `IconsEntry.iconSize` default: `= 24`
- [x] 1.5.2 Add `IconsEntry.generateReactComponents` default: `= true`
- [x] 1.5.3 Add `IconsEntry.nameStyle` default: `= "snake_case"`
- [x] 1.5.4 Add `ImagesEntry.generateReactComponents` default: `= true`
- [x] 1.5.5 Add `ImagesEntry.nameStyle` default: `= "snake_case"`

### 1.6 Defaults Verification

- [x] 1.6.1 Run `./bin/mise run codegen:pkl` — verify zero diff in Generated/*.pkl.swift
- [x] 1.6.2 Run `pkl eval --format json` on all example configs — verify resolved defaults
- [x] 1.6.3 Run `./bin/mise run test` — all tests pass
- [x] 1.6.4 Update example configs to omit fields that now have defaults

---

## 2. Entry-Level Overrides — PKL Schema Changes

> Добавление optional override полей в entry типы PKL-схем.

### 2.1 Common.pkl — figmaFileId

- [x] 2.1.1 Add `figmaFileId: String?` to `FrameSource` class with doc comment

### 2.2 iOS.pkl — xcassetsPath + templatesPath

- [x] 2.2.1 Add `xcassetsPath: String?` to `ColorsEntry` with doc comment
- [x] 2.2.2 Add `templatesPath: String?` to `ColorsEntry` with doc comment
- [x] 2.2.3 Add `xcassetsPath: String?` to `IconsEntry` with doc comment
- [x] 2.2.4 Add `templatesPath: String?` to `IconsEntry` with doc comment
- [x] 2.2.5 Add `xcassetsPath: String?` to `ImagesEntry` with doc comment
- [x] 2.2.6 Add `templatesPath: String?` to `ImagesEntry` with doc comment

### 2.3 Android.pkl — mainRes + mainSrc + templatesPath

- [x] 2.3.1 Add `mainRes: String?` to `ColorsEntry` with doc comment
- [x] 2.3.2 Add `mainSrc: String?` to `ColorsEntry` with doc comment
- [x] 2.3.3 Add `templatesPath: String?` to `ColorsEntry` with doc comment
- [x] 2.3.4 Add `mainRes: String?` to `IconsEntry` with doc comment
- [x] 2.3.5 Add `templatesPath: String?` to `IconsEntry` with doc comment
- [x] 2.3.6 Add `mainRes: String?` to `ImagesEntry` with doc comment
- [x] 2.3.7 Add `templatesPath: String?` to `ImagesEntry` with doc comment

### 2.4 Flutter.pkl — output + templatesPath

- [x] 2.4.1 Add `output: String?` to `ColorsEntry` (already optional, verify)
- [x] 2.4.2 Add `templatesPath: String?` to `ColorsEntry` with doc comment
- [x] 2.4.3 Add `templatesPath: String?` to `IconsEntry` with doc comment
- [x] 2.4.4 Add `templatesPath: String?` to `ImagesEntry` with doc comment

### 2.5 Web.pkl — output + templatesPath

- [x] 2.5.1 Add `output: String?` to `ColorsEntry` with doc comment
- [x] 2.5.2 Add `templatesPath: String?` to `ColorsEntry` with doc comment
- [x] 2.5.3 Add `templatesPath: String?` to `IconsEntry` with doc comment
- [x] 2.5.4 Add `templatesPath: String?` to `ImagesEntry` with doc comment

### 2.6 Schema Verification

- [x] 2.6.1 Run `./bin/mise run codegen:pkl` — new optional fields appear in Generated/*.pkl.swift
- [x] 2.6.2 Run `./bin/mise run build` — compiles (new fields are optional, nil by default)
- [x] 2.6.3 Run `pkl eval --format json` on example configs — verify new fields absent when not set
- [x] 2.6.4 Create test PKL config with entry-level overrides — verify JSON output

---

## 3. Entry-Level Overrides — Swift Resolution Logic

> Обновление Swift-кода для использования entry-level overrides.

### 3.1 Research: Find All Resolution Points

- [x] 3.1.1 Find all usages of `iOSConfig.xcassetsPath` in Swift code
- [x] 3.1.2 Find all usages of `iOSConfig.templatesPath` in Swift code
- [x] 3.1.3 Find all usages of `figma.lightFileId` for icons/images loading
- [x] 3.1.4 Find all usages of `AndroidConfig.mainRes`, `AndroidConfig.templatesPath`
- [x] 3.1.5 Find all usages of `FlutterConfig.output`, `FlutterConfig.templatesPath`
- [x] 3.1.6 Find all usages of `WebConfig.output`, `WebConfig.templatesPath`

### 3.2 iOS Entry Resolution

- [ ] 3.2.1 Add resolved computed properties to `iOSColorsEntry` extension (resolvedXcassetsPath, resolvedTemplatesPath)
- [ ] 3.2.2 Add resolved computed properties to `iOSIconsEntry` extension
- [ ] 3.2.3 Add resolved computed properties to `iOSImagesEntry` extension
- [ ] 3.2.4 Update `PluginiOSColorsExport.swift` to use resolved properties
- [ ] 3.2.5 Update `PluginiOSIconsExport.swift` to use resolved properties
- [ ] 3.2.6 Update `PluginiOSImagesExport.swift` to use resolved properties

### 3.3 figmaFileId Resolution

- [ ] 3.3.1 Add `resolvedFigmaFileId(fallback:)` method to FrameSource-based entries
- [ ] 3.3.2 Update `IconsExportContextImpl` to accept per-entry figmaFileId
- [ ] 3.3.3 Update `ImagesExportContextImpl` to accept per-entry figmaFileId
- [ ] 3.3.4 Update icon loaders to use entry-level figmaFileId
- [ ] 3.3.5 Update image loaders to use entry-level figmaFileId

### 3.4 Android Entry Resolution

- [ ] 3.4.1 Add resolved computed properties to Android entry extensions
- [ ] 3.4.2 Update `PluginAndroidColorsExport.swift` to use resolved properties
- [ ] 3.4.3 Update `PluginAndroidIconsExport.swift` to use resolved properties
- [ ] 3.4.4 Update `PluginAndroidImagesExport.swift` to use resolved properties

### 3.5 Flutter Entry Resolution

- [ ] 3.5.1 Add resolved computed properties to Flutter entry extensions
- [ ] 3.5.2 Update `PluginFlutterColorsExport.swift` to use resolved properties
- [ ] 3.5.3 Update `PluginFlutterIconsExport.swift` to use resolved properties
- [ ] 3.5.4 Update `PluginFlutterImagesExport.swift` to use resolved properties

### 3.6 Web Entry Resolution

- [ ] 3.6.1 Add resolved computed properties to Web entry extensions
- [ ] 3.6.2 Update `PluginWebColorsExport.swift` to use resolved properties
- [ ] 3.6.3 Update `PluginWebIconsExport.swift` to use resolved properties
- [ ] 3.6.4 Update `PluginWebImagesExport.swift` to use resolved properties

### 3.7 Tests for Entry Overrides

- [ ] 3.7.1 Add tests: iOS entry with xcassetsPath override resolves correctly
- [ ] 3.7.2 Add tests: iOS entry without override falls back to config value
- [ ] 3.7.3 Add tests: figmaFileId override resolves correctly for icons
- [ ] 3.7.4 Add tests: figmaFileId override resolves correctly for images
- [ ] 3.7.5 Add tests: Android entry with mainRes override resolves correctly
- [ ] 3.7.6 Add tests: Flutter entry with output override resolves correctly
- [ ] 3.7.7 Add tests: Web entry with output override resolves correctly
- [ ] 3.7.8 Run `./bin/mise run test` — all tests pass

---

## 4. Constraints — PKL Validation

> Constraints добавляются в PKL-схемы. Zero diff в сгенерированных Swift типах.

### 4.1 String Constraints

- [x] 4.1.1 Add `(!isEmpty)` to `VariablesColors.tokensFileId`
- [x] 4.1.2 Add `(!isEmpty)` to `VariablesColors.tokensCollectionName`
- [x] 4.1.3 Add `(!isEmpty)` to `VariablesColors.lightModeName`
- [x] 4.1.4 Add `(!isEmpty)` to `iOSConfig.xcodeprojPath`
- [x] 4.1.5 Add `(!isEmpty)` to `iOSConfig.target`
- [x] 4.1.6 Add `(!isEmpty)` to `AndroidConfig.mainRes`
- [x] 4.1.7 Add `(!isEmpty)` to `FlutterConfig.output`
- [x] 4.1.8 Add `(!isEmpty)` to `WebConfig.output`
- [x] 4.1.9 Add `(!isEmpty)` to `ThemeAttributes.themeName`

### 4.2 Numeric Constraints

- [x] 4.2.1 Add `(isBetween(1, 600))` to `FigmaConfig.timeout`

### 4.3 Constraints Verification

- [x] 4.3.1 Run `./bin/mise run codegen:pkl` — verify zero diff
- [x] 4.3.2 Create test PKL with empty `xcodeprojPath` — verify `pkl eval` fails
- [x] 4.3.3 Create test PKL with `timeout = 0` — verify `pkl eval` fails
- [x] 4.3.4 Create test PKL with valid values — verify `pkl eval` succeeds
- [x] 4.3.5 Run `./bin/mise run test` — all tests pass

---

## 5. Verification + Documentation

### 5.1 Full Verification

- [ ] 5.1.1 Run `./bin/mise run codegen:pkl` — all Generated files up to date
- [ ] 5.1.2 Run `pkl eval --format json` on all example configs — no errors
- [ ] 5.1.3 Run `./bin/mise run build` — compiles
- [ ] 5.1.4 Run `./bin/mise run test` — all tests pass
- [ ] 5.1.5 Run `./bin/mise run format && ./bin/mise run lint` — no issues
- [ ] 5.1.6 Create unified Oymyakon-style test config (6-in-1) and verify it parses
- [ ] 5.1.7 Verify backward compatibility: existing example configs work unchanged

### 5.2 Documentation

- [ ] 5.2.1 Update example configs in `Sources/ExFigCLI/Resources/Schemas/examples/`
- [ ] 5.2.2 Add entry-level override example to `exfig-ios.pkl`
- [ ] 5.2.3 Update CLAUDE.md if needed (new patterns, gotchas)
- [ ] 5.2.4 Update `docs/PKL.md` with entry-level overrides section
