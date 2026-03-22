/// Evaluates git diff stats against configured ordered rules.
package struct CheckRunner {
    private let diffProvider: any GitDiffProvider
    private let config: RuleConfig

    /// Production initializer with default implementations.
    package init(
        config: RuleConfig = RuleConfig(rules: []),
        diffProvider: any GitDiffProvider = DefaultGitDiffProvider()
    ) {
        self.config = config
        self.diffProvider = diffProvider
    }

    /// Runs the rule check and returns the result.
    package func run() throws -> CheckResult {
        let stats = try diffProvider.diffStats()
        let match = evaluate(stats: stats)
        return CheckResult(match: match, stats: stats)
    }

    /// Selects the matching rule according to the configured resolution mode.
    private func evaluate(stats: DiffStats) -> NagRule? {
        switch config.resolution {
        case .firstMatch:
            config.rules.first { $0.when.matches(stats) }
        }
    }
}
