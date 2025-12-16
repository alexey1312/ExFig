@testable import ExFig
import XCTest

final class MarkerFileUpdaterTests: XCTestCase {
    // MARK: - Marker Properties

    func testFullStartMarker() {
        let updater = MarkerFileUpdater(
            markerStart: "FIGMA COLORS START",
            markerEnd: "FIGMA COLORS END",
            themeName: "Theme.App"
        )
        XCTAssertEqual(updater.fullStartMarker, "<!-- FIGMA COLORS START: Theme.App -->")
    }

    func testFullEndMarker() {
        let updater = MarkerFileUpdater(
            markerStart: "FIGMA COLORS START",
            markerEnd: "FIGMA COLORS END",
            themeName: "Theme.App"
        )
        XCTAssertEqual(updater.fullEndMarker, "<!-- FIGMA COLORS END: Theme.App -->")
    }

    // MARK: - Update Success Cases

    func testUpdateBetweenMarkers() throws {
        let updater = MarkerFileUpdater(
            markerStart: "FIGMA COLORS START",
            markerEnd: "FIGMA COLORS END",
            themeName: "Theme.App"
        )

        let existing = """
        <resources>
            <!-- FIGMA COLORS START: Theme.App -->
            <attr name="oldAttr" format="color" />
            <!-- FIGMA COLORS END: Theme.App -->
        </resources>
        """

        let newContent = "    <attr name=\"newAttr\" format=\"color\" />"

        let result = try updater.update(content: newContent, in: existing, fileName: "attrs.xml")

        XCTAssertTrue(result.contains("newAttr"))
        XCTAssertFalse(result.contains("oldAttr"))
        XCTAssertTrue(result.contains("<resources>"))
        XCTAssertTrue(result.contains("</resources>"))
        XCTAssertTrue(result.contains("<!-- FIGMA COLORS START: Theme.App -->"))
        XCTAssertTrue(result.contains("<!-- FIGMA COLORS END: Theme.App -->"))
    }

    func testPreservesContentOutsideMarkers() throws {
        let updater = MarkerFileUpdater(
            markerStart: "MARKER START",
            markerEnd: "MARKER END",
            themeName: "Test"
        )

        let existing = """
        <!-- Header comment -->
        <resources>
            <attr name="existingAttr" format="boolean" />
            <!-- MARKER START: Test -->
            <attr name="generated" format="color" />
            <!-- MARKER END: Test -->
            <attr name="anotherExisting" format="string" />
        </resources>
        <!-- Footer -->
        """

        let newContent = "    <attr name=\"newGenerated\" format=\"color\" />"

        let result = try updater.update(content: newContent, in: existing, fileName: "test.xml")

        XCTAssertTrue(result.contains("<!-- Header comment -->"))
        XCTAssertTrue(result.contains("existingAttr"))
        XCTAssertTrue(result.contains("anotherExisting"))
        XCTAssertTrue(result.contains("<!-- Footer -->"))
        XCTAssertTrue(result.contains("newGenerated"))
        XCTAssertFalse(result.contains("generated\" format=\"color\""))
    }

    func testEmptyContent() throws {
        let updater = MarkerFileUpdater(
            markerStart: "START",
            markerEnd: "END",
            themeName: "Theme"
        )

        let existing = """
        <resources>
            <!-- START: Theme -->
            old content
            <!-- END: Theme -->
        </resources>
        """

        let result = try updater.update(content: "", in: existing, fileName: "test.xml")

        XCTAssertTrue(result.contains("<!-- START: Theme -->"))
        XCTAssertTrue(result.contains("<!-- END: Theme -->"))
        XCTAssertFalse(result.contains("old content"))
    }

    func testMultipleThemeSections() throws {
        let updaterA = MarkerFileUpdater(
            markerStart: "FIGMA START",
            markerEnd: "FIGMA END",
            themeName: "ThemeA"
        )

        let updaterB = MarkerFileUpdater(
            markerStart: "FIGMA START",
            markerEnd: "FIGMA END",
            themeName: "ThemeB"
        )

        let existing = """
        <resources>
            <style name="ThemeA">
                <!-- FIGMA START: ThemeA -->
                <item name="oldA">value</item>
                <!-- FIGMA END: ThemeA -->
            </style>
            <style name="ThemeB">
                <!-- FIGMA START: ThemeB -->
                <item name="oldB">value</item>
                <!-- FIGMA END: ThemeB -->
            </style>
        </resources>
        """

        // Update ThemeA
        var result = try updaterA.update(
            content: "        <item name=\"newA\">value</item>",
            in: existing,
            fileName: "styles.xml"
        )

        XCTAssertTrue(result.contains("newA"))
        XCTAssertFalse(result.contains("oldA"))
        XCTAssertTrue(result.contains("oldB")) // ThemeB should be untouched

        // Update ThemeB
        result = try updaterB.update(
            content: "        <item name=\"newB\">value</item>",
            in: result,
            fileName: "styles.xml"
        )

        XCTAssertTrue(result.contains("newA"))
        XCTAssertTrue(result.contains("newB"))
        XCTAssertFalse(result.contains("oldA"))
        XCTAssertFalse(result.contains("oldB"))
    }

    // MARK: - Error Cases

    func testMarkerNotFoundStart() {
        let updater = MarkerFileUpdater(
            markerStart: "FIGMA START",
            markerEnd: "FIGMA END",
            themeName: "Theme.App"
        )

        let existing = """
        <resources>
            <!-- FIGMA END: Theme.App -->
        </resources>
        """

        XCTAssertThrowsError(try updater.update(content: "content", in: existing, fileName: "test.xml")) { error in
            guard let markerError = error as? MarkerFileUpdaterError else {
                XCTFail("Expected MarkerFileUpdaterError")
                return
            }
            if case let .markerNotFound(marker, file) = markerError {
                XCTAssertTrue(marker.contains("FIGMA START"))
                XCTAssertEqual(file, "test.xml")
            } else {
                XCTFail("Expected markerNotFound error")
            }
        }
    }

