/// Outcome of a threshold check. Each violated threshold produces a `Violation`.
package struct NagResult: Equatable {
    package let violations: [Violation]
    package let stats: DiffStats

    /// `true` when at least one threshold was exceeded.
    package var shouldNag: Bool {
        !violations.isEmpty
    }

    package init(violations: [Violation], stats: DiffStats) {
        self.violations = violations
        self.stats = stats
    }
}

/// A single threshold breach.
package struct Violation: Equatable {
    package let kind: Kind
    package let actual: Int
    package let threshold: Int

    package enum Kind: String, Equatable {
        case added
        case deleted
        case filesChanged = "files_changed"
    }

    package init(kind: Kind, actual: Int, threshold: Int) {
        self.kind = kind
        self.actual = actual
        self.threshold = threshold
    }
}
