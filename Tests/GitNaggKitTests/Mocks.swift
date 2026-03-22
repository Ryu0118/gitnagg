@testable import GitNaggKit

/// In-memory stub that returns pre-configured diff stats for testing.
final class MockGitDiffProvider: GitDiffProvider, @unchecked Sendable {
    var result: DiffStats

    init(result: DiffStats = DiffStats(added: 0, deleted: 0, filesChanged: 0)) {
        self.result = result
    }

    func diffStats() throws -> DiffStats {
        result
    }
}