    func testMarkerNotFoundEnd() {
        let updater = MarkerFileUpdater(
            markerStart: "FIGMA START",
            markerEnd: "FIGMA END",
            themeName: "Theme.App"
        )

        let existing = """
        <resources>
            <!-- FIGMA START: Theme.App -->
        </resources>
        """

        XCTAssertThrowsError(try updater.update(content: "content", in: existing, fileName: "test.xml")) { error in
            guard let markerError = error as? MarkerFileUpdaterError else {
                XCTFail("Expected MarkerFileUpdaterError")
                return
            }
            if case let .markerNotFound(marker, _) = markerError {
                XCTAssertTrue(marker.contains("FIGMA END"))
            } else {
                XCTFail("Expected markerNotFound error")
            }
        }
    }

    func testMarkersOutOfOrder() {
        let updater = MarkerFileUpdater(
            markerStart: "START",
            markerEnd: "END",
            themeName: "Theme"
        )

        let existing = """
        <resources>
            <!-- END: Theme -->
            content
            <!-- START: Theme -->
        </resources>
        """

        XCTAssertThrowsError(try updater.update(content: "new", in: existing, fileName: "test.xml")) { error in
            guard let markerError = error as? MarkerFileUpdaterError else {
                XCTFail("Expected MarkerFileUpdaterError")
                return
            }
            if case let .markersOutOfOrder(file) = markerError {
                XCTAssertEqual(file, "test.xml")
            } else {
                XCTFail("Expected markersOutOfOrder error")
            }
        }
    }

    func testWrongThemeName() {
        let updater = MarkerFileUpdater(
            markerStart: "FIGMA START",
            markerEnd: "FIGMA END",
            themeName: "Theme.Other"
        )

        let existing = """
        <resources>
            <!-- FIGMA START: Theme.App -->
            content
            <!-- FIGMA END: Theme.App -->
        </resources>
        """

        XCTAssertThrowsError(try updater.update(content: "new", in: existing, fileName: "test.xml")) { error in
            guard case MarkerFileUpdaterError.markerNotFound = error else {
                XCTFail("Expected markerNotFound error")
                return
            }
        }
    }

    // MARK: - Template Creation

    func testCreateTemplate() {
        let updater = MarkerFileUpdater(
            markerStart: "FIGMA START",
            markerEnd: "FIGMA END",
            themeName: "Theme.App"
        )

        let template = """
        <?xml version="1.0" encoding="utf-8"?>
        <resources>
            {{START_MARKER}}
            {{END_MARKER}}
        </resources>
        """

        let result = updater.createTemplate(baseTemplate: template)

        XCTAssertTrue(result.contains("<!-- FIGMA START: Theme.App -->"))
        XCTAssertTrue(result.contains("<!-- FIGMA END: Theme.App -->"))
        XCTAssertFalse(result.contains("{{START_MARKER}}"))
        XCTAssertFalse(result.contains("{{END_MARKER}}"))
    }

    // MARK: - File Operations

    func testFileNotFound() throws {
        let updater = MarkerFileUpdater(
            markerStart: "START",
            markerEnd: "END",
            themeName: "Theme"
        )

        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/path/file.xml")

        XCTAssertThrowsError(try updater.update(content: "content", in: nonExistentURL)) { error in
            guard let markerError = error as? MarkerFileUpdaterError else {
                XCTFail("Expected MarkerFileUpdaterError")
                return
            }
            if case let .fileNotFound(path) = markerError {
                XCTAssertEqual(path, nonExistentURL.path)
            } else {
                XCTFail("Expected fileNotFound error")
            }
        }
    }

    func testAutoCreateWithTemplate() throws {
        let updater = MarkerFileUpdater(
            markerStart: "START",
            markerEnd: "END",
            themeName: "Theme"
        )

        let template = """
        <resources>
            <!-- START: Theme -->
            <!-- END: Theme -->
        </resources>
        """

        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/path/file.xml")

        let result = try updater.update(
            content: "content",
            in: nonExistentURL,
            autoCreate: true,
            templateContent: template
        )

        XCTAssertEqual(result, template)
    }

    // MARK: - Error Properties

    func testErrorDescription() {
        let notFound = MarkerFileUpdaterError.markerNotFound(marker: "<!-- START -->", file: "test.xml")
        XCTAssertTrue(notFound.errorDescription?.contains("not found") ?? false)

        let outOfOrder = MarkerFileUpdaterError.markersOutOfOrder(file: "test.xml")
        XCTAssertTrue(outOfOrder.errorDescription?.contains("after") ?? false)

        let fileNotFound = MarkerFileUpdaterError.fileNotFound(path: "/path/file.xml")
        XCTAssertTrue(fileNotFound.errorDescription?.contains("File not found") ?? false)
    }

    func testRecoverySuggestion() {
        let notFound = MarkerFileUpdaterError.markerNotFound(marker: "<!-- START -->", file: "test.xml")
        XCTAssertTrue(notFound.recoverySuggestion?.contains("Add marker") ?? false)

        let outOfOrder = MarkerFileUpdaterError.markersOutOfOrder(file: "test.xml")
        XCTAssertTrue(outOfOrder.recoverySuggestion?.contains("before") ?? false)

        let fileNotFound = MarkerFileUpdaterError.fileNotFound(path: "/path/file.xml")
        XCTAssertTrue(fileNotFound.recoverySuggestion?.contains("autoCreateMarkers") ?? false)
    }
}
