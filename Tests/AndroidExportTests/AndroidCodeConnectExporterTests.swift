import AndroidExport
import ExFigCore
import XCTest

final class AndroidCodeConnectExporterTests: XCTestCase {
    // MARK: - Properties

    private static let packageName = "com.example.app"
    private static let resourcePackage = "com.example.app"
    private let outputURL = URL(fileURLWithPath: "/output/CodeConnect.figma.kt")

    // MARK: - Helpers

    private func makePack(
        name: String,
        nodeId: String? = nil,
        fileId: String? = nil
    ) -> AssetPair<ImagePack> {
        let image = Image(
            name: name,
            scale: .all,
            // swiftlint:disable:next force_unwrapping
            url: URL(string: "https://example.com/\(name).svg")!,
            format: "svg"
        )
        let pack = ImagePack(
            image: image,
            nodeId: nodeId,
            fileId: fileId
        )
        return AssetPair(light: pack, dark: nil)
    }

    private func generateCode(
        packs: [AssetPair<ImagePack>],
        allAssetMetadata: [AssetMetadata]? = nil
    ) throws -> String {
        let exporter = AndroidCodeConnectExporter()
        let result = try XCTUnwrap(exporter.generateCodeConnect(
            imagePacks: packs,
            url: outputURL,
            packageName: Self.packageName,
            xmlResourcePackage: Self.resourcePackage,
            allAssetMetadata: allAssetMetadata
        ))
        let data = try XCTUnwrap(result.data)
        return try XCTUnwrap(String(data: data, encoding: .utf8))
    }

    // MARK: - Tests

    func testGeneratesCodeConnectWithValidAssets() throws {
        let packs = [
            makePack(name: "ic_home", nodeId: "12016:2218", fileId: "abc123"),
            makePack(name: "ic_settings", nodeId: "12016:2219", fileId: "abc123"),
        ]

        let code = try generateCode(packs: packs)
        XCTAssertTrue(code.contains("package \(Self.packageName)"))
        XCTAssertTrue(code.contains("import com.figma.code.connect.FigmaConnect"))
        XCTAssertTrue(code.contains("import \(Self.resourcePackage).R"))
        XCTAssertTrue(code.contains("@FigmaConnect(url = \"https://www.figma.com/design/abc123?node-id=12016-2218\")"))
        XCTAssertTrue(code.contains("fun Asset_ic_home()"))
        XCTAssertTrue(code.contains("R.drawable.ic_home"))
        XCTAssertTrue(code.contains("@FigmaConnect(url = \"https://www.figma.com/design/abc123?node-id=12016-2219\")"))
        XCTAssertTrue(code.contains("fun Asset_ic_settings()"))
        XCTAssertTrue(code.contains("R.drawable.ic_settings"))
        XCTAssertTrue(code.contains("import androidx.compose.material.Icon"))
    }

    func testEmptyImagePacksReturnsNil() throws {
        let exporter = AndroidCodeConnectExporter()
        let result = try exporter.generateCodeConnect(
            imagePacks: [],
            url: outputURL,
            packageName: Self.packageName,
            xmlResourcePackage: Self.resourcePackage
        )
        XCTAssertNil(result)
    }

    func testReturnsNilWhenAssetsLackNodeId() throws {
        let exporter = AndroidCodeConnectExporter()
        let packs = [
            makePack(name: "ic_home"),
            makePack(name: "ic_settings"),
        ]

        let result = try exporter.generateCodeConnect(
            imagePacks: packs,
            url: outputURL,
            packageName: Self.packageName,
            xmlResourcePackage: Self.resourcePackage
        )

        XCTAssertNil(result)
    }

    func testAssetWithNodeIdButNoFileIdIsFiltered() throws {
        let exporter = AndroidCodeConnectExporter()
        let packs = [
            makePack(name: "ic_home", nodeId: "1:1"),
        ]

        let result = try exporter.generateCodeConnect(
            imagePacks: packs,
            url: outputURL,
            packageName: Self.packageName,
            xmlResourcePackage: Self.resourcePackage
        )

        XCTAssertNil(result)
    }

    func testAssetWithFileIdButNoNodeIdIsFiltered() throws {
        let exporter = AndroidCodeConnectExporter()
        let packs = [
            makePack(name: "ic_home", fileId: "f1"),
        ]

        let result = try exporter.generateCodeConnect(
            imagePacks: packs,
            url: outputURL,
            packageName: Self.packageName,
            xmlResourcePackage: Self.resourcePackage
        )

        XCTAssertNil(result)
    }

    func testMixedAssetsOnlyIncludesThoseWithValidMetadata() throws {
        let packs = [
            makePack(name: "ic_home", nodeId: "12016:2218", fileId: "abc123"),
            makePack(name: "ic_settings"), // no nodeId/fileId
        ]

        let code = try generateCode(packs: packs)
        XCTAssertTrue(code.contains("ic_home"))
        XCTAssertFalse(code.contains("ic_settings"))
    }

