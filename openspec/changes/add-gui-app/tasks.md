# Tasks: Add ExFig Studio GUI Application

## 1. ExFigKit Module Extraction

- [ ] 1.1 Create `Sources/ExFigKit/` module structure
- [ ] 1.2 Move `Params.swift` to `ExFigKit/Config/`
- [ ] 1.3 Move Loaders to `ExFigKit/Loaders/`
- [ ] 1.4 Move Output (FileWriter, converters) to `ExFigKit/Output/`
- [ ] 1.5 Move Cache to `ExFigKit/Cache/`
- [ ] 1.6 Create `ProgressReporter` protocol
- [ ] 1.7 Update `Package.swift` with ExFigKit target
- [ ] 1.8 Update ExFig CLI to depend on ExFigKit
- [ ] 1.9 Verify CLI still works after refactor
- [ ] 1.10 Add Swift Task cancellation support to loaders

## 2. OAuth Authentication

- [ ] 2.1 Create `Sources/FigmaAPI/OAuth/OAuthClient.swift`
- [ ] 2.2 Create `Sources/FigmaAPI/OAuth/OAuthTokenManager.swift`
- [ ] 2.3 Create `Sources/FigmaAPI/OAuth/KeychainStorage.swift`
- [ ] 2.4 Implement PKCE flow (S256 code challenge)
- [ ] 2.5 Support token refresh
- [ ] 2.6 Add dual auth enum (OAuth + Personal Token)
- [ ] 2.7 Write OAuth tests

## 3. Tuist Project Setup

- [ ] 3.1 Add `tuist` to `mise.toml` tools
- [ ] 3.2 Create `Tuist/Config.swift` with global settings
- [ ] 3.3 Reference SPM package via `.package(path: ".")` in Project.swift
- [ ] 3.4 Create `Workspace.swift` combining CLI + App
- [ ] 3.5 Create `Projects/ExFigStudio/Project.swift` with app target
- [ ] 3.6 Configure `exfig://` URL scheme in InfoPlist
- [ ] 3.7 Add mise tasks: `app:generate`, `app:build`, `app:test`, `app:open`
- [ ] 3.8 Create `AppDelegate.swift` for URL handling
- [ ] 3.9 Create base `ExFigStudioApp.swift` entry point
- [ ] 3.10 Add `.gitignore` entries for generated `.xcodeproj`, `.xcworkspace`
- [ ] 3.11 Create `Projects/ExFigStudio/Resources/Assets.xcassets` with app icon placeholder
- [ ] 3.12 Run `tuist generate` and verify workspace opens

## 4. Core Views

- [ ] 4.1 Create `AuthView` with OAuth + Personal Token tabs
- [ ] 4.2 Create `OAuthWebView` using WKWebView
- [ ] 4.3 Create `ProjectBrowserView` with file tree
- [ ] 4.4 Create `AssetPreviewGrid` with lazy loading
- [ ] 4.5 Create `ConfigEditorView` with platform sections
- [ ] 4.6 Create `ExportProgressView` with phases
- [ ] 4.7 Create `ExportHistoryView` with list

## 5. Asset Preview System

- [ ] 5.1 Create `ThumbnailService` using Figma Image API
- [ ] 5.2 Create `AssetPreviewViewModel` with selection state
- [ ] 5.3 Implement thumbnail caching (NSCache)
- [ ] 5.4 Add asset type filtering (icons/images/colors)
- [ ] 5.5 Add batch select/deselect controls
- [ ] 5.6 Add error placeholder for failed thumbnail loads

## 6. Visual Config Editor

- [ ] 6.1 Create `FigmaSourceSection` (file IDs, Variables)
- [ ] 6.2 Create `iOSConfigSection` (colors, icons, images)
- [ ] 6.3 Create `AndroidConfigSection`
- [ ] 6.4 Create `FlutterConfigSection`
- [ ] 6.5 Create `WebConfigSection`
- [ ] 6.6 Create `CommonSettingsSection` (regex, naming)
- [ ] 6.7 Implement YAML import/export
- [ ] 6.8 Add real-time validation feedback

## 7. Export Execution

- [ ] 7.1 Create `ExportService` orchestrator
- [ ] 7.2 Implement `GUIProgressReporter` (conforms to `ProgressReporter`)
- [ ] 7.3 Add export cancellation support (Swift Task cancellation)
- [ ] 7.4 Display warnings and errors with recovery suggestions
- [ ] 7.5 Save export history to Application Support

## 8. Distribution

- [ ] 8.1 Configure GitHub secrets (APPLE_ID, TEAM_ID, CERT_BASE64, NOTARIZATION_PASSWORD)
- [ ] 8.2 Create `Scripts/build-release.sh`
- [ ] 8.3 Configure code signing with Developer ID
- [ ] 8.4 Set up notarization workflow
- [ ] 8.5 Create DMG with create-dmg
- [ ] 8.6 Write Homebrew Cask formula
- [ ] 8.7 Add GitHub Actions release workflow

## 9. Testing

- [ ] 9.1 Write ExFigKit unit tests
- [ ] 9.2 Write OAuth flow tests
- [ ] 9.3 Write ViewModel tests
- [ ] 9.4 Write UI tests for critical flows
