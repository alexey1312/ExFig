# Tasks: Add Image Optimization

TDD approach - write tests first, then implement.

## 1. ImageOptimizer Core (ImageOptimizer.swift)

- [x] 1.1 Write tests for `ImageOptimizerError` localized descriptions
- [x] 1.2 Write tests for `standardSearchPaths` (env, mise, gem paths)
- [x] 1.3 Write tests for `findImageOptim()` with mock file system
- [x] 1.4 Write tests for `isAvailable()` static method
- [x] 1.5 Write tests for `optimize(file:)` with lossless mode
- [x] 1.6 Write tests for `optimize(file:)` with lossy mode (allowLossy: true)
- [x] 1.7 Write tests for error handling (file not found, conversion failed)
- [x] 1.8 Implement `ImageOptimizerError` enum
- [x] 1.9 Implement `ImageOptimizer` class with binary discovery
- [x] 1.10 Run tests - verify pass

## 2. Batch Processing (ImageOptimizer.swift)

- [x] 2.1 Write tests for `optimizeBatch(files:onProgress:)` with empty array
- [x] 2.2 Write tests for `optimizeBatch(files:onProgress:)` with single file
- [x] 2.3 Write tests for `optimizeBatch(files:onProgress:)` with multiple files
- [x] 2.4 Write tests for progress callback invocation (current, total)
- [x] 2.5 Write tests for parallel execution (maxConcurrent limit)
- [x] 2.6 Implement batch processing with TaskGroup
- [x] 2.7 Run tests - verify pass

## 3. Configuration Parsing (Params.swift)

- [x] 3.1 Write tests for `OptimizeOptions` decoding (allowLossy field)
- [x] 3.2 Write tests for iOS.Images with optimize/optimizeOptions
- [x] 3.3 Write tests for Android.Images with optimize/optimizeOptions
- [x] 3.4 Write tests for Flutter.Images with optimize/optimizeOptions
- [x] 3.5 Write tests for backward compatibility (missing optimize fields)
- [x] 3.6 Add `OptimizeOptions` struct to Params.swift
- [x] 3.7 Add optimize fields to iOS.Images, Android.Images, Flutter.Images
- [x] 3.8 Run tests - verify pass

## 4. Export Integration (ExportImages.swift)

- [x] 4.1 Write tests for iOS export with optimization enabled
- [x] 4.2 Write tests for Android PNG export with optimization
- [x] 4.3 Write tests for Flutter PNG export with optimization
- [x] 4.4 Write tests for skipping optimization when format is webp
- [x] 4.5 Write tests for warning when image_optim not installed
- [x] 4.6 Integrate optimization into iOS export flow
- [x] 4.7 Integrate optimization into Android export flow
- [x] 4.8 Integrate optimization into Flutter export flow
- [x] 4.9 Run tests - verify pass

## 5. Documentation & Final Validation

- [x] 5.1 Add IMAGE_OPTIM_PATH to CLAUDE.md (Optional External Tools)
- [x] 5.2 Document optimize/optimizeOptions in CONFIG.md
- [x] 5.3 Add installation instructions (mise, gem)
- [x] 5.4 Run full test suite (`mise run test`)
- [x] 5.5 Run linter (`mise run lint`)
