/// Formats `NagResult` into human-readable warning messages for hooks output.
package enum NagFormatter {
    /// Produces a multiline warning string when violations exist, or `nil` when clean.
    package static func format(_ result: NagResult) -> String? {
        guard result.shouldNag else { return nil }

        var lines: [String] = []
        lines.append("[gitnagg] Uncommitted changes are piling up! Consider committing.")
        lines.append("")

        for violation in result.violations {
            lines.append(describeViolation(violation))
        }

        lines.append("")
        lines.append(
            "  Stats: +\(result.stats.added) -\(result.stats.deleted) in \(result.stats.filesChanged) file(s)"
        )
        return lines.joined(separator: "\n")
    }

    private static func describeViolation(_ violation: Violation) -> String {
        switch violation.kind {
        case .added:
            "  ⚠ Added lines: \(violation.actual) (threshold: \(violation.threshold))"
        case .deleted:
            "  ⚠ Deleted lines: \(violation.actual) (threshold: \(violation.threshold))"
        case .filesChanged:
            "  ⚠ Changed files: \(violation.actual) (threshold: \(violation.threshold))"
        }
    }
}
