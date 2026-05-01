/// Validates and resolves CLI arguments into a CheckCommandInput.
package struct CheckArgumentsValidator {
    private let metric: DiffMetric?
    private let gte: Int?
    private let severity: RuleSeverity?
    private let message: String?
    private let config: String?
    private let quiet: Bool
    private let hookMode: HookMode

    package init(
        metric: DiffMetric?,
        gte: Int?,
        severity: RuleSeverity?,
        message: String?,
        config: String?,
        quiet: Bool,
        hookMode: HookMode
    ) {
        self.metric = metric
        self.gte = gte
        self.severity = severity
        self.message = message
        self.config = config
        self.quiet = quiet
        self.hookMode = hookMode
    }

    package func validate() throws -> CheckCommandInput {
        let ruleConfig = try resolveRuleConfig()
        return CheckCommandInput(ruleConfig: ruleConfig, quiet: quiet, hookMode: hookMode)
    }

    private func resolveRuleConfig() throws -> RuleConfig {
        if let metric, let gte, let severity, let message {
            return RuleConfig.singleRule(metric: metric, gte: gte, severity: severity, message: message)
        }

        let yamlPath = config ?? ConfigLoader.defaultFileName
        let yamlConfig = ConfigLoader.load(from: yamlPath)

        if config != nil, yamlConfig == nil {
            logger.warning("Config file not found: \(yamlPath)")
        }

        return yamlConfig ?? RuleConfig(rules: [])
    }
}
