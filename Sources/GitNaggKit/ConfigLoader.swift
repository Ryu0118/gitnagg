import Foundation
import Yams

/// Loads `ThresholdConfig` from a YAML file.
///
/// Default search path: `.gitnagg.yml` in the current directory.
/// CLI options override any values found in the YAML file.
package enum ConfigLoader {
    package static let defaultFileName = ".gitnagg.yml"

    /// Loads thresholds from the YAML file at `path`.
    /// Returns `nil` if the file does not exist.
    package static func load(from path: String = defaultFileName) -> ThresholdConfig? {
        guard FileManager.default.fileExists(atPath: path),
              let data = FileManager.default.contents(atPath: path),
              let yaml = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return parse(yaml)
    }

    /// Parses a YAML string into `ThresholdConfig`.
    package static func parse(_ yaml: String) -> ThresholdConfig? {
        guard let dict = try? Yams.load(yaml: yaml) as? [String: Any] else {
            return nil
        }

        let added = dict["added"] as? Int
        let deleted = dict["deleted"] as? Int
        let filesChanged = dict["files"] as? Int

        return ThresholdConfig(
            added: added,
            deleted: deleted,
            filesChanged: filesChanged
        )
    }

    /// Merges a YAML-loaded config with explicit CLI overrides.
    /// CLI values take precedence; YAML fills in any unspecified values;
    /// built-in defaults fill in the rest.
    package static func merge(
        yamlConfig: ThresholdConfig?,
        cliAdded: Int?,
        cliDeleted: Int?,
        cliFiles: Int?
    ) -> ThresholdConfig {
        let defaults = ThresholdConfig()
        let yaml = yamlConfig ?? ThresholdConfig(added: nil, deleted: nil, filesChanged: nil)

        return ThresholdConfig(
            added: cliAdded ?? yaml.added ?? defaults.added,
            deleted: cliDeleted ?? yaml.deleted ?? defaults.deleted,
            filesChanged: cliFiles ?? yaml.filesChanged ?? defaults.filesChanged
        )
    }
}
