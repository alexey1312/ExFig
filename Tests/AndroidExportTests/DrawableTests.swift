@testable import AndroidExport
import XCTest

final class DrawableTests: XCTestCase {
    // MARK: - Single Scale Tests

    func testSingleScaleLightMode() {
        let name = Drawable.scaleToDrawableName(1, dark: false, singleScale: true)

        XCTAssertEqual(name, "drawable")
    }

    func testSingleScaleDarkMode() {
        let name = Drawable.scaleToDrawableName(1, dark: true, singleScale: true)

        XCTAssertEqual(name, "drawable-night")
    }

    // MARK: - Multi Scale Light Mode Tests

    func testScale1LightMode() {
        let name = Drawable.scaleToDrawableName(1, dark: false, singleScale: false)

        XCTAssertEqual(name, "drawable-mdpi")
    }

    func testScale1_5LightMode() {
        let name = Drawable.scaleToDrawableName(1.5, dark: false, singleScale: false)

        XCTAssertEqual(name, "drawable-hdpi")
    }

    func testScale2LightMode() {
        let name = Drawable.scaleToDrawableName(2, dark: false, singleScale: false)

        XCTAssertEqual(name, "drawable-xhdpi")
    }

    func testScale3LightMode() {
        let name = Drawable.scaleToDrawableName(3, dark: false, singleScale: false)

        XCTAssertEqual(name, "drawable-xxhdpi")
    }

    func testScale4LightMode() {
        let name = Drawable.scaleToDrawableName(4, dark: false, singleScale: false)

        XCTAssertEqual(name, "drawable-xxxhdpi")
    }

    // MARK: - Multi Scale Dark Mode Tests

    func testScale1DarkMode() {
        let name = Drawable.scaleToDrawableName(1, dark: true, singleScale: false)

        XCTAssertEqual(name, "drawable-night-mdpi")
    }

    func testScale1_5DarkMode() {
        let name = Drawable.scaleToDrawableName(1.5, dark: true, singleScale: false)

        XCTAssertEqual(name, "drawable-night-hdpi")
    }

    func testScale2DarkMode() {
        let name = Drawable.scaleToDrawableName(2, dark: true, singleScale: false)

        XCTAssertEqual(name, "drawable-night-xhdpi")
    }

    func testScale3DarkMode() {
        let name = Drawable.scaleToDrawableName(3, dark: true, singleScale: false)

        XCTAssertEqual(name, "drawable-night-xxhdpi")
    }

    func testScale4DarkMode() {
        let name = Drawable.scaleToDrawableName(4, dark: true, singleScale: false)

        XCTAssertEqual(name, "drawable-night-xxxhdpi")
    }
}
