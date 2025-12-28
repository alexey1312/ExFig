@testable import ExFig
@testable import FigmaAPI
import Logging
import XCTest

/// Tests for VersionTrackingConfig initialization and properties.
final class VersionTrackingConfigTests: XCTestCase {
    private var ui: TerminalUI!

    override func setUp() {
        super.setUp()
        ui = TerminalUI(outputMode: .quiet)
    }

    func testDefaultBatchMode() {
        // Given: Config without explicit batchMode
        let config = VersionTrackingConfig(
            client: MockClient(),
            params: Params.makeMinimal(),
            cacheOptions: CacheOptions(),
            configCacheEnabled: false,
            configCachePath: nil,
            assetType: "Icons",
            ui: ui,
            logger: Logger(label: "test")
        )

        // Then: batchMode defaults to false
        XCTAssertFalse(config.batchMode)
    }

    func testExplicitBatchMode() {
        // Given: Config with explicit batchMode
        let config = VersionTrackingConfig(
            client: MockClient(),
            params: Params.makeMinimal(),
            cacheOptions: CacheOptions(),
            configCacheEnabled: false,
            configCachePath: nil,
            assetType: "Colors",
            ui: ui,
            logger: Logger(label: "test"),
            batchMode: true
        )

        // Then: batchMode is set
        XCTAssertTrue(config.batchMode)
    }

    func testAssetTypeIsPreserved() {
        // Given: Different asset types
        let colorsConfig = VersionTrackingConfig(
            client: MockClient(),
            params: Params.makeMinimal(),
            cacheOptions: CacheOptions(),
            configCacheEnabled: false,
            configCachePath: nil,
            assetType: "Colors",
            ui: ui,
            logger: Logger(label: "test")
        )

        let iconsConfig = VersionTrackingConfig(
            client: MockClient(),
            params: Params.makeMinimal(),
            cacheOptions: CacheOptions(),
            configCacheEnabled: false,
            configCachePath: nil,
            assetType: "Icons",
            ui: ui,
            logger: Logger(label: "test")
        )

        // Then: Asset types are preserved
        XCTAssertEqual(colorsConfig.assetType, "Colors")
        XCTAssertEqual(iconsConfig.assetType, "Icons")
    }
}

/// Tests for VersionTrackingCheckResult enum.
final class VersionTrackingCheckResultTests: XCTestCase {
    func testSkipExportCase() {
        // Given: skipExport result
        let result = VersionTrackingCheckResult.skipExport

        // Then: It matches skipExport pattern
        if case .skipExport = result {
            // Pass
        } else {
            XCTFail("Expected skipExport")
        }
    }

    func testProceedCase() {
        // Given: proceed result with manager and versions
        let manager = ImageTrackingManager(
            client: MockClient(),
            cachePath: nil,
            logger: Logger(label: "test")
        )
        let versions = [
            FileVersionInfo(
                fileId: "file1",
                fileName: "Design",
                currentVersion: "v1",
                cachedVersion: nil,
                needsExport: true
            ),
        ]

        let result = VersionTrackingCheckResult.proceed(manager: manager, versions: versions)

        // Then: Values are accessible
        if case let .proceed(extractedManager, extractedVersions) = result {
            XCTAssertNotNil(extractedManager)
            XCTAssertEqual(extractedVersions.count, 1)
            XCTAssertEqual(extractedVersions[0].fileId, "file1")
        } else {
            XCTFail("Expected proceed")
        }
    }
}

// MARK: - Test Helpers

private extension Params {
    static func makeMinimal() -> Params {
        let json = """
        {
            "figma": {
                "lightFileId": "light123"
            }
        }
        """
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(Params.self, from: Data(json.utf8))
    }
}
