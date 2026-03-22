/// Selects the warning message shown when thresholds are exceeded.
package enum NagMessageResolver {
    /// Uses the YAML-defined message only when no CLI threshold overrides are active.
    package static func resolve(
        result: NagResult,
        config: ThresholdConfig,
        hasCLIThresholdOverrides: Bool
    ) -> String? {
        guard result.shouldNag else { return nil }

        if !hasCLIThresholdOverrides, let message = config.message, !message.isEmpty {
            return message
        }

        return NagFormatter.format(result)
    }
}
