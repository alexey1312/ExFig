## ADDED Requirements

### Requirement: ColorsSource protocol

The system SHALL define a `ColorsSource` protocol in ExFigCore with the following contract:

```swift
public protocol ColorsSource: Sendable {
    var sourceKind: DesignSourceKind { get }
    func loadColors(from input: ColorsSourceInput) async throws -> ColorsLoadOutput
}
```

The protocol SHALL accept the existing `ColorsSourceInput` type and return the existing `ColorsLoadOutput` type, preserving full compatibility with downstream processors and exporters.

#### Scenario: Figma source loads colors via Variables API

- **WHEN** a `ColorsSource` with `sourceKind == .figma` receives a `ColorsSourceInput` with `tokensFileId`, `tokensCollectionName`, and `lightModeName`
- **THEN** it SHALL return a `ColorsLoadOutput` with `light`, `dark`, `lightHC`, and `darkHC` color arrays populated from Figma Variables

#### Scenario: Tokens file source loads colors from local file

- **WHEN** a `ColorsSource` with `sourceKind == .tokensFile` receives a `ColorsSourceInput` with `tokensFilePath` set
- **THEN** it SHALL return a `ColorsLoadOutput` with `light` array populated from the parsed `.tokens.json` file
- **AND** `dark`, `lightHC`, `darkHC` arrays SHALL be empty

### Requirement: ComponentsSource protocol

The system SHALL define a `ComponentsSource` protocol in ExFigCore with the following contract:

```swift
public protocol ComponentsSource: Sendable {
    var sourceKind: DesignSourceKind { get }
    func loadIcons(from input: IconsSourceInput) async throws -> IconsLoadOutput
    func loadImages(from input: ImagesSourceInput) async throws -> ImagesLoadOutput
}
```

The protocol SHALL accept the existing `IconsSourceInput`/`ImagesSourceInput` types and return `IconsLoadOutput`/`ImagesLoadOutput`.

#### Scenario: Figma source loads icons from a frame

- **WHEN** a `ComponentsSource` with `sourceKind == .figma` receives an `IconsSourceInput` with `frameName`
- **THEN** it SHALL return an `IconsLoadOutput` with `ImagePack` arrays containing SVG/PDF download URLs from Figma

#### Scenario: Figma source loads images with RTL variants

- **WHEN** a `ComponentsSource` receives an `IconsSourceInput` with `rtlProperty` set
- **THEN** it SHALL detect RTL variants via the component property and pair them with their LTR counterparts in the returned `ImagePack` entries

### Requirement: TypographySource protocol

The system SHALL define a `TypographySource` protocol in ExFigCore with the following contract:

```swift
public protocol TypographySource: Sendable {
    var sourceKind: DesignSourceKind { get }
    func loadTypography(from input: TypographySourceInput) async throws -> TypographyLoadOutput
}
```

#### Scenario: Figma source loads text styles

- **WHEN** a `TypographySource` with `sourceKind == .figma` receives a `TypographySourceInput` with `fileId`
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

### Requirement: SourceInput types include sourceKind

Each `*SourceInput` type (`ColorsSourceInput`, `IconsSourceInput`, `ImagesSourceInput`, `TypographySourceInput`) SHALL include a `sourceKind: DesignSourceKind` field with a default value of `.figma`.

#### Scenario: Default sourceKind is figma

- **WHEN** a `ColorsSourceInput` is constructed without specifying `sourceKind`
- **THEN** `sourceKind` SHALL be `.figma`

#### Scenario: sourceKind can be overridden

- **WHEN** a `ColorsSourceInput` is constructed with `sourceKind: .tokensFile`
- **THEN** `sourceKind` SHALL be `.tokensFile`

#### Scenario: Backward compatibility with existing callers

- **WHEN** existing code constructs any `*SourceInput` without the new `sourceKind` parameter
- **THEN** the code SHALL compile without changes due to the default value

### Requirement: Protocols live in ExFigCore

All source protocols (`ColorsSource`, `ComponentsSource`, `TypographySource`) and `DesignSourceKind` SHALL be defined in the `ExFigCore` module. They SHALL NOT import `FigmaAPI`, `PenpotAPI`, or any other source-specific module.

#### Scenario: ExFigCore compiles without FigmaAPI

- **WHEN** ExFigCore is compiled
- **THEN** it SHALL NOT have any import dependency on FigmaAPI or other source-specific modules

### Requirement: FigmaColorsSource implementation

The system SHALL provide a `FigmaColorsSource` struct in ExFigCLI that implements `ColorsSource`. It SHALL encapsulate the current `ColorsVariablesLoader` logic extracted from `ColorsExportContextImpl.loadColorsFromFigma()`.

#### Scenario: FigmaColorsSource produces identical output to current implementation

- **WHEN** `FigmaColorsSource.loadColors()` is called with the same `ColorsSourceInput` as the current `ColorsExportContextImpl.loadColorsFromFigma()`
- **THEN** the returned `ColorsLoadOutput` SHALL be identical

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
