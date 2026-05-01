/// Ordered rule configuration for gitnagg.
package struct RuleConfig: Codable, Equatable {
    /// Schema version for future compatibility.
    package let version: Int
    /// How to resolve multiple matching rules.
    package let resolution: ResolutionMode
    /// Exit code to use when an error-severity rule matches (default: 2).
    package let exitCode: Int32
    /// Ordered rules to evaluate.
    package let rules: [NagRule]

    /// Creates a `RuleConfig` with the given version, resolution mode, exit code, and rules.
    package init(
        version: Int = 1,
        resolution: ResolutionMode = .firstMatch,
        exitCode: Int32 = 2,
        rules: [NagRule]
    ) {
        self.version = version
        self.resolution = resolution
        self.exitCode = exitCode
        self.rules = rules
    }

    /// Convenience factory that builds a single-rule config from inline CLI arguments.
    package static func singleRule(
        metric: DiffMetric,
        gte: Int,
        severity: RuleSeverity,
        message: String
    ) -> RuleConfig {
        RuleConfig(
            rules: [
                NagRule(
                    severity: severity,
                    message: message,
                    when: .metric(MetricCondition(metric: metric, gte: gte))
                ),
            ]
        )
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case resolution
        case exitCode = "exit_code"
        case rules
    }

    /// Decodes a `RuleConfig` from a YAML/JSON container, applying defaults for absent fields.
    package init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        resolution = try container.decodeIfPresent(ResolutionMode.self, forKey: .resolution) ?? .firstMatch
        exitCode = try container.decodeIfPresent(Int32.self, forKey: .exitCode) ?? 2
        rules = try container.decodeIfPresent([NagRule].self, forKey: .rules) ?? []
    }
}

/// Strategy used when more than one rule matches.
package enum ResolutionMode: String, Codable, Equatable {
    case firstMatch = "first-match"
}

/// A single ordered nag rule.
package struct NagRule: Codable, Equatable {
    /// Severity applied when this rule matches.
    package let severity: RuleSeverity
    /// Message emitted when this rule matches.
    package let message: String
    /// Condition tree that decides whether the rule matches.
    package let when: RuleCondition

    /// Creates a `NagRule` with the given severity, message, and condition.
    package init(severity: RuleSeverity, message: String, when: RuleCondition) {
        self.severity = severity
        self.message = message
        self.when = when
    }
}

/// User-visible severity for a matched rule.
package enum RuleSeverity: String, Codable, Equatable {
    case info
    case warning
    case error
}

package extension NagRule {
    func logMatch() {
        switch severity {
        case .info:
            logger.info("\(message)", metadata: .plainOutput)
        case .warning:
            logger.warning("\(message)", metadata: .plainOutput)
        case .error:
            logger.error("\(message)", metadata: .plainOutput)
        }
    }
}

/// Diff metric that can be used in a condition.
package enum DiffMetric: String, Codable, Equatable {
    case added
    case deleted
    case files

    /// Returns the numeric value of this metric from the given diff stats.
    package func value(in stats: DiffStats) -> Int {
        switch self {
        case .added:
            stats.added
        case .deleted:
            stats.deleted
        case .files:
            stats.filesChanged
        }
    }
}

/// A single threshold condition against one diff metric.
package struct MetricCondition: Codable, Equatable {
    /// The diff metric to compare.
    package let metric: DiffMetric
    /// The minimum value (inclusive) that triggers a match.
    package let gte: Int

    /// Creates a condition that matches when `metric` is at least `gte`.
    package init(metric: DiffMetric, gte: Int) {
        self.metric = metric
        self.gte = gte
    }

    /// Returns `true` when the metric value in `stats` meets the threshold.
    package func matches(_ stats: DiffStats) -> Bool {
        metric.value(in: stats) >= gte
    }
}
