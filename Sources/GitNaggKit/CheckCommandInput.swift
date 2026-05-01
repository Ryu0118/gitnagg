/// Hook mode requested by the CLI caller.
package enum HookMode: Equatable {
    case none
    case claude
    case codex
}

/// Resolved, validated input for CheckRunner.
package struct CheckCommandInput: Equatable {
    /// The resolved rule configuration to evaluate against.
    package let ruleConfig: RuleConfig
    /// When `true`, informational output is suppressed and the exit code is always 0.
    package let quiet: Bool
    /// The hook output mode requested by the caller.
    package let hookMode: HookMode

    /// Creates a new `CheckCommandInput` with the given parameters.
    package init(ruleConfig: RuleConfig, quiet: Bool, hookMode: HookMode) {
        self.ruleConfig = ruleConfig
        self.quiet = quiet
        self.hookMode = hookMode
    }
}
