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
}

public struct Node: Decodable, Sendable {
    public let document: Document
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
    public let fills: [Paint]
    public let style: TypeStyle?
}

// https://www.figma.com/plugin-docs/api/Paint/
public struct Paint: Decodable, Sendable {
    public let type: PaintType
    public let opacity: Double?
    public let color: PaintColor?

    public var asSolid: SolidPaint? {
        SolidPaint(self)
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
}
