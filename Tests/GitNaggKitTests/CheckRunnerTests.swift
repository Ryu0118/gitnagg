@testable import GitNaggKit
import Testing

/// Parameterized scenario for `CheckRunner` threshold evaluation.
struct ThresholdScenario: CustomTestStringConvertible {
    let label: String
    let stats: DiffStats
    let config: ThresholdConfig
    let expectedViolationKinds: [Violation.Kind]

    var testDescription: String {
        label
    }
}

@Suite
struct CheckRunnerTests {
    static let scenarios: [ThresholdScenario] = [
        ThresholdScenario(
            label: "no violations when under all thresholds",
            stats: DiffStats(added: 50, deleted: 30, filesChanged: 2),
            config: ThresholdConfig(added: 100, deleted: 100, filesChanged: 3),
            expectedViolationKinds: []
        ),
        ThresholdScenario(
            label: "added lines exceed threshold",
            stats: DiffStats(added: 150, deleted: 10, filesChanged: 1),
            config: ThresholdConfig(added: 100, deleted: 100, filesChanged: 3),
            expectedViolationKinds: [.added]
        ),
        ThresholdScenario(
            label: "deleted lines exceed threshold",
            stats: DiffStats(added: 10, deleted: 120, filesChanged: 1),
            config: ThresholdConfig(added: 100, deleted: 100, filesChanged: 3),
            expectedViolationKinds: [.deleted]
        ),
        ThresholdScenario(
            label: "files changed exceed threshold",
            stats: DiffStats(added: 10, deleted: 10, filesChanged: 5),
            config: ThresholdConfig(added: 100, deleted: 100, filesChanged: 3),
            expectedViolationKinds: [.filesChanged]
        ),
        ThresholdScenario(
            label: "multiple violations at once",
            stats: DiffStats(added: 200, deleted: 200, filesChanged: 10),
            config: ThresholdConfig(added: 100, deleted: 100, filesChanged: 3),
            expectedViolationKinds: [.added, .deleted, .filesChanged]
        ),
        ThresholdScenario(
            label: "exact threshold triggers violation",
            stats: DiffStats(added: 100, deleted: 100, filesChanged: 3),
            config: ThresholdConfig(added: 100, deleted: 100, filesChanged: 3),
            expectedViolationKinds: [.added, .deleted, .filesChanged]
        ),
        ThresholdScenario(
            label: "nil thresholds are ignored",
            stats: DiffStats(added: 999, deleted: 999, filesChanged: 99),
            config: ThresholdConfig(added: nil, deleted: nil, filesChanged: nil),
            expectedViolationKinds: []
        ),
        ThresholdScenario(
            label: "zero stats produce no violations",
            stats: DiffStats(added: 0, deleted: 0, filesChanged: 0),
            config: ThresholdConfig(added: 100, deleted: 100, filesChanged: 3),
            expectedViolationKinds: []
        ),
    ]

    @Test("Threshold evaluation", arguments: scenarios)
    func thresholdEvaluation(scenario: ThresholdScenario) throws {
        let mock = MockGitDiffProvider(result: scenario.stats)
        let runner = CheckRunner(config: scenario.config, diffProvider: mock)

        let result = try runner.run()

        #expect(result.violations.map(\.kind) == scenario.expectedViolationKinds)
        #expect(result.shouldNag == !scenario.expectedViolationKinds.isEmpty)
        #expect(result.stats == scenario.stats)
    }
}
