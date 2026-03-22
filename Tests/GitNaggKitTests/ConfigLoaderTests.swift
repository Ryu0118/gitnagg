@testable import GitNaggKit
import Testing

@Suite("ConfigLoader parses YAML and merges with CLI overrides following precedence rules")
struct ConfigLoaderTests {
    @Test("Parses valid YAML with all fields")
    func parseAllFields() throws {
        let yaml = """
        added: 200
        deleted: 150
        files: 5
        """
        let config = try #require(ConfigLoader.parse(yaml))
        #expect(config.added == 200)
        #expect(config.deleted == 150)
        #expect(config.filesChanged == 5)
    }

    @Test("Parses YAML with partial fields, missing ones are nil")
    func parsePartialFields() throws {
        let yaml = """
        added: 50
        """
        let config = try #require(ConfigLoader.parse(yaml))
        #expect(config.added == 50)
        #expect(config.deleted == nil)
        #expect(config.filesChanged == nil)
    }

    @Test("Returns nil for empty YAML")
    func parseEmptyYaml() {
        #expect(ConfigLoader.parse("") == nil)
    }

    @Test("Returns nil for invalid YAML")
    func parseInvalidYaml() {
        #expect(ConfigLoader.parse("[[[invalid") == nil)
    }

    @Test("CLI options override YAML values")
    func mergeCliOverridesYaml() {
        let yaml = ThresholdConfig(added: 200, deleted: 150, filesChanged: 5)
        let merged = ConfigLoader.merge(
            yamlConfig: yaml,
            cliAdded: 50,
            cliDeleted: nil,
            cliFiles: 10
        )
        #expect(merged.added == 50)
        #expect(merged.deleted == 150)
        #expect(merged.filesChanged == 10)
    }

    @Test("YAML values fill in when CLI options are nil")
    func mergeYamlFillsDefaults() {
        let yaml = ThresholdConfig(added: 200, deleted: nil, filesChanged: 5)
        let merged = ConfigLoader.merge(
            yamlConfig: yaml,
            cliAdded: nil,
            cliDeleted: nil,
            cliFiles: nil
        )
        #expect(merged.added == 200)
        #expect(merged.deleted == 100) // built-in default
        #expect(merged.filesChanged == 5)
    }

    @Test("Built-in defaults used when both YAML and CLI are absent")
    func mergeAllDefaults() {
        let merged = ConfigLoader.merge(
            yamlConfig: nil,
            cliAdded: nil,
            cliDeleted: nil,
            cliFiles: nil
        )
        #expect(merged.added == 100)
        #expect(merged.deleted == 100)
        #expect(merged.filesChanged == 3)
    }
}
