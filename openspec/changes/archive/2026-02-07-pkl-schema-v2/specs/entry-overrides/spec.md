# Entry-Level Overrides

Per-entry override полей, которые раньше жили только на уровне platform config.

## ADDED Requirements

### Requirement: Entry-level figmaFileId override

Each Icons or Images entry SHALL support an optional `figmaFileId` field that overrides the global `figma.lightFileId` for that specific entry.

#### Scenario: Entry with figmaFileId override

- **WHEN** an IconsEntry has `figmaFileId = "VXmPoarVoCQSNjdlROoJLO"`
- **AND** the global `figma.lightFileId = "abc123"`
- **THEN** the system SHALL use `"VXmPoarVoCQSNjdlROoJLO"` when loading Figma data for that entry

#### Scenario: Entry without figmaFileId override

- **WHEN** an IconsEntry does not specify `figmaFileId`
- **AND** the global `figma.lightFileId = "abc123"`
- **THEN** the system SHALL use `"abc123"` when loading Figma data for that entry

#### Scenario: Entry with figmaFileId but no global figma config

- **WHEN** an IconsEntry has `figmaFileId = "VXmPoarVoCQSNjdlROoJLO"`
- **AND** no global `figma` section is defined
- **THEN** the system SHALL use `"VXmPoarVoCQSNjdlROoJLO"` when loading Figma data for that entry

### Requirement: iOS entry-level xcassetsPath override

Each iOS ColorsEntry, IconsEntry, and ImagesEntry SHALL support an optional `xcassetsPath` field that overrides `iOSConfig.xcassetsPath` for that specific entry.

#### Scenario: iOS entry with xcassetsPath override

- **WHEN** an iOS IconsEntry has `xcassetsPath = "./Resources/TemplateIcons.xcassets"`
- **AND** `iOSConfig.xcassetsPath = "./Resources/Main.xcassets"`
- **THEN** the system SHALL write icons to `"./Resources/TemplateIcons.xcassets"` for that entry

#### Scenario: iOS entry without xcassetsPath override

- **WHEN** an iOS IconsEntry does not specify `xcassetsPath`
- **AND** `iOSConfig.xcassetsPath = "./Resources/Main.xcassets"`
- **THEN** the system SHALL write icons to `"./Resources/Main.xcassets"` for that entry

### Requirement: iOS entry-level templatesPath override

Each iOS ColorsEntry, IconsEntry, and ImagesEntry SHALL support an optional `templatesPath` field that overrides `iOSConfig.templatesPath` for that specific entry.

#### Scenario: iOS entry with templatesPath override

- **WHEN** an iOS ColorsEntry has `templatesPath = "./templates/colors/ds3/"`
- **AND** `iOSConfig.templatesPath = "./templates/"`
- **THEN** the system SHALL use `"./templates/colors/ds3/"` as the templates directory for that entry

#### Scenario: iOS entry without templatesPath override

- **WHEN** an iOS ColorsEntry does not specify `templatesPath`
- **AND** `iOSConfig.templatesPath = "./templates/"`
- **THEN** the system SHALL use `"./templates/"` as the templates directory for that entry

### Requirement: Android entry-level path overrides

Each Android ColorsEntry, IconsEntry, and ImagesEntry SHALL support optional `mainRes`, `mainSrc`, and `templatesPath` fields that override the corresponding `AndroidConfig`-level values.

#### Scenario: Android entry with mainRes override

- **WHEN** an Android ImagesEntry has `mainRes = "./feature/src/main/res"`
- **AND** `AndroidConfig.mainRes = "./app/src/main/res"`
- **THEN** the system SHALL write images to `"./feature/src/main/res"` for that entry

#### Scenario: Android entry without mainRes override

- **WHEN** an Android ImagesEntry does not specify `mainRes`
- **AND** `AndroidConfig.mainRes = "./app/src/main/res"`
- **THEN** the system SHALL write images to `"./app/src/main/res"` for that entry

### Requirement: Flutter entry-level path overrides

Each Flutter ColorsEntry, IconsEntry, and ImagesEntry SHALL support optional `output` and `templatesPath` fields that override the corresponding `FlutterConfig`-level values.

#### Scenario: Flutter entry with output override

- **WHEN** a Flutter ImagesEntry has `output = "./packages/images/assets"`
- **AND** `FlutterConfig.output = "./lib/assets"`
- **THEN** the system SHALL write images to `"./packages/images/assets"` for that entry

### Requirement: Web entry-level path overrides

Each Web ColorsEntry, IconsEntry, and ImagesEntry SHALL support optional `output` and `templatesPath` fields that override the corresponding `WebConfig`-level values.

#### Scenario: Web entry with output override

- **WHEN** a Web IconsEntry has `output = "./packages/icons/src"`
- **AND** `WebConfig.output = "./src/generated"`
- **THEN** the system SHALL write icons to `"./packages/icons/src"` for that entry

### Requirement: Backward compatibility

All entry-level override fields SHALL be optional. Existing configurations without entry-level overrides SHALL continue to work identically.

#### Scenario: Existing config without overrides

- **WHEN** a PKL config file created for ExFig v2.0 is used with the updated schemas
- **AND** no entry-level override fields are specified
- **THEN** the system SHALL behave identically to ExFig v2.0

#### Scenario: PKL evaluation with overrides

- **WHEN** `pkl eval --format json` is run on a config with entry-level overrides
- **THEN** the JSON output SHALL include the override fields alongside existing entry fields
