import Foundation

/// Registry for platform plugins with routing capabilities.
///
/// The `PluginRegistry` manages platform plugins and provides methods
/// for routing export requests to the appropriate plugin based on
/// configuration keys.
///
/// ## Usage
///
/// ```swift
/// let registry = PluginRegistry()
/// registry.register(iOSPlugin())
/// registry.register(AndroidPlugin())
///
/// // Find plugin for a platform
/// if let plugin = registry.plugin(for: .ios) {
///     let exporters = plugin.exporters()
///     // ...
/// }
/// ```
public final class PluginRegistry: @unchecked Sendable {
    private var plugins: [String: any PlatformPlugin] = [:]
    private let lock = NSLock()

    public init() {}

    /// Registers a plugin in the registry.
    ///
    /// - Parameter plugin: The plugin to register.
    public func register(_ plugin: some PlatformPlugin) {
        lock.lock()
        defer { lock.unlock() }
        plugins[plugin.identifier] = plugin
    }

    /// Returns the plugin for a given platform.
    ///
    /// - Parameter platform: The target platform.
    /// - Returns: The registered plugin, or nil if not found.
    public func plugin(for platform: Platform) -> (any PlatformPlugin)? {
        lock.lock()
        defer { lock.unlock() }
        return plugins.values.first { $0.platform == platform }
    }

    /// Returns the plugin with a given identifier.
    ///
    /// - Parameter identifier: The plugin identifier (e.g., "ios", "android").
    /// - Returns: The registered plugin, or nil if not found.
    public func plugin(identifier: String) -> (any PlatformPlugin)? {
        lock.lock()
        defer { lock.unlock() }
        return plugins[identifier]
    }

    /// Returns all registered plugins.
    public var allPlugins: [any PlatformPlugin] {
        lock.lock()
        defer { lock.unlock() }
        return Array(plugins.values)
    }

    /// Returns the colors exporter for a platform, if available.
    ///
    /// - Parameter platform: The target platform.
    /// - Returns: The colors exporter, or nil if not available.
    public func colorsExporter(for platform: Platform) -> (any AssetExporter)? {
        plugin(for: platform)?.exporters().first { $0.assetType == .colors }
    }
}
