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

package enum CheckRunnerError: Error, Equatable {
    case exitCode(Int32)
}
