/// Abstracts git diff stat retrieval for testability.
package protocol GitDiffProvider: Sendable {
    /// Returns aggregated diff statistics for uncommitted changes (staged + unstaged).
    func diffStats() throws -> DiffStats
}
