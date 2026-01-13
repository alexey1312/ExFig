@testable import SVGKit
import Testing

@Suite("SVG Shape Transform Tests")
struct SVGShapeTransformTests {
    @Test("Rect with transform produces group wrapper")
    func rectWithTransformProducesGroup() throws {
        let svg = """
        <svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
          <rect x="0" y="0" width="18" height="2" rx="1" fill="#1A1919" transform="matrix(1 0 0 -1 3 13)"/>
        </svg>
        """

        let parser = SVGParser()
        let parsed = try parser.parse(svg.data(using: .utf8)!, normalize: false)

        // Should have an element which is a group
        #expect(!parsed.elements.isEmpty)

        if case let .group(group) = parsed.elements.first {
            // Group should have transform
            #expect(group.transform != nil)
            #expect(group.transform?.translateX == 3)
            #expect(group.transform?.translateY == 13)
            #expect(group.transform?.scaleY == -1)

            // Group should contain the path
            #expect(!group.paths.isEmpty)
        } else {
            Issue.record("Expected a group element but got \(String(describing: parsed.elements.first))")
        }
    }

    @Test("Circle with translate transform")
    func circleWithTranslateTransform() throws {
        let svg = """
        <svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
          <circle cx="5" cy="5" r="5" fill="#FF0000" transform="translate(10, 10)"/>
        </svg>
        """

        let parser = SVGParser()
        let parsed = try parser.parse(svg.data(using: .utf8)!, normalize: false)

        #expect(!parsed.elements.isEmpty)

        if case let .group(group) = parsed.elements.first {
            #expect(group.transform?.translateX == 10)
            #expect(group.transform?.translateY == 10)
        } else {
            Issue.record("Expected a group element")
        }
    }

    @Test("Shape without transform remains as path")
    func shapeWithoutTransformRemainsPath() throws {
        let svg = """
        <svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
          <rect x="0" y="0" width="24" height="24" fill="#000000"/>
        </svg>
        """

        let parser = SVGParser()
        let parsed = try parser.parse(svg.data(using: .utf8)!, normalize: false)

        // Without transform, it should be a direct path
        #expect(parsed.paths.count == 1)
        #expect(parsed.elements.isEmpty || parsed.elements.allSatisfy {
            if case .path = $0 { return true }
            return false
        })
    }

    @Test("Generate VectorDrawable with group from transformed rect")
    func generateVectorDrawableWithGroupFromTransform() throws {
        let svg = """
        <svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
          <rect x="0" y="0" width="18" height="2" rx="1" fill="#1A1919" transform="matrix(1 0 0 -1 3 13)"/>
        </svg>
        """

        let parser = SVGParser()
        let parsed = try parser.parse(svg.data(using: .utf8)!, normalize: false)

        let generator = VectorDrawableXMLGenerator()
        let xml = generator.generate(from: parsed)

        // Should contain group with translate and scale
        #expect(xml.contains("<group"))
        #expect(xml.contains("translateX=\"3\""))
        #expect(xml.contains("translateY=\"13\""))
        #expect(xml.contains("scaleY=\"-1\""))
    }

    @Test("Nested group with transformed shape")
    func nestedGroupWithTransformedShape() throws {
        let svg = """
        <svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
          <g>
            <rect x="0" y="0" width="10" height="10" fill="#FF0000" transform="scale(2)"/>
          </g>
        </svg>
        """

        let parser = SVGParser()
        let parsed = try parser.parse(svg.data(using: .utf8)!, normalize: false)

        // Should have nested group structure
        #expect(parsed.groups?.count == 1)

        let outerGroup = parsed.groups?.first
        #expect(outerGroup?.elements.count == 1)

        // The inner element should be a group (due to transform on rect)
        if case let .group(innerGroup) = outerGroup?.elements.first {
            #expect(innerGroup.transform?.scaleX == 2)
            #expect(innerGroup.transform?.scaleY == 2)
        } else {
            Issue.record("Expected inner group from transformed rect")
        }
    }
}
