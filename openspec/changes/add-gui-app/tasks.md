# Tasks: Add ExFig Studio GUI Application

## 1. ExFigKit Module Extraction

- [x] 1.1 Create `Sources/ExFigKit/` module structure
- [x] 1.2 Move `Params.swift` to `ExFigKit/Config/` (with public access, Sendable conformance)
- [ ] 1.3 Move Loaders to `ExFigKit/Loaders/` (deferred - requires extensive public access refactoring)
- [ ] 1.4 Move Output (FileWriter, converters) to `ExFigKit/Output/` (deferred)
- [x] 1.5 Move Cache data models to `ExFigKit/Cache/` (FNV1aHasher, NodeHasher, ImageTrackingCache, checkpoints)
- [x] 1.6 Create `ProgressReporter` protocol (in `Sources/ExFigKit/Progress/ProgressReporter.swift`)
- [x] 1.7 Update `Package.swift` with ExFigKit target
- [x] 1.8 Update ExFig CLI to depend on ExFigKit
- [x] 1.9 Verify CLI still works after refactor (build passes, 1782 tests pass)
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

- [x] 9.1 Write ExFigKit unit tests (existing - 1824 tests pass)
- [x] 9.2 Write OAuth flow tests (24 tests pass)
- [ ] 9.3 Write ViewModel tests
- [ ] 9.4 Write UI tests for critical flows
