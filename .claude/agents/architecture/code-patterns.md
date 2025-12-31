# Code Patterns

## Adding a CLI Command

1. Create `Sources/ExFig/Subcommands/NewCommand.swift` implementing `AsyncParsableCommand`
2. Register in `ExFigCommand.swift` subcommands array
3. Use `@OptionGroup` for shared options (`GlobalOptions`, `CacheOptions`)
4. Use `TerminalUI` for progress: `try await ui.withSpinner("Loading...") { ... }`

Example structure:

```swift
import ArgumentParser

struct NewCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "new",
        abstract: "Description of the command"
    )

    @OptionGroup
    var globalOptions: GlobalOptions

    @OptionGroup
    var faultToleranceOptions: FaultToleranceOptions

    func run() async throws {
        let ui = TerminalUI(quiet: globalOptions.quiet)
        // Implementation
    }
}
```

## Adding a Figma API Endpoint

1. Create endpoint in `Sources/FigmaAPI/Endpoint/`
2. Add response models in `Sources/FigmaAPI/Model/`
3. Add method to `FigmaClient.swift`

Example endpoint:

```swift
struct NewEndpoint: FigmaEndpoint {
    typealias Response = NewResponse

    let fileId: String

    var path: String { "/v1/files/\(fileId)/new" }
    var method: HTTPMethod { .get }
}
```

## Modifying Generated Code

Templates are in `Sources/*/Resources/`. Use Stencil syntax. Update tests after changes.

Key template locations:

| Module          | Templates                                |
| --------------- | ---------------------------------------- |
| `XcodeExport`   | Swift extensions, asset catalog helpers  |
| `AndroidExport` | XML resources, Compose code, Kotlin      |
| `FlutterExport` | Dart code, theme extensions              |
