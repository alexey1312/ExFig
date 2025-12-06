import Foundation
#if os(Linux)
    import FoundationNetworking
#endif

public final class FigmaClient: BaseClient, @unchecked Sendable {
    // swiftlint:disable:next force_unwrapping
    private static let figmaBaseURL = URL(string: "https://api.figma.com/v1/")!

    public init(accessToken: String, timeout: TimeInterval?) {
        let config = URLSessionConfiguration.ephemeral
        config.httpAdditionalHeaders = ["X-Figma-Token": accessToken]
        config.timeoutIntervalForRequest = timeout ?? 30
        super.init(baseURL: Self.figmaBaseURL, config: config)
    }
}
