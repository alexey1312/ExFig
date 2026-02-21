@testable import ExFigCore
import Foundation
import XCTest

final class DestinationTests: XCTestCase {
    func testURL() throws {
        let directory = URL(fileURLWithPath: "/output/images")
        let file = try XCTUnwrap(URL(string: "icon.png"))
        let destination = Destination(directory: directory, file: file)

        XCTAssertEqual(destination.url.path, "/output/images/icon.png")
    }

    func testURLWithSubdirectoryPath() throws {
        let directory = URL(fileURLWithPath: "/output/lib")
        let file = try XCTUnwrap(URL(string: "icons/actions.dart"))
        let destination = Destination(directory: directory, file: file)

        XCTAssertEqual(destination.url.path, "/output/lib/icons/actions.dart")
    }

    func testURLWithDeepSubdirectoryPath() throws {
        let directory = URL(fileURLWithPath: "/output/lib")
        let file = try XCTUnwrap(URL(string: "src/icons/actions.dart"))
        let destination = Destination(directory: directory, file: file)

        XCTAssertEqual(destination.url.path, "/output/lib/src/icons/actions.dart")
    }

    func testURLPreservesSimpleFileURLPath() {
        let directory = URL(fileURLWithPath: "/output/images")
        let file = URL(fileURLWithPath: "icon.png")
        let destination = Destination(directory: directory, file: file)

        XCTAssertEqual(destination.url.lastPathComponent, "icon.png")
    }

    func testEquality() {
        let dest1 = Destination(
            directory: URL(fileURLWithPath: "/output"),
            file: URL(fileURLWithPath: "file.png")
        )
        let dest2 = Destination(
            directory: URL(fileURLWithPath: "/output"),
            file: URL(fileURLWithPath: "file.png")
        )

        XCTAssertEqual(dest1, dest2)
    }
}

final class FileContentsTests: XCTestCase {
    // MARK: - In-Memory File Init

    func testInMemoryFileInit() {
        let destination = makeDestination(file: "test.png")
        let data = Data("test content".utf8)

        let contents = FileContents(destination: destination, data: data)

        XCTAssertEqual(contents.data, data)
        XCTAssertNil(contents.dataFile)
        XCTAssertNil(contents.sourceURL)
        XCTAssertEqual(contents.scale, 1.0)
        XCTAssertFalse(contents.dark)
        XCTAssertFalse(contents.isRTL)
    }

    func testInMemoryFileInitWithAllParameters() {
        let destination = makeDestination(file: "test.png")
        let data = Data("test".utf8)

        let contents = FileContents(
            destination: destination,
            data: data,
            scale: 2.0,
            dark: true,
            isRTL: true
        )

        XCTAssertEqual(contents.scale, 2.0)
        XCTAssertTrue(contents.dark)
        XCTAssertTrue(contents.isRTL)
    }

    // MARK: - Remote File Init

    func testRemoteFileInit() throws {
        let destination = makeDestination(file: "image.png")
        // swiftlint:disable:next force_unwrapping
        let sourceURL = try XCTUnwrap(URL(string: "https://figma.com/image.png"))

        let contents = FileContents(destination: destination, sourceURL: sourceURL)

        XCTAssertEqual(contents.sourceURL, sourceURL)
        XCTAssertNil(contents.data)
        XCTAssertNil(contents.dataFile)
        XCTAssertEqual(contents.scale, 1.0)
        XCTAssertFalse(contents.dark)
        XCTAssertFalse(contents.isRTL)
    }

    func testRemoteFileInitWithAllParameters() throws {
        let destination = makeDestination(file: "image.png")
        // swiftlint:disable:next force_unwrapping
        let sourceURL = try XCTUnwrap(URL(string: "https://figma.com/image.png"))

        let contents = FileContents(
            destination: destination,
            sourceURL: sourceURL,
            scale: 3.0,
            dark: true,
            isRTL: true
        )

        XCTAssertEqual(contents.scale, 3.0)
        XCTAssertTrue(contents.dark)
        XCTAssertTrue(contents.isRTL)
    }

    // MARK: - On-Disk File Init

