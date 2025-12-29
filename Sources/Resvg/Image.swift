import CResvg
import Foundation

// MARK: - ImageNode

/// An image element in the SVG tree.
///
/// Represents embedded or linked images (JPEG, PNG, GIF, or nested SVG).
public struct ImageNode: @unchecked Sendable {
    let ptr: OpaquePointer
    let tree: SvgTree

    init(_ ptr: OpaquePointer, tree: SvgTree) {
        self.ptr = ptr
        self.tree = tree
    }

    /// The element ID (from `id` attribute), or empty string if none.
    public var id: String {
        var len: UInt = 0
        guard let idPtr = resvg_image_id(ptr, &len), len > 0 else {
            return ""
        }
        return String(cString: idPtr)
    }

    /// The relative transform of this image.
    public var transform: Transform {
        Transform(resvg_image_transform(ptr))
    }

    /// The absolute transform including all ancestor transforms.
    public var absoluteTransform: Transform {
        Transform(resvg_image_abs_transform(ptr))
    }

    /// Whether this image is visible.
    public var isVisible: Bool {
        resvg_image_is_visible(ptr)
    }

    /// The size of this image in pixels.
    public var size: Size {
        Size(resvg_image_size(ptr))
    }

    /// The type of image data.
    public var kind: ImageKind {
        ImageKind(rawValue: resvg_image_get_kind(ptr).rawValue) ?? .jpeg
    }
}

// MARK: - ImageKind

/// The type of embedded image data.
public enum ImageKind: UInt32, Sendable {
    case jpeg = 0
    case png = 1
    case gif = 2
    case svg = 3
}
