# Tasks: Add Fault Tolerance to Individual Commands

## 1. Shared Options Group

- [ ] 1.1 Create `FaultToleranceOptions` option group with --max-retries, --rate-limit, --fail-fast
- [ ] 1.2 Add helper method to create configured `RateLimitedClient` from options

## 2. Export Commands

- [ ] 2.1 Add `FaultToleranceOptions` to `ExportColors`
- [ ] 2.2 Add `FaultToleranceOptions` to `ExportIcons`
- [ ] 2.3 Add `FaultToleranceOptions` to `ExportImages`
- [ ] 2.4 Add `FaultToleranceOptions` to `ExportTypography`
- [ ] 2.5 Refactor commands to use `RateLimitedClient`

## 3. Fetch/Download Commands

- [ ] 3.1 Add `FaultToleranceOptions` to `Fetch`
- [ ] 3.2 Add `FaultToleranceOptions` to `Download` (colors, icons, typography, images, all)
- [ ] 3.3 Refactor commands to use `RateLimitedClient`

## 4. Checkpoint Support (Optional)

- [ ] 4.1 Evaluate if --resume makes sense for individual commands
- [ ] 4.2 If yes, add checkpoint support to icons/images commands

## 5. Testing

- [ ] 5.1 Add tests for FaultToleranceOptions parsing
- [ ] 5.2 Verify retry behavior in individual commands

## 6. Documentation

- [ ] 6.1 Update command help text with new options
- [ ] 6.2 Add examples to README
