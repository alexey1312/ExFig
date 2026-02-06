import ArgumentParser
import FigmaAPI
import Foundation
import Logging
import Noora

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
            let p = { (s: String) in NooraUI.format(.primary(s)) }
            let url = NooraUI.formatLink(
                "https://github.com/alexey1312/ExFig/releases",
                useColors: true
            )

            let message = """

            \(p("╭\(border)"))
            \(p("│"))
            \(p("│"))   \(NooraUI.format(.success("🚀 Update Available: \(latestVersion)")))
            \(p("│"))      Current version: \(ExFigCommand.version)
            \(p("│"))
            \(p("│"))   To update, visit:
            \(p("│"))   \(url)
            \(p("│"))
            \(p("╰\(border)"))
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
