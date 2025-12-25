import Foundation

/// Collected theme attributes from a single config's colors export.
///
/// In batch mode, multiple configs may export to the same `attrs.xml` and `styles.xml` files.
/// This struct captures one config's contribution for later merging.
public struct ThemeAttributesCollection: Sendable {
    /// Theme name used in markers (e.g., "Theme.MyApp.Main").
    public let themeName: String

    /// Base marker start text (e.g., "FIGMA COLORS MARKER START").
    public let markerStart: String

    /// Base marker end text (e.g., "FIGMA COLORS MARKER END").
    public let markerEnd: String

    /// Content for attrs.xml (lines between markers).
    public let attrsContent: String

    /// Content for styles.xml (lines between markers).
    public let stylesContent: String

    /// Target attrs.xml file path.
    public let attrsFile: URL

    /// Target styles.xml file path.
    public let stylesFile: URL

    /// Target styles-night.xml file path (optional).
    public let stylesNightFile: URL?

    /// Whether to auto-create files with markers if missing.
    public let autoCreateMarkers: Bool

    public init(
        themeName: String,
        markerStart: String,
        markerEnd: String,
        attrsContent: String,
        stylesContent: String,
        attrsFile: URL,
        stylesFile: URL,
        stylesNightFile: URL?,
        autoCreateMarkers: Bool
    ) {
        self.themeName = themeName
        self.markerStart = markerStart
        self.markerEnd = markerEnd
        self.attrsContent = attrsContent
        self.stylesContent = stylesContent
        self.attrsFile = attrsFile
        self.stylesFile = stylesFile
        self.stylesNightFile = stylesNightFile
        self.autoCreateMarkers = autoCreateMarkers
    }
}

/// Actor for collecting theme attributes from multiple configs in batch mode.
///
/// When batch processing, each config may export theme attributes to shared files.
/// This actor collects all contributions and allows merging them after batch completes.
///
/// ## Usage
///
/// ```swift
/// let collector = SharedThemeAttributesCollector()
///
/// // Inject via TaskLocal
/// await SharedThemeAttributesStorage.$collector.withValue(collector) {
///     await executor.execute(configs: configs) { ... }
/// }
///
/// // After batch: merge and write all collected attributes
/// let collections = await collector.getAll()
/// try mergeThemeAttributes(collections: collections)
/// ```
public actor SharedThemeAttributesCollector {
    private var collections: [ThemeAttributesCollection] = []

    public init() {}

    /// Add a theme attributes collection from a config export.
    public func add(_ collection: ThemeAttributesCollection) {
        collections.append(collection)
    }

    /// Get all collected theme attributes.
    public func getAll() -> [ThemeAttributesCollection] {
        collections
    }

    /// Check if any collections have been added.
    public var isEmpty: Bool {
        collections.isEmpty
    }

    /// Number of collected entries.
    public var count: Int {
        collections.count
    }

    /// Clear all collected attributes.
    public func clear() {
        collections.removeAll()
    }
}

/// TaskLocal storage for shared theme attributes collector.
///
/// When running in batch mode, this storage holds the shared collector.
/// When running standalone commands, this is `nil` and theme attributes
/// are written immediately.
///
/// ## Usage in ExportColors
///
/// ```swift
/// if let collector = SharedThemeAttributesStorage.collector {
///     // Batch mode: collect for later merge
///     await collector.add(collection)
/// } else {
///     // Standalone mode: write immediately
///     try writeThemeAttributes(...)
/// }
/// ```
public enum SharedThemeAttributesStorage {
    @TaskLocal public static var collector: SharedThemeAttributesCollector?
}
