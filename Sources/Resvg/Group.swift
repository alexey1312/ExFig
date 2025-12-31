import CResvg
import Foundation

// MARK: - TreeNode

/// A node in the SVG tree.
///
/// Use `nodeType` to determine the type, then call the appropriate `as*()` method
/// to get a typed reference.
public struct TreeNode: @unchecked Sendable {
    let ptr: UnsafeRawPointer
    let tree: SvgTree

    init(_ ptr: UnsafeRawPointer, tree: SvgTree) {
        self.ptr = ptr
        self.tree = tree
    }

    /// The type of this node.
    public var nodeType: NodeType {
        let type = resvg_node_get_type(OpaquePointer(ptr))
        return NodeType(rawValue: type.rawValue) ?? .group
    }

    /// Cast to Group if this is a group node.
    public func asGroup() -> Group? {
        guard let groupPtr = resvg_node_as_group(OpaquePointer(ptr)) else {
            return nil
        }
        return Group(groupPtr, tree: tree)
    }

    /// Cast to Path if this is a path node.
    public func asPath() -> Path? {
        guard let pathPtr = resvg_node_as_path(OpaquePointer(ptr)) else {
            return nil
        }
        return Path(pathPtr, tree: tree)
    }

    /// Cast to Image if this is an image node.
    public func asImage() -> ImageNode? {
        guard let imagePtr = resvg_node_as_image(OpaquePointer(ptr)) else {
            return nil
        }
        return ImageNode(imagePtr, tree: tree)
    }

    /// Cast to Text if this is a text node.
    public func asText() -> TextNode? {
        guard let textPtr = resvg_node_as_text(OpaquePointer(ptr)) else {
            return nil
        }
        return TextNode(textPtr, tree: tree)
    }
}

// MARK: - Group

/// A group element in the SVG tree.
///
/// Groups can contain children and may have masks, clip paths, transforms, and opacity.
public struct Group: @unchecked Sendable {
    let ptr: OpaquePointer
    let tree: SvgTree

    init(_ ptr: OpaquePointer, tree: SvgTree) {
        self.ptr = ptr
        self.tree = tree
    }

    /// The element ID (from `id` attribute), or empty string if none.
    public var id: String {
        var len: UInt = 0
        guard let idPtr = resvg_group_id(ptr, &len), len > 0 else {
            return ""
        }
        return String(cString: idPtr)
    }

    /// The relative transform of this group.
    public var transform: Transform {
        Transform(resvg_group_transform(ptr))
    }

    /// The absolute transform including all ancestor transforms.
    public var absoluteTransform: Transform {
        Transform(resvg_group_abs_transform(ptr))
    }

    /// The opacity of this group (0.0 to 1.0).
    public var opacity: Float {
        resvg_group_opacity(ptr)
    }

    /// The blend mode of this group.
    public var blendMode: BlendMode {
        BlendMode(rawValue: resvg_group_blend_mode(ptr).rawValue) ?? .normal
    }

    /// Whether this group has a mask.
    public var hasMask: Bool {
        resvg_group_has_mask(ptr)
    }

    /// Whether this group has a clip path.
    public var hasClipPath: Bool {
        resvg_group_has_clip_path(ptr)
    }

    /// Whether this group is isolated.
    public var isIsolated: Bool {
        resvg_group_isolate(ptr)
    }

    /// The mask applied to this group, if any.
    public var mask: Mask? {
        guard let maskPtr = resvg_group_mask(ptr) else {
            return nil
        }
        return Mask(maskPtr, tree: tree)
    }

    /// The clip path applied to this group, if any.
    public var clipPath: ClipPath? {
        guard let clipPtr = resvg_group_clip_path(ptr) else {
            return nil
        }
        return ClipPath(clipPtr, tree: tree)
    }

    /// The number of children in this group.
    public var childCount: Int {
        Int(resvg_group_children_count(ptr))
    }

    /// The children of this group.
    public var children: [TreeNode] {
        let count = childCount
        var result: [TreeNode] = []
        result.reserveCapacity(count)
        for i in 0 ..< count {
            if let childPtr = resvg_group_child_at(ptr, UInt(i)) {
                result.append(TreeNode(UnsafeRawPointer(childPtr), tree: tree))
            }
        }
        return result
    }

    /// Get a child at a specific index.
    public func child(at index: Int) -> TreeNode? {
        guard index >= 0, index < childCount else { return nil }
        guard let childPtr = resvg_group_child_at(ptr, UInt(index)) else {
            return nil
        }
        return TreeNode(UnsafeRawPointer(childPtr), tree: tree)
    }
}

// MARK: - BlendMode

/// SVG blend modes.
public enum BlendMode: UInt32, Sendable {
    case normal = 0
    case multiply = 1
    case screen = 2
    case overlay = 3
    case darken = 4
    case lighten = 5
    case colorDodge = 6
    case colorBurn = 7
    case hardLight = 8
    case softLight = 9
    case difference = 10
    case exclusion = 11
    case hue = 12
    case saturation = 13
    case color = 14
    case luminosity = 15
}

// MARK: - Mask

/// A mask applied to a group.
public struct Mask: @unchecked Sendable {
    let ptr: OpaquePointer
    let tree: SvgTree

    init(_ ptr: OpaquePointer, tree: SvgTree) {
        self.ptr = ptr
        self.tree = tree
    }

    /// The mask ID.
    public var id: String {
        var len: UInt = 0
        guard let idPtr = resvg_mask_id(ptr, &len), len > 0 else {
            return ""
        }
        return String(cString: idPtr)
    }

    /// The mask bounding rectangle.
    public var rect: Rect {
        Rect(resvg_mask_rect(ptr))
    }

    /// The mask type (luminance or alpha).
    public var kind: MaskType {
        MaskType(rawValue: resvg_mask_kind(ptr).rawValue) ?? .luminance
    }

    /// The root group containing the mask content.
    public var root: Group {
        let rootPtr = resvg_mask_root(ptr)!
        return Group(rootPtr, tree: tree)
    }

    /// A nested mask, if any.
    public var nestedMask: Mask? {
        guard let maskPtr = resvg_mask_mask(ptr) else {
            return nil
        }
        return Mask(maskPtr, tree: tree)
    }
}

/// Mask type.
public enum MaskType: UInt32, Sendable {
    case luminance = 0
    case alpha = 1
}

// MARK: - ClipPath

/// A clip path applied to a group.
public struct ClipPath: @unchecked Sendable {
    let ptr: OpaquePointer
    let tree: SvgTree

    init(_ ptr: OpaquePointer, tree: SvgTree) {
        self.ptr = ptr
        self.tree = tree
    }

    /// The clip path ID.
    public var id: String {
        var len: UInt = 0
        guard let idPtr = resvg_clip_path_id(ptr, &len), len > 0 else {
            return ""
        }
        return String(cString: idPtr)
    }

    /// The clip path transform.
    public var transform: Transform {
        Transform(resvg_clip_path_transform(ptr))
    }

    /// The root group containing the clip path content.
    public var root: Group {
        let rootPtr = resvg_clip_path_root(ptr)!
        return Group(rootPtr, tree: tree)
    }
}
