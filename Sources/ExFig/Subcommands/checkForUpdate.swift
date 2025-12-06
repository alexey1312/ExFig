import ArgumentParser
import FigmaAPI
import Foundation
import Logging

func checkForUpdate(logger: Logger) async {
    let client = GitHubClient()
    let endpoint = LatestReleaseEndpoint()
    guard let latestRelease = try? await client.request(endpoint) else {
        return
    }
    let latestVersion = latestRelease.tagName

    if ExFigCommand.version != latestVersion {
        logger.info("""

        ----------------------------------------------------------------------------
        exfig \(latestVersion) is available. You are on \(ExFigCommand.version).
        You should use the latest version.
        Please update using `mint install alexey1312/ExFig` or build from source.
        To see what's new, open https://github.com/alexey1312/ExFig/releases
        ----------------------------------------------------------------------------
        """)
    }
}
