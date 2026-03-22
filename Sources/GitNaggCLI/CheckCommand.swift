import ArgumentParser
import GitNaggKit

/// Checks uncommitted changes against thresholds and exits non-zero when exceeded.
///
/// Threshold resolution order:
/// 1. CLI options (`--added`, `--deleted`, `--files`)
/// 2. YAML config file (`.gitnagg.yml` or `--config <path>`)
/// 3. Built-in defaults (100, 100, 3)
struct CheckCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "check",
        abstract: "Check if uncommitted changes exceed thresholds"
    )

    @Option(name: .long, help: "Path to YAML config file (default: .gitnagg.yml)")
    var config: String?

    @Option(name: .long, help: "Max added lines before nagging")
    var added: Int?

    @Option(name: .long, help: "Max deleted lines before nagging")
    var deleted: Int?

    @Option(name: .long, help: "Max changed files before nagging")
    var files: Int?

    @Flag(name: .shortAndLong, help: "Exit silently with code 0 even when thresholds exceeded")
    var quiet: Bool = false

    func run() throws {
        bootstrapLogging()

        let yamlPath = config ?? ConfigLoader.defaultFileName
        let yamlConfig = ConfigLoader.load(from: yamlPath)

        if config != nil, yamlConfig == nil {
            logger.warning("Config file not found: \(yamlPath)")
        }

        let resolved = ConfigLoader.merge(
            yamlConfig: yamlConfig,
            cliAdded: added,
            cliDeleted: deleted,
            cliFiles: files
        )

        let runner = CheckRunner(config: resolved)
        let result = try runner.run()

        if let message = NagFormatter.format(result) {
            logger.warning("\(message)")
            if !quiet {
                throw ExitCode.failure
            }
        } else {
            logger.info("All clear — changes are within thresholds.")
        }
    }
}
