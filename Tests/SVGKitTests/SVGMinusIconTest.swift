@testable import SVGKit
import Testing

@Suite("Minus Icon Regression Test")
struct SVGMinusIconTest {
    @Test("Convert minus.svg to VectorDrawable with correct group transform")
    func convertMinusSvgToVectorDrawable() throws {
        // This is the actual minus.svg from the iOS project
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect width="18" height="2" rx="1" transform="matrix(1 0 0 -1 3 13)" fill="#141414"/>
        </svg>
        """

        let parser = SVGParser()
        let parsed = try parser.parse(svg.data(using: .utf8)!, normalize: false)

        let generator = VectorDrawableXMLGenerator()
        let xml = generator.generate(from: parsed)

        print("Generated VectorDrawable XML:")
        print(xml)

        // Verify the group has the correct transform attributes
        #expect(xml.contains("<group"))
        #expect(xml.contains("translateX=\"3\""))
        #expect(xml.contains("translateY=\"13\""))
        #expect(xml.contains("scaleY=\"-1\""))
        // scaleX=1 and rotation=0 should NOT be output (they are defaults)
        #expect(!xml.contains("scaleX=\"1\""))
        #expect(!xml.contains("rotation=\"0\""))
        #expect(xml.contains("</group>"))
    }

    @Test("Convert closeOverlayColorL.svg with fillAlpha")
    func convertCloseOverlayWithFillAlpha() throws {
        // This is similar to closeOverlayColorL.svg with fill-opacity
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <circle cx="12" cy="12" r="10" fill="#141414" fill-opacity="0.5"/>
        <path d="M8 8L16 16M16 8L8 16" stroke="#FFFFFF" stroke-width="2"/>
        </svg>
        """

        let parser = SVGParser()
        let parsed = try parser.parse(svg.data(using: .utf8)!, normalize: false)

        let generator = VectorDrawableXMLGenerator()
        let xml = generator.generate(from: parsed)

        print("Generated VectorDrawable XML:")
        print(xml)

        // Verify fillAlpha is present
        #expect(xml.contains("fillAlpha=\"0.5\""))
    }
}
