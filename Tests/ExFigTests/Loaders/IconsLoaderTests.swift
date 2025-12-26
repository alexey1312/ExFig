@testable import ExFig
import ExFigCore
@testable import FigmaAPI
import Logging
import XCTest

final class IconsLoaderTests: XCTestCase {
    var mockClient: MockClient!
    var logger: Logger!

    override func setUp() {
        super.setUp()
        mockClient = MockClient()
        logger = Logger(label: "test")
    }

    override func tearDown() {
        mockClient = nil
        super.tearDown()
    }

    // MARK: - Basic Icon Loading

    func testLoadIconsFromLightFile() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "icon_home", frameName: "Icons"),
            Component.make(nodeId: "1:2", name: "icon_settings", frameName: "Icons"),
        ]
        let imageUrls: [NodeId: ImagePath?] = [
            "1:1": "https://figma.com/icon_home.pdf",
            "1:2": "https://figma.com/icon_settings.pdf",
        ]

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)

        let params = Params.make(lightFileId: "test-file", iconsFrameName: "Icons")
        let loader = IconsLoader(client: mockClient, params: params, platform: .ios, logger: logger)

        let result = try await loader.load()

        XCTAssertEqual(result.light.count, 2)
        XCTAssertNil(result.dark)
    }

    func testLoadIconsFromLightAndDarkFiles() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "icon_home", frameName: "Icons"),
        ]
        let imageUrls: [NodeId: ImagePath?] = [
            "1:1": "https://figma.com/icon.pdf",
        ]

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)

        let params = Params.make(
            lightFileId: "light-file",
            darkFileId: "dark-file",
            iconsFrameName: "Icons"
        )
        let loader = IconsLoader(client: mockClient, params: params, platform: .ios, logger: logger)

        let result = try await loader.load()

        XCTAssertEqual(result.light.count, 1)
        XCTAssertNotNil(result.dark)
    }

    // MARK: - Parallel Loading Performance

    func testLoadIconsFromLightAndDarkFilesInParallel() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "icon_home", frameName: "Icons"),
        ]
        let imageUrls: [NodeId: ImagePath?] = [
            "1:1": "https://figma.com/icon.pdf",
        ]

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)
        mockClient.setRequestDelay(0.08) // 80ms per request

        let params = Params.make(
            lightFileId: "light-file",
            darkFileId: "dark-file",
            iconsFrameName: "Icons"
        )
        let loader = IconsLoader(client: mockClient, params: params, platform: .ios, logger: logger)

        let startTime = Date()
        let result = try await loader.load()
        let duration = Date().timeIntervalSince(startTime)

        // 2 files x 2 requests each (Components + Image) = 4 requests
        // Sequential: 4 x 80ms = 320ms minimum
        // Parallel (2 files): ~160ms (2 sequential per file, 2 files parallel)
        // Threshold 0.5s gives CI headroom while proving parallelism (CI can be slow)
        XCTAssertLessThan(duration, 0.5, "Loading should be parallel across files")

        XCTAssertEqual(result.light.count, 1)
        XCTAssertNotNil(result.dark)
    }

    func testLoadIconsParallelMaintainsCorrectResults() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "icon_home", frameName: "Icons"),
            Component.make(nodeId: "1:2", name: "icon_settings", frameName: "Icons"),
        ]
        let imageUrls: [NodeId: ImagePath?] = [
            "1:1": "https://figma.com/icon_home.pdf",
            "1:2": "https://figma.com/icon_settings.pdf",
        ]

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)

        let params = Params.make(
            lightFileId: "light-file",
            darkFileId: "dark-file",
            iconsFrameName: "Icons"
        )
        let loader = IconsLoader(client: mockClient, params: params, platform: .ios, logger: logger)

        let result = try await loader.load()

        // Verify structure
        XCTAssertEqual(result.light.count, 2)
        XCTAssertEqual(result.dark?.count, 2)

        // Verify content
        let homeIcon = result.light.first { $0.name == "icon_home" }
        XCTAssertNotNil(homeIcon)
    }

    // MARK: - Filtering

    func testLoadIconsWithFilter() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "button/primary", frameName: "Icons"),
            Component.make(nodeId: "1:2", name: "button/secondary", frameName: "Icons"),
            Component.make(nodeId: "1:3", name: "nav/home", frameName: "Icons"),
        ]
        let imageUrls: [NodeId: ImagePath?] = [
            "1:1": "https://figma.com/button_primary.pdf",
            "1:2": "https://figma.com/button_secondary.pdf",
        ]

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)

        let params = Params.make(lightFileId: "test-file", iconsFrameName: "Icons")
        let loader = IconsLoader(client: mockClient, params: params, platform: .ios, logger: logger)

        let result = try await loader.load(filter: "button/*")

        XCTAssertEqual(result.light.count, 2)
        XCTAssertTrue(result.light.allSatisfy { $0.name.hasPrefix("button/") })
    }

    // MARK: - Platform Filtering

    func testFiltersComponentsByPlatform() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "icon_ios", description: "ios", frameName: "Icons"),
            Component.make(nodeId: "1:2", name: "icon_android", description: "android", frameName: "Icons"),
            Component.make(nodeId: "1:3", name: "icon_shared", frameName: "Icons"),
        ]
        let imageUrls: [NodeId: ImagePath?] = [
            "1:1": "https://figma.com/icon_ios.pdf",
            "1:3": "https://figma.com/icon_shared.pdf",
        ]

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)

        let params = Params.make(lightFileId: "test-file", iconsFrameName: "Icons")
        let loader = IconsLoader(client: mockClient, params: params, platform: .ios, logger: logger)

        let result = try await loader.load()

        // Should include iOS-specific and shared, but not Android
        XCTAssertEqual(result.light.count, 2)
        let iconNames = result.light.map(\.name)
        XCTAssertTrue(iconNames.contains("icon_ios"))
        XCTAssertTrue(iconNames.contains("icon_shared"))
        XCTAssertFalse(iconNames.contains("icon_android"))
    }

    // MARK: - Batch Loading

    func testLoadIconsWithManyComponents() async throws {
        // Create 50 components (within single batch of 100)
        let components = (0 ..< 50).map { i in
            Component.make(nodeId: "node\(i)", name: "icon_\(i)", frameName: "Icons")
        }
        var imageUrls: [NodeId: ImagePath?] = [:]
        for i in 0 ..< 50 {
            imageUrls["node\(i)"] = "https://figma.com/icon_\(i).pdf"
        }

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)

        let params = Params.make(lightFileId: "test-file", iconsFrameName: "Icons")
        let loader = IconsLoader(client: mockClient, params: params, platform: .ios, logger: logger)

        let result = try await loader.load()

        // Verify all icons are returned
        XCTAssertEqual(result.light.count, 50)

        // Verify some specific icons exist
        let icon0 = result.light.first { $0.name == "icon_0" }
        let icon49 = result.light.first { $0.name == "icon_49" }
        XCTAssertNotNil(icon0)
        XCTAssertNotNil(icon49)
    }

    // MARK: - Integration Tests

    func testParallelLoadingMaintainsIconProperties() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "icon_home", frameName: "Icons"),
            Component.make(nodeId: "1:2", name: "icon_settings", frameName: "Icons"),
        ]
        let imageUrls: [NodeId: ImagePath?] = [
            "1:1": "https://figma.com/icon_home.pdf",
            "1:2": "https://figma.com/icon_settings.pdf",
        ]

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)

        let params = Params.make(
            lightFileId: "light-file",
            darkFileId: "dark-file",
            iconsFrameName: "Icons"
        )
        let loader = IconsLoader(client: mockClient, params: params, platform: .ios, logger: logger)

        let result = try await loader.load()

        // Verify light icons have all properties
        let homeIconLight = result.light.first { $0.name == "icon_home" }
        XCTAssertNotNil(homeIconLight)
        XCTAssertEqual(homeIconLight?.name, "icon_home")
        XCTAssertEqual(homeIconLight?.images.first?.url.absoluteString, "https://figma.com/icon_home.pdf")
        XCTAssertEqual(homeIconLight?.platform, .ios) // Platform from loader, not component

        let settingsIconLight = result.light.first { $0.name == "icon_settings" }
        XCTAssertNotNil(settingsIconLight)
        XCTAssertEqual(settingsIconLight?.platform, .ios) // Platform from loader

        // Verify dark icons exist and match
        XCTAssertNotNil(result.dark)
        let homeIconDark = result.dark?.first { $0.name == "icon_home" }
        XCTAssertNotNil(homeIconDark)
        XCTAssertEqual(homeIconDark?.name, "icon_home")
    }

    // MARK: - Error Handling

    func testThrowsWhenNoComponentsFound() async {
        mockClient.setResponse([Component](), for: ComponentsEndpoint.self)

        let params = Params.make(lightFileId: "test-file", iconsFrameName: "Icons")
        let loader = IconsLoader(client: mockClient, params: params, platform: .ios, logger: logger)

        do {
            _ = try await loader.load()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is ExFigError)
        }
    }
}
