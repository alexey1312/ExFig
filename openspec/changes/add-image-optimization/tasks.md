# Tasks: Add Image Optimization

TDD approach - write tests first, then implement.

## 1. ImageOptimizer Core (ImageOptimizer.swift)

- [ ] 1.1 Write tests for `ImageOptimizerError` localized descriptions
- [ ] 1.2 Write tests for `standardSearchPaths` (env, mise, gem paths)
- [ ] 1.3 Write tests for `findImageOptim()` with mock file system
- [ ] 1.4 Write tests for `isAvailable()` static method
- [ ] 1.5 Write tests for `optimize(file:)` with lossless mode
- [ ] 1.6 Write tests for `optimize(file:)` with lossy mode (allowLossy: true)
- [ ] 1.7 Write tests for error handling (file not found, conversion failed)
- [ ] 1.8 Implement `ImageOptimizerError` enum
- [ ] 1.9 Implement `ImageOptimizer` class with binary discovery
- [ ] 1.10 Run tests - verify pass

## 2. Batch Processing (ImageOptimizer.swift)

- [ ] 2.1 Write tests for `optimizeBatch(files:onProgress:)` with empty array
- [ ] 2.2 Write tests for `optimizeBatch(files:onProgress:)` with single file
- [ ] 2.3 Write tests for `optimizeBatch(files:onProgress:)` with multiple files
- [ ] 2.4 Write tests for progress callback invocation (current, total)
- [ ] 2.5 Write tests for parallel execution (maxConcurrent limit)
- [ ] 2.6 Implement batch processing with TaskGroup
- [ ] 2.7 Run tests - verify pass

## 3. Configuration Parsing (Params.swift)

- [ ] 3.1 Write tests for `OptimizeOptions` decoding (allowLossy field)
- [ ] 3.2 Write tests for iOS.Images with optimize/optimizeOptions
- [ ] 3.3 Write tests for Android.Images with optimize/optimizeOptions
- [ ] 3.4 Write tests for Flutter.Images with optimize/optimizeOptions
- [ ] 3.5 Write tests for backward compatibility (missing optimize fields)
- [ ] 3.6 Add `OptimizeOptions` struct to Params.swift
- [ ] 3.7 Add optimize fields to iOS.Images, Android.Images, Flutter.Images
- [ ] 3.8 Run tests - verify pass

## 4. Export Integration (ExportImages.swift)

- [ ] 4.1 Write tests for iOS export with optimization enabled
- [ ] 4.2 Write tests for Android PNG export with optimization
- [ ] 4.3 Write tests for Flutter PNG export with optimization
- [ ] 4.4 Write tests for skipping optimization when format is webp
- [ ] 4.5 Write tests for warning when image_optim not installed
- [ ] 4.6 Integrate optimization into iOS export flow
- [ ] 4.7 Integrate optimization into Android export flow
- [ ] 4.8 Integrate optimization into Flutter export flow
- [ ] 4.9 Run tests - verify pass

## 5. Documentation & Final Validation

- [ ] 5.1 Add IMAGE_OPTIM_PATH to CLAUDE.md (Optional External Tools)
- [ ] 5.2 Document optimize/optimizeOptions in CONFIG.md
- [ ] 5.3 Add installation instructions (mise, gem)
- [ ] 5.4 Run full test suite (`mise run test`)
- [ ] 5.5 Run linter (`mise run lint`)
