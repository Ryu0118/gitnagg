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
    package let metric: DiffMetric
    package let gte: Int

    package init(metric: DiffMetric, gte: Int) {
        self.metric = metric
        self.gte = gte
    }

    package func matches(_ stats: DiffStats) -> Bool {
        metric.value(in: stats) >= gte
    }
}

/// Recursive rule condition tree.
package indirect enum RuleCondition: Codable, Equatable {
    case metric(MetricCondition)
    case and([RuleCondition])
    case either([RuleCondition])

    package func matches(_ stats: DiffStats) -> Bool {
        switch self {
        case let .metric(condition):
            condition.matches(stats)
        case let .and(conditions):
            conditions.allSatisfy { $0.matches(stats) }
        case let .either(conditions):
            conditions.contains { $0.matches(stats) }
        }
    }

    private enum CodingKeys: String, CodingKey {
        case metric
        case gte
        case and
        case orKey = "or"
    }

    package init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.contains(.and) {
            self = try .and(container.decode([RuleCondition].self, forKey: .and))
            return
        }

        if container.contains(.orKey) {
            self = try .either(container.decode([RuleCondition].self, forKey: .orKey))
            return
        }

        if container.contains(.metric) {
            self = try .metric(MetricCondition(from: decoder))
            return
        }

        throw DecodingError.dataCorruptedError(
            forKey: .metric,
            in: container,
            debugDescription: "Rule condition must define either metric/gte, and, or or."
        )
    }

    package func encode(to encoder: Encoder) throws {
        switch self {
        case let .metric(condition):
            try condition.encode(to: encoder)
        case let .and(conditions):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(conditions, forKey: .and)
        case let .either(conditions):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(conditions, forKey: .orKey)
        }
    }
}
