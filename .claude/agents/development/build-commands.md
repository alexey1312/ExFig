# Build Commands

All commands use mise (`./bin/mise` self-contained, no global install needed).

## Build

```bash
./bin/mise run build                # Debug build
./bin/mise run build:release        # Release build
```

## Test

```bash
./bin/mise run test                 # All tests
./bin/mise run test:filter NAME     # Filter by target/class/method
./bin/mise run test:file FILE       # Run tests for specific file
```

Examples:

```bash
./bin/mise run test:filter ExFigTests              # By test target
./bin/mise run test:filter SVGParserTests          # By test class
./bin/mise run test:file Tests/SVGKitTests/SVGParserTests.swift  # By file
```

## Code Quality

```bash
./bin/mise run format               # Format all (Swift + Markdown)
./bin/mise run format:swift         # Format Swift only
./bin/mise run format:md            # Format Markdown only
./bin/mise run lint                 # SwiftLint + actionlint
```

## Setup

```bash
./bin/mise run setup                # Install hk git hooks (one-time)
```

## Run CLI

```bash
.build/debug/exfig --help
.build/debug/exfig colors -i config.yaml
.build/debug/exfig fetch -f FILE_ID -r "Frame" -o ./output
```

## Generate Starter Config

```bash
exfig init -p ios
exfig init -p android
```
