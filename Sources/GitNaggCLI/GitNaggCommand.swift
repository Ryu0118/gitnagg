import ArgumentParser
import GitNaggKit

/// Root command for the `gitnagg` CLI.
@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
public struct GitNaggCommand: AsyncParsableCommand {
    /// ArgumentParser configuration: name, abstract, version, and subcommands.
    public static let configuration = CommandConfiguration(
        commandName: "gitnagg",
        abstract: "Nag you to commit when uncommitted changes exceed thresholds",
        version: GitNaggVersion.current,
        subcommands: [CheckCommand.self],
        defaultSubcommand: CheckCommand.self
    )

    /// Creates a new instance of `GitNaggCommand`.
    public init() {}
}
