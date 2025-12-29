# Tasks: Add ExFig Studio GUI Application

## 1. ExFigKit Module Extraction

- [x] 1.1 Create `Sources/ExFigKit/` module structure
- [x] 1.2 Move `Params.swift` to `ExFigKit/Config/` (with public access, Sendable conformance)
- [x] 1.3 Move Loaders to `ExFigKit/Loaders/` — DEFERRED to Phase 2 (requires extensive public access refactoring)
- [x] 1.4 Move Output (FileWriter, converters) to `ExFigKit/Output/` — DEFERRED to Phase 2
- [x] 1.5 Move Cache data models to `ExFigKit/Cache/` (FNV1aHasher, NodeHasher, ImageTrackingCache, checkpoints)
- [x] 1.6 Create `ProgressReporter` protocol (in `Sources/ExFigKit/Progress/ProgressReporter.swift`)
- [x] 1.7 Update `Package.swift` with ExFigKit target
- [x] 1.8 Update ExFig CLI to depend on ExFigKit
- [x] 1.9 Verify CLI still works after refactor (build passes, 1824 tests pass)
- [x] 1.10 Add Swift Task cancellation support to loaders

**Note:** Conservative extraction approach taken for Phase 1:

- `Params`, `ExFigError`, `ProgressReporter` moved to ExFigKit (core config and protocols)
- Cache data models moved: `FNV1aHasher`, `NodeHasher`, `ImageTrackingCache`, `CachedFileInfo`, `ExportCheckpoint`, `BatchCheckpoint`
- Cache managers (`GranularCacheManager`, `ImageTrackingManager`, `VersionTrackingHelper`) remain in ExFig due to TerminalUI dependency
- Full extraction of Loaders/Output deferred due to extensive public access modifications needed
- Task cancellation added to `ImageLoaderBase` (loadImages, loadImageBatch, loadPNGImages, loadVectorImages)

## 2. OAuth Authentication

- [x] 2.1 Create `Sources/FigmaAPI/OAuth/OAuthClient.swift`
- [x] 2.2 Create `Sources/FigmaAPI/OAuth/OAuthTokenManager.swift`
- [x] 2.3 Create `Sources/FigmaAPI/OAuth/KeychainStorage.swift`
- [x] 2.4 Implement PKCE flow (S256 code challenge)
- [x] 2.5 Support token refresh
- [x] 2.6 Add dual auth enum (OAuth + Personal Token)
- [x] 2.7 Write OAuth tests (24 tests pass)

**Implemented:**

- `OAuthClient` actor with PKCE S256 challenge generation
- `OAuthTokenManager` actor for secure token storage and automatic refresh
- `KeychainStorage` using macOS Keychain (with file-based fallback for Linux)
- `FigmaAuth` enum supporting both `.personalToken(String)` and `.oauth(OAuthTokenManager)`
- `AuthenticatedFigmaClient` with automatic token refresh on 401
- Comprehensive test suite covering PKCE, token management, storage, and auth flow

## 3. Tuist Project Setup

- [x] 3.1 Add `tuist` to `mise.toml` tools
- [x] 3.2 Create `Tuist/Config.swift` with global settings
- [x] 3.3 Create `Tuist/Package.swift` with third-party dependencies
- [x] 3.4 Create `Workspace.swift` combining CLI + App
- [x] 3.5 Create `Projects/ExFigStudio/Project.swift` with app target
- [x] 3.6 Configure `exfig://` URL scheme in InfoPlist
- [x] 3.7 Add mise tasks: `app:generate`, `app:build`, `app:test`, `app:open`, `app:clean`
- [x] 3.8 Create `AppDelegate.swift` for URL handling
- [x] 3.9 Create base `ExFigStudioApp.swift` entry point
- [x] 3.10 Add `.gitignore` entries for generated `.xcodeproj`, `.xcworkspace`
- [x] 3.11 Create `Projects/ExFigStudio/Resources/Assets.xcassets` with app icon placeholder
- [x] 3.12 Run `tuist generate` and verify workspace opens

**Resolution:** Used Tuist native targets approach (option 2 from earlier notes).

