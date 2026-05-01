/// Hook mode requested by the CLI caller.
package enum HookMode: Equatable {
    case none
    case claude
    case codex
}

/// Resolved, validated input for CheckRunner.
package struct CheckCommandInput: Equatable {
    package let ruleConfig: RuleConfig
    package let quiet: Bool
    package let hookMode: HookMode

    package init(ruleConfig: RuleConfig, quiet: Bool, hookMode: HookMode) {
        self.ruleConfig = ruleConfig
        self.quiet = quiet
        self.hookMode = hookMode
    }
}
