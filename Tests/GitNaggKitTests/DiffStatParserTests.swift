@testable import GitNaggKit
import Testing

/// Parameterized scenario for parsing `git diff --stat` output.
struct ParseScenario: CustomTestStringConvertible {
    let label: String
    let input: String
    let expected: DiffStats

    var testDescription: String {
        label
    }
}

@Suite
struct DiffStatParserTests {
    static let scenarios: [ParseScenario] = [
        ParseScenario(
            label: "typical output with insertions and deletions",
            input: """
             Sources/Foo.swift | 10 ++++------
             Sources/Bar.swift | 5 ++---
             2 files changed, 6 insertions(+), 9 deletions(-)
            """,
            expected: DiffStats(added: 6, deleted: 9, filesChanged: 2)
        ),
        ParseScenario(
            label: "insertions only",
            input: """
             README.md | 20 ++++++++++++++++++++
             1 file changed, 20 insertions(+)
            """,
            expected: DiffStats(added: 20, deleted: 0, filesChanged: 1)
        ),
        ParseScenario(
            label: "deletions only",
            input: """
             OldFile.swift | 15 ---------------
             1 file changed, 15 deletions(-)
            """,
            expected: DiffStats(added: 0, deleted: 15, filesChanged: 1)
        ),
        ParseScenario(
            label: "empty output",
            input: "",
            expected: DiffStats(added: 0, deleted: 0, filesChanged: 0)
        ),
        ParseScenario(
            label: "many files changed",
            input: """
             a.swift | 1 +
             b.swift | 2 +-
             c.swift | 3 ++-
             3 files changed, 4 insertions(+), 2 deletions(-)
            """,
            expected: DiffStats(added: 4, deleted: 2, filesChanged: 3)
        ),
    ]

    @Test("Parse git diff --stat output", arguments: scenarios)
    func parseDiffStat(scenario: ParseScenario) {
        let result = DefaultGitDiffProvider.parse(scenario.input)
        #expect(result == scenario.expected)
    }
}
