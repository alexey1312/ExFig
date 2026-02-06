import ExFig_Android
import ExFig_Flutter
import ExFig_iOS
import ExFig_Web
@testable import ExFigCLI
import XCTest

final class PlatformConfigTests: XCTestCase {
    // MARK: - iOS platformConfig

    func testIOSPlatformConfigMapsAllFields() throws {
        let json = """
        {
            "xcodeprojPath": "MyApp.xcodeproj",
            "target": "MyApp",
            "xcassetsPath": "./Resources/Assets.xcassets",
            "xcassetsInMainBundle": true,
            "xcassetsInSwiftPackage": true,
            "resourceBundleNames": ["MyBundle"],
            "addObjcAttribute": true,
            "templatesPath": "./Templates"
        }
        """
        let ios = try JSONDecoder().decode(PKLConfig.iOS.self, from: Data(json.utf8))

        let figma = PKLConfig.Figma(
            lightFileId: "figma-file-123",
            darkFileId: "dark-456",
            lightHighContrastFileId: nil,
            darkHighContrastFileId: nil,
            timeout: 30.0
        )

        let config = ios.platformConfig(figma: figma)

        XCTAssertEqual(config.xcodeprojPath, "MyApp.xcodeproj")
        XCTAssertEqual(config.target, "MyApp")
        XCTAssertEqual(config.xcassetsPath?.lastPathComponent, "Assets.xcassets")
        XCTAssertTrue(config.xcassetsInMainBundle)
        XCTAssertEqual(config.xcassetsInSwiftPackage, true)
        XCTAssertEqual(config.resourceBundleNames, ["MyBundle"])
        XCTAssertEqual(config.addObjcAttribute, true)
        XCTAssertEqual(config.templatesPath?.lastPathComponent, "Templates")
        XCTAssertEqual(config.figmaFileId, "figma-file-123")
        XCTAssertEqual(config.figmaTimeout, 30.0)
    }

    func testIOSPlatformConfigNilFigmaGivesNilFileId() throws {
        let json = """
        {
            "xcodeprojPath": "MyApp.xcodeproj",
            "target": "MyApp",
            "xcassetsPath": "./Resources/Assets.xcassets",
            "xcassetsInMainBundle": false
        }
        """
        let ios = try JSONDecoder().decode(PKLConfig.iOS.self, from: Data(json.utf8))

        let config = ios.platformConfig()

        XCTAssertNil(config.figmaFileId)
        XCTAssertNil(config.figmaTimeout)
        XCTAssertFalse(config.xcassetsInMainBundle)
    }

    // MARK: - Android platformConfig

    func testAndroidPlatformConfigMapsAllFields() throws {
        let json = """
        {
            "mainRes": "./app/src/main/res",
            "resourcePackage": "com.example.app",
            "mainSrc": "./app/src/main/java",
            "templatesPath": "./android-templates"
        }
        """
        let android = try JSONDecoder().decode(PKLConfig.Android.self, from: Data(json.utf8))

        let figma = PKLConfig.Figma(
            lightFileId: "android-figma",
            darkFileId: nil,
            lightHighContrastFileId: nil,
            darkHighContrastFileId: nil,
            timeout: 60.0
        )

        let config = android.platformConfig(figma: figma)

        XCTAssertEqual(config.mainRes.lastPathComponent, "res")
        XCTAssertEqual(config.resourcePackage, "com.example.app")
        XCTAssertEqual(config.mainSrc?.lastPathComponent, "java")
        XCTAssertEqual(config.templatesPath?.lastPathComponent, "android-templates")
        XCTAssertEqual(config.figmaFileId, "android-figma")
        XCTAssertEqual(config.figmaTimeout, 60.0)
    }

    func testAndroidPlatformConfigNilFigmaGivesNilFileId() throws {
        let json = """
        {
            "mainRes": "./app/src/main/res"
        }
        """
        let android = try JSONDecoder().decode(PKLConfig.Android.self, from: Data(json.utf8))

        let config = android.platformConfig()

        XCTAssertNil(config.figmaFileId)
        XCTAssertNil(config.figmaTimeout)
        XCTAssertNil(config.resourcePackage)
        XCTAssertNil(config.mainSrc)
    }

    // MARK: - Flutter platformConfig

    func testFlutterPlatformConfigMapsOutput() throws {
        let json = """
        {
            "output": "./lib/generated",
            "templatesPath": "./flutter-templates"
        }
        """
        let flutter = try JSONDecoder().decode(PKLConfig.Flutter.self, from: Data(json.utf8))

        let config = flutter.platformConfig()

        XCTAssertEqual(config.output.lastPathComponent, "generated")
        XCTAssertEqual(config.templatesPath?.lastPathComponent, "flutter-templates")
    }

    func testFlutterPlatformConfigWithoutTemplates() throws {
        let json = """
        {
            "output": "./lib/generated"
        }
        """
        let flutter = try JSONDecoder().decode(PKLConfig.Flutter.self, from: Data(json.utf8))

        let config = flutter.platformConfig()

        XCTAssertEqual(config.output.lastPathComponent, "generated")
        XCTAssertNil(config.templatesPath)
    }

    // MARK: - Web platformConfig

    func testWebPlatformConfigMapsOutput() throws {
        let json = """
        {
            "output": "./dist/styles",
            "templatesPath": "./web-templates"
        }
        """
        let web = try JSONDecoder().decode(PKLConfig.Web.self, from: Data(json.utf8))

        let config = web.platformConfig()

        XCTAssertEqual(config.output.lastPathComponent, "styles")
        XCTAssertEqual(config.templatesPath?.lastPathComponent, "web-templates")
    }

    func testWebPlatformConfigWithoutTemplates() throws {
        let json = """
        {
            "output": "./dist/styles"
        }
        """
        let web = try JSONDecoder().decode(PKLConfig.Web.self, from: Data(json.utf8))

        let config = web.platformConfig()

        XCTAssertEqual(config.output.lastPathComponent, "styles")
        XCTAssertNil(config.templatesPath)
    }
}
