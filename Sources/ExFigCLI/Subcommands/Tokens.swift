import ArgumentParser

extension ExFigCommand {
    struct Tokens: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "tokens",
            abstract: "Work with local .tokens.json files (no config or Figma token needed)",
            subcommands: [TokensInfo.self, TokensConvert.self],
            defaultSubcommand: TokensInfo.self
        )
    }
}
