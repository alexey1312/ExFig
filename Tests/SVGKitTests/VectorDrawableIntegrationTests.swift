import Foundation
@testable import SVGKit
import XCTest

/// Integration tests comparing native VectorDrawableXMLGenerator output with expected format
final class VectorDrawableIntegrationTests: XCTestCase {
    var parser: SVGParser!
    var generator: VectorDrawableXMLGenerator!

    override func setUp() {
        super.setUp()
        parser = SVGParser()
        generator = VectorDrawableXMLGenerator()
    }

    override func tearDown() {
        parser = nil
        generator = nil
        super.tearDown()
    }

    // MARK: - Real Icon Tests

    // swiftlint:disable:next function_body_length
    func testGenerateDotsIcon() throws {
        // swiftlint:disable:next line_length
        let pathData = "M6 10C7.10457 10 8 10.8954 8 12C8 13.1046 7.10457 14 6 14C4.89543 14 4 13.1046 4 12C4 10.8954 4.89543 10 6 10ZM12 10C13.1046 10 14 10.8954 14 12C14 13.1046 13.1046 14 12 14C10.8954 14 10 13.1046 10 12C10 10.8954 10.8954 10 12 10ZM20 12C20 10.8954 19.1046 10 18 10C16.8954 10 16 10.8954 16 12C16 13.1046 16.8954 14 18 14C19.1046 14 20 13.1046 20 12Z"
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path fill-rule="evenodd" clip-rule="evenodd" d="\(pathData)" fill="black"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: false)
        let xml = generator.generate(from: parsed)

        // Verify structure
        XCTAssertTrue(xml.contains("<?xml version=\"1.0\" encoding=\"utf-8\"?>"))
        XCTAssertTrue(xml.contains("<vector"))
        XCTAssertTrue(xml.contains("xmlns:android=\"http://schemas.android.com/apk/res/android\""))
        XCTAssertTrue(xml.contains("android:width=\"24dp\""))
        XCTAssertTrue(xml.contains("android:height=\"24dp\""))
        XCTAssertTrue(xml.contains("android:viewportWidth=\"24\""))
        XCTAssertTrue(xml.contains("android:viewportHeight=\"24\""))
        XCTAssertTrue(xml.contains("<path"))
        XCTAssertTrue(xml.contains("android:fillType=\"evenOdd\""))
        XCTAssertTrue(xml.contains("android:fillColor=\"#000000\""))
        XCTAssertTrue(xml.contains("</vector>"))
    }

    func testGenerateArrowIcon() throws {
        // swiftlint:disable:next line_length
        let pathData = "M6.4142 13L12.9981 19.5839L11.5839 20.9981L3.2929 12.7071C2.9024 12.3166 2.9024 11.6834 3.2929 11.2929L11.5839 3.0019L12.9981 4.4161L6.4142 11H21V13H6.4142Z"
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path fill-rule="evenodd" clip-rule="evenodd" d="\(pathData)" fill="black"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: false)
        let xml = generator.generate(from: parsed)

        XCTAssertTrue(xml.contains("android:pathData=\"M6.4142 13L12.9981 19.5839"))
        XCTAssertTrue(xml.contains("android:fillColor=\"#000000\""))
        XCTAssertTrue(xml.contains("android:fillType=\"evenOdd\""))
    }

    func testGenerateIconWithStroke() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
        <path d="M12 4L12 20" stroke="#FF0000" stroke-width="2" stroke-linecap="round"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: false)
        let xml = generator.generate(from: parsed)

        XCTAssertTrue(xml.contains("android:strokeColor=\"#FF0000\""))
        XCTAssertTrue(xml.contains("android:strokeWidth=\"2\""))
        XCTAssertTrue(xml.contains("android:strokeLineCap=\"round\""))
    }

    func testGenerateIconWithGroup() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
        <g transform="translate(2, 2)">
            <path d="M0 0L20 20" fill="#0000FF"/>
        </g>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: false)
        let xml = generator.generate(from: parsed)

        XCTAssertTrue(xml.contains("<group"))
        XCTAssertTrue(xml.contains("android:translateX=\"2\""))
        XCTAssertTrue(xml.contains("android:translateY=\"2\""))
        XCTAssertTrue(xml.contains("</group>"))
    }

    func testGenerateIconWithAutoMirrored() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
        <path d="M4 12L20 12" fill="#000000"/>
        </svg>
        """

        let generatorWithMirror = VectorDrawableXMLGenerator(autoMirrored: true)
        let parsed = try parser.parse(Data(svg.utf8), normalize: false)
        let xml = generatorWithMirror.generate(from: parsed)

        XCTAssertTrue(xml.contains("android:autoMirrored=\"true\""))
    }

    func testGenerateIconWithClipPath() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
        <defs>
            <clipPath id="clip0">
                <path d="M0 0L24 0L24 24L0 24Z"/>
            </clipPath>
        </defs>
        <g clip-path="url(#clip0)">
            <path d="M12 4L12 20" fill="#000000"/>
        </g>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: false)
        let xml = generator.generate(from: parsed)

        XCTAssertTrue(xml.contains("<clip-path"))
        XCTAssertTrue(xml.contains("android:pathData=\"M0 0L24 0L24 24L0 24Z\""))
    }

    func testGenerateIconWithColorAlpha() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
        <path d="M0 0L24 24" fill="rgba(255, 0, 0, 0.5)"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: false)
        let xml = generator.generate(from: parsed)

        // Alpha 0.5 = 127 (0x7F)
        XCTAssertTrue(xml.contains("#7FFF0000") || xml.contains("#80FF0000"))
    }

    // MARK: - XML Validity Tests

    func testGeneratedXMLIsWellFormed() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
        <g transform="translate(5, 5)">
            <g transform="scale(0.8)">
                <path d="M0 0L10 10" fill="#FF0000"/>
            </g>
        </g>
        <path d="M20 20L24 24" fill="#00FF00"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: false)
        let xml = generator.generate(from: parsed)

        // Verify XML is well-formed by parsing it
        // XMLDocument is not available on Linux, so we do basic structure validation there
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            XCTAssertNoThrow(try XMLDocument(xmlString: xml, options: []))
        #else
            // On Linux, just verify basic structure
            XCTAssertTrue(xml.hasPrefix("<?xml"))
            XCTAssertTrue(xml.contains("<vector"))
            XCTAssertTrue(xml.contains("</vector>"))
        #endif
    }

    func testGeneratedXMLHasCorrectIndentation() throws {
        let svg = """
        <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
        <path d="M0 0L24 24" fill="#000000"/>
        </svg>
        """

        let parsed = try parser.parse(Data(svg.utf8), normalize: false)
        let xml = generator.generate(from: parsed)

        // Check indentation (4 spaces)
        XCTAssertTrue(xml.contains("    xmlns:android="))
        XCTAssertTrue(xml.contains("    <path"))
        XCTAssertTrue(xml.contains("        android:pathData="))
    }
}
