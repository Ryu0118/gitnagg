/// Outcome produced by CheckRunner.
package struct CheckRunResult: Equatable {
    package let match: NagRule?
    package let stats: DiffStats
    package let exitCode: Int32?
    package let hookOutput: ClaudeHookOutput?

    package init(match: NagRule?, stats: DiffStats, exitCode: Int32?, hookOutput: ClaudeHookOutput?) {
        self.match = match
        self.stats = stats
        self.exitCode = exitCode
        self.hookOutput = hookOutput
    }
}

/// Evaluates git diff stats against configured ordered rules.
package struct CheckRunner {
    private let diffProvider: any GitDiffProvider
    private let input: CheckCommandInput

    package init(
        input: CheckCommandInput,
        diffProvider: any GitDiffProvider = DefaultGitDiffProvider()
    ) {
        self.input = input
        self.diffProvider = diffProvider
    }

    package func run() throws -> CheckRunResult {
        let stats = try diffProvider.diffStats()
        let match = evaluate(stats: stats)

        switch input.hookMode {
        case .claude, .codex:
            let hookOutput = match.map { ClaudeHookOutput(reason: $0.message) }
            return CheckRunResult(match: match, stats: stats, exitCode: nil, hookOutput: hookOutput)
        case .none:
            let exitCode: Int32? = (match?.severity == .error && !input.quiet) ? input.ruleConfig.exitCode : nil
            return CheckRunResult(match: match, stats: stats, exitCode: exitCode, hookOutput: nil)
        }
    }

    private func evaluate(stats: DiffStats) -> NagRule? {
        switch input.ruleConfig.resolution {
        case .firstMatch:
            input.ruleConfig.rules.first { $0.when.matches(stats) }
        }
    }
}
