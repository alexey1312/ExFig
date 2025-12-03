# Getting Started with ExFig

This guide will help you install ExFig and run your first export.

## Prerequisites

### Figma Personal Access Token

Before using ExFig, you need a Figma personal access token to access the Figma API.

1. Generate a token through your [Figma account settings](https://www.figma.com/developers/api#access-tokens)
2. Set it as an environment variable:

```bash
export FIGMA_PERSONAL_TOKEN=your_token_here
```

**For Fastlane users**: Add this line to your `fastlane/.env` file:

```
FIGMA_PERSONAL_TOKEN=your_token_here
```

## Installation

Choose one of the following installation methods:

### Option 1: Mint (Recommended for Swift projects)

If you use [Mint](https://github.com/yonaskolb/mint) for managing Swift command-line tools:

```bash
mint install alexey1312/ExFig
```

### Option 2: mise (Recommended for general use)

If you use [mise](https://mise.jdx.dev/) for managing development tools:

```bash
# Install using ubi backend (downloads from GitHub releases)
mise use -g ubi:alexey1312/ExFig
```

### Option 3: Build from Source

For the latest development version:

```bash
git clone https://github.com/alexey1312/ExFig.git
cd ExFig
swift build -c release
cp .build/release/exfig /usr/local/bin/
```

**Requirements for building from source:**

- Swift 6.0 or later
- macOS 12.0 or later

## Quick Start

### 1. Generate Configuration File

Create a starter configuration for your platform:

```bash
# For iOS/Xcode projects
exfig init --platform ios

# For Android projects
exfig init --platform android
```

This creates an `exfig.yaml` configuration file in your current directory.

### 2. Configure Figma File IDs

Edit `exfig.yaml` and add your Figma file IDs:

```yaml
figma:
  lightFileId: YOUR_FIGMA_FILE_ID  # Required
  darkFileId: YOUR_DARK_FILE_ID    # Optional
```

**How to find your Figma file ID:** Open your Figma file in a browser. The URL will look like:

```
https://www.figma.com/file/abc123def456/Your-File-Name
                              ^^^^^^^^^^^^
                              This is your file ID
```

### 3. Run Your First Export

#### Export Colors

```bash
exfig colors
```

#### Export Icons

```bash
exfig icons
```

#### Export Images

```bash
exfig images
```

#### Export Typography

```bash
exfig typography
```

### 4. Verify the Output

**For iOS projects:**

- Check `Assets.xcassets` folder for new color sets, image sets, or icon sets
- Check generated Swift files for UIKit/SwiftUI extensions

**For Android projects:**

- Check `res/` folder for new XML files
- Check generated Kotlin files for Jetpack Compose code

## Configuration Tips

### Specify Configuration File Location

If your `exfig.yaml` is not in the current directory:

```bash
exfig colors -i path/to/exfig.yaml
```

### Platform-Specific Configuration

For detailed configuration options, see:

- [iOS Configuration Guide](ios/index.md)
- [Android Configuration Guide](android/index.md)
- [Complete Configuration Reference](../../CONFIG.md)

## Common Issues

### "Failed to fetch Figma file"

- Verify your `FIGMA_PERSONAL_TOKEN` is set correctly
- Check that the Figma file ID is correct
- Ensure your token has access to the file

### "No colors/icons/images found"

- Review [Design Requirements](design-requirements.md) for proper Figma file structure
- Check that color styles, components, or frames are named correctly
- Verify the `figmaFrameName` in your configuration matches your Figma file

### "cwebp tool not found" (Android/Flutter WebP)

ExFig requires the `cwebp` command-line tool for WebP image conversion. Install it using one of these methods:

```bash
# macOS (Homebrew)
brew install webp

# macOS (MacPorts)
port install webp

# Linux (Debian/Ubuntu)
sudo apt install webp

# Linux (Fedora/RHEL)
sudo dnf install libwebp-tools

# Linux (Arch)
sudo pacman -S libwebp
```

**Custom path**: If cwebp is installed in a non-standard location, set the environment variable:

```bash
export CWEBP_PATH=/path/to/cwebp
```

**Search paths**: ExFig searches for cwebp in the following locations:

| Platform | Paths |
|----------|-------|
| macOS | `/opt/homebrew/bin/cwebp`, `/usr/local/bin/cwebp`, `/opt/local/bin/cwebp` |
| Linux | `/usr/bin/cwebp`, `/usr/local/bin/cwebp`, `/home/linuxbrew/.linuxbrew/bin/cwebp` |
| Both | `~/.local/share/mise/shims/cwebp`, `~/.local/bin/cwebp`, `$PATH` |

### "WebP conversion failed for file"

This error indicates cwebp encountered a problem converting a specific file:

- **Corrupted PNG**: The source PNG file may be corrupted
- **Disk space**: Insufficient disk space for output
- **Permissions**: Cannot write to output directory

Check the error message for the specific exit code and stderr output.

## Next Steps

- Learn about [CLI usage and arguments](usage.md)
- Review [Design Requirements](design-requirements.md) to structure your Figma files correctly
- Explore [Example Projects](../../Examples/README.md) for working configurations
- Customize [code generation templates](custom-templates.md)

## See Also

- [Usage Guide](usage.md) - Detailed CLI commands
- [Configuration Reference](../../CONFIG.md) - All available options
- [Design Requirements](design-requirements.md) - Figma file structure

______________________________________________________________________

[← Back to Index](index.md) | [Next: Usage Guide →](usage.md)
