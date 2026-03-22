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

    @Flag(name: .shortAndLong, help: "Exit silently with code 0 even when thresholds exceeded")
    var quiet: Bool = false

    func validate() throws {
        let hasCLICondition = metric != nil || gte != nil || severity != nil || message != nil
        let isCompleteCLICondition = metric != nil && gte != nil && severity != nil && message != nil

        if hasCLICondition && !isCompleteCLICondition {
            throw ValidationError(
                "Simple CLI rules require --metric, --gte, --severity, and --message together."
            )
        }

        if config != nil && hasCLICondition {
            throw ValidationError("Use either --config or the simple CLI rule options, not both.")
        }
    }

    func run() throws {
        let ruleConfig = try resolveRuleConfig()
        let runner = CheckRunner(config: ruleConfig)
        let result = try runner.run()

        guard let match = result.match else {
            if ruleConfig.rules.isEmpty {
                logger.info("No rules configured.")
            } else {
                logger.info("All clear — no rules matched.")
            }
            return
        }

        logMatch(match)

        if match.severity == .error, !quiet {
            throw ExitCode.failure
        }
    }

    private func resolveRuleConfig() throws -> RuleConfig {
        if let metric, let gte, let severity, let message {
            return RuleConfig.singleRule(
                metric: metric.value,
                gte: gte,
                severity: severity.value,
                message: message
            )
        }

        let yamlPath = config ?? ConfigLoader.defaultFileName
        let yamlConfig = ConfigLoader.load(from: yamlPath)

        if config != nil, yamlConfig == nil {
            logger.warning("Config file not found: \(yamlPath)")
        }

        return yamlConfig ?? RuleConfig(rules: [])
    }

    private func logMatch(_ match: NagRule) {
        switch match.severity {
        case .info:
            logger.info("\(match.message)", metadata: .plainOutput)
        case .warning:
            logger.warning("\(match.message)", metadata: .plainOutput)
        case .error:
            logger.error("\(match.message)", metadata: .plainOutput)
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
