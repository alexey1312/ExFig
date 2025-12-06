@testable import FigmaAPI
import Foundation
import XCTest

final class LineHeightUnitTests: XCTestCase {
    func testPixelsRawValue() {
        XCTAssertEqual(LineHeightUnit.pixels.rawValue, "PIXELS")
    }

    func testFontSizeRawValue() {
        XCTAssertEqual(LineHeightUnit.fontSize.rawValue, "FONT_SIZE_%")
    }

    func testIntrinsicRawValue() {
        XCTAssertEqual(LineHeightUnit.intrinsic.rawValue, "INTRINSIC_%")
    }

    func testDecoding() throws {
        let json = "\"PIXELS\""
        let unit = try JSONDecoder().decode(LineHeightUnit.self, from: Data(json.utf8))
        XCTAssertEqual(unit, .pixels)
    }
}

final class TextCaseNodeTests: XCTestCase {
    func testRawValues() {
        XCTAssertEqual(TextCase.original.rawValue, "ORIGINAL")
        XCTAssertEqual(TextCase.upper.rawValue, "UPPER")
        XCTAssertEqual(TextCase.lower.rawValue, "LOWER")
        XCTAssertEqual(TextCase.title.rawValue, "TITLE")
        XCTAssertEqual(TextCase.smallCaps.rawValue, "SMALL_CAPS")
        XCTAssertEqual(TextCase.smallCapsForced.rawValue, "SMALL_CAPS_FORCED")
    }

    func testDecoding() throws {
        let json = "\"UPPER\""
        let textCase = try JSONDecoder().decode(TextCase.self, from: Data(json.utf8))
        XCTAssertEqual(textCase, .upper)
    }
}

final class PaintTypeTests: XCTestCase {
    func testRawValues() {
        XCTAssertEqual(PaintType.solid.rawValue, "SOLID")
        XCTAssertEqual(PaintType.image.rawValue, "IMAGE")
        XCTAssertEqual(PaintType.rectangle.rawValue, "RECTANGLE")
        XCTAssertEqual(PaintType.gradientLinear.rawValue, "GRADIENT_LINEAR")
        XCTAssertEqual(PaintType.gradientRadial.rawValue, "GRADIENT_RADIAL")
        XCTAssertEqual(PaintType.gradientAngular.rawValue, "GRADIENT_ANGULAR")
        XCTAssertEqual(PaintType.gradientDiamond.rawValue, "GRADIENT_DIAMOND")
    }
}

final class PaintColorTests: XCTestCase {
    func testDecoding() throws {
        let json = """
        {"r": 1.0, "g": 0.5, "b": 0.25, "a": 0.8}
        """

        let color = try JSONDecoder().decode(PaintColor.self, from: Data(json.utf8))

        XCTAssertEqual(color.r, 1.0)
        XCTAssertEqual(color.g, 0.5)
        XCTAssertEqual(color.b, 0.25)
        XCTAssertEqual(color.a, 0.8)
    }
}

final class PaintTests: XCTestCase {
    func testDecodingSolidPaint() throws {
        let json = """
        {
            "type": "SOLID",
            "opacity": 0.9,
            "color": {"r": 1.0, "g": 0.0, "b": 0.0, "a": 1.0}
        }
        """

        let paint = try JSONDecoder().decode(Paint.self, from: Data(json.utf8))

        XCTAssertEqual(paint.type, .solid)
        XCTAssertEqual(paint.opacity, 0.9)
        XCTAssertNotNil(paint.color)
    }

    func testDecodingGradientPaint() throws {
        let json = """
        {
            "type": "GRADIENT_LINEAR",
            "opacity": 1.0
        }
        """

        let paint = try JSONDecoder().decode(Paint.self, from: Data(json.utf8))

        XCTAssertEqual(paint.type, .gradientLinear)
        XCTAssertNil(paint.color)
    }

    func testAsSolidWithSolidPaint() throws {
        let json = """
        {
            "type": "SOLID",
            "opacity": 0.5,
            "color": {"r": 0.0, "g": 1.0, "b": 0.0, "a": 1.0}
        }
        """

        let paint = try JSONDecoder().decode(Paint.self, from: Data(json.utf8))
        let solid = paint.asSolid

        XCTAssertNotNil(solid)
        XCTAssertEqual(solid?.opacity, 0.5)
        XCTAssertEqual(solid?.color.g, 1.0)
    }

