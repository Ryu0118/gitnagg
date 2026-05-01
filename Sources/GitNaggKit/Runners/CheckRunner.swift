/// Outcome produced by CheckRunner.
package struct CheckRunResult: Equatable {
    /// The first matching nag rule, or `nil` when no rule matched.
    package let match: NagRule?
    /// The diff statistics collected from `git diff --stat`.
    package let stats: DiffStats
    /// Non-nil when the runner determined a non-zero exit code should be used.
    package let exitCode: Int32?
    /// Non-nil in hook mode when a rule matched and a hook payload was produced.
    package let hookOutput: ClaudeHookOutput?

    /// Creates a `CheckRunResult` with the given values.
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

    /// Creates a runner with the given validated input and diff provider.
    package init(
        input: CheckCommandInput,
        diffProvider: any GitDiffProvider = DefaultGitDiffProvider()
    ) {
        self.input = input
        self.diffProvider = diffProvider
    }

    /// Runs the check, logging output or emitting hook JSON, and throws ``CheckRunnerError`` on exit-code rules.
    package func run() throws -> CheckRunResult {
        if input.hookMode != .none {
            return runHook()
        }

        let result = try evaluate()
        log(result)

        if let exitCode = result.exitCode {
            throw CheckRunnerError.exitCode(exitCode)
        }

        return result
    }

    /// Collects diff stats, evaluates rules, and returns the result without side-effects (no logging, no exit).
    package func evaluate() throws -> CheckRunResult {
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

    private func runHook() -> CheckRunResult {
        do {
            let result = try evaluate()
            if let output = result.hookOutput {
                logger.notice("\(output.jsonString)", metadata: .stdoutOutput)
            }
            return result
        } catch {
            return CheckRunResult(
                match: nil,
                stats: DiffStats(added: 0, deleted: 0, filesChanged: 0),
                exitCode: nil,
                hookOutput: nil
            )
        }
    }

    private func log(_ result: CheckRunResult) {
        guard let match = result.match else {
            logNoMatch()
            return
        }

        match.logMatch()
    }

    private func logNoMatch() {
        guard !input.quiet else { return }

        if input.ruleConfig.rules.isEmpty {
            logger.info("No rules configured.")
        } else {
            logger.info("All clear — no rules matched.")
        }
    }

    private func evaluate(stats: DiffStats) -> NagRule? {
        switch input.ruleConfig.resolution {
        case .firstMatch:
            input.ruleConfig.rules.first { $0.when.matches(stats) }
        }
    }
}

/// Errors thrown by ``CheckRunner/run()``.
package enum CheckRunnerError: Error, Equatable {
    case exitCode(Int32)
}
