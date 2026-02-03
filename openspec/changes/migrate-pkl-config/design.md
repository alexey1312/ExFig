# Design: PKL Configuration Architecture

## Context

ExFig uses YAML for configuration via the Yams library. Users request config inheritance for multi-project setups,
but YAML has no native support for this. Options considered: TOML (no inheritance), JSON (no comments), PKL (native
inheritance via `amends`).

## Goals / Non-Goals

**Goals:**

- Native configuration inheritance and composition
- Type-safe configuration with validation at parse time
- Remote schema imports for team-wide consistency
- Maintain existing `Params` Decodable structure

**Non-Goals:**

- YAML backward compatibility (clean break)
- Bundling PKL CLI with ExFig releases
- Auto-migration tool from YAML to PKL

## Decisions

### 1. PKL CLI Distribution via mise

**Decision:** Users install PKL via `mise use pkl`, not bundled with ExFig.

**Rationale:**

- Follows hk pattern (`mise use hk pkl`)
- Avoids bloating release archives with 10MB binaries per platform
- mise handles version management and PATH setup
- Users already use mise for ExFig development

**Implementation:**

```swift
struct PKLLocator {
    func findPKL() throws -> URL {
        // 1. mise shim: ~/.local/share/mise/shims/pkl
        // 2. PATH fallback
        // 3. Error with install instructions
    }
}
```

### 2. PKL → JSON → Params Pipeline

**Decision:** PKL evaluates to JSON, then JSONDecoder creates `Params`.

**Rationale:**

- No changes to existing 1142-line `Params.swift`
- PKL has native `--format json` output
- JSONDecoder is built-in, no new dependencies
- Type validation happens in PKL schemas before reaching Swift

**Data flow:**

```
exfig.pkl → pkl eval --format json → String → JSONDecoder → Params
```

### 3. Schema Publishing via GitHub Releases

**Decision:** PKL schemas published as separate GitHub release artifacts.

**URL format:**

```
package://github.com/niceplaces/exfig/releases/download/schemas-v2.0.0/exfig-schemas@2.0.0#/ExFig.pkl
```

**Rationale:**

- Schemas can version independently from CLI
- Standard PKL package resolution
- GitHub handles hosting and versioning
- Users pin schema version in `amends` declaration

### 4. Complete YAML Removal

**Decision:** Remove YAML support entirely, no deprecation period.

**Rationale:**

- Clean codebase without dual-format complexity
- Forces adoption of superior tooling
- Simplifies testing and maintenance
- ExFig 2.0 is a major version (breaking changes expected)

## Architecture

### New Files

```
Sources/ExFig/
├── PKL/
│   ├── PKLError.swift         # NotFound, EvaluationFailed
│   ├── PKLLocator.swift       # Find pkl via mise/PATH
│   └── PKLEvaluator.swift     # Subprocess wrapper
└── Resources/
    └── Schemas/
        ├── PklProject         # Package manifest
        ├── ExFig.pkl          # Main schema (abstract)
        ├── Figma.pkl          # Figma settings
        ├── Common.pkl         # Shared settings
        ├── iOS.pkl            # iOS platform
        ├── Android.pkl        # Android platform
        ├── Flutter.pkl        # Flutter platform
        └── Web.pkl            # Web platform
```

### PKLEvaluator Interface

```swift
struct PKLEvaluator {
    let pklPath: URL

    func evaluate(configPath: URL) async throws -> Params {
        // 1. Run: pkl eval --format json <configPath>
        // 2. Capture stdout
        // 3. JSONDecoder.decode(Params.self, from: jsonData)
    }
}
```

### PKL Schema Structure

```pkl
// ExFig.pkl
abstract module ExFig

import "Figma.pkl"
import "Common.pkl"
import "iOS.pkl"
import "Android.pkl"
import "Flutter.pkl"
import "Web.pkl"

figma: Figma?
common: Common?
ios: iOS?
android: Android?
flutter: Flutter?
web: Web?
```

## Risks / Trade-offs

| Risk                        | Mitigation                                   |
| --------------------------- | -------------------------------------------- |
| PKL not installed           | Clear error message with `mise use pkl`      |
| Slower startup (subprocess) | PKL eval is fast (~50ms for typical configs) |
| Users unfamiliar with PKL   | Comprehensive docs + migration guide         |
| Schema version mismatch     | Explicit version in `amends` URL             |

## Migration Plan

1. Create PKL schemas matching current `Params.swift` structure
2. Implement `PKLLocator` and `PKLEvaluator`
3. Update `ExFigOptions` to use PKL
4. Update `ConfigDiscovery` for `.pkl` files
5. Remove Yams from `Package.swift`
6. Update all documentation
7. Publish schemas to GitHub releases
8. Release ExFig 2.0

**Rollback:** Not applicable (major version with breaking changes).

## Open Questions

None — all decisions made.
