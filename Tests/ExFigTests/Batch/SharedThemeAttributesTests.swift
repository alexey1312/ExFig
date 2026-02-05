@testable import ExFig
import XCTest

final class SharedThemeAttributesTests: XCTestCase {
    // MARK: - SharedThemeAttributesCollector Tests

    func testCollectorStartsEmpty() async {
        let collector = SharedThemeAttributesCollector()

        let isEmpty = await collector.isEmpty
        let count = await collector.count

        XCTAssertTrue(isEmpty)
        XCTAssertEqual(count, 0)
    }

    func testCollectorAddsCollection() async {
        let collector = SharedThemeAttributesCollector()
        let collection = makeCollection(themeName: "Theme.App")

        await collector.add(collection)

        let isEmpty = await collector.isEmpty
        let count = await collector.count

        XCTAssertFalse(isEmpty)
        XCTAssertEqual(count, 1)
    }

    func testCollectorGetAll() async {
        let collector = SharedThemeAttributesCollector()
        let collection1 = makeCollection(themeName: "Theme.A")
        let collection2 = makeCollection(themeName: "Theme.B")

        await collector.add(collection1)
        await collector.add(collection2)

        let all = await collector.getAll()

        XCTAssertEqual(all.count, 2)
        XCTAssertEqual(all[0].themeName, "Theme.A")
        XCTAssertEqual(all[1].themeName, "Theme.B")
    }

    func testCollectorClear() async {
        let collector = SharedThemeAttributesCollector()
        await collector.add(makeCollection(themeName: "Theme.App"))

        await collector.clear()

        let isEmpty = await collector.isEmpty
        XCTAssertTrue(isEmpty)
    }

    // MARK: - Batch Merge Integration Test

    func testBatchMergeMultipleThemesToSameFile() throws {
        // Simulate two configs writing to the same attrs.xml with different themes
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let attrsURL = tempDir.appendingPathComponent("attrs.xml")

        // Create initial file with markers for both themes
        let initialContent = """
        <?xml version="1.0" encoding="utf-8"?>
        <resources>
            <!-- FIGMA COLORS MARKER START: Theme.A -->
            <!-- FIGMA COLORS MARKER END: Theme.A -->

            <!-- FIGMA COLORS MARKER START: Theme.B -->
            <!-- FIGMA COLORS MARKER END: Theme.B -->
        </resources>
        """
        try Data(initialContent.utf8).write(to: attrsURL)

        // Update Theme.A
        let updaterA = MarkerFileUpdater(
            markerStart: "FIGMA COLORS MARKER START",
            markerEnd: "FIGMA COLORS MARKER END",
            themeName: "Theme.A"
        )
        var content = try String(contentsOf: attrsURL, encoding: .utf8)
        content = try updaterA.update(
            content: "    <attr name=\"colorPrimaryA\" format=\"color\" />",
            in: content,
            fileName: "attrs.xml"
        )

        // Update Theme.B
        let updaterB = MarkerFileUpdater(
            markerStart: "FIGMA COLORS MARKER START",
            markerEnd: "FIGMA COLORS MARKER END",
            themeName: "Theme.B"
        )
        content = try updaterB.update(
            content: "    <attr name=\"colorPrimaryB\" format=\"color\" />",
            in: content,
            fileName: "attrs.xml"
        )

        // Verify both themes have their content
        XCTAssertTrue(content.contains("colorPrimaryA"))
        XCTAssertTrue(content.contains("colorPrimaryB"))
        XCTAssertTrue(content.contains("<!-- FIGMA COLORS MARKER START: Theme.A -->"))
        XCTAssertTrue(content.contains("<!-- FIGMA COLORS MARKER END: Theme.A -->"))
        XCTAssertTrue(content.contains("<!-- FIGMA COLORS MARKER START: Theme.B -->"))
        XCTAssertTrue(content.contains("<!-- FIGMA COLORS MARKER END: Theme.B -->"))

        // Verify Theme.A content is between Theme.A markers
        let rangeA = try XCTUnwrap(content.range(of: "<!-- FIGMA COLORS MARKER START: Theme.A -->"))
        let rangeEndA = try XCTUnwrap(content.range(of: "<!-- FIGMA COLORS MARKER END: Theme.A -->"))
        let sectionA = String(content[rangeA.upperBound ..< rangeEndA.lowerBound])
        XCTAssertTrue(sectionA.contains("colorPrimaryA"))
        XCTAssertFalse(sectionA.contains("colorPrimaryB"))

        // Verify Theme.B content is between Theme.B markers
        let rangeB = try XCTUnwrap(content.range(of: "<!-- FIGMA COLORS MARKER START: Theme.B -->"))
        let rangeEndB = try XCTUnwrap(content.range(of: "<!-- FIGMA COLORS MARKER END: Theme.B -->"))
        let sectionB = String(content[rangeB.upperBound ..< rangeEndB.lowerBound])
        XCTAssertTrue(sectionB.contains("colorPrimaryB"))
        XCTAssertFalse(sectionB.contains("colorPrimaryA"))
    }

    func testTaskLocalStorageIsolation() {
        // Test that TaskLocal storage is properly isolated via BatchSharedState
        let collector = SharedThemeAttributesCollector()
        let batchState = BatchSharedState(
            context: BatchContext(),
            themeCollector: collector
        )

        // Run with collector in BatchSharedState
        BatchSharedState.$current.withValue(batchState) {
            // Inside this scope, collector should be accessible via shim
            let stored = SharedThemeAttributesStorage.collector
            XCTAssertNotNil(stored)
        }

        // Outside scope, should be nil
        let outside = SharedThemeAttributesStorage.collector
        XCTAssertNil(outside)
    }

    // MARK: - Helpers

    private func makeCollection(
        themeName: String,
        attrsContent: String = "    <attr name=\"colorTest\" format=\"color\" />",
        stylesContent: String = "        <item name=\"colorTest\">@color/test</item>"
    ) -> ThemeAttributesCollection {
        ThemeAttributesCollection(
            themeName: themeName,
            markerStart: "FIGMA COLORS MARKER START",
            markerEnd: "FIGMA COLORS MARKER END",
            attrsContent: attrsContent,
            stylesContent: stylesContent,
            attrsFile: URL(fileURLWithPath: "/tmp/attrs.xml"),
            stylesFile: URL(fileURLWithPath: "/tmp/styles.xml"),
            stylesNightFile: nil,
            autoCreateMarkers: false
        )
    }
}
