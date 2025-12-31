import ArgumentParser
import ExFigKit

/// Global CLI options shared across all subcommands
struct GlobalOptions: ParsableArguments {
    @Flag(name: .shortAndLong, help: "Show detailed output including debug information")
    var verbose: Bool = false

    @Flag(name: .shortAndLong, help: "Show only errors, suppress progress output")
    var quiet: Bool = false
}
