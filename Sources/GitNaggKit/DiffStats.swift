/// Aggregated statistics from `git diff --stat`.
package struct DiffStats: Equatable {
    /// Number of lines added (insertions).
    package let added: Int
    /// Number of lines deleted (deletions).
    package let deleted: Int
    /// Number of files changed.
    package let filesChanged: Int

    package init(added: Int, deleted: Int, filesChanged: Int) {
        self.added = added
        self.deleted = deleted
        self.filesChanged = filesChanged
    }
}
