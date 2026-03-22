/// Configurable thresholds that trigger a commit reminder.
/// Any threshold set to `nil` is ignored.
package struct ThresholdConfig: Equatable {
    /// Maximum added lines before nagging.
    package let added: Int?
    /// Maximum deleted lines before nagging.
    package let deleted: Int?
    /// Maximum changed files before nagging.
    package let filesChanged: Int?
    /// Optional YAML-defined warning message used when no CLI threshold overrides are active.
    package let message: String?

    package init(
        added: Int? = 100,
        deleted: Int? = 100,
        filesChanged: Int? = 3,
        message: String? = nil
    ) {
        self.added = added
        self.deleted = deleted
        self.filesChanged = filesChanged
        self.message = message
    }
}
