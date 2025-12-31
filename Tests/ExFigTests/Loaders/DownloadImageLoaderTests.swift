import ExFigKit

// swiftlint:disable file_length type_body_length
@testable import ExFig
import ExFigCore
@testable import FigmaAPI
import Logging
import XCTest

final class DownloadImageLoaderTests: XCTestCase {
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

    // MARK: - Vector Image Loading

    func testLoadVectorImagesReturnsImagePacks() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "icon_home", frameName: "Icons"),
            Component.make(nodeId: "1:2", name: "icon_settings", frameName: "Icons"),
        ]
        let imageUrls: [NodeId: ImagePath?] = [
            "1:1": "https://figma.com/icon_home.svg",
            "1:2": "https://figma.com/icon_settings.svg",
        ]

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)

        let loader = DownloadImageLoader(client: mockClient, logger: logger)

        let result = try await loader.loadVectorImages(
            fileId: "test-file",
            frameName: "Icons",
            params: SVGParams(),
            filter: nil
        )

        XCTAssertEqual(result.count, 2)
        let names = result.map(\.name).sorted()
        XCTAssertEqual(names, ["icon_home", "icon_settings"])
    }

    func testLoadVectorImagesWithPDFFormat() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "vector_icon", frameName: "Icons"),
        ]
        let imageUrls: [NodeId: ImagePath?] = [
            "1:1": "https://figma.com/vector_icon.pdf",
        ]

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)

        let loader = DownloadImageLoader(client: mockClient, logger: logger)

        let result = try await loader.loadVectorImages(
            fileId: "test-file",
            frameName: "Icons",
            params: PDFParams(),
            filter: nil
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].images[0].format, "pdf")
    }

    func testLoadVectorImagesFiltersEmptyNames() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "valid_icon", frameName: "Icons"),
            Component.make(nodeId: "1:2", name: "   ", frameName: "Icons"), // Empty name
            Component.make(nodeId: "1:3", name: "", frameName: "Icons"), // Empty name
        ]
        let imageUrls: [NodeId: ImagePath?] = [
            "1:1": "https://figma.com/valid.svg",
        ]

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)

        let loader = DownloadImageLoader(client: mockClient, logger: logger)

        let result = try await loader.loadVectorImages(
            fileId: "test-file",
            frameName: "Icons",
            params: SVGParams(),
            filter: nil
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "valid_icon")
    }

    // MARK: - Raster Image Loading

    func testLoadRasterImagesReturnsImagePacks() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "photo_1", frameName: "Images"),
            Component.make(nodeId: "1:2", name: "photo_2", frameName: "Images"),
        ]
        let imageUrls: [NodeId: ImagePath?] = [
            "1:1": "https://figma.com/photo_1.png",
            "1:2": "https://figma.com/photo_2.png",
        ]

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)

        let loader = DownloadImageLoader(client: mockClient, logger: logger)

        let result = try await loader.loadRasterImages(
            fileId: "test-file",
            frameName: "Images",
            scale: 2.0,
            format: "png",
            filter: nil
        )

        XCTAssertEqual(result.count, 2)

        // Verify scale is set correctly
        let scales = result.flatMap { $0.images.map(\.scale.value) }
        XCTAssertTrue(scales.allSatisfy { $0 == 2.0 })
    }

    func testLoadRasterImagesWithJPGFormat() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "photo", frameName: "Photos"),
        ]
        let imageUrls: [NodeId: ImagePath?] = [
            "1:1": "https://figma.com/photo.jpg",
        ]

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)

        let loader = DownloadImageLoader(client: mockClient, logger: logger)

        let result = try await loader.loadRasterImages(
            fileId: "test-file",
            frameName: "Photos",
            scale: 3.0,
            format: "jpg",
            filter: nil
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].images[0].format, "jpg")
    }

    // MARK: - Filtering

    func testLoadVectorImagesWithFilter() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "button/primary", frameName: "Icons"),
            Component.make(nodeId: "1:2", name: "button/secondary", frameName: "Icons"),
            Component.make(nodeId: "1:3", name: "nav/home", frameName: "Icons"),
        ]
        let imageUrls: [NodeId: ImagePath?] = [
            "1:1": "https://figma.com/button_primary.svg",
            "1:2": "https://figma.com/button_secondary.svg",
        ]

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)

        let loader = DownloadImageLoader(client: mockClient, logger: logger)

        let result = try await loader.loadVectorImages(
            fileId: "test-file",
            frameName: "Icons",
            params: SVGParams(),
            filter: "button/*"
        )

        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.name.hasPrefix("button/") })
    }

    func testLoadRasterImagesWithFilter() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "logo/main", frameName: "Images"),
            Component.make(nodeId: "1:2", name: "logo/alt", frameName: "Images"),
            Component.make(nodeId: "1:3", name: "banner/hero", frameName: "Images"),
        ]
        let imageUrls: [NodeId: ImagePath?] = [
            "1:1": "https://figma.com/logo_main.png",
            "1:2": "https://figma.com/logo_alt.png",
        ]

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)

        let loader = DownloadImageLoader(client: mockClient, logger: logger)

        let result = try await loader.loadRasterImages(
            fileId: "test-file",
            frameName: "Images",
            scale: 2.0,
            format: "png",
            filter: "logo/*"
        )

        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.name.hasPrefix("logo/") })
    }

    // MARK: - Frame Filtering

    func testLoadVectorImagesFiltersbyFrameName() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "icon_a", frameName: "Icons"),
            Component.make(nodeId: "1:2", name: "icon_b", frameName: "OtherFrame"),
        ]
        let imageUrls: [NodeId: ImagePath?] = [
            "1:1": "https://figma.com/icon_a.svg",
        ]

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)

        let loader = DownloadImageLoader(client: mockClient, logger: logger)

        let result = try await loader.loadVectorImages(
            fileId: "test-file",
            frameName: "Icons",
            params: SVGParams(),
            filter: nil
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "icon_a")
    }

    // MARK: - Error Handling

    func testThrowsWhenNoComponentsFound() async {
        mockClient.setResponse([Component](), for: ComponentsEndpoint.self)

        let loader = DownloadImageLoader(client: mockClient, logger: logger)

        do {
            _ = try await loader.loadVectorImages(
                fileId: "test-file",
                frameName: "Icons",
                params: SVGParams(),
                filter: nil
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is ExFigError)
        }
    }

    func testThrowsWhenNoComponentsMatchFrame() async {
        let components = [
            Component.make(nodeId: "1:1", name: "icon", frameName: "OtherFrame"),
        ]
        mockClient.setResponse(components, for: ComponentsEndpoint.self)

        let loader = DownloadImageLoader(client: mockClient, logger: logger)

        do {
            _ = try await loader.loadVectorImages(
                fileId: "test-file",
                frameName: "Icons",
                params: SVGParams(),
                filter: nil
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is ExFigError)
        }
    }

    func testSkipsComponentsWithFailedImageFetch() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "good_icon", frameName: "Icons"),
            Component.make(nodeId: "1:2", name: "bad_icon", frameName: "Icons"),
        ]
        // Only one image URL returned - the other failed
        let imageUrls: [NodeId: ImagePath?] = [
            "1:1": "https://figma.com/good_icon.svg",
            "1:2": nil, // Failed to fetch
        ]

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)

        let loader = DownloadImageLoader(client: mockClient, logger: logger)

        let result = try await loader.loadVectorImages(
            fileId: "test-file",
            frameName: "Icons",
            params: SVGParams(),
            filter: nil
        )

        // Should only return the successful one
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "good_icon")
    }

    // MARK: - Image Pack Properties

    func testVectorImagePackHasCorrectProperties() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "test_icon", frameName: "Icons"),
        ]
        let imageUrls: [NodeId: ImagePath?] = [
            "1:1": "https://figma.com/test_icon.svg",
        ]

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)

        let loader = DownloadImageLoader(client: mockClient, logger: logger)

        let result = try await loader.loadVectorImages(
            fileId: "test-file",
            frameName: "Icons",
            params: SVGParams(),
            filter: nil
        )

        XCTAssertEqual(result.count, 1)

        let pack = result[0]
        XCTAssertEqual(pack.name, "test_icon")
        XCTAssertNil(pack.platform) // Download command doesn't set platform
        XCTAssertEqual(pack.images.count, 1)

        let image = pack.images[0]
        XCTAssertEqual(image.name, "test_icon")
        XCTAssertEqual(image.scale.value, 1.0) // Vector images use .all scale
        XCTAssertEqual(image.format, "svg")
        XCTAssertEqual(image.url.absoluteString, "https://figma.com/test_icon.svg")
    }

    func testRasterImagePackHasCorrectProperties() async throws {
        let components = [
            Component.make(nodeId: "1:1", name: "test_photo", frameName: "Photos"),
        ]
        let imageUrls: [NodeId: ImagePath?] = [
            "1:1": "https://figma.com/test_photo.png",
        ]

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)

        let loader = DownloadImageLoader(client: mockClient, logger: logger)

        let result = try await loader.loadRasterImages(
            fileId: "test-file",
            frameName: "Photos",
            scale: 2.5,
            format: "png",
            filter: nil
        )

        XCTAssertEqual(result.count, 1)

        let pack = result[0]
        XCTAssertEqual(pack.name, "test_photo")
        XCTAssertNil(pack.platform)
        XCTAssertEqual(pack.images.count, 1)

        let image = pack.images[0]
        XCTAssertEqual(image.name, "test_photo")
        XCTAssertEqual(image.scale.value, 2.5)
        XCTAssertEqual(image.format, "png")
    }

    // MARK: - Batch Loading

    func testLoadManyComponentsInBatches() async throws {
        // Create 50 components (within batch size of 100 to avoid mock client limitations)
        let components = (0 ..< 50).map { i in
            Component.make(nodeId: "\(i):\(i)", name: "icon_\(i)", frameName: "Icons")
        }
        var imageUrls: [NodeId: ImagePath?] = [:]
        for i in 0 ..< 50 {
            imageUrls["\(i):\(i)"] = "https://figma.com/icon_\(i).svg"
        }

        mockClient.setResponse(components, for: ComponentsEndpoint.self)
        mockClient.setResponse(imageUrls, for: ImageEndpoint.self)

        let loader = DownloadImageLoader(client: mockClient, logger: logger)

        let result = try await loader.loadVectorImages(
            fileId: "test-file",
            frameName: "Icons",
            params: SVGParams(),
            filter: nil
        )

        XCTAssertEqual(result.count, 50)
    }
}
