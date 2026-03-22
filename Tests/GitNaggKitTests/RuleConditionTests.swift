@testable import GitNaggKit
import Testing

struct ConditionScenario: CustomTestStringConvertible {
    let label: String
    let condition: RuleCondition
    let stats: DiffStats
    let expected: Bool

    var testDescription: String {
        label
    }
}

@Suite
struct RuleConditionTests {
    static let scenarios: [ConditionScenario] = [
        ConditionScenario(
            label: "metric condition compares against the selected metric",
            condition: .metric(MetricCondition(metric: .added, gte: 100)),
            stats: DiffStats(added: 120, deleted: 10, filesChanged: 1),
            expected: true
        ),
        ConditionScenario(
            label: "and condition requires every child to match",
            condition: .and([
                .metric(MetricCondition(metric: .added, gte: 100)),
                .metric(MetricCondition(metric: .files, gte: 3)),
            ]),
            stats: DiffStats(added: 120, deleted: 10, filesChanged: 2),
            expected: false
        ),
        ConditionScenario(
            label: "or condition matches when one child matches",
            condition: .either([
                .metric(MetricCondition(metric: .deleted, gte: 80)),
                .metric(MetricCondition(metric: .files, gte: 5)),
            ]),
            stats: DiffStats(added: 40, deleted: 20, filesChanged: 6),
            expected: true
        ),
    ]

    @Test("Rule condition matching", arguments: scenarios)
    func conditionMatching(scenario: ConditionScenario) {
        #expect(scenario.condition.matches(scenario.stats) == scenario.expected)
    }
}
