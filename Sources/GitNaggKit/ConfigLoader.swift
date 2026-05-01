import Foundation
import Yams

/// Loads `RuleConfig` from a YAML file.
///
/// Default search path: `.gitnagg.yml` in the current directory.
package enum ConfigLoader {
    /// Default config file name searched in the current working directory.
    package static let defaultFileName = ".gitnagg.yml"

    /// Loads rules from the YAML file at `path`.
    /// Returns `nil` if the file does not exist.
    package static func load(from path: String = defaultFileName) -> RuleConfig? {
        guard FileManager.default.fileExists(atPath: path),
              let data = FileManager.default.contents(atPath: path),
              let yaml = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return parse(yaml)
    }

    /// Parses a YAML string into `RuleConfig`.
    package static func parse(_ yaml: String) -> RuleConfig? {
        try? YAMLDecoder().decode(RuleConfig.self, from: yaml)
    }
}
