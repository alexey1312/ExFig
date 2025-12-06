import Foundation
#if os(Linux)
    import FoundationNetworking
#endif

public final class GitHubClient: BaseClient, @unchecked Sendable {
    // swiftlint:disable:next force_unwrapping
    private static let gitHubBaseURL = URL(string: "https://api.github.com/")!

    public init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        super.init(baseURL: Self.gitHubBaseURL, config: config)
    }
}
