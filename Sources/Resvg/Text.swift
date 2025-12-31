import CResvg
import Foundation

// MARK: - TextNode

/// A text element in the SVG tree.
///
/// Text elements contain positioned text with styling. After parsing,
/// text is converted to flattened paths for rendering.
public struct TextNode: @unchecked Sendable {
    let ptr: OpaquePointer
    let tree: SvgTree

    init(_ ptr: OpaquePointer, tree: SvgTree) {
        self.ptr = ptr
        self.tree = tree
    }

    /// The element ID (from `id` attribute), or empty string if none.
    public var id: String {
        var len: UInt = 0
        guard let idPtr = resvg_text_id(ptr, &len), len > 0 else {
            return ""
        }
        return String(cString: idPtr)
    }

    /// The relative transform of this text element.
    public var transform: Transform {
        Transform(resvg_text_transform(ptr))
    }

    /// The absolute transform including all ancestor transforms.
    public var absoluteTransform: Transform {
        Transform(resvg_text_abs_transform(ptr))
    }

    /// The bounding box of the text.
    public var boundingBox: Rect {
        Rect(resvg_text_bounding_box(ptr))
    }

    /// The flattened paths representing this text.
    ///
    /// Returns the group containing the text converted to paths.
    /// This is what gets rendered - text is always converted to paths
    /// after font resolution.
    public var flattened: Group? {
        guard let groupPtr = resvg_text_flattened(ptr) else {
            return nil
        }
        return Group(groupPtr, tree: tree)
    }
}
