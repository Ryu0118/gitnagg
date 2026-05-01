import Foundation

/// Calls `git diff` via `Process` to collect real diff statistics.
package struct DefaultGitDiffProvider: GitDiffProvider {
    private let workingDirectory: String?

    package init(workingDirectory: String? = nil) {
        self.workingDirectory = workingDirectory
    }

    package func diffStats() throws -> DiffStats {
        let output = try run(["diff", "--stat", "HEAD"])
        return parse(output)
    }

    /// Runs a git subcommand and returns its stdout.
    private func run(_ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/git")
        process.arguments = arguments
        if let workingDirectory {
            process.currentDirectoryURL = URL(filePath: workingDirectory)
        }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// Parses the summary line of `git diff --stat` output.
    ///
    /// Example summary: ` 3 files changed, 45 insertions(+), 12 deletions(-)`
    package static func parse(_ output: String) -> DiffStats {
        let lines = output.split(separator: "\n")
        guard let summary = lines.last else {
            return DiffStats(added: 0, deleted: 0, filesChanged: 0)
        }

        let text = String(summary)
        let files = extractNumber(from: text, before: "file")
        let insertions = extractNumber(from: text, before: "insertion")
        let deletions = extractNumber(from: text, before: "deletion")

        return DiffStats(added: insertions, deleted: deletions, filesChanged: files)
    }

    private func parse(_ output: String) -> DiffStats {
        Self.parse(output)
    }

    /// Extracts the integer immediately preceding a keyword in the summary line.
    private static func extractNumber(from text: String, before keyword: String) -> Int {
        guard let range = text.range(of: keyword) else { return 0 }
        let prefix = text[text.startIndex ..< range.lowerBound]
            .trimmingCharacters(in: .whitespaces)
        let components = prefix.split(separator: " ")
        guard let last = components.last, let number = Int(last) else { return 0 }
        return number
    }
}
