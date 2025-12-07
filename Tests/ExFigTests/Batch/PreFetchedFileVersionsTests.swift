@testable import ExFig
@testable import FigmaAPI
import XCTest

final class PreFetchedFileVersionsTests: XCTestCase {
    // MARK: - Basic Operations

    func testEmptyStorageReturnsNilForAnyId() {
        let storage = PreFetchedFileVersions(versions: [:])

        XCTAssertNil(storage.metadata(for: "any-file-id"))
    }

    func testReturnsMetadataForKnownId() {
        let metadata = FileMetadata.make(name: "Test File", version: "123")
        let storage = PreFetchedFileVersions(versions: ["file-1": metadata])

        let result = storage.metadata(for: "file-1")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Test File")
        XCTAssertEqual(result?.version, "123")
    }

    func testReturnsNilForUnknownId() {
        let metadata = FileMetadata.make(name: "Test", version: "1")
        let storage = PreFetchedFileVersions(versions: ["file-1": metadata])

        XCTAssertNil(storage.metadata(for: "unknown-id"))
    }

    func testHasMetadataReturnsTrueForKnownId() {
        let metadata = FileMetadata.make(name: "Test", version: "1")
        let storage = PreFetchedFileVersions(versions: ["file-1": metadata])

        XCTAssertTrue(storage.hasMetadata(for: "file-1"))
    }

    func testHasMetadataReturnsFalseForUnknownId() {
        let storage = PreFetchedFileVersions(versions: [:])

        XCTAssertFalse(storage.hasMetadata(for: "unknown"))
    }

    func testCountReturnsCorrectNumber() {
        let storage1 = PreFetchedFileVersions(versions: [:])
        let storage2 = PreFetchedFileVersions(versions: [
            "file-1": FileMetadata.make(name: "F1", version: "1"),
            "file-2": FileMetadata.make(name: "F2", version: "2"),
            "file-3": FileMetadata.make(name: "F3", version: "3"),
        ])

        XCTAssertEqual(storage1.count, 0)
        XCTAssertEqual(storage2.count, 3)
    }

    // MARK: - Multiple Files

    func testHandlesMultipleFiles() {
        let storage = PreFetchedFileVersions(versions: [
            "light-file": FileMetadata.make(name: "Light", version: "100"),
            "dark-file": FileMetadata.make(name: "Dark", version: "200"),
        ])

        XCTAssertEqual(storage.metadata(for: "light-file")?.name, "Light")
        XCTAssertEqual(storage.metadata(for: "dark-file")?.name, "Dark")
        XCTAssertNil(storage.metadata(for: "other-file"))
    }
}

// MARK: - Test Helper

extension FileMetadata {
    static func make(
        name: String = "Test File",
        version: String = "1",
        lastModified: String = "2024-01-01T00:00:00Z"
    ) -> FileMetadata {
        let json = """
        {
            "name": "\(name)",
            "version": "\(version)",
            "lastModified": "\(lastModified)"
        }
        """
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(FileMetadata.self, from: Data(json.utf8))
    }
}
