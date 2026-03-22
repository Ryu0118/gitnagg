/// Outcome of evaluating diff stats against ordered nag rules.
package struct CheckResult: Equatable {
    /// The first matched rule, if any.
    package let match: NagRule?
    /// Raw git diff statistics used during evaluation.
    package let stats: DiffStats

    package var shouldNag: Bool {
        match != nil
    }

    package init(match: NagRule?, stats: DiffStats) {
        self.match = match
        self.stats = stats
    }
}
