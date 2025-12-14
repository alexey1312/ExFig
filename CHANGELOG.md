# Changelog

All notable changes to this project will be documented in this file.

## [1.1.3] - 2025-12-11

### Documentation

- **docc**: Migrate documentation from GitHub docs to DocC by @alexey1312


### Features

- **batch**: Add nodes and components pre-fetch for granular cache by @alexey1312


## [1.1.2] - 2025-12-09

### Bug Fixes

- **cache**: Sort children by name for stable granular cache hashing by @alexey1312


### Miscellaneous Tasks

- **release**: Add static Swift stdlib for Linux builds by @alexey1312


## [1.1.1] - 2025-12-09

### Features

- **icons**: Ensure light/dark pairs export together with granular cache by @alexey1312


## [1.1.0] - 2025-12-09

### Other

- Update batch

* feat(batch): add pipelined download queue for parallelism

Introduce SharedDownloadQueue to coordinate CDN downloads across
parallel configs in batch mode. Downloads are prioritized by config
submission order and processed with shared concurrency pool.

- Add DownloadJob/DownloadJobResult for batch coordination
- Add PipelinedDownloader helper with TaskLocal injection
- Add SharedDownloadQueueStorage for config-level context
- Update BatchConfigRunner to inject queue and priority
- Update ExportIcons/ExportImages to use PipelinedDownloader
- Scale total download slots by parallel workers count

Benefits: eliminates per-config download bottlenecks, improves
throughput in multi-config batch runs, maintains FIFO ordering.

* feat(batch): add rich progress view with ETA and status

- Add BatchProgressView integration with per-config status tracking
- Calculate and display ETA based on export progress
- Coordinate UI suppression via BatchProgressViewStorage TaskLocal
- Clear/redraw progress display for log/error output
- Update rate limiter status every 500ms during execution
- Suppress spinners and progress bars in batch mode to prevent corruption

* feat(batch): centralize update check to end of batch

Suppress individual update checks during batch exports and check once
after all configs complete. by @alexey1312 in [#10](https://github.com/alexey1312/ExFig/pull/10)


## [1.0.8] - 2025-12-09

### Documentation

- **batch**: Clarify granular cache merge sequence by @alexey1312


### Features

- **batch**: Add shared granular cache for parallel configs by @alexey1312


## [1.0.7] - 2025-12-08

### Bug Fixes

- **release**: Use v-prefixed version format consistently by @alexey1312


## [1.0.6] - 2025-12-08

### Features

- **svg**: Add CSS styles, use/symbol refs, stroke-dasharray parsing by @alexey1312

- **cli**: Add --timeout flag for API request timeout override by @alexey1312

- **cache**: Add granular node-level cache tracking  by @alexey1312 in [#9](https://github.com/alexey1312/ExFig/pull/9)


## [1.0.5] - 2025-12-07

### Features

- **terminal**: Add unified warning types with TOON formatting by @alexey1312

- **terminal**: Add unified error formatting with recovery suggestions by @alexey1312

- **batch**: Pre-fetch file versions for cache-enabled batch runs by @alexey1312


## [1.0.4] - 2025-12-07

### Bug Fixes

- **batch**: Skip unconfigured asset types and simplify output by @alexey1312


### Miscellaneous Tasks

- **release**: Use git-cliff for release notes generation by @alexey1312


## [1.0.3] - 2025-12-07

### Bug Fixes

- **api**: Increase default retry base delay to 3 seconds by @alexey1312


### Documentation

- **oxipng**: Update doc to oxipng by @alexey1312


### Features

- **batch**: Add cache and concurrency options to batch command by @alexey1312


## [1.0.2] - 2025-12-06

### Bug Fixes

- **cli**: Improve help text and add version to main command by @alexey1312


### Miscellaneous Tasks

- **release**: Use v-prefixed tags for mise/ubi compatibility by @alexey1312


## [1.0.1] - 2025-12-06

### Miscellaneous Tasks

- **release**: Rename binary from exfig to ExFig in dist by @alexey1312


## [1.0.0] - 2025-12-06

### Features

- Complete ExFig implementation by @alexey1312



