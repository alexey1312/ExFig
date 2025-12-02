# Flutter Example

This is a sample Flutter project demonstrating how to use ExFig to export design assets from Figma.

## Getting Started

1. Set up your Figma personal access token:
   ```bash
   export FIGMA_PERSONAL_TOKEN="your-token-here"
   ```

2. Run ExFig to export assets:
   ```bash
   exfig colors    # Export colors to lib/generated/colors.dart
   exfig icons     # Export icons to assets/icons/
   exfig images    # Export images to assets/images/
   ```

3. Run the Flutter app:
   ```bash
   flutter pub get
   flutter run
   ```

## Project Structure

```
FlutterExample/
├── exfig.yaml                 # ExFig configuration
├── lib/
│   ├── main.dart             # App entry point
│   ├── generated/            # Generated Dart files
│   │   ├── colors.dart       # Color constants
│   │   ├── icons.dart        # Icon asset paths
│   │   └── images.dart       # Image asset paths
│   └── ui/                   # UI pages
│       ├── colors_page.dart
│       ├── icons_page.dart
│       └── images_page.dart
├── assets/
│   ├── icons/                # SVG icon assets
│   └── images/               # Multi-scale PNG images
│       ├── *.png             # 1x images
│       ├── 2.0x/*.png        # 2x images
│       └── 3.0x/*.png        # 3x images
└── pubspec.yaml
```

## Configuration

The `exfig.yaml` file configures ExFig for Flutter export:

- **output**: Path to generated Dart files (`lib/generated/`)
- **colors**: Color class name and output file
- **icons**: SVG icon assets directory and Dart constants
- **images**: Multi-scale PNG images with Dart constants

## Generated Code Usage

### Colors

```dart
import 'generated/colors.dart';

// Light theme
Container(color: AppColors.backgroundPrimary)

// Dark theme
Container(color: AppColorsDark.backgroundPrimary)
```

### Icons

```dart
import 'package:flutter_svg/flutter_svg.dart';
import 'generated/icons.dart';

SvgPicture.asset(AppIcons.ic24ArrowBack)
```

### Images

```dart
import 'generated/images.dart';

Image.asset(AppImages.imgZeroEmpty)
```
