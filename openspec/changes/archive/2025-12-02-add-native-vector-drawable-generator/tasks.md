# Tasks: Add Native Vector Drawable XML Generator

> **Approach: Test-Driven Development (TDD)**
>
> Each feature follows Red-Green-Refactor cycle:
>
> 1. Write failing test first
> 2. Implement minimal code to pass
> 3. Refactor while keeping tests green

## 0. Create SVGKit Target

- [ ] 0.1 Create `Sources/SVGKit/` directory
- [ ] 0.2 Move `SVGParser.swift` from AndroidExport/ImageVector/ to SVGKit/
- [ ] 0.3 Move `SVGPathParser.swift` from AndroidExport/ImageVector/ to SVGKit/
- [ ] 0.4 Move `ImageVectorGenerator.swift` from AndroidExport/ImageVector/ to SVGKit/
- [ ] 0.5 Add SVGKit target to `Package.swift`
- [ ] 0.6 Add SVGKitTests target to `Package.swift`
- [ ] 0.7 Update AndroidExport to depend on SVGKit
- [ ] 0.8 Move existing tests from AndroidExportTests to SVGKitTests
- [ ] 0.9 Update imports in AndroidExport files
- [ ] 0.10 Verify build passes (`mise run build`)
- [ ] 0.11 Verify tests pass (`mise run test`)

## 1. Extend Data Model (TDD)

- [ ] 1.1 Write tests for `SVGTransform` struct
- [ ] 1.2 Implement `SVGTransform` to pass tests
- [ ] 1.3 Write tests for `SVGGroup` struct
- [ ] 1.4 Implement `SVGGroup` to pass tests
- [ ] 1.5 Write tests for extended `ParsedSVG` with groups
- [ ] 1.6 Extend `ParsedSVG` to pass tests

## 2. Implement Group Parsing (TDD)

- [ ] 2.1 Write tests for parsing SVG `<g>` elements
- [ ] 2.2 Implement `<g>` parsing to pass tests
- [ ] 2.3 Write tests for `transform` attribute parsing (translate, scale, rotate)
- [ ] 2.4 Implement transform parsing to pass tests
- [ ] 2.5 Write tests for `clip-path` parsing
- [ ] 2.6 Implement clip-path parsing to pass tests
- [ ] 2.7 Write tests for nested groups
- [ ] 2.8 Implement nested group support to pass tests

## 3. Create VectorDrawableXMLGenerator (TDD)

- [ ] 3.1 Write tests for `<vector>` root element generation
- [ ] 3.2 Implement root element generation to pass tests
- [ ] 3.3 Write tests for `<path>` element with fill/stroke attributes
- [ ] 3.4 Implement path generation to pass tests
- [ ] 3.5 Write tests for `<group>` element with transforms
- [ ] 3.6 Implement group generation to pass tests
- [ ] 3.7 Write tests for `<clip-path>` element
- [ ] 3.8 Implement clip-path generation to pass tests
- [ ] 3.9 Write tests for `autoMirrored` RTL support
- [ ] 3.10 Implement autoMirrored to pass tests

## 4. Create NativeVectorDrawableConverter (TDD)

- [ ] 4.1 Write tests for single file conversion
- [ ] 4.2 Implement single file conversion to pass tests
- [ ] 4.3 Write tests for directory batch conversion
- [ ] 4.4 Implement batch conversion to pass tests
- [ ] 4.5 Write tests for error handling (invalid SVG, missing files)
- [ ] 4.6 Implement error handling to pass tests

## 5. Integration

- [ ] 5.1 Replace converter in `ExFigCommand.swift`
- [ ] 5.2 Update `ExportIcons.swift` to pass RTL flag to converter
- [ ] 5.3 Remove `rewriteXMLFile` post-processing from `ExportIcons.swift`
- [ ] 5.4 Update `ExportImages.swift` to use native converter

## 6. Validation

- [ ] 6.1 Compare output with existing Examples/ icons
- [ ] 6.2 Test with real Figma exports
- [ ] 6.3 Verify dark mode icon variants work correctly
- [ ] 6.4 Run full test suite (`mise run test`)

## 7. Cleanup

- [ ] 7.1 Remove `VectorDrawableConverter.swift`
- [ ] 7.2 Remove `Release/vd-tool/` directory
- [ ] 7.3 Remove empty `AndroidExport/ImageVector/` directory
- [ ] 7.4 Update CLAUDE.md documentation
