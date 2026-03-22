@testable import GitNaggKit
import Testing

/// Parameterized scenario for YAML parsing.
struct ConfigParseScenario: CustomTestStringConvertible {
    let label: String
    let yaml: String
    let expectedConfig: ThresholdConfig?

    var testDescription: String {
        label
    }
}

/// Parameterized scenario for config merging.
struct ConfigMergeScenario: CustomTestStringConvertible {
    let label: String
    let yamlConfig: ThresholdConfig?
    let cliAdded: Int?
    let cliDeleted: Int?
    let cliFiles: Int?
    let expectedConfig: ThresholdConfig

    var testDescription: String {
        label
    }
}

@Suite("ConfigLoader parses YAML and merges with CLI overrides following precedence rules")
struct ConfigLoaderTests {
    static let parseScenarios: [ConfigParseScenario] = [
        ConfigParseScenario(
            label: "parses valid YAML with all fields",
            yaml: """
            added: 200
            deleted: 150
            files: 5
            message: Please commit before this grows further.
            """,
            expectedConfig: ThresholdConfig(
                added: 200,
                deleted: 150,
                filesChanged: 5,
                message: "Please commit before this grows further."
            )
        ),
        ConfigParseScenario(
            label: "parses YAML with partial fields and missing ones are nil",
            yaml: """
            added: 50
            """,
            expectedConfig: ThresholdConfig(added: 50, deleted: nil, filesChanged: nil)
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

    static let mergeScenarios: [ConfigMergeScenario] = [
        ConfigMergeScenario(
            label: "CLI options override YAML values",
            yamlConfig: ThresholdConfig(added: 200, deleted: 150, filesChanged: 5),
            cliAdded: 50,
            cliDeleted: nil,
            cliFiles: 10,
            expectedConfig: ThresholdConfig(added: 50, deleted: 150, filesChanged: 10)
        ),
        ConfigMergeScenario(
            label: "YAML values fill in when CLI options are nil",
            yamlConfig: ThresholdConfig(
                added: 200,
                deleted: nil,
                filesChanged: 5,
                message: "Commit now."
            ),
            cliAdded: nil,
            cliDeleted: nil,
            cliFiles: nil,
            expectedConfig: ThresholdConfig(
                added: 200,
                deleted: 100,
                filesChanged: 5,
                message: "Commit now."
            )
        ),
        ConfigMergeScenario(
            label: "built-in defaults used when both YAML and CLI are absent",
            yamlConfig: nil,
            cliAdded: nil,
            cliDeleted: nil,
            cliFiles: nil,
            expectedConfig: ThresholdConfig()
        ),
    ]

    @Test("Parse config YAML", arguments: parseScenarios)
    func parseYaml(scenario: ConfigParseScenario) {
        #expect(ConfigLoader.parse(scenario.yaml) == scenario.expectedConfig)
    }

    @Test("Merge config sources", arguments: mergeScenarios)
    func mergeConfig(scenario: ConfigMergeScenario) {
        let merged = ConfigLoader.merge(
            yamlConfig: scenario.yamlConfig,
            cliAdded: scenario.cliAdded,
            cliDeleted: scenario.cliDeleted,
            cliFiles: scenario.cliFiles
        )

        #expect(merged == scenario.expectedConfig)
    }
}