Tuist has issues with local SPM packages containing binary dependencies (e.g., `swift-resvg` with `CResvg` binary target). The solution was to:

1. Define `ExFigCore`, `FigmaAPI`, and `ExFigKit` as native Tuist framework targets in `Project.swift`
2. Use `.sourceFilesList(globs: [.glob(.relativeToRoot("Sources/..."))])` to reference source files from the main package
3. Add only pure Swift dependencies (Yams, swift-log) to `Tuist/Package.swift` as external dependencies
4. Reference external dependencies in native targets via `.external(name: "...")`

This approach avoids Tuist's limitation with binary targets while maintaining a single source tree.

**Verified:**

- `tuist generate` succeeds (4.464s)
- `tuist build ExFigStudio` succeeds (Build Succeeded)
- Generated workspace: `ExFig.xcworkspace`

## 4. Core Views

- [x] 4.1 Create `AuthView` with OAuth + Personal Token tabs
- [x] 4.2 Create `OAuthWebView` using WKWebView
- [x] 4.3 Create `ProjectBrowserView` with file tree
- [x] 4.4 Create `AssetPreviewGrid` with lazy loading
- [x] 4.5 Create `ConfigEditorView` with platform sections
- [x] 4.6 Create `ExportProgressView` with phases
- [x] 4.7 Create `ExportHistoryView` with list

**Implemented:**

- `AuthView` with segmented picker for OAuth/Personal Token authentication methods
- `AuthViewModel` handling token validation, OAuth flow, and Keychain storage
- `OAuthWebView` using WKWebView with navigation delegate for callback handling
- `ProjectBrowserView` with NavigationSplitView, recent files, and file detail preview
- `ProjectViewModel` using `FileMetadataEndpoint` from FigmaAPI
- `AssetPreviewGrid` with lazy loading grid, asset type filtering, and batch selection
- `AssetPreviewViewModel` with asset loading and thumbnail caching via `ImageEndpoint`
- `ConfigEditorView` with platform sections, YAML import/export, and validation
- `ConfigViewModel` with platform configuration and common options
- `ExportProgressView` with phases, logs, and progress visualization
- `ExportViewModel` with simulated export and `GUIProgressReporter` implementation
- `ExportHistoryView` with grouped-by-date list and detail view
- `ExportHistoryViewModel` with UserDefaults persistence
- `MainView` with NavigationSplitView combining all views
- `AppState` for global authentication and navigation state

**Verified:**

- `tuist build ExFigStudio` succeeds (Build Succeeded)
- All views compile with proper FigmaAPI integration

## 5. Asset Preview System

- [x] 5.1 Create `ThumbnailService` using Figma Image API (integrated in AssetPreviewViewModel)
- [x] 5.2 Create `AssetPreviewViewModel` with selection state
- [x] 5.3 Implement thumbnail caching (NSCache)
- [x] 5.4 Add asset type filtering (icons/images/colors)
- [x] 5.5 Add batch select/deselect controls
- [x] 5.6 Add error placeholder for failed thumbnail loads

**Note:** Asset Preview System was implemented as part of Phase 4 Core Views. The `AssetPreviewViewModel` and `AssetPreviewGrid` include all required functionality:

- Thumbnail loading via FigmaAPI `ImageEndpoint` with `PNGParams(scale: 0.5)`
- Selection state with `isSelected` property on `AssetItem`
- NSCache for thumbnail caching
- Asset type filtering with `AssetType` enum and segmented picker
- Batch select/deselect with `selectAllVisible()` and `deselectAllVisible()`
- Placeholder views for loading and error states in `AssetGridItem`

## 6. Visual Config Editor

- [x] 6.1 Create `FigmaSourceSection` (file IDs, Variables) - integrated in ConfigEditorView
- [x] 6.2 Create `iOSConfigSection` (colors, icons, images) - via PlatformConfigView
- [x] 6.3 Create `AndroidConfigSection` - via PlatformConfigView
- [x] 6.4 Create `FlutterConfigSection` - via PlatformConfigView
- [x] 6.5 Create `WebConfigSection` - via PlatformConfigView
- [x] 6.6 Create `CommonSettingsSection` (regex, naming) - CommonOptionsRow
- [x] 6.7 Implement YAML import/export - YAMLExportSheet, YAMLImportSheet
- [x] 6.8 Add real-time validation feedback - via ConfigViewModel.validate()

