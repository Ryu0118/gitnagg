@testable import GitNaggKit
import Testing

/// Parameterized scenario for `CheckRunner` rule evaluation.
struct CheckScenario: CustomTestStringConvertible {
    let label: String
    let stats: DiffStats
    let config: RuleConfig
    let expectedMatch: NagRule?

    var testDescription: String {
        label
    }
}

@Suite
struct CheckRunnerTests {
    static let scenarios: [CheckScenario] = [
        CheckScenario(
            label: "no match when no rule condition is met",
            stats: DiffStats(added: 50, deleted: 30, filesChanged: 2),
            config: RuleConfig(
                rules: [
                    NagRule(
                        severity: .warning,
                        message: "Commit soon.",
                        when: .metric(MetricCondition(metric: .added, gte: 100))
                    ),
                ]
            ),
            expectedMatch: nil
        ),
        CheckScenario(
            label: "single metric rule matches",
            stats: DiffStats(added: 150, deleted: 10, filesChanged: 1),
            config: RuleConfig(
                rules: [
                    NagRule(
                        severity: .warning,
                        message: "Commit soon.",
                        when: .metric(MetricCondition(metric: .added, gte: 100))
                    ),
                ]
            ),
            expectedMatch: NagRule(
                severity: .warning,
                message: "Commit soon.",
                when: .metric(MetricCondition(metric: .added, gte: 100))
            )
        ),
        CheckScenario(
            label: "and rule matches only when all conditions are met",
            stats: DiffStats(added: 120, deleted: 55, filesChanged: 3),
            config: RuleConfig(
                rules: [
                    NagRule(
                        severity: .warning,
                        message: "Checkpoint commit recommended.",
                        when: .and([
                            .metric(MetricCondition(metric: .added, gte: 100)),
                            .metric(MetricCondition(metric: .deleted, gte: 50)),
                            .metric(MetricCondition(metric: .files, gte: 3)),
                        ])
                    ),
                ]
            ),
            expectedMatch: NagRule(
                severity: .warning,
                message: "Checkpoint commit recommended.",
                when: .and([
                    .metric(MetricCondition(metric: .added, gte: 100)),
                    .metric(MetricCondition(metric: .deleted, gte: 50)),
                    .metric(MetricCondition(metric: .files, gte: 3)),
                ])
            )
        ),
        CheckScenario(
            label: "or rule matches when any branch is met",
            stats: DiffStats(added: 40, deleted: 20, filesChanged: 9),
            config: RuleConfig(
                rules: [
                    NagRule(
                        severity: .warning,
                        message: "The diff is spreading.",
                        when: .either([
                            .metric(MetricCondition(metric: .added, gte: 180)),
                            .metric(MetricCondition(metric: .files, gte: 8)),
                        ])
                    ),
                ]
            ),
            expectedMatch: NagRule(
                severity: .warning,
                message: "The diff is spreading.",
                when: .either([
                    .metric(MetricCondition(metric: .added, gte: 180)),
                    .metric(MetricCondition(metric: .files, gte: 8)),
                ])
            )
        ),
        CheckScenario(
            label: "first match wins when more than one rule matches",
            stats: DiffStats(added: 320, deleted: 80, filesChanged: 12),
            config: RuleConfig(
                rules: [
                    NagRule(
                        severity: .error,
                        message: "Commit now.",
                        when: .metric(MetricCondition(metric: .added, gte: 300))
                    ),
                    NagRule(
                        severity: .warning,
                        message: "Checkpoint commit recommended.",
                        when: .and([
                            .metric(MetricCondition(metric: .added, gte: 100)),
                            .metric(MetricCondition(metric: .deleted, gte: 50)),
                            .metric(MetricCondition(metric: .files, gte: 3)),
                        ])
                    ),
                ]
            ),
            expectedMatch: NagRule(
                severity: .error,
                message: "Commit now.",
                when: .metric(MetricCondition(metric: .added, gte: 300))
            )
        ),
        CheckScenario(
            label: "empty rules produce no match",
            stats: DiffStats(added: 0, deleted: 0, filesChanged: 0),
            config: RuleConfig(rules: []),
            expectedMatch: nil
        ),
    ]

    @Test("Rule evaluation", arguments: scenarios)
    func thresholdEvaluation(scenario: CheckScenario) throws {
        let mock = MockGitDiffProvider(result: scenario.stats)
        let runner = CheckRunner(config: scenario.config, diffProvider: mock)

        let result = try runner.run()

        #expect(result.match == scenario.expectedMatch)
        #expect(result.shouldNag == (scenario.expectedMatch != nil))
        #expect(result.stats == scenario.stats)
    }
}
