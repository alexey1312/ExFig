@testable import SVGKit
import Testing

@Suite("SVG Fill Opacity Tests")
struct SVGFillOpacityTests {
    @Test("Parse fill-opacity from circle element")
    func parseFillOpacityFromCircle() throws {
        let svg = """
        <svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
          <circle cx="12" cy="12" r="10" fill="#141414" fill-opacity="0.5"/>
        </svg>
        """

        let parser = SVGParser()
        let parsed = try parser.parse(svg.data(using: .utf8)!, normalize: false)

        #expect(parsed.paths.count == 1)
        #expect(parsed.paths[0].fillOpacity == 0.5)
    }

    @Test("Parse fill-opacity from path element")
    func parseFillOpacityFromPath() throws {
        let svg = """
        <svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
          <path d="M0 0h24v24H0z" fill="#000000" fill-opacity="0.3"/>
        </svg>
        """

        let parser = SVGParser()
        let parsed = try parser.parse(svg.data(using: .utf8)!, normalize: false)

        #expect(parsed.paths.count == 1)
        #expect(parsed.paths[0].fillOpacity == 0.3)
    }

    @Test("Generate VectorDrawable with fillAlpha from fillOpacity")
    func generateVectorDrawableWithFillAlpha() throws {
        let svg = """
        <svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
          <circle cx="12" cy="12" r="10" fill="#141414" fill-opacity="0.5"/>
        </svg>
        """

        let parser = SVGParser()
        let parsed = try parser.parse(svg.data(using: .utf8)!, normalize: false)

        let generator = VectorDrawableXMLGenerator()
        let xml = generator.generate(from: parsed)

        #expect(xml.contains("fillAlpha=\"0.5\""))
    }

    @Test("Generate ImageVector with fillAlpha from fillOpacity")
    func generateImageVectorWithFillAlpha() throws {
        let svg = """
        <svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
          <circle cx="12" cy="12" r="10" fill="#141414" fill-opacity="0.5"/>
        </svg>
        """

        let parser = SVGParser()
        let parsed = try parser.parse(svg.data(using: .utf8)!, normalize: false)

        let config = ImageVectorGenerator.Config(packageName: "com.test", generatePreview: false)
        let generator = ImageVectorGenerator(config: config)
        let kotlin = generator.generate(name: "test", svg: parsed)

        #expect(kotlin.contains("fillAlpha = 0.5f"))
    }

    @Test("Fill opacity does not affect stroke-only paths")
    func fillOpacityStrokeOnlyPath() throws {
        let svg = """
        <svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
          <path d="M8 8L16 16" stroke="#FFFFFF" stroke-width="2" fill="none" fill-opacity="0.5"/>
        </svg>
        """

        let parser = SVGParser()
        let parsed = try parser.parse(svg.data(using: .utf8)!, normalize: false)

        // Path with fill="none" should still parse fill-opacity
        #expect(parsed.paths[0].fillOpacity == 0.5)
    }

    @Test("Inherit fill-opacity from parent group")
    func inheritFillOpacityFromGroup() throws {
        let svg = """
        <svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
          <g fill-opacity="0.7">
            <circle cx="12" cy="12" r="10" fill="#141414"/>
          </g>
        </svg>
        """

        let parser = SVGParser()
        let parsed = try parser.parse(svg.data(using: .utf8)!, normalize: false)

        // Check that the circle inherits fill-opacity from the group
        #expect(parsed.groups?.first?.paths.first?.fillOpacity == 0.7)
    }
}
