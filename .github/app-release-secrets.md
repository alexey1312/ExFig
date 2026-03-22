# ExFig Studio Release Secrets Configuration

This document describes the GitHub secrets required for automated ExFig Studio releases.

## Required Secrets

| Secret                        | Description                                         | Required For         |
| ----------------------------- | --------------------------------------------------- | -------------------- |
| `APPLE_TEAM_ID`               | Apple Developer Team ID (10-character alphanumeric) | Code signing         |
| `APPLE_IDENTITY_NAME`         | Code signing identity name (e.g., "Your Name")      | Code signing         |
| `APPLE_CERTIFICATE_BASE64`    | Developer ID certificate (.p12) as base64           | Code signing         |
| `APPLE_CERTIFICATE_PASSWORD`  | Password for the .p12 certificate                   | Code signing         |
| `APPLE_ID`                    | Apple ID email for notarization                     | Notarization         |
| `APPLE_NOTARIZATION_PASSWORD` | App-specific password for notarization              | Notarization         |
| `HOMEBREW_TAP_TOKEN`          | GitHub PAT with repo access to homebrew-exfig       | Homebrew Cask update |

## Setup Instructions

### 1. Export Developer ID Certificate

```bash
# Open Keychain Access, find "Developer ID Application" certificate
# Right-click → Export → Save as .p12 with password

# Encode to base64
base64 -i DeveloperID.p12 | pbcopy
# Paste into APPLE_CERTIFICATE_BASE64 secret
```

### 2. Create App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in and navigate to Security → App-Specific Passwords
3. Generate a new password for "ExFig Studio Notarization"
4. Save as `APPLE_NOTARIZATION_PASSWORD` secret

### 3. Create Homebrew Tap Token

1. Go to [github.com/settings/tokens](https://github.com/settings/tokens)
2. Create a new PAT (classic) with `repo` scope
3. Save as `HOMEBREW_TAP_TOKEN` secret

### 4. Find Your Team ID

```bash
# If you have Xcode installed
security find-identity -v -p codesigning | grep "Developer ID Application"
# Team ID is in parentheses: "Developer ID Application: Name (TEAM_ID)"
```

## Release Process

### Create a Release

```bash
# Tag format: studio-v<major>.<minor>.<patch>
git tag studio-v1.0.0
git push origin studio-v1.0.0
```

### Manual Build (for testing)

```bash
# Local build without signing
./Scripts/build-app-release.sh

# Local build with signing
APPLE_TEAM_ID=YOUR_TEAM_ID ./Scripts/build-app-release.sh
```

### Workflow Dispatch

You can also trigger a release manually from the GitHub Actions tab:

1. Go to Actions → Release App
2. Click "Run workflow"
3. Enter the version number
4. Optionally skip notarization for testing

## Homebrew Cask

After a successful release, the workflow automatically updates the Homebrew Cask formula at:
`alexey1312/homebrew-exfig/Casks/exfig-studio.rb`

Users can install with:

```bash
brew tap alexey1312/exfig
brew install --cask exfig-studio
```

## Troubleshooting

### Certificate Issues

```bash
# Verify certificate is in keychain
security find-identity -v -p codesigning

# Verify certificate chain
codesign -vvv --deep "dist/ExFig Studio.app"
```

### Notarization Failures

```bash
# Check notarization status
xcrun notarytool history --apple-id YOUR_APPLE_ID --team-id YOUR_TEAM_ID

# Get detailed log for a submission
xcrun notarytool log SUBMISSION_ID --apple-id YOUR_APPLE_ID --team-id YOUR_TEAM_ID
```

### Gatekeeper Issues

```bash
# Verify app is properly signed and notarized
spctl --assess --verbose "dist/ExFig Studio.app"

# Check stapling
xcrun stapler validate "dist/ExFig Studio.app"
```
