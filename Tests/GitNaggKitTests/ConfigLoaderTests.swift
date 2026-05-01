@testable import GitNaggKit
import Testing

/// Parameterized scenario for YAML parsing.
struct ConfigParseScenario: CustomTestStringConvertible {
    let label: String
    let yaml: String
    let expectedConfig: RuleConfig?

    var testDescription: String {
        label
    }
}

@Suite
struct ConfigLoaderTests {
    static let parseScenarios: [ConfigParseScenario] = [
        ConfigParseScenario(
            label: "parses rule config with resolution and nested conditions",
            yaml: """
            version: 1
            resolution: first-match
            rules:
              - severity: error
                message: Commit now.
                when:
                  or:
                    - metric: added
                      gte: 300
                    - metric: files
                      gte: 12
              - severity: warning
                message: Make a checkpoint commit.
                when:
                  and:
                    - metric: added
                      gte: 100
                    - metric: deleted
                      gte: 50
            """,
            expectedConfig: RuleConfig(
                rules: [
                    NagRule(
                        severity: .error,
                        message: "Commit now.",
                        when: .either([
                            .metric(MetricCondition(metric: .added, gte: 300)),
                            .metric(MetricCondition(metric: .files, gte: 12)),
                        ])
                    ),
                    NagRule(
                        severity: .warning,
                        message: "Make a checkpoint commit.",
                        when: .and([
                            .metric(MetricCondition(metric: .added, gte: 100)),
                            .metric(MetricCondition(metric: .deleted, gte: 50)),
                        ])
                    ),
                ]
            )
        ),
        ConfigParseScenario(
            label: "defaults version and resolution when omitted",
            yaml: """
            rules:
              - severity: info
                message: Good checkpoint.
                when:
                  metric: added
                  gte: 80
            """,
            expectedConfig: RuleConfig(
                rules: [
                    NagRule(
                        severity: .info,
                        message: "Good checkpoint.",
                        when: .metric(MetricCondition(metric: .added, gte: 80))
                    ),
                ]
            )
        ),
        ConfigParseScenario(
            label: "parses exit_code from YAML",
            yaml: """
            version: 1
            exit_code: 2
            rules:
              - severity: error
                message: Stop.
                when:
                  metric: added
                  gte: 100
            """,
            expectedConfig: RuleConfig(
                exitCode: 2,
                rules: [
                    NagRule(
                        severity: .error,
                        message: "Stop.",
                        when: .metric(MetricCondition(metric: .added, gte: 100))
                    ),
                ]
            )
        ),
        ConfigParseScenario(
            label: "defaults exit_code to 2 when omitted",
            yaml: """
            rules:
              - severity: error
                message: Stop.
                when:
                  metric: added
                  gte: 100
            """,
            expectedConfig: RuleConfig(
                exitCode: 2,
                rules: [
                    NagRule(
                        severity: .error,
                        message: "Stop.",
                        when: .metric(MetricCondition(metric: .added, gte: 100))
                    ),
                ]
            )
        ),
        ConfigParseScenario(
            label: "returns nil for empty YAML",
            yaml: "",
            expectedConfig: nil
        ),
        ConfigParseScenario(
            label: "returns nil for invalid YAML",
            yaml: "[[[invalid",
            expectedConfig: nil
        ),
    ]

    @Test("Parse config YAML", arguments: parseScenarios)
    func parseYaml(scenario: ConfigParseScenario) {
        #expect(ConfigLoader.parse(scenario.yaml) == scenario.expectedConfig)
    }
}
