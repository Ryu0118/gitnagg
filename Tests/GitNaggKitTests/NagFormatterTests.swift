@testable import GitNaggKit
import Testing

@Suite
struct NagFormatterTests {
    @Test("Returns nil when no violations exist")
    func noViolations() {
        let result = NagResult(
            violations: [],
            stats: DiffStats(added: 10, deleted: 5, filesChanged: 1)
        )

        #expect(NagFormatter.format(result) == nil)
    }

    @Test("Includes threshold and actual value for a single added-lines violation")
    func singleViolation() throws {
        let result = NagResult(
            violations: [
                Violation(kind: .added, actual: 150, threshold: 100),
            ],
            stats: DiffStats(added: 150, deleted: 5, filesChanged: 1)
        )

        let output = try #require(NagFormatter.format(result))
        #expect(output.contains("[gitnagg]"))
        #expect(output.contains("Added lines: 150"))
        #expect(output.contains("threshold: 100"))
        #expect(output.contains("+150 -5 in 1 file(s)"))
    }

    @Test("Lists all violation kinds when multiple thresholds are exceeded")
    func multipleViolations() throws {
        let result = NagResult(
            violations: [
                Violation(kind: .added, actual: 200, threshold: 100),
                Violation(kind: .deleted, actual: 150, threshold: 100),
                Violation(kind: .filesChanged, actual: 10, threshold: 3),
            ],
            stats: DiffStats(added: 200, deleted: 150, filesChanged: 10)
        )

        let output = try #require(NagFormatter.format(result))
        #expect(output.contains("Added lines: 200"))
        #expect(output.contains("Deleted lines: 150"))
        #expect(output.contains("Changed files: 10"))
    }
}
