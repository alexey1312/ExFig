@testable import Resvg
import XCTest

final class SvgRasterizerTests: XCTestCase {
    func testRasterizeSimpleSVG() throws {
        // Simple red circle SVG
        let svgString = """
        <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
          <circle cx="50" cy="50" r="40" fill="red"/>
        </svg>
        """

        let svgData = Data(svgString.utf8)
        let rasterizer = SvgRasterizer()

        let result = try rasterizer.rasterize(data: svgData, scale: 1.0)

        XCTAssertEqual(result.width, 100)
        XCTAssertEqual(result.height, 100)
        XCTAssertEqual(result.rgba.count, 100 * 100 * 4)
    }

    func testRasterizeWithScale() throws {
        let svgString = """
        <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
          <rect width="100" height="100" fill="blue"/>
        </svg>
        """

        let svgData = Data(svgString.utf8)
        let rasterizer = SvgRasterizer()

        let result = try rasterizer.rasterize(data: svgData, scale: 2.0)

        XCTAssertEqual(result.width, 200)
        XCTAssertEqual(result.height, 200)
        XCTAssertEqual(result.rgba.count, 200 * 200 * 4)
    }

    func testRasterizeZeroSizeImage() throws {
        // An SVG with zero dimensions
        let svgString = """
        <svg width="0" height="0" xmlns="http://www.w3.org/2000/svg">
        </svg>
        """

        let svgData = Data(svgString.utf8)
        let rasterizer = SvgRasterizer()

        XCTAssertThrowsError(try rasterizer.rasterize(data: svgData, scale: 1.0)) { error in
            guard let resvgError = error as? ResvgError else {
                XCTFail("Expected ResvgError")
                return
            }
            XCTAssertEqual(resvgError, .invalidSize)
        }
    }

    func testRasterizeInvalidSVG() throws {
        let invalidData = Data("not an svg".utf8)
        let rasterizer = SvgRasterizer()

        XCTAssertThrowsError(try rasterizer.rasterize(data: invalidData, scale: 1.0)) { error in
            guard let resvgError = error as? ResvgError else {
                XCTFail("Expected ResvgError")
                return
            }
            XCTAssertEqual(resvgError, .parsingFailed)
        }
    }

    func testRasterizePreservesTransparency() throws {
        // SVG with transparent background
        let svgString = """
        <svg width="10" height="10" xmlns="http://www.w3.org/2000/svg">
          <circle cx="5" cy="5" r="3" fill="green"/>
        </svg>
        """

        let svgData = Data(svgString.utf8)
        let rasterizer = SvgRasterizer()

        let result = try rasterizer.rasterize(data: svgData, scale: 1.0)

        // Check corner pixels are transparent (alpha = 0)
        // Corner is at (0,0), index 0 in RGBA
        XCTAssertEqual(result.rgba[3], 0, "Corner pixel should be transparent")
    }
}