    func testNodeIdColonsConvertedToHyphens() throws {
        let packs = [
            makePack(name: "ic_arrow", nodeId: "12016:2218", fileId: "xyz"),
        ]

        let code = try generateCode(packs: packs)
        XCTAssertTrue(code.contains("node-id=12016-2218"))
        XCTAssertFalse(code.contains("node-id=12016:2218"))
    }

    func testAssetsSortedByName() throws {
        let packs = [
            makePack(name: "ic_zebra", nodeId: "1:3", fileId: "f1"),
            makePack(name: "ic_apple", nodeId: "1:1", fileId: "f1"),
            makePack(name: "ic_mango", nodeId: "1:2", fileId: "f1"),
        ]

        let code = try generateCode(packs: packs)
        let appleIndex = try XCTUnwrap(code.range(of: "ic_apple")?.lowerBound)
        let mangoIndex = try XCTUnwrap(code.range(of: "ic_mango")?.lowerBound)
        let zebraIndex = try XCTUnwrap(code.range(of: "ic_zebra")?.lowerBound)
        XCTAssertTrue(appleIndex < mangoIndex)
        XCTAssertTrue(mangoIndex < zebraIndex)
    }

    func testGranularCacheModeUsesAllAssetMetadata() throws {
        let packs = [
            makePack(name: "ic_home", nodeId: "1:1", fileId: "f1"),
        ]
        let allMetadata = [
            AssetMetadata(name: "ic_home", nodeId: "1:1", fileId: "f1"),
            AssetMetadata(name: "ic_settings", nodeId: "1:2", fileId: "f1"),
            AssetMetadata(name: "ic_profile", nodeId: "1:3", fileId: "f1"),
        ]

        let code = try generateCode(packs: packs, allAssetMetadata: allMetadata)
        XCTAssertTrue(code.contains("ic_home"))
        XCTAssertTrue(code.contains("ic_settings"))
        XCTAssertTrue(code.contains("ic_profile"))
    }

    func testEmptyAllAssetMetadataFallsBackToImagePacks() throws {
        let packs = [
            makePack(name: "ic_home", nodeId: "1:1", fileId: "f1"),
        ]

        let code = try generateCode(packs: packs, allAssetMetadata: [])
        XCTAssertTrue(code.contains("ic_home"))
    }

    func testAllAssetMetadataFiltersEmptyNodeId() throws {
        let exporter = AndroidCodeConnectExporter()
        let packs = [makePack(name: "ic_home", nodeId: "1:1", fileId: "f1")]
        let allMetadata = [
            AssetMetadata(name: "ic_valid", nodeId: "1:1", fileId: "f1"),
            AssetMetadata(name: "ic_empty_node", nodeId: "", fileId: "f1"),
            AssetMetadata(name: "ic_empty_file", nodeId: "1:2", fileId: ""),
        ]

        let result = try XCTUnwrap(exporter.generateCodeConnect(
            imagePacks: packs,
            url: outputURL,
            packageName: Self.packageName,
            xmlResourcePackage: Self.resourcePackage,
            allAssetMetadata: allMetadata
        ))
        let data = try XCTUnwrap(result.data)
        let code = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(code.contains("ic_valid"))
        XCTAssertFalse(code.contains("ic_empty_node"))
        XCTAssertFalse(code.contains("ic_empty_file"))
    }

    func testResourceNameSanitized() throws {
        let packs = [
            makePack(name: "icon-with-dashes", nodeId: "1:1", fileId: "f1"),
            makePack(name: "icon.with.dots", nodeId: "1:2", fileId: "f1"),
            makePack(name: "3starts_with_digit", nodeId: "1:3", fileId: "f1"),
        ]

        let code = try generateCode(packs: packs)
        XCTAssertTrue(code.contains("R.drawable.icon_with_dashes"))
        XCTAssertTrue(code.contains("R.drawable.icon_with_dots"))
        XCTAssertTrue(code.contains("R.drawable._3starts_with_digit"))
    }

    func testOutputFileDestination() throws {
        let exporter = AndroidCodeConnectExporter()
        let packs = [
            makePack(name: "ic_test", nodeId: "1:1", fileId: "f1"),
        ]

        let result = try XCTUnwrap(exporter.generateCodeConnect(
            imagePacks: packs,
            url: outputURL,
            packageName: Self.packageName,
            xmlResourcePackage: Self.resourcePackage
        ))

        XCTAssertEqual(result.destination.file.lastPathComponent, "CodeConnect.figma.kt")
        XCTAssertEqual(result.destination.directory.path, "/output")
    }
}
