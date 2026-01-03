//
//  Node.swift
//  FigmaColorExporter
//
//  Created by Daniil Subbotin on 28.03.2020.
//  Copyright © 2020 Daniil Subbotin. All rights reserved.
//

public typealias NodeId = String

public struct NodesResponse: Decodable, Sendable {
    public let nodes: [NodeId: Node]

    enum CodingKeys: String, CodingKey {
        case nodes
    }
}

public struct Node: Decodable, Sendable {
    public let document: Document

    enum CodingKeys: String, CodingKey {
        case document
    }
}

public enum LineHeightUnit: String, Decodable, Sendable {
    case pixels = "PIXELS"
    case fontSize = "FONT_SIZE_%"
    case intrinsic = "INTRINSIC_%"
}

public struct TypeStyle: Decodable, Sendable {
    public var fontFamily: String?
    public var fontPostScriptName: String?
    public var fontWeight: Double
    public var fontSize: Double
    public var lineHeightPx: Double
    public var letterSpacing: Double
    public var lineHeightUnit: LineHeightUnit
    public var textCase: TextCase?

    enum CodingKeys: String, CodingKey {
        case fontFamily = "font_family"
        case fontPostScriptName = "font_post_script_name"
        case fontWeight = "font_weight"
        case fontSize = "font_size"
        case lineHeightPx = "line_height_px"
        case letterSpacing = "letter_spacing"
        case lineHeightUnit = "line_height_unit"
        case textCase = "text_case"
    }
}

public enum TextCase: String, Decodable, Sendable {
    case original = "ORIGINAL"
    case upper = "UPPER"
    case lower = "LOWER"
    case title = "TITLE"
    case smallCaps = "SMALL_CAPS"
    case smallCapsForced = "SMALL_CAPS_FORCED"
}

public struct Document: Decodable, Sendable {
    public let id: String
    public let name: String
    public let type: String?
    public let fills: [Paint]
    public let strokes: [Paint]?
    public let strokeWeight: Double?
    public let strokeAlign: StrokeAlign?
    public let strokeJoin: StrokeJoin?
    public let strokeCap: StrokeCap?
    public let effects: [Effect]?
    public let opacity: Double?
    public let blendMode: BlendMode?
    public let clipsContent: Bool?
    public let rotation: Double?
    public let children: [Document]?
    public let style: TypeStyle?

    enum CodingKeys: String, CodingKey {
        case id, name, type, fills, strokes, effects, opacity, rotation, children, style
        case strokeWeight = "stroke_weight"
        case strokeAlign = "stroke_align"
        case strokeJoin = "stroke_join"
        case strokeCap = "stroke_cap"
        case blendMode = "blend_mode"
        case clipsContent = "clips_content"
    }
}

// MARK: - Stroke Enums

public enum StrokeAlign: String, Decodable, Sendable {
    case inside = "INSIDE"
    case outside = "OUTSIDE"
    case center = "CENTER"
}

public enum StrokeJoin: String, Decodable, Sendable {
    case miter = "MITER"
    case bevel = "BEVEL"
    case round = "ROUND"
}

public enum StrokeCap: String, Decodable, Sendable {
    case none = "NONE"
    case round = "ROUND"
    case square = "SQUARE"
    case lineArrow = "LINE_ARROW"
    case triangleArrow = "TRIANGLE_ARROW"
}

// MARK: - Effect

public struct Effect: Decodable, Sendable {
    public let type: EffectType
    public let visible: Bool?
    public let radius: Double?
    public let color: PaintColor?
    public let offset: Vector?
    public let spread: Double?
    public let blendMode: BlendMode?

    enum CodingKeys: String, CodingKey {
        case type, visible, radius, color, offset, spread
        case blendMode = "blend_mode"
    }
}

public enum EffectType: String, Decodable, Sendable {
    case innerShadow = "INNER_SHADOW"
    case dropShadow = "DROP_SHADOW"
    case layerBlur = "LAYER_BLUR"
    case backgroundBlur = "BACKGROUND_BLUR"
}

// MARK: - Vector

public struct Vector: Decodable, Sendable {
    // swiftlint:disable:next identifier_name
    public let x, y: Double

    enum CodingKeys: String, CodingKey {
        case x, y
    }
}

// MARK: - Blend Mode

public enum BlendMode: String, Decodable, Sendable {
    case passThrough = "PASS_THROUGH"
    case normal = "NORMAL"
    case darken = "DARKEN"
    case multiply = "MULTIPLY"
    case linearBurn = "LINEAR_BURN"
    case colorBurn = "COLOR_BURN"
    case lighten = "LIGHTEN"
    case screen = "SCREEN"
    case linearDodge = "LINEAR_DODGE"
    case colorDodge = "COLOR_DODGE"
    case overlay = "OVERLAY"
    case softLight = "SOFT_LIGHT"
    case hardLight = "HARD_LIGHT"
    case difference = "DIFFERENCE"
    case exclusion = "EXCLUSION"
    case hue = "HUE"
    case saturation = "SATURATION"
    case color = "COLOR"
    case luminosity = "LUMINOSITY"
}