    func testAsSolidWithNonSolidPaint() throws {
        let json = """
        {
            "type": "IMAGE"
        }
        """

        let paint = try JSONDecoder().decode(Paint.self, from: Data(json.utf8))

        XCTAssertNil(paint.asSolid)
    }

    func testAsSolidWithMissingColor() throws {
        let json = """
        {
            "type": "SOLID"
        }
        """

        let paint = try JSONDecoder().decode(Paint.self, from: Data(json.utf8))

        XCTAssertNil(paint.asSolid)
    }
}

final class TypeStyleTests: XCTestCase {
    func testDecoding() throws {
        let json = """
        {
            "fontFamily": "Roboto",
            "fontPostScriptName": "Roboto-Bold",
            "fontWeight": 700,
            "fontSize": 16,
            "lineHeightPx": 24,
            "letterSpacing": 0.5,
            "lineHeightUnit": "PIXELS",
            "textCase": "UPPER"
        }
        """

        let style = try JSONDecoder().decode(TypeStyle.self, from: Data(json.utf8))

        XCTAssertEqual(style.fontFamily, "Roboto")
        XCTAssertEqual(style.fontPostScriptName, "Roboto-Bold")
        XCTAssertEqual(style.fontWeight, 700)
        XCTAssertEqual(style.fontSize, 16)
        XCTAssertEqual(style.lineHeightPx, 24)
        XCTAssertEqual(style.letterSpacing, 0.5)
        XCTAssertEqual(style.lineHeightUnit, .pixels)
        XCTAssertEqual(style.textCase, .upper)
    }

    func testDecodingWithNilOptionals() throws {
        let json = """
        {
            "fontWeight": 400,
            "fontSize": 14,
            "lineHeightPx": 20,
            "letterSpacing": 0,
            "lineHeightUnit": "FONT_SIZE_%"
        }
        """

        let style = try JSONDecoder().decode(TypeStyle.self, from: Data(json.utf8))

        XCTAssertNil(style.fontFamily)
        XCTAssertNil(style.fontPostScriptName)
        XCTAssertNil(style.textCase)
    }
}

final class DocumentTests: XCTestCase {
    func testDecoding() throws {
        let json = """
        {
            "id": "123:456",
            "name": "Primary Color",
            "fills": [
                {
                    "type": "SOLID",
                    "color": {"r": 0.2, "g": 0.4, "b": 0.8, "a": 1.0}
                }
            ]
        }
        """

        let document = try JSONDecoder().decode(Document.self, from: Data(json.utf8))

        XCTAssertEqual(document.id, "123:456")
        XCTAssertEqual(document.name, "Primary Color")
        XCTAssertEqual(document.fills.count, 1)
        XCTAssertNil(document.style)
    }

    func testDecodingWithStyle() throws {
        let json = """
        {
            "id": "789:012",
            "name": "Heading",
            "fills": [],
            "style": {
                "fontFamily": "Inter",
                "fontWeight": 600,
                "fontSize": 24,
                "lineHeightPx": 32,
                "letterSpacing": -0.5,
                "lineHeightUnit": "PIXELS"
            }
        }
        """

        let document = try JSONDecoder().decode(Document.self, from: Data(json.utf8))

        XCTAssertNotNil(document.style)
        XCTAssertEqual(document.style?.fontFamily, "Inter")
    }
}

final class NodeResponseTests: XCTestCase {
    func testDecoding() throws {
        let json = """
        {
            "nodes": {
                "123:0": {
                    "document": {
                        "id": "123:0",
                        "name": "Test",
                        "fills": []
                    }
                }
            }
        }
        """

        let response = try JSONDecoder().decode(NodesResponse.self, from: Data(json.utf8))

        XCTAssertEqual(response.nodes.count, 1)
        XCTAssertNotNil(response.nodes["123:0"])
        XCTAssertEqual(response.nodes["123:0"]?.document.name, "Test")
    }
}
