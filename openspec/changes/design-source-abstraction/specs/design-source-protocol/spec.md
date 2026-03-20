## ADDED Requirements

### Requirement: ColorsSource protocol

The system SHALL define a `ColorsSource` protocol in ExFigCore with the following contract:

```swift
public protocol ColorsSource: Sendable {
    func loadColors(from input: ColorsSourceInput) async throws -> ColorsLoadOutput
}
```

The protocol SHALL accept the existing `ColorsSourceInput` type and return the existing `ColorsLoadOutput` type, preserving full compatibility with downstream processors and exporters. The protocol SHALL NOT include a `sourceKind` property — dispatch is handled by the source factory, not by protocol consumers.

#### Scenario: Figma source loads colors via Variables API

- **WHEN** a `FigmaColorsSource` receives a `ColorsSourceInput` with `tokensFileId`, `tokensCollectionName`, and `lightModeName`
- **THEN** it SHALL return a `ColorsLoadOutput` with `light`, `dark`, `lightHC`, and `darkHC` color arrays populated from Figma Variables

#### Scenario: Tokens file source loads colors from local file

- **WHEN** a `TokensFileColorsSource` receives a `ColorsSourceInput` with `tokensFilePath` set
- **THEN** it SHALL return a `ColorsLoadOutput` with `light` array populated from the parsed `.tokens.json` file
- **AND** `dark`, `lightHC`, `darkHC` arrays SHALL be empty

### Requirement: ComponentsSource protocol

The system SHALL define a `ComponentsSource` protocol in ExFigCore with the following contract:

```swift
public protocol ComponentsSource: Sendable {
    func loadIcons(from input: IconsSourceInput) async throws -> IconsLoadOutput
    func loadImages(from input: ImagesSourceInput) async throws -> ImagesLoadOutput
}
```

The protocol SHALL accept the existing `IconsSourceInput`/`ImagesSourceInput` types and return `IconsLoadOutput`/`ImagesLoadOutput`. The protocol SHALL NOT include a `sourceKind` property.

#### Scenario: Figma source loads icons from a frame

- **WHEN** a `FigmaComponentsSource` receives an `IconsSourceInput` with `frameName`
- **THEN** it SHALL return an `IconsLoadOutput` with `ImagePack` arrays containing SVG/PDF download URLs from Figma

#### Scenario: Figma source loads images with RTL variants

- **WHEN** a `ComponentsSource` receives an `IconsSourceInput` with `rtlProperty` set
- **THEN** it SHALL detect RTL variants via the component property and pair them with their LTR counterparts in the returned `ImagePack` entries

### Requirement: TypographySource protocol

The system SHALL define a `TypographySource` protocol in ExFigCore with the following contract:

```swift
public protocol TypographySource: Sendable {
    func loadTypography(from input: TypographySourceInput) async throws -> TypographyLoadOutput
}
```

The protocol SHALL NOT include a `sourceKind` property.

#### Scenario: Figma source loads text styles

- **WHEN** a `FigmaTypographySource` receives a `TypographySourceInput` with `fileId`
- **THEN** it SHALL return a `TypographyLoadOutput` with `TextStyle` entries populated from Figma Styles API

### Requirement: DesignSourceKind enum

The system SHALL define a `DesignSourceKind` enum in ExFigCore:

```swift
public enum DesignSourceKind: String, Sendable, CaseIterable {
    case figma
    case penpot
    case tokensFile
    case tokensStudio
    case sketchFile
}
```

The enum SHALL be `Sendable` and `CaseIterable`. Cases for future sources (penpot, tokensStudio, sketchFile) SHALL be defined but have no implementations yet.

#### Scenario: Enum includes all planned source kinds

- **WHEN** `DesignSourceKind.allCases` is enumerated
- **THEN** it SHALL contain exactly: `figma`, `penpot`, `tokensFile`, `tokensStudio`, `sketchFile`

### Requirement: ColorsSourceConfig protocol

The system SHALL define a `ColorsSourceConfig` protocol in ExFigCore:

```swift
public protocol ColorsSourceConfig: Sendable {}
```

Source-specific config types SHALL conform to this protocol:

```swift
public struct FigmaColorsConfig: ColorsSourceConfig {
    public let tokensFileId: String
    public let tokensCollectionName: String
    public let lightModeName: String
    public let darkModeName: String?
    public let lightHCModeName: String?
    public let darkHCModeName: String?
    public let primitivesModeName: String?
}

public struct TokensFileColorsConfig: ColorsSourceConfig {
    public let filePath: String
    public let groupFilter: String?
}
```

#### Scenario: FigmaColorsConfig holds Figma-specific fields

- **WHEN** a `FigmaColorsConfig` is constructed
- **THEN** it SHALL contain all fields previously in `ColorsSourceInput` that are Figma-specific (`tokensFileId`, `tokensCollectionName`, `lightModeName`, `darkModeName`, `lightHCModeName`, `darkHCModeName`, `primitivesModeName`)

#### Scenario: TokensFileColorsConfig holds tokens-file-specific fields

- **WHEN** a `TokensFileColorsConfig` is constructed
- **THEN** it SHALL contain `filePath` and optional `groupFilter`
- **AND** it SHALL NOT contain any Figma-specific fields

