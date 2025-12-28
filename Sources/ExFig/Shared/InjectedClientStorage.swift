import ExFigKit
import FigmaAPI

/// Storage for injected Figma API client using Swift's TaskLocal mechanism.
///
/// This is used by batch processing to share a single rate-limited client across
/// multiple subcommand executions. When running individual commands (not in batch mode),
/// the client is `nil` and commands create their own clients.
///
/// ## Usage in Batch Mode
///
/// ```swift
/// try await InjectedClientStorage.$client.withValue(rateLimitedClient) {
///     // All subcommands executed here will use the injected client
///     try await colorsCommand.run()
///     try await iconsCommand.run()
/// }
/// ```
///
/// ## Usage in Subcommands
///
/// ```swift
/// let client = InjectedClientStorage.client ?? createNewClient()
/// ```
enum InjectedClientStorage {
    @TaskLocal static var client: Client?
}
