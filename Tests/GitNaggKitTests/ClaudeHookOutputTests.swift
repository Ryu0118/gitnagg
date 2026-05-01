import Foundation

// swiftformat:disable redundantSwiftTestingSuite
@testable import GitNaggKit
import Testing

@Suite
struct ClaudeHookOutputTests {
    @Test("jsonString returns block decision with reason")
    func jsonStringOnMatch() {
        let output = ClaudeHookOutput(reason: "Commit now.")
        let json = output.jsonString
        #expect(json == "{\"decision\":\"block\",\"reason\":\"Commit now.\"}")
    }

    @Test("decision is always block")
    func decisionIsAlwaysBlock() {
        let output = ClaudeHookOutput(reason: "anything")
        #expect(output.decision == "block")
    }

    @Test("CheckResult returns claudeHookOutput when rule matched")
    func checkResultReturnsOutputOnMatch() {
        let condition = MetricCondition(metric: .added, gte: 100)
        let rule = NagRule(severity: .error, message: "Commit now.", when: .metric(condition))
        let result = CheckResult(match: rule, stats: DiffStats(added: 150, deleted: 0, filesChanged: 1))
        let output = result.claudeHookOutput
        #expect(output != nil)
        #expect(output?.reason == "Commit now.")
        #expect(output?.decision == "block")
    }

    @Test("CheckResult returns nil claudeHookOutput when no rule matched")
    func checkResultReturnsNilOnNoMatch() {
        let result = CheckResult(match: nil, stats: DiffStats(added: 50, deleted: 0, filesChanged: 1))
        #expect(result.claudeHookOutput == nil)
    }

    @Test("jsonString escapes double quotes in reason")
    func jsonStringEscapesQuotes() throws {
        let message = #"Stop: "commit" now"#
        let output = ClaudeHookOutput(reason: message)
        let json = output.jsonString
        let data = Data(json.utf8)
        let decoded = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])
        #expect(decoded["decision"] == "block")
        #expect(decoded["reason"] == message)
    }

    @Test("jsonString escapes backslashes in reason")
    func jsonStringEscapesBackslashes() throws {
        let message = #"path\to\file"#
        let output = ClaudeHookOutput(reason: message)
        let data = Data(output.jsonString.utf8)
        let decoded = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])
        #expect(decoded["reason"] == message)
    }

    @Test("jsonString escapes newlines in reason")
    func jsonStringEscapesNewlines() throws {
        let message = "line1\nline2"
        let output = ClaudeHookOutput(reason: message)
        let data = Data(output.jsonString.utf8)
        let decoded = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])
        #expect(decoded["reason"] == message)
    }

    @Test("jsonString works for warning severity match")
    func jsonStringWarning() {
        let condition = MetricCondition(metric: .added, gte: 50)
        let rule = NagRule(severity: .warning, message: "Good checkpoint.", when: .metric(condition))
        let result = CheckResult(match: rule, stats: DiffStats(added: 80, deleted: 0, filesChanged: 1))
        let json = result.claudeHookOutput?.jsonString ?? ""
        #expect(json.contains("\"decision\":\"block\""))
        #expect(json.contains("Good checkpoint."))
    }

    @Test("ClaudeHookOutput round-trips through Codable")
    func codableRoundTrip() throws {
        let original = ClaudeHookOutput(reason: "test reason")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ClaudeHookOutput.self, from: data)
        #expect(decoded == original)
    }
}
