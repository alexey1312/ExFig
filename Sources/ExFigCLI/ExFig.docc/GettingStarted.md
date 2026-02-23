# Getting Started

Install ExFig and configure your first export.

## Overview

ExFig is a command-line tool that exports design resources from Figma to iOS, Android, and Flutter projects.

## Requirements

- macOS 13.0 or later (or Linux Ubuntu 22.04)
- Figma account with file access
- Figma Personal Access Token

## Installation

### Using Homebrew (Recommended)

```bash
brew install alexey1312/tap/exfig
```

### Using Mint

```bash
mint install alexey1312/ExFig
```

### Using Mise

```bash
mise use -g github:alexey1312/ExFig
```

### From Source

```bash
git clone https://github.com/alexey1312/ExFig.git
cd ExFig
swift build -c release
cp .build/release/exfig /usr/local/bin/
```

### Download Binary

Download the latest release from [GitHub Releases](https://github.com/alexey1312/ExFig/releases).

## Figma Access Token

ExFig requires a Figma Personal Access Token to access the Figma API.

### Create a Token

1. Open [Figma Account Settings](https://www.figma.com/settings)
2. Scroll to **Personal access tokens**
3. Click **Create a new personal access token**
4. Give it a descriptive name (e.g., "ExFig CLI")
5. Copy the generated token

### Set the Token

Set the `FIGMA_PERSONAL_TOKEN` environment variable:

```bash
# Add to ~/.zshrc or ~/.bashrc
export FIGMA_PERSONAL_TOKEN="your-token-here"
```

Or pass it directly to commands:

```bash
FIGMA_PERSONAL_TOKEN="your-token" exfig colors
```

## Quick Start

### 1. Initialize Configuration

Generate a starter configuration file for your platform:

```bash
# For iOS projects
exfig init --platform ios

# For Android projects
exfig init --platform android

# For Flutter projects
exfig init --platform flutter
```

This creates an `exfig.pkl` file in your current directory.

### 2. Get Your Figma File ID

The file ID is in the Figma URL:

```
https://www.figma.com/file/ABC123xyz/My-Design-System
                          ^^^^^^^^^^^
                          This is your file ID
```

### 3. Configure exfig.pkl

Edit the generated `exfig.pkl`:

```pkl
amends ".exfig/schemas/ExFig.pkl"

import ".exfig/schemas/Figma.pkl"
import ".exfig/schemas/iOS.pkl"

figma = new Figma.FigmaConfig {
  lightFileId = "YOUR_FILE_ID_HERE"
}

ios = new iOS.iOSConfig {
  xcodeprojPath = "./MyApp.xcodeproj"
  xcassetsPath = "./Resources/Assets.xcassets"
  // ... other iOS settings
}
```

### 4. Export Resources

```bash
# Export individual resource types
exfig colors
exfig icons
exfig images
exfig typography

# Or export everything at once with batch
exfig batch exfig.pkl
```

> Note: Individual commands use the `-i` flag for custom config paths (`exfig colors -i path.pkl`),
> while `batch` takes paths as positional arguments (`exfig batch path.pkl`).

## What's Next

- <doc:Usage> - Learn about all CLI commands and options
- <doc:Configuration> - Full configuration reference
- <doc:DesignRequirements> - How to structure your Figma files
- <doc:iOS> - iOS-specific export guide
- <doc:Android> - Android-specific export guide
- <doc:Flutter> - Flutter-specific export guide
