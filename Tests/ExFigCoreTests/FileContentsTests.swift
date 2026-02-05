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
