import Foundation

/// Represents the scale factor for an image asset.
///
/// Scale determines how images are rendered at different display densities:
/// - iOS: @1x, @2x, @3x
/// - Android: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi
public enum Scale: Sendable {
    /// Vector image that scales to any size (e.g., PDF, SVG).
    case all

    /// Raster image at a specific scale factor (e.g., 1.0, 2.0, 3.0).
    case individual(_ value: Double)

    /// The numeric scale value. Returns 1.0 for `.all`.
    public var value: Double {
        switch self {
        case .all:
            1
        case let .individual(value):
            value
        }
    }
}

/// A single image asset at a specific scale.
///
/// Images represent individual bitmap or vector files exported from Figma.
/// They are typically grouped into ``ImagePack`` collections that contain
/// all scale variants of the same logical image.
public struct Image: Asset, Sendable {
    /// The image name, used in generated code.
    public var name: String

    /// The scale factor for this image variant.
    public let scale: Scale

    /// The image file format (e.g., "png", "pdf", "svg").
    public let format: String

    /// The URL to download this image from Figma.
    public let url: URL

    /// The device idiom for iOS (e.g., "iphone", "ipad"). Empty for universal images.
    public let idiom: String?

    /// Whether this image should be mirrored for right-to-left languages.
    public let isRTL: Bool

    /// The target platform for this image.
    public var platform: Platform?

    /// Creates a new image asset.
    ///
    /// - Parameters:
    ///   - name: The image name.
    ///   - scale: The scale factor (default: `.all` for vectors).
    ///   - platform: Optional target platform.
    ///   - idiom: Optional device idiom for iOS.
    ///   - url: The download URL from Figma.
    ///   - format: The file format.
    ///   - isRTL: Whether to mirror for RTL languages.
    public init(
        name: String,
        scale: Scale = .all,
        platform: Platform? = nil,
        idiom: String? = nil,
        url: URL,
        format: String,
        isRTL: Bool = false
    ) {
        self.name = name
        self.scale = scale
        self.platform = platform
        self.url = url
        self.idiom = idiom
        self.format = format
        self.isRTL = isRTL
    }

    // MARK: Hashable

    public static func == (lhs: Image, rhs: Image) -> Bool {
        lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

/// A collection of image variants for a single logical image asset.
///
/// An `ImagePack` groups together all scale variants (1x, 2x, 3x) and device idioms
/// (iPhone, iPad) for a single image. This is the primary unit for image export.
///
/// ## Example
/// An icon might have 3 variants (1x, 2x, 3x) all grouped in one ImagePack.
public struct ImagePack: Asset, Sendable {
    /// All image variants for this asset.
    public var images: [Image]

    /// The Xcode render mode for icons (template, original, default).
    public var renderMode = XcodeRenderMode.template

    /// The asset name. Setting this updates all contained images.
    public var name: String {
        didSet {
            images = images.map { image -> Image in
                var newImage = image
                newImage.name = name
                return newImage
            }
        }
    }

    /// The target platform.
    public var platform: Platform?

    /// The Figma node ID for this asset (e.g., "12016:2218").
    /// Used for Code Connect integration to link back to Figma components.
    public var nodeId: String?

    /// The Figma file ID containing this asset.
    /// Used for Code Connect integration to construct Figma URLs.
    public var fileId: String?

    /// Creates an image pack with multiple variants.
    ///
    /// - Parameters:
    ///   - name: The asset name.
    ///   - images: Array of image variants.
    ///   - platform: Optional target platform.
    ///   - nodeId: Optional Figma node ID for Code Connect.
    ///   - fileId: Optional Figma file ID for Code Connect.
    public init(
        name: String,
        images: [Image],
        platform: Platform? = nil,
        nodeId: String? = nil,
        fileId: String? = nil
    ) {
        self.name = name
        self.images = images
        self.platform = platform
        self.nodeId = nodeId
        self.fileId = fileId
    }

    /// Creates an image pack from a single image.
    ///
    /// - Parameters:
    ///   - image: The single image variant.
    ///   - platform: Optional target platform.
    ///   - nodeId: Optional Figma node ID for Code Connect.
    ///   - fileId: Optional Figma file ID for Code Connect.
    public init(
        image: Image,
        platform: Platform? = nil,
        nodeId: String? = nil,
        fileId: String? = nil
    ) {
        name = image.name
        images = [image]
        self.platform = platform
        self.nodeId = nodeId
        self.fileId = fileId
    }
}