    func testOnDiskFileInit() {
        let destination = makeDestination(file: "icon.png")
        let dataFile = URL(fileURLWithPath: "/tmp/cached/icon.png")

        let contents = FileContents(destination: destination, dataFile: dataFile)

        XCTAssertEqual(contents.dataFile, dataFile)
        XCTAssertNil(contents.data)
        XCTAssertNil(contents.sourceURL)
        XCTAssertEqual(contents.scale, 1.0)
        XCTAssertFalse(contents.dark)
        XCTAssertFalse(contents.isRTL)
    }

    func testOnDiskFileInitWithAllParameters() {
        let destination = makeDestination(file: "icon.png")
        let dataFile = URL(fileURLWithPath: "/tmp/cached/icon.png")

        let contents = FileContents(
            destination: destination,
            dataFile: dataFile,
            scale: 2.0,
            dark: true,
            isRTL: true
        )

        XCTAssertEqual(contents.scale, 2.0)
        XCTAssertTrue(contents.dark)
        XCTAssertTrue(contents.isRTL)
    }

    // MARK: - Changing Extension

    func testChangingExtensionForInMemoryFile() {
        let destination = makeDestination(file: "image.png")
        let data = Data("test".utf8)
        let contents = FileContents(destination: destination, data: data, scale: 2.0, dark: true)

        let webpContents = contents.changingExtension(newExtension: "webp")

        XCTAssertTrue(webpContents.destination.file.path.hasSuffix(".webp"))
        XCTAssertEqual(webpContents.data, data)
        XCTAssertEqual(webpContents.scale, 2.0)
        XCTAssertTrue(webpContents.dark)
    }

    func testChangingExtensionForRemoteFile() throws {
        let destination = makeDestination(file: "image.png")
        // swiftlint:disable:next force_unwrapping
        let sourceURL = try XCTUnwrap(URL(string: "https://figma.com/image.png"))
        let contents = FileContents(destination: destination, sourceURL: sourceURL, scale: 3.0, dark: true)

        let webpContents = contents.changingExtension(newExtension: "webp")

        XCTAssertTrue(webpContents.destination.file.path.hasSuffix(".webp"))
        XCTAssertEqual(webpContents.sourceURL, sourceURL)
        XCTAssertEqual(webpContents.scale, 3.0)
        XCTAssertTrue(webpContents.dark)
    }

    func testChangingExtensionForOnDiskFile() {
        let destination = makeDestination(file: "image.png")
        let dataFile = URL(fileURLWithPath: "/tmp/image.png")
        let contents = FileContents(destination: destination, dataFile: dataFile, scale: 1.5, dark: false)

        let webpContents = contents.changingExtension(newExtension: "webp")

        XCTAssertTrue(webpContents.destination.file.path.hasSuffix(".webp"))
        // dataFile extension is also updated to match the new destination extension
        XCTAssertEqual(webpContents.dataFile, URL(fileURLWithPath: "/tmp/image.webp"))
        XCTAssertEqual(webpContents.scale, 1.5)
        XCTAssertFalse(webpContents.dark)
    }

    // MARK: - Stripping Scale Suffix

    func testStrippingScaleSuffixFromInMemoryFile() {
        let destination = makeDestination(file: "icon@2x.png")
        let data = Data("png".utf8)
        let contents = FileContents(destination: destination, data: data, scale: 2.0, dark: true)

        let stripped = contents.strippingScaleSuffix()

        XCTAssertEqual(stripped.destination.file.lastPathComponent, "icon.png")
        XCTAssertEqual(stripped.data, data)
        XCTAssertNil(stripped.dataFile)
        XCTAssertEqual(stripped.scale, 2.0)
        XCTAssertTrue(stripped.dark)
    }

    func testStrippingScaleSuffixFromOnDiskFile() {
        let destination = makeDestination(file: "icon@3x.png")
        let dataFile = URL(fileURLWithPath: "/tmp/icon@3x.png")
        let contents = FileContents(destination: destination, dataFile: dataFile, scale: 3.0, dark: false)

        let stripped = contents.strippingScaleSuffix()

        XCTAssertEqual(stripped.destination.file.lastPathComponent, "icon.png")
        XCTAssertEqual(stripped.dataFile, dataFile)
        XCTAssertEqual(stripped.scale, 3.0)
    }

