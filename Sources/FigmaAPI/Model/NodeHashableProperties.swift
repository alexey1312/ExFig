import Foundation

/// Hashable representation of a Figma node's visual properties.
///
/// Contains only the properties that affect visual output, used for
/// change detection via FNV-1a hashing. Properties like `boundVariables`
/// and `absoluteBoundingBox` are excluded as they don't affect rendered output.
///
/// Float values should be normalized to 6 decimal places before creating
/// this struct to handle Figma API precision drift.
public struct NodeHashableProperties: Encodable, Sendable {
    public let name: String
    public let type: String
    public let fills: [HashablePaint]
    public let strokes: [HashablePaint]?
    public let strokeWeight: Double?
    public let strokeAlign: String?
    public let strokeJoin: String?
    public let strokeCap: String?
    public let effects: [HashableEffect]?
    public let opacity: Double?
    public let blendMode: String?
    public let clipsContent: Bool?
    public let rotation: Double?
    public let children: [NodeHashableProperties]?

    public init(
        name: String,
        type: String,
        fills: [HashablePaint],
        strokes: [HashablePaint]?,
        strokeWeight: Double?,
        strokeAlign: String?,
        strokeJoin: String?,
        strokeCap: String?,
        effects: [HashableEffect]?,
        opacity: Double?,
        blendMode: String?,
        clipsContent: Bool?,
        rotation: Double?,
        children: [NodeHashableProperties]?
    ) {
        self.name = name
        self.type = type
        self.fills = fills
        self.strokes = strokes
        self.strokeWeight = strokeWeight
        self.strokeAlign = strokeAlign
        self.strokeJoin = strokeJoin
        self.strokeCap = strokeCap
        self.effects = effects
        self.opacity = opacity
        self.blendMode = blendMode
        self.clipsContent = clipsContent
        self.rotation = rotation
        self.children = children
    }
}

/// Hashable representation of a paint (fill or stroke).
public struct HashablePaint: Encodable, Sendable {
    public let type: String
    public let blendMode: String?
    public let color: HashableColor?
    public let opacity: Double?
    public let gradientStops: [HashableGradientStop]?

    public init(
        type: String,
        blendMode: String? = nil,
        color: HashableColor? = nil,
        opacity: Double? = nil,
        gradientStops: [HashableGradientStop]? = nil
    ) {
        self.type = type
        self.blendMode = blendMode
        self.color = color
        self.opacity = opacity
        self.gradientStops = gradientStops
    }
}

/// Hashable representation of a color.
/// Channel values should be normalized to 6 decimal places.
public struct HashableColor: Encodable, Sendable {
    // swiftlint:disable:next identifier_name
    public let r, g, b, a: Double

    public init(r: Double, g: Double, b: Double, a: Double) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
}

/// Hashable representation of a gradient stop.
public struct HashableGradientStop: Encodable, Sendable {
    public let color: HashableColor
    public let position: Double

    public init(color: HashableColor, position: Double) {
        self.color = color
        self.position = position
    }
}

/// Hashable representation of an effect (shadow, blur, etc.).
public struct HashableEffect: Encodable, Sendable {
    public let type: String
    public let radius: Double?
    public let spread: Double?
    public let offset: HashableVector?
    public let color: HashableColor?
    public let visible: Bool?

    public init(
        type: String,
        radius: Double? = nil,
        spread: Double? = nil,
        offset: HashableVector? = nil,
        color: HashableColor? = nil,
        visible: Bool? = nil
    ) {
        self.type = type
        self.radius = radius
        self.spread = spread
        self.offset = offset
        self.color = color
        self.visible = visible
    }
}

/// Hashable representation of a 2D vector.
public struct HashableVector: Encodable, Sendable {
    // swiftlint:disable:next identifier_name
    public let x, y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}
