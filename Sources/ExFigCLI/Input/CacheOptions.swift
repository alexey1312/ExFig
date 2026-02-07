import ArgumentParser

/// CLI options for controlling version tracking cache.
/// These options can override the configuration.
struct CacheOptions: ParsableArguments {
    @Flag(
        name: .long,
        help: "Enable version tracking cache (skip export if unchanged)"
    )
    var cache: Bool = false

    @Flag(
        name: .long,
        help: "Disable version tracking cache (always export)"
    )
    var noCache: Bool = false

    @Flag(
        name: .long,
        help: "Force export and update cache (ignore cached version)"
    )
    var force: Bool = false

    @Option(
        name: .long,
        help: "Custom path to cache file (default: .exfig-cache.json)"
    )
    var cachePath: String?

    @Flag(
        name: .long,
        help: "[EXPERIMENTAL] Enable per-node hash tracking for granular cache invalidation"
    )
    var experimentalGranularCache: Bool = false

    /// Resolves the effective cache enabled state.
    /// CLI flags take priority over config.
    /// - Parameter configEnabled: The value from config (common.cache.enabled).
    /// - Returns: Whether cache should be enabled.
    func isEnabled(configEnabled: Bool) -> Bool {
        // CLI flags override config
        if noCache {
            return false
        }
        if cache || force {
            return true
        }
        // Fall back to config value
        return configEnabled
    }

    /// Resolves the effective cache path.
    /// CLI option takes priority over config.
    /// - Parameter configPath: The value from config (common.cache.path).
    /// - Returns: The cache path to use (nil means use default).
    func resolvePath(configPath: String?) -> String? {
        cachePath ?? configPath
    }

    /// Checks if granular cache is enabled with proper --cache flag.
    /// - Parameter configEnabled: The value from config (common.cache.enabled).
    /// - Returns: Whether granular cache should be active.
    func isGranularCacheEnabled(configEnabled: Bool) -> Bool {
        experimentalGranularCache && isEnabled(configEnabled: configEnabled)
    }

    /// Returns a warning if granular cache is enabled without --cache.
    /// - Parameter configEnabled: The value from config (common.cache.enabled).
    /// - Returns: Warning if misconfigured, nil otherwise.
    func granularCacheWarning(configEnabled: Bool) -> ExFigWarning? {
        if experimentalGranularCache, !isEnabled(configEnabled: configEnabled) {
            return .granularCacheWithoutCache
        }
        return nil
    }
}
