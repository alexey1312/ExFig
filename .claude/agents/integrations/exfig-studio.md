# ExFig Studio (GUI App)

ExFig Studio is a macOS GUI app built with SwiftUI and managed by Tuist.

## Building ExFig Studio

```bash
# Generate Xcode project
./bin/mise exec -- tuist generate --no-open

# Build and run
open ExFig.xcworkspace
# Select "ExFigStudio" scheme and run

# Or build from command line
xcodebuild -workspace ExFig.xcworkspace -scheme ExFigStudio -configuration Debug build
```

## Project Structure

```
Projects/ExFigStudio/
├── Sources/
│   ├── Views/       # SwiftUI views (MainView, ConfigView, ExportView, etc.)
│   ├── ViewModels/  # Observable ViewModels (AuthViewModel, ExportViewModel, etc.)
│   └── App/         # App entry point, AppDelegate
├── Resources/       # Assets.xcassets, entitlements
└── Project.swift    # Tuist project definition
```

## Key Components

| Component         | File                                           | Purpose                              |
| ----------------- | ---------------------------------------------- | ------------------------------------ |
| `AuthViewModel`   | `Projects/ExFigStudio/Sources/ViewModels/`     | OAuth 2.0 flow with Figma            |
| `ExportViewModel` | `Projects/ExFigStudio/Sources/ViewModels/`     | Export progress and state management |
| `OAuthClient`     | `Sources/FigmaAPI/OAuth/OAuthClient.swift`     | PKCE-based OAuth implementation      |
| `KeychainStorage` | `Sources/FigmaAPI/OAuth/KeychainStorage.swift` | Secure token storage                 |

## OAuth 2.0 Authentication

ExFig Studio uses OAuth 2.0 with PKCE for secure Figma authentication:

```swift
// Generate authorization URL
let client = OAuthClient(config: OAuthConfig(
    clientId: "your-client-id",
    clientSecret: "your-client-secret",
    scopes: [.filesRead]
))
let (url, state) = try await client.authorizationURL()

// Handle callback
let tokens = try await client.handleCallback(callbackURL)

// Refresh token
let newTokens = try await client.refreshToken(tokens.refreshToken)
```

## Security Notes

- PKCE uses SHA-256 via Swift Crypto (cross-platform)
- Tokens stored in macOS Keychain (Linux uses file-based fallback with 0600 permissions)
- State parameter validated to prevent CSRF attacks
