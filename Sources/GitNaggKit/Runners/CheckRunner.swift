/// Evaluates git diff stats against configured thresholds and produces a nag result.
package struct CheckRunner {
    private let diffProvider: any GitDiffProvider
    private let config: ThresholdConfig

    /// Production initializer with default implementations.
    package init(
        config: ThresholdConfig = ThresholdConfig(),
        diffProvider: any GitDiffProvider = DefaultGitDiffProvider()
    ) {
        self.config = config
        self.diffProvider = diffProvider
    }

    /// Runs the threshold check and returns the result.
    package func run() throws -> NagResult {
        let stats = try diffProvider.diffStats()
        let violations = evaluate(stats: stats)
        return NagResult(violations: violations, stats: stats)
    }

    /// Compares each threshold against the actual diff stats.
    private func evaluate(stats: DiffStats) -> [Violation] {
        var violations: [Violation] = []

        if let threshold = config.added, stats.added >= threshold {
            violations.append(Violation(kind: .added, actual: stats.added, threshold: threshold))
        }
        if let threshold = config.deleted, stats.deleted >= threshold {
            violations.append(Violation(kind: .deleted, actual: stats.deleted, threshold: threshold))
        }
        if let threshold = config.filesChanged, stats.filesChanged >= threshold {
            violations.append(
                Violation(kind: .filesChanged, actual: stats.filesChanged, threshold: threshold)
            )
        }

        return violations
    }
}
