import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Endpoint to fetch file metadata (version, lastModified) without the full document tree.
/// Uses depth=1 to minimize response size.
public struct FileMetadataEndpoint: BaseEndpoint {
    public typealias Content = FileMetadata

    private let fileId: String

    public init(fileId: String) {
        self.fileId = fileId
    }

    public func makeRequest(baseURL: URL) throws -> URLRequest {
        let url = baseURL
            .appendingPathComponent("files")
            .appendingPathComponent(fileId)

        var comps = URLComponents(url: url, resolvingAgainstBaseURL: true)
        // depth=1 returns only the top-level document node, minimizing response size
        comps?.queryItems = [
            URLQueryItem(name: "depth", value: "1"),
        ]
        guard let components = comps, let url = components.url else {
            throw URLError(
                .badURL, userInfo: [NSLocalizedDescriptionKey: "Invalid URL components for FileMetadataEndpoint"]
            )
        }
        return URLRequest(url: url)
    }
}

// MARK: - Response Model

/// File metadata returned by Figma API.
/// Contains version information used for change tracking.
public struct FileMetadata: Decodable, Sendable {
    /// The name of the file.
    public let name: String

    /// Timestamp of the last modification (ISO 8601 format).
    /// Note: This updates on ANY change, including auto-saves.
    public let lastModified: String

    /// Version identifier of the file.
    /// Changes when the library is published or a version is manually saved.
    public let version: String

    /// URL to the file's thumbnail.
    public let thumbnailUrl: String?

    /// The editor type (figma or figjam).
    public let editorType: String?
}
