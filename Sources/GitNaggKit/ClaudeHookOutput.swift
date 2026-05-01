import Foundation

/// Payload for the Claude Code PostToolUse hook decision.
package struct ClaudeHookOutput: Codable, Equatable {
    /// The hook decision; always `"block"` when a nag rule is triggered.
    package let decision: String
    /// Human-readable reason shown in the Claude Code UI.
    package let reason: String

    /// Creates a blocking hook output with the given `reason`.
    package init(reason: String) {
        decision = "block"
        self.reason = reason
    }

    /// JSON-encoded representation suitable for writing to stdout.
    package var jsonString: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(self) else { return "{}" }
        return String(bytes: data, encoding: .utf8) ?? "{}"
    }
}