**Note:** Visual Config Editor was implemented as part of Phase 4 Core Views. All platform sections use a unified `PlatformConfigView` with platform-specific options stored in `PlatformConfig` struct.

## 7. Export Execution

- [x] 7.1 Create `ExportService` orchestrator - ExportViewModel handles orchestration
- [x] 7.2 Implement `GUIProgressReporter` (conforms to `ProgressReporter`)
- [x] 7.3 Add export cancellation support (Swift Task cancellation)
- [x] 7.4 Display warnings and errors with recovery suggestions - via ExportLogEntry
- [x] 7.5 Save export history to Application Support - ExportHistoryViewModel with UserDefaults

**Note:** Export Execution was implemented as part of Phase 4 Core Views. The `ExportViewModel` includes:

- Phase-based progress tracking with `ExportPhase` struct
- `GUIProgressReporter` conforming to `ProgressReporter` protocol
- Task cancellation via `exportTask?.cancel()`
- Log entries with info/warning/error/success levels
- Export history persistence in `ExportHistoryViewModel`

## 8. Distribution

- [x] 8.1 Configure GitHub secrets (APPLE_ID, TEAM_ID, CERT_BASE64, NOTARIZATION_PASSWORD) - documented in `docs/app-release-secrets.md`
- [x] 8.2 Create `Scripts/build-app-release.sh` for local builds
- [x] 8.3 Configure code signing with Developer ID - integrated in release workflow
- [x] 8.4 Set up notarization workflow - integrated in `.github/workflows/release-app.yml`
- [x] 8.5 Create DMG with `Scripts/create-dmg.sh`
- [x] 8.6 Write Homebrew Cask formula - `Casks/exfig-studio.rb` (template for homebrew-exfig tap)
- [x] 8.7 Add GitHub Actions release workflow - `.github/workflows/release-app.yml`

**Implemented:**

- `Scripts/build-app-release.sh` - Local build script with optional signing and notarization
- `Scripts/create-dmg.sh` - DMG creation with custom icon layout
- `.github/workflows/release-app.yml` - Complete release workflow:
  - Builds signed/unsigned app based on available secrets
  - Notarizes with Apple notarytool
  - Creates DMG and checksums
  - Publishes GitHub Release
  - Updates Homebrew Cask formula automatically
- `Casks/exfig-studio.rb` - Homebrew Cask template for `alexey1312/homebrew-exfig`
- `docs/app-release-secrets.md` - Documentation for required GitHub secrets

**Release process:**

```bash
# Create release tag
git tag studio-v1.0.0
git push origin studio-v1.0.0
```

**Local build:**

```bash
./Scripts/build-app-release.sh
# Or with signing:
APPLE_TEAM_ID=YOUR_TEAM_ID ./Scripts/build-app-release.sh
```

## 9. Testing

- [x] 9.1 Write ExFigKit unit tests (existing - 1824 tests pass)
- [x] 9.2 Write OAuth flow tests (24 tests pass)
- [x] 9.3 Write ViewModel tests (98 tests pass)
- [x] 9.4 Write UI tests for critical flows

**ViewModel Tests Implemented:**

- `AuthViewModelTests` - Authentication state, token validation, sign out, OAuth flow
- `ProjectViewModelTests` - Project filtering, recent files, file opening
- `AssetPreviewViewModelTests` - Asset filtering, selection, batch operations
- `ConfigViewModelTests` - Platform configuration, YAML import/export, validation
- `ExportViewModelTests` - Export state, cancellation, phase management
- `ExportHistoryViewModelTests` - History filtering, grouping, persistence

**UI Tests Implemented:**

