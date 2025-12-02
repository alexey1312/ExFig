# Android Export: Vector Drawable XML Generation

## ADDED Requirements

### Requirement: Native SVG to Vector Drawable XML Conversion

The system SHALL convert SVG files to Android Vector Drawable XML format using a native Swift implementation without
external dependencies.

#### Scenario: Basic SVG conversion

- **WHEN** an SVG file with path elements is provided
- **THEN** a valid Vector Drawable XML file is generated with corresponding `<path>` elements

#### Scenario: SVG with groups

- **WHEN** an SVG file contains `<g>` group elements
- **THEN** the Vector Drawable XML contains corresponding `<group>` elements preserving hierarchy

#### Scenario: SVG with transforms

- **WHEN** an SVG group has transform attributes (translate, scale, rotate)
- **THEN** the Vector Drawable XML group has corresponding `android:translateX`, `android:scaleX`, `android:rotation`
  attributes

#### Scenario: SVG with clip-path

- **WHEN** an SVG element has a clip-path applied
- **THEN** the Vector Drawable XML contains a `<clip-path>` element with the path data

### Requirement: Vector Drawable Path Attributes

The system SHALL map SVG path attributes to Vector Drawable XML attributes correctly.

#### Scenario: Fill color mapping

- **WHEN** an SVG path has `fill` attribute with color value
- **THEN** the Vector Drawable path has `android:fillColor` in #AARRGGBB format

#### Scenario: Stroke attributes mapping

- **WHEN** an SVG path has stroke attributes (color, width, linecap, linejoin)
- **THEN** the Vector Drawable path has corresponding `android:strokeColor`, `android:strokeWidth`,
  `android:strokeLineCap`, `android:strokeLineJoin` attributes

#### Scenario: Fill rule mapping

- **WHEN** an SVG path has `fill-rule="evenodd"`
- **THEN** the Vector Drawable path has `android:fillType="evenOdd"`

#### Scenario: Opacity mapping

- **WHEN** an SVG path has opacity attribute
- **THEN** the Vector Drawable path has `android:fillAlpha` and/or `android:strokeAlpha` attributes

### Requirement: RTL Layout Support

The system SHALL support right-to-left layout mirroring for icons.

#### Scenario: Auto-mirrored icon

- **WHEN** an icon is marked for RTL support
- **THEN** the Vector Drawable XML has `android:autoMirrored="true"` attribute on the root element

### Requirement: Batch Conversion

The system SHALL convert multiple SVG files in a directory to Vector Drawable XML format.

#### Scenario: Directory conversion

- **WHEN** a directory containing SVG files is provided
- **THEN** all SVG files are converted to XML files in the same directory

#### Scenario: File extension replacement

- **WHEN** an SVG file is converted
- **THEN** the output file has `.xml` extension instead of `.svg`

### Requirement: SVG Group Parsing

The system SHALL parse SVG group elements preserving structure and attributes.

#### Scenario: Nested groups

- **WHEN** an SVG contains nested `<g>` elements
- **THEN** the parsed structure maintains the nesting hierarchy

#### Scenario: Group transform decomposition

- **WHEN** an SVG group has `transform="translate(10, 20) rotate(45)"`
- **THEN** the parsed transform contains translateX=10, translateY=20, rotation=45

#### Scenario: Inherited attributes

- **WHEN** a group has fill/stroke attributes
- **THEN** child elements inherit these attributes if not overridden

## REMOVED Requirements

### Requirement: External vd-tool Dependency

The system no longer requires external Java vd-tool for SVG to Vector Drawable conversion.

**Reason**: Replaced with native Swift implementation for better user experience and simpler distribution.

**Migration**: Users no longer need Java Runtime installed. The conversion happens natively.
