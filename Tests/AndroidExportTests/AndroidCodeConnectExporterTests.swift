import AndroidExport
import CustomDump
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

    // MARK: - Tests

    func testGeneratesCodeConnectWithValidAssets() throws {
        let exporter = AndroidCodeConnectExporter()
        let packs = [
            makePack(name: "ic_home", nodeId: "12016:2218", fileId: "abc123"),
            makePack(name: "ic_settings", nodeId: "12016:2219", fileId: "abc123"),
        ]

        let result = try XCTUnwrap(exporter.generateCodeConnect(
            imagePacks: packs,
            url: outputURL,
            packageName: Self.packageName,
            xmlResourcePackage: Self.resourcePackage
        ))

        let generatedCode = try String(data: XCTUnwrap(result.data), encoding: .utf8)
        // Verify key content markers instead of exact match (Stencil whitespace varies)
        let code = try XCTUnwrap(generatedCode)
        XCTAssertTrue(code.contains("package \(Self.packageName)"))
        XCTAssertTrue(code.contains("import com.figma.code.connect.FigmaConnect"))
        XCTAssertTrue(code.contains("import \(Self.resourcePackage).R"))
        XCTAssertTrue(code.contains("@FigmaConnect(url = \"https://www.figma.com/design/abc123?node-id=12016-2218\")"))
        XCTAssertTrue(code.contains("fun Asset_ic_home()"))
        XCTAssertTrue(code.contains("R.drawable.ic_home"))
        XCTAssertTrue(code.contains("@FigmaConnect(url = \"https://www.figma.com/design/abc123?node-id=12016-2219\")"))
        XCTAssertTrue(code.contains("fun Asset_ic_settings()"))
        XCTAssertTrue(code.contains("R.drawable.ic_settings"))
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

    func testMixedAssetsOnlyIncludesThoseWithValidMetadata() throws {
        let exporter = AndroidCodeConnectExporter()
        let packs = [
            makePack(name: "ic_home", nodeId: "12016:2218", fileId: "abc123"),
            makePack(name: "ic_settings"), // no nodeId/fileId
        ]

        let result = try XCTUnwrap(exporter.generateCodeConnect(
            imagePacks: packs,
            url: outputURL,
            packageName: Self.packageName,
            xmlResourcePackage: Self.resourcePackage
        ))

        let generatedCode = try String(data: XCTUnwrap(result.data), encoding: .utf8)
        XCTAssertTrue(generatedCode?.contains("ic_home") == true)
        XCTAssertFalse(generatedCode?.contains("ic_settings") == true)
    }

    func testNodeIdColonsConvertedToHyphens() throws {
        let exporter = AndroidCodeConnectExporter()
        let packs = [
            makePack(name: "ic_arrow", nodeId: "12016:2218", fileId: "xyz"),
        ]

        let result = try XCTUnwrap(exporter.generateCodeConnect(
            imagePacks: packs,
            url: outputURL,
            packageName: Self.packageName,
            xmlResourcePackage: Self.resourcePackage
        ))

        let generatedCode = try String(data: XCTUnwrap(result.data), encoding: .utf8)
        XCTAssertTrue(generatedCode?.contains("node-id=12016-2218") == true)
        XCTAssertFalse(generatedCode?.contains("node-id=12016:2218") == true)
    }

    func testAssetsSortedByName() throws {
        let exporter = AndroidCodeConnectExporter()
        let packs = [
            makePack(name: "ic_zebra", nodeId: "1:3", fileId: "f1"),
            makePack(name: "ic_apple", nodeId: "1:1", fileId: "f1"),
            makePack(name: "ic_mango", nodeId: "1:2", fileId: "f1"),
        ]

        let result = try XCTUnwrap(exporter.generateCodeConnect(
            imagePacks: packs,
            url: outputURL,
            packageName: Self.packageName,
            xmlResourcePackage: Self.resourcePackage
        ))

        let generatedCode = try XCTUnwrap(String(data: XCTUnwrap(result.data), encoding: .utf8))
        let appleIndex = try XCTUnwrap(generatedCode.range(of: "ic_apple")?.lowerBound)
        let mangoIndex = try XCTUnwrap(generatedCode.range(of: "ic_mango")?.lowerBound)
        let zebraIndex = try XCTUnwrap(generatedCode.range(of: "ic_zebra")?.lowerBound)
        XCTAssertTrue(appleIndex < mangoIndex)
        XCTAssertTrue(mangoIndex < zebraIndex)
    }

    func testGranularCacheModeUsesAllAssetMetadata() throws {
        let exporter = AndroidCodeConnectExporter()
        let packs = [
            makePack(name: "ic_home", nodeId: "1:1", fileId: "f1"),
        ]
        let allMetadata = [
            AssetMetadata(name: "ic_home", nodeId: "1:1", fileId: "f1"),
            AssetMetadata(name: "ic_settings", nodeId: "1:2", fileId: "f1"),
            AssetMetadata(name: "ic_profile", nodeId: "1:3", fileId: "f1"),
        ]

        let result = try XCTUnwrap(exporter.generateCodeConnect(
            imagePacks: packs,
            url: outputURL,
            packageName: Self.packageName,
            xmlResourcePackage: Self.resourcePackage,
            allAssetMetadata: allMetadata
        ))

        let generatedCode = try String(data: XCTUnwrap(result.data), encoding: .utf8)
        XCTAssertTrue(generatedCode?.contains("ic_home") == true)
        XCTAssertTrue(generatedCode?.contains("ic_settings") == true)
        XCTAssertTrue(generatedCode?.contains("ic_profile") == true)
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
