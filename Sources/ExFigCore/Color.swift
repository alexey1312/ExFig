import Foundation

/// A color asset with RGBA components.
///
/// Colors are exported from Figma and can be generated as:
/// - Xcode asset catalogs (`.colorset`)
/// - Swift extensions for `UIColor` and SwiftUI `Color`
/// - Android XML color resources
/// - Jetpack Compose color definitions
///
/// Color components are normalized to the range 0.0 to 1.0.
public struct Color: Asset, Sendable {
    /// The sanitized name used in generated code.
    public var name: String

    /// The original name from Figma, preserved for namespacing and grouping.
    public let originalName: String

    /// The target platform for this color, if platform-specific.
    public let platform: Platform?

    /// Red component (0.0 to 1.0).
    public let red: Double

    /// Green component (0.0 to 1.0).
    public let green: Double

    /// Blue component (0.0 to 1.0).
    public let blue: Double

    /// Alpha (opacity) component (0.0 to 1.0).
    public let alpha: Double

    /// Creates a new color with the specified components.
    ///
    /// - Parameters:
    ///   - name: The color name, used in generated code.
    ///   - platform: Optional target platform.
    ///   - red: Red component (0.0 to 1.0).
    ///   - green: Green component (0.0 to 1.0).
    ///   - blue: Blue component (0.0 to 1.0).
    ///   - alpha: Alpha component (0.0 to 1.0).
    public init(name: String, platform: Platform? = nil, red: Double, green: Double, blue: Double, alpha: Double) {
        self.name = name
        originalName = name
        self.platform = platform
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    // MARK: Hashable

    public static func == (lhs: Color, rhs: Color) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
