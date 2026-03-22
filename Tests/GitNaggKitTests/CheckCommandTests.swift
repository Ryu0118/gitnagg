@testable import GitNaggCLI
@testable import GitNaggKit
import ArgumentParser
import Testing

struct ValidationScenario: CustomTestStringConvertible {
    let label: String
    let command: CheckCommand
    let shouldThrow: Bool

    var testDescription: String {
        label
    }
}

struct ExitBehaviorScenario: CustomTestStringConvertible {
    let label: String
    let command: CheckCommand
    let stats: DiffStats
    let shouldThrowExitFailure: Bool

    var testDescription: String {
        label
    }
}

@Suite
struct CheckCommandTests {
    static let validationScenarios: [ValidationScenario] = [
        ValidationScenario(
            label: "accepts a complete simple CLI rule",
            command: makeCommand(metric: .added, gte: 100, severity: .warning, message: "Commit soon."),
            shouldThrow: false
        ),
        ValidationScenario(
            label: "rejects partial simple CLI rule options",
            command: makeCommand(metric: .added, gte: 100, severity: nil, message: "Commit soon."),
            shouldThrow: true
        ),
        ValidationScenario(
            label: "rejects mixing config path with simple CLI rule options",
            command: makeCommand(
                config: ".gitnagg.yml",
                metric: .added,
                gte: 100,
                severity: .warning,
                message: "Commit soon."
            ),
            shouldThrow: true
        ),
    ]

    static let exitBehaviorScenarios: [ExitBehaviorScenario] = [
        ExitBehaviorScenario(
            label: "warning match does not fail",
            command: makeCommand(metric: .added, gte: 100, severity: .warning, message: "Commit soon."),
            stats: DiffStats(added: 150, deleted: 0, filesChanged: 1),
            shouldThrowExitFailure: false
        ),
        ExitBehaviorScenario(
            label: "error match fails without quiet",
            command: makeCommand(metric: .added, gte: 100, severity: .error, message: "Commit now."),
            stats: DiffStats(added: 150, deleted: 0, filesChanged: 1),
            shouldThrowExitFailure: true
        ),
        ExitBehaviorScenario(
            label: "error match does not fail with quiet",
            command: makeCommand(
                metric: .added,
                gte: 100,
                severity: .error,
                message: "Commit now.",
                quiet: true
            ),
            stats: DiffStats(added: 150, deleted: 0, filesChanged: 1),
            shouldThrowExitFailure: false
        ),
    ]

    @Test("Check command validation", arguments: validationScenarios)
    func validation(scenario: ValidationScenario) {
        if scenario.shouldThrow {
            #expect(throws: Error.self) {
                try scenario.command.validate()
            }
        } else {
            #expect(throws: Never.self) {
                try scenario.command.validate()
            }
        }
    }

    @Test("Check command exit behavior", arguments: exitBehaviorScenarios)
    func exitBehavior(scenario: ExitBehaviorScenario) throws {
        let provider = MockGitDiffProvider(result: scenario.stats)

        if scenario.shouldThrowExitFailure {
            do {
                try scenario.command.execute(diffProvider: provider)
                Issue.record("Expected ExitCode.failure but command completed successfully.")
            } catch let error as ExitCode {
                #expect(error == .failure)
            } catch {
                Issue.record("Expected ExitCode.failure but got \(error).")
            }
        } else {
            #expect(throws: Never.self) {
                try scenario.command.execute(diffProvider: provider)
            }
        }
    }

    private static func makeCommand(
        config: String? = nil,
        metric: MetricOption? = nil,
        gte: Int? = nil,
        severity: SeverityOption? = nil,
        message: String? = nil,
        quiet: Bool = false
    ) -> CheckCommand {
        var command = CheckCommand()
        command.config = config
        command.metric = metric
        command.gte = gte
        command.severity = severity
        command.message = message
        command.quiet = quiet
        return command
    }
}