// https://www.figma.com/plugin-docs/api/Paint/
public struct Paint: Decodable, Sendable {
    public let type: PaintType
    public let blendMode: BlendMode?
    public let opacity: Double?
    public let visible: Bool?
    public let color: PaintColor?
    public let gradientStops: [GradientStop]?

    enum CodingKeys: String, CodingKey {
        case type, visible, opacity, color
        case blendMode = "blend_mode"
        case gradientStops = "gradient_stops"
    }

    public var asSolid: SolidPaint? {
        SolidPaint(self)
    }
}

// MARK: - Gradient Stop

public struct GradientStop: Decodable, Sendable {
    public let position: Double
    public let color: PaintColor

    enum CodingKeys: String, CodingKey {
        case position, color
    }
}

public enum PaintType: String, Decodable, Sendable {
    case solid = "SOLID"
    case image = "IMAGE"
    case rectangle = "RECTANGLE"
    case gradientLinear = "GRADIENT_LINEAR"
    case gradientRadial = "GRADIENT_RADIAL"
    case gradientAngular = "GRADIENT_ANGULAR"
    case gradientDiamond = "GRADIENT_DIAMOND"
}

public struct SolidPaint: Decodable, Sendable {
    public let opacity: Double?
    public let color: PaintColor

    public init?(_ paint: Paint) {
        guard paint.type == .solid else { return nil }
        guard let color = paint.color else { return nil }
        opacity = paint.opacity
        self.color = color
    }
}

public struct PaintColor: Codable, Sendable {
    // swiftlint:disable:next identifier_name
    /// Channel value, between 0 and 1
    public let r, g, b, a: Double

    enum CodingKeys: String, CodingKey {
        case r, g, b, a
    }
}

// MARK: - Document → NodeHashableProperties Conversion

public extension Document {
    /// Converts the document to a hashable properties struct for change detection.
    /// Float values are normalized to 6 decimal places to handle Figma API precision drift.
    /// Children are sorted by name for stable hashing regardless of Figma API order.
    func toHashableProperties() -> NodeHashableProperties {
        // Sort children by name for stable hash (Figma API may return in different order)
        let sortedChildren = children?
            .map { $0.toHashableProperties() }
            .sorted { $0.name < $1.name }

        return NodeHashableProperties(
            name: name,
            type: type ?? "UNKNOWN",
            fills: fills.map { $0.toHashablePaint() },
            strokes: strokes?.map { $0.toHashablePaint() },
            strokeWeight: strokeWeight?.normalized,
            strokeAlign: strokeAlign?.rawValue,
            strokeJoin: strokeJoin?.rawValue,
            strokeCap: strokeCap?.rawValue,
            effects: effects?.map { $0.toHashableEffect() },
            opacity: opacity?.normalized,
            blendMode: blendMode?.rawValue,
            clipsContent: clipsContent,
            rotation: rotation?.normalized,
            children: sortedChildren
        )
    }
}

public extension Paint {
    /// Converts the paint to a hashable paint struct.
    func toHashablePaint() -> HashablePaint {
        HashablePaint(
            type: type.rawValue,
            blendMode: blendMode?.rawValue,
            color: color?.toHashableColor(),
            opacity: opacity?.normalized,
            gradientStops: gradientStops?.map { $0.toHashableGradientStop() }
        )
    }
}

public extension PaintColor {
    /// Converts the color to a hashable color struct with normalized values.
    func toHashableColor() -> HashableColor {
        HashableColor(
            r: r.normalized,
            g: g.normalized,
            b: b.normalized,
            a: a.normalized
        )
    }
}

public extension GradientStop {
    /// Converts the gradient stop to a hashable gradient stop struct.
    func toHashableGradientStop() -> HashableGradientStop {
        HashableGradientStop(
            color: color.toHashableColor(),
            position: position.normalized
        )
    }
}

public extension Effect {
    /// Converts the effect to a hashable effect struct.
    func toHashableEffect() -> HashableEffect {
        HashableEffect(
            type: type.rawValue,
            radius: radius?.normalized,
            spread: spread?.normalized,
            offset: offset?.toHashableVector(),
            color: color?.toHashableColor(),
            visible: visible
        )
    }
}

public extension Vector {
    /// Converts the vector to a hashable vector struct.
    func toHashableVector() -> HashableVector {
        HashableVector(
            x: x.normalized,
            y: y.normalized
        )
    }
}