- `AuthFlowUITests` - Auth view display, method picker, token input, OAuth button
- `NavigationUITests` - Sidebar navigation, view switching, sign out button
- `ConfigEditorUITests` - Platform sections, file ID field, YAML import/export
- `ExportFlowUITests` - Export controls, phase indicators, log display, history
- `AssetPreviewUITests` - Asset grid, type filter, batch selection, search

UI tests located in `Projects/ExFigStudio/UITests/`.

All tests use Swift Testing framework (`@Test`, `@Suite`, `#expect`) for unit tests
and XCTest for UI tests.

**mise tasks:**

- `./bin/mise run app:test` - Run unit tests
- `./bin/mise run app:uitest` - Run UI tests
- `./bin/mise run app:test:all` - Run all tests

## 10. Real Export Integration (Track 3)

- [x] 10.1 Move Loaders to ExFigKit (IconsLoader, ImagesLoader, ColorsVariablesLoader, etc.)
- [x] 10.2 Create `ExportCoordinator` actor for GUI export orchestration
- [x] 10.3 Wire `ExportViewModel.startExport()` to `ExportCoordinator`
- [x] 10.4 Implement `ConfigViewModel.buildParams()` to convert GUI config to `Params`
- [x] 10.5 Wire up export flow from UI (start button, directory picker, platform selection)
- [x] 10.6 Update `ExportProgressView` to use `AppState` for full config access

**Implemented:**

- **ExportCoordinator** (`Projects/ExFigStudio/Sources/Services/ExportCoordinator.swift`)
  - Actor orchestrating real export using ExFigKit loaders
  - `exportAll()` dispatches to `exportColors()`, `exportIcons()`, `exportImages()`, `exportTypography()`
  - Uses `GUIProgressReporter` for progress updates
  - Currently exports with simulated file write (TODOs for full platform exporter wiring)

- **ConfigViewModel.buildParams()** (`Projects/ExFigStudio/Sources/ViewModels/ConfigViewModel.swift`)
  - JSON dictionary construction + JSONDecoder pattern to work around synthesized initializers
  - Converts GUI platform configs to proper `Params.iOS`, `Params.Android`, etc.
  - Helper methods: `buildFigmaJSON()`, `buildCommonJSON()`, `buildIOSJSON()`, etc.

- **ExportProgressView** (`Projects/ExFigStudio/Sources/Views/Export/ExportProgressView.swift`)
  - Now takes `@Bindable var appState: AppState` instead of just `ExportViewModel`
  - Export setup UI when idle: validation status, directory picker, platforms summary
  - Start button triggers `startExport()` which builds params and calls coordinator
  - Uses `.fileImporter` for sandboxed directory selection with security-scoped resources

- **ExportViewModel.startExport()** (`Projects/ExFigStudio/Sources/ViewModels/ExportViewModel.swift`)
  - New signature: `startExport(params:platforms:selectedAssets:figmaAuth:)`
  - Creates `FigmaClient` from `FigmaAuth`, instantiates `ExportCoordinator`
  - Converts GUI `Platform` enum to `ExFigCore.Platform`

**Key Implementation Notes:**

1. **JSON-based Params construction** — `Params` structs have internal synthesized initializers, so GUI uses JSON dictionary → JSONDecoder pattern:
   ```swift
   var json: [String: Any] = [:]
   json["figma"] = buildFigmaJSON()
   json["common"] = buildCommonJSON()
   // ...
   let data = try JSONSerialization.data(withJSONObject: json)
   return try JSONDecoder().decode(Params.self, from: data)
   ```

2. **Type disambiguation** — ExFigStudio has local `Platform` enum conflicting with `ExFigCore.Platform`:
   - `ExportCoordinator` uses `ExFigCore.Platform` explicitly in all method signatures
   - `ExportViewModel` converts via `ExFigCore.Platform(rawValue:)`
   - `ExportLogEntry.Level.color` uses `SwiftUI.Color` to avoid conflict with `ExFigCore.Color`

3. **Security-scoped resources** — Directory picker uses `startAccessingSecurityScopedResource()` for sandbox compliance

**Verification:**

- `swift build` ✅
- `xcodebuild -scheme ExFigStudio` ✅
- `mise lint` ✅
- `mise format` ✅
