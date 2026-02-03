import Foundation

/// Protocol for platform plugins that provide asset exporters.
///
/// A `PlatformPlugin` represents a target platform (iOS, Android, Flutter, Web)
/// and provides the exporters needed to export assets to that platform.
///
/// ## Plugin Registration
///
/// Plugins are registered with a `PluginRegistry` and are selected based on
/// configuration keys found in the PKL config file:
///
/// ```swift
/// struct iOSPlugin: PlatformPlugin {
///     let identifier = "ios"
///     let platform: Platform = .ios
///     let configKeys: Set<String> = ["ios"]
///
///     func exporters() -> [any AssetExporter] {
///         [
///             iOSColorsExporter(),
///             iOSIconsExporter(),
///             iOSImagesExporter(),
///             iOSTypographyExporter()
///         ]
///     }
/// }
/// ```
///
/// ## Configuration Keys
///
/// The `configKeys` property defines which PKL configuration sections this plugin
/// handles. For example, the iOS plugin handles the `ios` section of the config.
public protocol PlatformPlugin: Sendable {
    /// Unique identifier for this plugin.
    ///
    /// Used for logging, debugging, and plugin selection.
    /// Should be lowercase and match the platform name (e.g., "ios", "android").
    var identifier: String { get }

    /// The target platform for this plugin.
    var platform: Platform { get }

    /// Configuration keys that this plugin handles.
    ///
    /// When a PKL config contains any of these keys, this plugin will be activated.
    /// For example, `["ios"]` means the plugin handles `ios { ... }` sections.
    var configKeys: Set<String> { get }

    /// Returns the asset exporters provided by this plugin.
    ///
    /// Each exporter handles a specific asset type (colors, icons, images, typography).
    /// The plugin decides which exporters to provide based on the platform's capabilities.
    ///
    /// - Returns: Array of asset exporters for this platform.
    func exporters() -> [any AssetExporter]
}
