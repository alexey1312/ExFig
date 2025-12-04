# Change: Add Fault Tolerance

## Why

ExFig interacts with external systems (Figma API, file system) that can fail unpredictably:

- **Figma API**: Rate limits (429), network timeouts, temporary outages
- **File system**: Disk full, permission errors, concurrent access

Currently, failures cause immediate termination. Users must restart from scratch, potentially hitting rate limits again.

## What Changes

- Add automatic retry with exponential backoff for API requests
- Implement rate limit detection and adaptive throttling
- Add atomic file writes with rollback on failure
- Create checkpoint/resume capability for large exports
- Add `--resume` flag to continue interrupted exports

## Impact

- Affected specs: `reliability` (new capability)
- Affected code:
  - `Sources/FigmaAPI/Client.swift` - Retry logic
  - `Sources/FigmaAPI/FigmaClient.swift` - Rate limit handling
  - `Sources/ExFig/Output/FileWriter.swift` - Atomic writes
  - `Sources/ExFig/Cache/` - Checkpoint management
  - `Sources/ExFig/Subcommands/*.swift` - Resume support
