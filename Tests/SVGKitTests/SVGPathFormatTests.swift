@testable import SVGKit
import Testing

@Suite("SVG Path Format Preservation Tests")
struct SVGPathFormatTests {
    @Test("Rect element converts to absolute path commands")
    func rectConvertsToAbsoluteCommands() throws {
        // This is how Figma exports the rounded rect border for flags
        let svg = """
        <svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
          <rect x="0" y="4" width="24" height="16" rx="2" ry="2" fill="#009F60"/>
        </svg>
        """

        let parser = SVGParser()
        let parsed = try parser.parse(#require(svg.data(using: .utf8)), normalize: false)

        #expect(parsed.paths.count == 1)
        let pathData = parsed.paths[0].pathData

        print("Rect converted to path: \(pathData)")

        // Should use absolute L and C commands, NOT relative h, v, a
        #expect(pathData.contains("L")) // Absolute line
        #expect(pathData.contains("C")) // Absolute cubic Bezier
        #expect(!pathData.contains("h")) // NO relative horizontal
        #expect(!pathData.contains("v")) // NO relative vertical
        #expect(!pathData.contains("a")) // NO relative arc
    }

    @Test("Simple rect converts to absolute L commands")
    func simpleRectConvertsToAbsoluteL() throws {
        let svg = """
        <svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
          <rect x="2" y="4" width="20" height="16" fill="#000000"/>
        </svg>
        """

        let parser = SVGParser()
        let parsed = try parser.parse(#require(svg.data(using: .utf8)), normalize: false)

        let pathData = parsed.paths[0].pathData
        print("Simple rect path: \(pathData)")

        // Should be M2,4L22,4L22,20L2,20Z (absolute commands)
        #expect(pathData.hasPrefix("M2,4"))
        #expect(pathData.contains("L22,4"))
        #expect(pathData.contains("L22,20"))
        #expect(pathData.contains("L2,20"))
        #expect(!pathData.contains("h")) // NO relative
        #expect(!pathData.contains("v")) // NO relative
    }

    @Test("Path data format is preserved without normalization")
    func pathDataPreservedWithoutNormalization() throws {
        // This is the exact path format from the dev branch Zambia flag
        // swiftlint:disable:next line_length
        let pathStr = "M2,4L22,4C23.105,4 24,4.895 24,6L24,18C24,19.105 23.105,20 22,20L2,20C0.895,20 0,19.105 0,18L0,6C0,4.895 0.895,4 2,4Z"
        let svg = """
        <svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
          <path d="\(pathStr)" fill="#009F60"/>
        </svg>
        """

        let parser = SVGParser()
        let parsed = try parser.parse(#require(svg.data(using: .utf8)), normalize: false)

        // The path data should be exactly preserved
        #expect(parsed.paths.count == 1)
        let pathData = parsed.paths[0].pathData

        print("Original: \(pathStr)")
        print("Parsed:   \(pathData)")

        // Check that it still uses absolute commands (L, C) not relative (l, c, h, a)
        #expect(pathData.contains("L22"))
        #expect(pathData.contains("C23"))
        #expect(!pathData.contains("h20")) // Should NOT have relative commands
        #expect(!pathData.contains("a2")) // Should NOT have arc commands
    }

    @Test("Path data format changes with normalization")
    func pathDataChangesWithNormalization() throws {
        // swiftlint:disable:next line_length
        let pathStr = "M2,4L22,4C23.105,4 24,4.895 24,6L24,18C24,19.105 23.105,20 22,20L2,20C0.895,20 0,19.105 0,18L0,6C0,4.895 0.895,4 2,4Z"
        let svg = """
        <svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
          <path d="\(pathStr)" fill="#009F60"/>
        </svg>
        """

        let parser = SVGParser()
        let parsed = try parser.parse(#require(svg.data(using: .utf8)), normalize: true)

        print("Normalized path: \(parsed.paths.first?.pathData ?? "none")")

        // Just verify it parses - the format may be different after normalization
        #expect(parsed.paths.count == 1)
    }

    @Test("VectorDrawable output preserves path data format")
    func vectorDrawablePreservesPathFormat() throws {
        let svg = """
        <svg viewBox="0 0 24 24" width="24" height="24" xmlns="http://www.w3.org/2000/svg">
          <path d="M2,4L22,4C23.105,4 24,4.895 24,6" fill="#009F60"/>
        </svg>
        """

        let parser = SVGParser()
        let parsed = try parser.parse(#require(svg.data(using: .utf8)), normalize: false)

        let generator = VectorDrawableXMLGenerator()
        let xml = generator.generate(from: parsed)

        print("Generated XML:")
        print(xml)

        // The output should contain the original path format
        #expect(xml.contains("M2,4L22,4C23.105,4 24,4.895 24,6"))
    }
}
