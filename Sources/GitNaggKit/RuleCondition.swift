/// Recursive rule condition tree.
package indirect enum RuleCondition: Codable, Equatable {
    case metric(MetricCondition)
    case and([RuleCondition])
    case either([RuleCondition])

    /// Returns `true` when this condition is satisfied by the given diff stats.
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

    /// Decodes a `RuleCondition` from a YAML/JSON container by inspecting present keys.
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

    /// Encodes the condition back to a keyed container matching the YAML schema.
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
