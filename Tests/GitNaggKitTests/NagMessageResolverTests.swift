@testable import GitNaggKit
import Testing

/// Parameterized scenario for warning message resolution.
struct NagMessageScenario: CustomTestStringConvertible {
    let label: String
    let result: NagResult
    let config: ThresholdConfig
    let hasCLIThresholdOverrides: Bool
    let expectedMessage: String?
    let expectedFragments: [String]

    var testDescription: String {
        label
    }
}

@Suite
struct NagMessageResolverTests {
    static let scenarios: [NagMessageScenario] = [
        NagMessageScenario(
            label: "uses YAML custom message when no CLI threshold overrides are active",
            result: NagResult(
                violations: [
                    Violation(kind: .filesChanged, actual: 8, threshold: 5),
                ],
                stats: DiffStats(added: 89, deleted: 50, filesChanged: 8)
            ),
            config: ThresholdConfig(message: "Please commit before continuing."),
            hasCLIThresholdOverrides: false,
            expectedMessage: "Please commit before continuing.",
            expectedFragments: []
        ),
        NagMessageScenario(
            label: "falls back to the default formatter when CLI threshold overrides are active",
            result: NagResult(
                violations: [
                    Violation(kind: .filesChanged, actual: 8, threshold: 5),
                ],
                stats: DiffStats(added: 89, deleted: 50, filesChanged: 8)
            ),
            config: ThresholdConfig(message: "Please commit before continuing."),
            hasCLIThresholdOverrides: true,
            expectedMessage: nil,
            expectedFragments: ["[gitnagg]", "Changed files: 8"]
        ),
        NagMessageScenario(
            label: "returns nil when there is no violation",
            result: NagResult(
                violations: [],
                stats: DiffStats(added: 10, deleted: 5, filesChanged: 1)
            ),
            config: ThresholdConfig(message: "unused"),
            hasCLIThresholdOverrides: false,
            expectedMessage: nil,
            expectedFragments: []
        ),
    ]

    @Test("Resolve nag message", arguments: scenarios)
    func resolveMessage(scenario: NagMessageScenario) throws {
        let message = NagMessageResolver.resolve(
            result: scenario.result,
            config: scenario.config,
            hasCLIThresholdOverrides: scenario.hasCLIThresholdOverrides
        )

        if let expectedMessage = scenario.expectedMessage {
            #expect(message == expectedMessage)
            return
        }

        if scenario.result.shouldNag {
            let unwrappedMessage = try #require(message)
            for fragment in scenario.expectedFragments {
                #expect(unwrappedMessage.contains(fragment))
            }
        } else {
            #expect(message == nil)
        }
    }
}