#### Scenario: Source implementations cast sourceConfig

- **WHEN** `FigmaColorsSource.loadColors()` receives a `ColorsSourceInput`
- **THEN** it SHALL cast `input.sourceConfig` to `FigmaColorsConfig`
- **AND** it SHALL throw a descriptive error if the cast fails

### Requirement: ColorsSourceInput refactored with sourceConfig

`ColorsSourceInput` SHALL be refactored to contain `sourceKind`, `sourceConfig`, and only shared (source-agnostic) fields:

```swift
public struct ColorsSourceInput: Sendable {
    public let sourceKind: DesignSourceKind
    public let sourceConfig: any ColorsSourceConfig
    public let nameValidateRegexp: String?
    public let nameReplaceRegexp: String?
}
```

Fields `tokensFilePath`, `tokensFileGroupFilter`, `tokensFileId`, `tokensCollectionName`, `lightModeName`, `darkModeName`, `lightHCModeName`, `darkHCModeName`, `primitivesModeName` SHALL be removed from `ColorsSourceInput` and moved to the appropriate `ColorsSourceConfig` conformance.

The `isLocalTokensFile` computed property SHALL be removed — dispatch is now explicit via `sourceKind`.

#### Scenario: Default sourceKind is figma

- **WHEN** a `ColorsSourceInput` is constructed with a `FigmaColorsConfig`
- **THEN** `sourceKind` SHALL be `.figma`

#### Scenario: Tokens file sourceKind

- **WHEN** a `ColorsSourceInput` is constructed with a `TokensFileColorsConfig`
- **THEN** `sourceKind` SHALL be `.tokensFile`

### Requirement: Icons/Images/Typography SourceInputs add sourceKind only

`IconsSourceInput`, `ImagesSourceInput`, and `TypographySourceInput` SHALL add a `sourceKind: DesignSourceKind` field with a default value of `.figma`. They SHALL NOT be refactored with a SourceConfig protocol — they currently have only Figma fields. SourceConfig split is deferred until a second source requires it.

#### Scenario: Backward compatibility for Icons/Images/Typography

- **WHEN** existing code constructs `IconsSourceInput` without specifying `sourceKind`
- **THEN** the code SHALL compile without changes due to the default value

### Requirement: Protocols live in ExFigCore

All source protocols (`ColorsSource`, `ComponentsSource`, `TypographySource`), `ColorsSourceConfig` protocol, config structs (`FigmaColorsConfig`, `TokensFileColorsConfig`), and `DesignSourceKind` SHALL be defined in the `ExFigCore` module. They SHALL NOT import `FigmaAPI`, `PenpotAPI`, or any other source-specific module.

#### Scenario: ExFigCore compiles without FigmaAPI

- **WHEN** ExFigCore is compiled
- **THEN** it SHALL NOT have any import dependency on FigmaAPI or other source-specific modules

### Requirement: FigmaColorsSource implementation

The system SHALL provide a `FigmaColorsSource` struct in ExFigCLI that implements `ColorsSource`. It SHALL encapsulate the current `ColorsVariablesLoader` logic extracted from `ColorsExportContextImpl.loadColorsFromFigma()`. It SHALL cast `input.sourceConfig` to `FigmaColorsConfig` and use its fields to configure the `ColorsVariablesLoader`.

#### Scenario: FigmaColorsSource produces identical output to current implementation

- **WHEN** `FigmaColorsSource.loadColors()` is called with a `ColorsSourceInput` containing a `FigmaColorsConfig` with the same field values as the current implementation
- **THEN** the returned `ColorsLoadOutput` SHALL be identical

#### Scenario: FigmaColorsSource rejects wrong config type

- **WHEN** `FigmaColorsSource.loadColors()` is called with a `ColorsSourceInput` containing a `TokensFileColorsConfig`
- **THEN** it SHALL throw an error indicating config type mismatch

### Requirement: FigmaComponentsSource implementation

The system SHALL provide a `FigmaComponentsSource` struct in ExFigCLI that implements `ComponentsSource`. It SHALL wrap the existing `IconsLoader` and `ImagesLoader` (via `ImageLoaderBase`) without modifying their internal logic.

#### Scenario: FigmaComponentsSource wraps IconsLoader

- **WHEN** `FigmaComponentsSource.loadIcons()` is called
- **THEN** it SHALL delegate to `IconsLoader` internally and return the same `IconsLoadOutput`

#### Scenario: Granular cache remains internal

- **WHEN** `FigmaComponentsSource` is used with granular cache enabled
- **THEN** the granular cache logic SHALL remain inside the wrapper, invisible to the `ComponentsSource` protocol consumer

### Requirement: FigmaTypographySource implementation

The system SHALL provide a `FigmaTypographySource` struct in ExFigCLI that implements `TypographySource`. It SHALL encapsulate the current `TextStylesLoader` logic.

#### Scenario: FigmaTypographySource produces identical output

- **WHEN** `FigmaTypographySource.loadTypography()` is called with the same input as the current implementation
- **THEN** the returned `TypographyLoadOutput` SHALL be identical
