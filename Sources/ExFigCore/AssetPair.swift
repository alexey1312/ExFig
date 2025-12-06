/// A container that groups related asset variants for different appearances.
///
/// `AssetPair` holds up to four variants of the same asset:
/// - Light mode (required)
/// - Dark mode (optional)
/// - Light mode with high contrast (optional, iOS only)
/// - Dark mode with high contrast (optional, iOS only)
///
/// This structure is used throughout the export pipeline to maintain the relationship
/// between appearance variants of the same logical asset.
///
/// ## Example
/// ```swift
/// let colorPair = AssetPair(
///     light: Color(name: "background", red: 1, green: 1, blue: 1, alpha: 1),
///     dark: Color(name: "background", red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
/// )
/// ```
public struct AssetPair<AssetType>: Sendable where AssetType: Asset {
    /// The light mode variant of the asset. Always required.
    public let light: AssetType

    /// The dark mode variant of the asset. `nil` if no dark mode variant exists.
    public let dark: AssetType?

    /// The high contrast light mode variant (iOS accessibility feature).
    public let lightHC: AssetType?

    /// The high contrast dark mode variant (iOS accessibility feature).
    public let darkHC: AssetType?

    /// Creates a new asset pair with the specified variants.
    ///
    /// - Parameters:
    ///   - light: The required light mode variant.
    ///   - dark: Optional dark mode variant.
    ///   - lightHC: Optional high contrast light mode variant (iOS).
    ///   - darkHC: Optional high contrast dark mode variant (iOS).
    public init(
        light: AssetType,
        dark: AssetType?,
        lightHC: AssetType? = nil,
        darkHC: AssetType? = nil
    ) {
        self.light = light
        self.dark = dark
        self.lightHC = lightHC
        self.darkHC = darkHC
    }
}
