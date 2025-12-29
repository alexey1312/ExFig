import ArgumentParser
import FigmaAPI
import Foundation
import Logging
import Rainbow

func checkForUpdate(logger: Logger) async {
    let client = GitHubClient()
    let endpoint = LatestReleaseEndpoint()
    guard let latestRelease = try? await client.request(endpoint) else {
        return
    }
    let latestVersion = latestRelease.tagName

    if ExFigCommand.version != latestVersion {
        if TTYDetector.colorsEnabled {
            let border = "──────────────────────────────────────────────────────────────"

            let message = """

            \("╭\(border)".cyan)
            \("│".cyan)
            \("│".cyan)   \("🚀 Update Available: \(latestVersion)".bold.green)
            \("│".cyan)      Current version: \(ExFigCommand.version)
            \("│".cyan)
            \("│".cyan)   To update, visit:
            \("│".cyan)   \("https://github.com/alexey1312/ExFig/releases".blue.underline)
            \("│".cyan)
            \("╰\(border)".cyan)
            """
            logger.info(Logger.Message(stringLiteral: message))
        } else {
            logger.info("""

            ----------------------------------------------------------------------------
            exfig \(latestVersion) is available. You are on \(ExFigCommand.version).
            You should use the latest version.
            To update, visit https://github.com/alexey1312/ExFig/releases
            ----------------------------------------------------------------------------
            """)
        }
    }
}
