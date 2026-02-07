import ExFig_Android
import ExFig_Flutter
import ExFig_iOS
import ExFig_Web
import ExFigCore

/// Registry that manages platform plugins and routes config keys to the appropriate plugin.
///
/// The registry is the central coordination point for the plugin system. It:
/// - Maintains a list of all registered plugins
/// - Routes configuration keys to the appropriate plugin
/// - Provides lookup by platform or identifier
///
/// ## Usage
///
/// ```swift
/// let registry = PluginRegistry.default
///
/// // Find plugin for a config key
/// if let plugin = registry.plugin(forConfigKey: "ios") {
///     let exporters = plugin.exporters()
///     // Use exporters...
/// }
///
/// // Find plugin for a platform
/// if let plugin = registry.plugin(for: .android) {
///     print("Using \(plugin.identifier) plugin")
/// }
/// ```
public struct PluginRegistry: Sendable {
    /// All registered plugins.
    public let allPlugins: [any PlatformPlugin]

    /// Lookup table from config key to plugin.
    private let configKeyIndex: [String: any PlatformPlugin]

    /// Lookup table from identifier to plugin.
    private let identifierIndex: [String: any PlatformPlugin]

    /// Lookup table from platform to plugin.
    private let platformIndex: [Platform: any PlatformPlugin]

    /// Creates a registry with the given plugins.
    ///
    /// - Parameter plugins: The plugins to register.
    public init(plugins: [any PlatformPlugin]) {
        allPlugins = plugins

        var configKeyIndex: [String: any PlatformPlugin] = [:]
        var identifierIndex: [String: any PlatformPlugin] = [:]
        var platformIndex: [Platform: any PlatformPlugin] = [:]

        for plugin in plugins {
            for key in plugin.configKeys {
                assert(
                    configKeyIndex[key] == nil,
                    "Duplicate config key '\(key)' registered by '\(plugin.identifier)'"
                )
                configKeyIndex[key] = plugin
            }
            identifierIndex[plugin.identifier] = plugin
            platformIndex[plugin.platform] = plugin
        }

        self.configKeyIndex = configKeyIndex
        self.identifierIndex = identifierIndex
        self.platformIndex = platformIndex
    }

    /// The default registry with all built-in plugins.
    public static let `default` = PluginRegistry(plugins: [
        iOSPlugin(),
        AndroidPlugin(),
        FlutterPlugin(),
        WebPlugin(),
    ])

    /// Returns the plugin that handles the given configuration key.
    ///
    /// - Parameter configKey: The configuration key (e.g., "ios", "android").
    /// - Returns: The plugin that handles this key, or nil if none found.
    public func plugin(forConfigKey configKey: String) -> (any PlatformPlugin)? {
        configKeyIndex[configKey]
    }

    /// Returns the plugin with the given identifier.
    ///
    /// - Parameter identifier: The plugin identifier (e.g., "ios", "android").
    /// - Returns: The plugin with this identifier, or nil if none found.
    public func plugin(withIdentifier identifier: String) -> (any PlatformPlugin)? {
        identifierIndex[identifier]
    }

    /// Returns the plugin for the given platform.
    ///
    /// - Parameter platform: The target platform.
    /// - Returns: The plugin for this platform, or nil if none found.
    public func plugin(for platform: Platform) -> (any PlatformPlugin)? {
        platformIndex[platform]
    }
}
