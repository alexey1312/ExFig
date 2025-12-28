# ExFig Studio GUI Application

Native SwiftUI macOS application for visual Figma asset export.

## ADDED Requirements

### Requirement: Tuist Project Generation

The system SHALL use Tuist for Xcode project generation with mise for tool management.

#### Scenario: Generate Xcode workspace

- **GIVEN** developer has cloned the repository
- **WHEN** `./bin/mise run app:generate` is executed
- **THEN** Xcode workspace is generated with CLI package and GUI app

#### Scenario: Build app via mise

- **GIVEN** Tuist manifests are configured
- **WHEN** `./bin/mise run app:build` is executed
- **THEN** ExFig Studio app is built successfully

#### Scenario: Open in Xcode

- **GIVEN** Xcode workspace is generated
- **WHEN** `./bin/mise run app:open` is executed
- **THEN** Xcode opens with the workspace ready for development

### Requirement: Figma Authentication

The system SHALL support both OAuth 2.0 and Personal Access Token authentication for Figma API access.

#### Scenario: OAuth login flow

- **GIVEN** user clicks "Sign in with Figma"
- **WHEN** OAuth flow completes with authorization code
- **THEN** tokens are exchanged and stored in Keychain

#### Scenario: Personal Access Token entry

- **GIVEN** user enters a Personal Access Token
- **WHEN** token is validated against Figma API
- **THEN** token is stored in Keychain for future use

#### Scenario: Token refresh

- **GIVEN** OAuth access token has expired
- **WHEN** API request is made
- **THEN** refresh token is used to obtain new access token

### Requirement: Visual Configuration Editor

The system SHALL provide a visual editor for creating and modifying ExFig configuration without manual YAML editing.

#### Scenario: Configure Figma source

- **GIVEN** user is on configuration screen
- **WHEN** user enters Figma file IDs and selects color source (Variables/Styles)
- **THEN** configuration is updated with source settings

#### Scenario: Configure platform export

- **GIVEN** user selects a platform (iOS/Android/Flutter/Web)
- **WHEN** user configures export settings (format, paths, naming)
- **THEN** platform-specific configuration is saved

#### Scenario: Import existing YAML

- **GIVEN** user has an existing exfig.yaml file
- **WHEN** user imports the file
- **THEN** configuration is loaded into the visual editor

#### Scenario: Export to YAML

- **GIVEN** user has configured export settings
- **WHEN** user clicks "Export YAML"
- **THEN** valid exfig.yaml file is generated

### Requirement: Asset Preview

The system SHALL display thumbnails of icons and images from Figma before export.

#### Scenario: Load asset thumbnails

- **GIVEN** a Figma file is selected
- **WHEN** user navigates to asset preview
- **THEN** thumbnails are loaded from Figma Image API

#### Scenario: Filter assets by type

- **GIVEN** assets are displayed in preview grid
- **WHEN** user selects filter (Icons/Images/All)
- **THEN** grid shows only matching assets

#### Scenario: Handle thumbnail load failure

- **GIVEN** a Figma file is selected
- **WHEN** thumbnail fails to load (network error, API error)
- **THEN** error placeholder is displayed with retry option

### Requirement: Asset Selection

The system SHALL allow users to select or exclude individual assets before export.

#### Scenario: Select individual asset

- **GIVEN** asset preview grid is displayed
- **WHEN** user clicks on an asset
- **THEN** asset is toggled between selected/deselected

#### Scenario: Batch selection

- **GIVEN** multiple assets are displayed
- **WHEN** user clicks "Select All" or "Deselect All"
- **THEN** all visible assets are selected or deselected

#### Scenario: Export only selected

- **GIVEN** some assets are selected
- **WHEN** user clicks "Export"
- **THEN** only selected assets are exported

### Requirement: Export Progress Visualization

The system SHALL display real-time progress during export with phase information.

#### Scenario: Show export phases

- **GIVEN** export is in progress
- **WHEN** each phase completes (fetching, processing, downloading, writing)
- **THEN** phase indicator updates to show current state

#### Scenario: Display asset count

- **GIVEN** export is downloading assets
- **WHEN** download progresses
- **THEN** current/total count is displayed (e.g., "15 of 50")

#### Scenario: Cancel export

- **GIVEN** export is in progress
- **WHEN** user clicks "Cancel"
- **THEN** export is cancelled and partial results are cleaned up

#### Scenario: Handle export error

- **GIVEN** export is in progress
- **WHEN** an error occurs (API error, disk full, permission denied)
- **THEN** error is displayed with recovery suggestion and option to retry

### Requirement: Export History

The system SHALL maintain a history of previous exports for quick re-run.

#### Scenario: Save export history

- **GIVEN** export completes successfully
- **WHEN** results are saved
- **THEN** export entry is added to history with config, counts, and paths

#### Scenario: Re-run previous export

- **GIVEN** user views export history
- **WHEN** user clicks "Re-run" on a history entry
- **THEN** export is executed with saved configuration

### Requirement: Error Handling

The system SHALL display errors with recovery suggestions.

#### Scenario: Display API error

- **GIVEN** Figma API returns an error
- **WHEN** error is caught
- **THEN** user sees error message with recovery suggestion

#### Scenario: Display validation error

- **GIVEN** configuration has invalid values
- **WHEN** user attempts to export
- **THEN** validation errors are shown inline in the config editor

### Requirement: Homebrew Cask Distribution

The system SHALL be distributed as a signed and notarized macOS application via Homebrew Cask.

#### Scenario: Install via Homebrew

- **GIVEN** ExFig Studio cask is available
- **WHEN** user runs `brew install --cask exfig-studio`
- **THEN** application is installed to /Applications

#### Scenario: Notarization check passes

- **GIVEN** application is downloaded
- **WHEN** user first launches the app
- **THEN** Gatekeeper allows launch without warning
