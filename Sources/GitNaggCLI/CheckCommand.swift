import ArgumentParser
import GitNaggKit

/// Checks uncommitted changes against configured nag rules.
struct CheckCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "check",
        abstract: "Check if uncommitted changes match configured nag rules"
    )

    @Option(name: .long, help: "Path to YAML config file (default: .gitnagg.yml)")
    var config: String?

    @Option(name: .long, help: "Simple CLI rule metric: added, deleted, or files")
    var metric: MetricOption?

    @Option(name: .long, help: "Simple CLI rule threshold using >= comparison")
    var gte: Int?

    @Option(name: .long, help: "Simple CLI rule severity: info, warning, or error")
    var severity: SeverityOption?

    @Option(name: .long, help: "Simple CLI rule message")
    var message: String?

    @Flag(name: .shortAndLong, help: "Suppress informational output and exit with code 0 even when thresholds exceeded")
    var quiet: Bool = false

    @Flag(
        name: .long,
        help: "Emit Claude Code hook JSON to stdout and always exit 0. Mutually exclusive with --codex-hook."
    )
    var claudeHook: Bool = false

    @Flag(
        name: .long,
        help: "Emit Codex PostToolUse hook JSON to stdout and always exit 0. Mutually exclusive with --claude-hook."
    )
    var codexHook: Bool = false

    func validate() throws {
        let hasCLICondition = metric != nil || gte != nil || severity != nil || message != nil
        let isCompleteCLICondition = metric != nil && gte != nil && severity != nil && message != nil

        if hasCLICondition, !isCompleteCLICondition {
            throw ValidationError(
                "Simple CLI rules require --metric, --gte, --severity, and --message together."
            )
        }

        if config != nil, hasCLICondition {
            throw ValidationError("Use either --config or the simple CLI rule options, not both.")
        }

        if claudeHook, codexHook {
            throw ValidationError("--claude-hook and --codex-hook are mutually exclusive.")
        }

        if claudeHook, quiet {
            throw ValidationError("--claude-hook and --quiet are mutually exclusive.")
        }

        if codexHook, quiet {
            throw ValidationError("--codex-hook and --quiet are mutually exclusive.")
        }
    }

    func run() throws {
        try execute(diffProvider: DefaultGitDiffProvider())
    }

    func execute(diffProvider: any GitDiffProvider) throws {
        let hookMode: HookMode = claudeHook ? .claude : codexHook ? .codex : .none
        do {
            let input = try CheckArgumentsValidator(
                metric: metric?.value,
                gte: gte,
                severity: severity?.value,
                message: message,
                config: config,
                quiet: quiet,
                hookMode: hookMode
            ).validate()

            _ = try CheckRunner(input: input, diffProvider: diffProvider).run()
        } catch let error as CheckRunnerError {
            switch error {
            case let .exitCode(exitCode):
                throw ExitCode(exitCode)
            }
        } catch {
            if hookMode != .none { return }
            throw error
        }
    }
}

enum MetricOption: String, ExpressibleByArgument {
    case added
    case deleted
    case files

    var value: DiffMetric {
        switch self {
        case .added:
            .added
        case .deleted:
            .deleted
        case .files:
            .files
        }
    }
}

enum SeverityOption: String, ExpressibleByArgument {
    case info
    case warning
    case error

    var value: RuleSeverity {
        switch self {
        case .info:
            .info
        case .warning:
            .warning
        case .error:
            .error
        }
    }
}
