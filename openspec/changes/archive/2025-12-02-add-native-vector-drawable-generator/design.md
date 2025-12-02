# Design: Native Vector Drawable XML Generator

## Context

ExFig exports design assets from Figma to Android projects. For vector icons, it needs to convert SVG files to Android
Vector Drawable XML format. Currently this is done via `vd-tool`, an external Java utility that requires JRE.

The project already has a native Swift implementation for parsing SVG and generating Jetpack Compose `ImageVector` code.
This change extends that foundation to also generate Vector Drawable XML.

## Goals / Non-Goals

**Goals:**

- Remove Java/vd-tool dependency entirely
- Support full Vector Drawable XML specification (paths, groups, clip-paths, transforms)
- Maintain backward compatibility with existing export workflows
- Extract SVG parsing into reusable `SVGKit` target for future library extraction

**Non-Goals:**

- Animated Vector Drawable support (out of scope)
- SVG features not supported by Vector Drawable format
- Changes to ImageVector generation (keep existing behavior)

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                       SVGKit                            │
│  (new target - can be extracted as separate library)    │
│                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐  │
│  │  SVGParser  │    │ SVGTransform│    │  SVGGroup   │  │
│  └──────┬──────┘    └─────────────┘    └─────────────┘  │
│         │                                               │
│         v                                               │
│  ┌─────────────┐                                        │
│  │  ParsedSVG  │                                        │
│  └──────┬──────┘                                        │
│         │                                               │
│    ┌────┴────┐                                          │
│    │         │                                          │
│    v         v                                          │
│ ┌──────────────────┐  ┌─────────────────────────────┐   │
│ │ImageVectorGen    │  │VectorDrawableXMLGenerator   │   │
│ │(Kotlin output)   │  │(XML output)                 │   │
│ └──────────────────┘  └─────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          │
                          v
              ┌───────────────────────┐
              │    AndroidExport      │
              │  (depends on SVGKit)  │
              └───────────────────────┘
```

## Module Structure

### New Target: `SVGKit`

**Location:** `Sources/SVGKit/`

**Contents (moved from AndroidExport/ImageVector/):**

- `SVGParser.swift` - SVG parsing with group support
- `SVGPathParser.swift` - Path command parsing
- `SVGTypes.swift` - ParsedSVG, SVGPath, SVGGroup, SVGTransform, SVGColor
- `ImageVectorGenerator.swift` - Kotlin ImageVector generation
- `VectorDrawableXMLGenerator.swift` - XML Vector Drawable generation (new)

**Dependencies:** None (pure Swift, Foundation only)

**Why separate target:**

- Clean separation of concerns
- Can be extracted to standalone Swift Package later
- Testable in isolation
- Reusable by other tools

### Updated Target: `AndroidExport`

**Dependencies:** `ExFigCore`, `SVGKit`, `Stencil`, `StencilSwiftKit`

**Changes:**

- Remove `ImageVector/` directory (moved to SVGKit)
- Keep Android-specific exporters that use SVGKit

## Decisions

### 1. New Target vs Extend Existing

**Decision:** Create new `SVGKit` target.

**Rationale:**

- Future-proofs for library extraction
- Clear dependency direction (SVGKit has no dependencies)
- Better testability
- Follows single responsibility principle

### 2. Extend ParsedSVG vs Create New Type

**Decision:** Extend existing `ParsedSVG` with optional `groups` property.

**Rationale:**

- Maintains backward compatibility - existing code sees `paths` as before
- Groups are optional - simple SVGs without groups work unchanged
- Single parser for both output formats

### 3. Group Structure

**Decision:** Add `SVGGroup` type with recursive children.

```swift
public struct SVGGroup: Equatable, Sendable {
    public let transform: SVGTransform?
    public let clipPath: String?
    public let paths: [SVGPath]
    public let children: [SVGGroup]
    public let opacity: Double?
}
```

**Rationale:**

- Mirrors Android `<group>` element structure
- Supports nested groups (common in complex icons)
- Separates transform concerns from path data

### 4. Transform Representation

**Decision:** Use decomposed transform properties matching Android attributes.

```swift
public struct SVGTransform: Equatable, Sendable {
    public let translateX: Double?
    public let translateY: Double?
    public let scaleX: Double?
    public let scaleY: Double?
    public let rotation: Double?
    public let pivotX: Double?
    public let pivotY: Double?
}
```

**Rationale:**

- Direct mapping to Android `android:translateX`, `android:rotation`, etc.
- SVG `transform` attribute will be decomposed during parsing
- Supports common transforms; complex matrix transforms logged as warnings

### 5. Converter Integration

**Decision:** Drop-in replacement with same interface.

**Rationale:**

- Minimal changes to export commands
- Single point of change in `ExFigCommand.swift`
- Easy rollback if issues arise

## File Changes Summary

### Files to Create

| File | Purpose | | --------------------------------------------------- | ----------------------------- | |
`Sources/SVGKit/SVGTypes.swift` | Shared types (new file) | | `Sources/SVGKit/VectorDrawableXMLGenerator.swift` | XML
generation | | `Sources/ExFig/Output/NativeVectorDrawableConverter.swift` | File conversion wrapper | |
`Tests/SVGKitTests/` (directory) | Tests for SVGKit |

### Files to Move

| From | To | | --------------------------------------------------- | ----------------------------- | |
`Sources/AndroidExport/ImageVector/SVGParser.swift` | `Sources/SVGKit/SVGParser.swift` | |
`Sources/AndroidExport/ImageVector/SVGPathParser.swift` | `Sources/SVGKit/SVGPathParser.swift` | |
`Sources/AndroidExport/ImageVector/ImageVectorGenerator.swift` | `Sources/SVGKit/ImageVectorGenerator.swift` |

### Files to Modify

| File | Changes | | ---------------------- | ------------------------------------------ | | `Package.swift` | Add
SVGKit target, update AndroidExport deps | | `ExFigCommand.swift` | Switch to native converter | | `ExportIcons.swift` |
Pass RTL flag, remove post-processing | | `ExportImages.swift` | Use native converter |

### Files to Delete

| File | Reason | | ---------------------------------------------- | ----------------------------------- | |
`Sources/ExFig/Output/VectorDrawableConverter.swift` | Replaced by native implementation | | `Release/vd-tool/`
(directory) | No longer needed |

## Risks / Trade-offs

| Risk | Mitigation | | --------------------------- | ------------------------------------------------------- | | Output
differs from vd-tool | Compare output on all Examples/ icons before removing | | Complex SVG transforms fail | Log
warnings, fall back to flattened paths | | Breaking change for users | Document in release notes, provide migration
guide | | Performance regression | Native Swift should be faster than spawning Java process | | Import changes in
existing code | Update imports from AndroidExport to SVGKit |

## Migration Plan

1. Create `SVGKit` target with existing files
2. Move SVG-related code from AndroidExport to SVGKit
3. Update imports and dependencies
4. Implement VectorDrawableXMLGenerator with TDD
5. Validate output matches vd-tool on all example icons
6. Remove vd-tool dependency after validation passes
7. Update documentation

## Open Questions

- Q: Should we keep vd-tool as fallback for edge cases?
- A: No, clean removal preferred. Log warnings for unsupported features.
