## ADDED Requirements

### Requirement: SourceKind typealias in Common.pkl

The `Common.pkl` schema SHALL define a `SourceKind` typealias:

```pkl
typealias SourceKind = "figma"|"penpot"|"tokens-file"|"tokens-studio"|"sketch-file"
```

#### Scenario: Valid sourceKind values accepted

- **WHEN** a PKL config sets `sourceKind = "figma"`
- **THEN** PKL evaluation SHALL succeed

#### Scenario: Invalid sourceKind rejected

- **WHEN** a PKL config sets `sourceKind = "unknown"`
- **THEN** PKL evaluation SHALL fail with a validation error

### Requirement: sourceKind field in FrameSource

The `FrameSource` open class in `Common.pkl` SHALL include an optional `sourceKind` field:

```pkl
open class FrameSource extends NameProcessing {
    sourceKind: SourceKind?
    // ... existing fields
}
```

When `sourceKind` is `null`, the system SHALL default to `"figma"`.

#### Scenario: FrameSource without sourceKind defaults to figma

- **WHEN** an icons entry does not specify `sourceKind`
- **THEN** the system SHALL treat it as `sourceKind = "figma"`

#### Scenario: FrameSource with explicit sourceKind

- **WHEN** an icons entry specifies `sourceKind = "penpot"`
- **THEN** the system SHALL use `"penpot"` as the source kind for that entry

### Requirement: sourceKind field in VariablesSource

The `VariablesSource` open class in `Common.pkl` SHALL include an optional `sourceKind` field:

```pkl
open class VariablesSource extends NameProcessing {
    sourceKind: SourceKind?
    // ... existing fields
}
```

When `sourceKind` is `null`, the system SHALL auto-detect:

- If `tokensFile` is set → `.tokensFile`
- Otherwise → `.figma`

#### Scenario: VariablesSource auto-detects tokensFile

- **WHEN** a colors entry has `tokensFile` set but `sourceKind` is null
- **THEN** the system SHALL use `tokensFile` as the source kind

#### Scenario: VariablesSource auto-detects figma

- **WHEN** a colors entry has no `tokensFile` and `sourceKind` is null
- **THEN** the system SHALL use `figma` as the source kind

#### Scenario: Explicit sourceKind overrides auto-detection

- **WHEN** a colors entry has `sourceKind = "tokens-studio"` and no `tokensFile`
- **THEN** the system SHALL use `tokens-studio` as the source kind regardless of auto-detection

#### Scenario: Explicit sourceKind takes priority over tokensFile presence

- **WHEN** a colors entry has `sourceKind = "figma"` AND `tokensFile` is also set
- **THEN** the system SHALL use `figma` as the source kind (explicit overrides auto-detection)
- **NOTE:** This handles the case where a user switches back from tokens-file to figma without removing the `tokensFile` field

### Requirement: PKL codegen produces DesignSourceKind bridging

After running `./bin/mise run codegen:pkl`, the generated Swift types SHALL include `SourceKind` as a String-based enum. The ExFig-* platform entry types SHALL bridge PKL `SourceKind` to ExFigCore `DesignSourceKind`.

#### Scenario: PKL SourceKind bridges to Swift DesignSourceKind

- **WHEN** a PKL config with `sourceKind = "tokens-file"` is evaluated
- **THEN** the generated Swift value SHALL be bridged to `DesignSourceKind.tokensFile`

### Requirement: Backward compatibility

All existing PKL configs without `sourceKind` fields SHALL continue to work without modification. The field is optional with null default, and null maps to auto-detected behavior (figma for FrameSource, figma-or-tokensFile for VariablesSource).

#### Scenario: Existing config without sourceKind

- **WHEN** an existing `exfig.pkl` config with no `sourceKind` fields is evaluated
- **THEN** PKL evaluation SHALL succeed
- **AND** export behavior SHALL be identical to the current implementation