    func testStrippingScaleSuffixFromRemoteFile() throws {
        let destination = makeDestination(file: "icon@2x.webp")
        let sourceURL = try XCTUnwrap(URL(string: "https://figma.com/icon.webp"))
        let contents = FileContents(destination: destination, sourceURL: sourceURL, scale: 2.0)

        let stripped = contents.strippingScaleSuffix()

        XCTAssertEqual(stripped.destination.file.lastPathComponent, "icon.webp")
        XCTAssertEqual(stripped.sourceURL, sourceURL)
    }

    func testStrippingScaleSuffixNoSuffix() {
        let destination = makeDestination(file: "icon.png")
        let data = Data("png".utf8)
        let contents = FileContents(destination: destination, data: data)

        let stripped = contents.strippingScaleSuffix()

        XCTAssertEqual(stripped.destination.file.lastPathComponent, "icon.png")
    }

    // MARK: - URL.strippingScaleSuffix

    func testURLStrippingScaleSuffix2x() {
        let url = URL(fileURLWithPath: "icon@2x.png")
        XCTAssertEqual(url.strippingScaleSuffix().lastPathComponent, "icon.png")
    }

    func testURLStrippingScaleSuffix3x() {
        let url = URL(fileURLWithPath: "arrow@3x.webp")
        XCTAssertEqual(url.strippingScaleSuffix().lastPathComponent, "arrow.webp")
    }

    func testURLStrippingScaleSuffixNoSuffix() {
        let url = URL(fileURLWithPath: "logo.svg")
        XCTAssertEqual(url.strippingScaleSuffix().lastPathComponent, "logo.svg")
    }

    func testURLStrippingScaleSuffixPreservesExtension() {
        let url = URL(fileURLWithPath: "photo@2x.heic")
        XCTAssertEqual(url.strippingScaleSuffix().lastPathComponent, "photo.heic")
    }

    func testURLStrippingScaleSuffixAtSignInName() {
        let url = URL(fileURLWithPath: "user@home.png")
        XCTAssertEqual(url.strippingScaleSuffix().lastPathComponent, "user@home.png")
    }

    // MARK: - Path Traversal Sanitization

    func testURLSanitizesParentDirectoryTraversal() throws {
        let directory = URL(fileURLWithPath: "/output/images")
        let file = try XCTUnwrap(URL(string: "../../etc/passwd"))
        let destination = Destination(directory: directory, file: file)

        XCTAssertEqual(destination.url.path, "/output/images/etc/passwd")
    }

    func testURLSanitizesDotComponents() throws {
        let directory = URL(fileURLWithPath: "/output/images")
        let file = try XCTUnwrap(URL(string: "./icon.png"))
        let destination = Destination(directory: directory, file: file)

        XCTAssertEqual(destination.url.path, "/output/images/icon.png")
    }

    func testURLSanitizesMultipleTraversalSegments() throws {
        let directory = URL(fileURLWithPath: "/output/images")
        let file = try XCTUnwrap(URL(string: "a/../../../secret.txt"))
        let destination = Destination(directory: directory, file: file)

        XCTAssertEqual(destination.url.path, "/output/images/a/secret.txt")
    }

    func testURLSanitizesEmptySegments() throws {
        let directory = URL(fileURLWithPath: "/output/images")
        let file = try XCTUnwrap(URL(string: "a//b///c.png"))
        let destination = Destination(directory: directory, file: file)

        XCTAssertEqual(destination.url.path, "/output/images/a/b/c.png")
    }

    func testURLPreservesPathAfterFileURLTraversal() {
        let directory = URL(fileURLWithPath: "/output/images")
        // fileURL with "../" — uses lastPathComponent, so only the filename matters
        let file = URL(fileURLWithPath: "../icon.png")
        let destination = Destination(directory: directory, file: file)

        XCTAssertEqual(destination.url.lastPathComponent, "icon.png")
    }

    // MARK: - Equatable

    func testEquality() {
        let destination = makeDestination(file: "test.png")
        let data = Data("test".utf8)

        let contents1 = FileContents(destination: destination, data: data)
        let contents2 = FileContents(destination: destination, data: data)

        XCTAssertEqual(contents1, contents2)
    }

    // MARK: - Helpers

    private func makeDestination(file: String) -> Destination {
        Destination(
            directory: URL(fileURLWithPath: "/output"),
            file: URL(fileURLWithPath: file)
        )
    }
}
