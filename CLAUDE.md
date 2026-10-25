# gitnagg

CLI tool that monitors uncommitted git changes and nags you to commit when thresholds are exceeded. Designed as a hook executable for Claude Code Hooks.

## Commands

- Build: `swift build`
- Test: `swift test`
- Run: `swift run gitnagg check`

## Architecture

3-layer structure: CLI → Kit → Providers.

- `Sources/gitnagg/` — Entry point (GitNaggMain.swift only)
- `Sources/GitNaggCLI/` — ArgumentParser-based CLI command definitions
- `Sources/GitNaggKit/` — Core logic (CLI-independent)
  - `Runners/` — Command runners that coordinate providers and format output

## Configuration

gitnagg uses ordered rules instead of built-in thresholds.

- `.gitnagg.yml` — Project-level rule config, auto-loaded from cwd
- `resolution: first-match` — Explicit top-to-bottom rule priority in YAML
- `when` supports a single metric condition or nested `and` / `or`
- `--config <path>` — Explicit config path override
- `--metric`, `--gte`, `--severity`, `--message` — Single-rule CLI shortcut that replaces the YAML file. Mutually exclusive with `--config`; these flags do not override rules in `.gitnagg.yml`

## Code Style

- Swift 6.0 strict concurrency (`Sendable` required)
- Default access level is `package` (`public` only for CLI entry)
- Use `logger` (swift-log) for all output. No `print` statements
- Add doc comments to non-trivial types and functions whose role is not obvious from the call site

## Documentation

- When documentation and the existing code disagree, follow the conventions used in the existing code, and in your final reply list every inconsistency you found between the documentation and the code.

## Testing

- Tests live in `Tests/GitNaggKitTests/`
- Git operations are mocked via `GitDiffProvider` protocol + `MockGitDiffProvider`
- Use Swift Testing framework (`import Testing`, `#expect`, `#require`)
- Use parameterized tests (`@Test(arguments:)`) with `CustomTestStringConvertible` for scenarios

## CI/CD

- `.github/workflows/test.yml` — SwiftLint + macOS unit tests on push/PR
- `.github/workflows/publish-release.yml` — workflow_dispatch で macOS universal binary をビルドし GitHub Release を作成

## Hook Integration

gitnagg is intended to be used as a Claude Code PostToolUse hook in `.claude/settings.json`.

PostToolUse hooks require **exit 0** and **JSON stdout** (`{"decision":"block","reason":"..."}`) to surface output to Claude. `gitnagg check --claude-hook` emits that JSON natively and always exits 0, so no wrapper script is required.

### settings.json

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "gitnagg check --claude-hook"
          }
        ]
      }
    ]
  }
}
```

### How it works

1. After each Edit/Write, the hook runs `gitnagg check --claude-hook`
2. If an ordered rule matches, gitnagg writes `{"decision":"block","reason":"<rule message>"}` to stdout and exits 0
3. If no rule matches, gitnagg writes nothing and exits 0
4. `--claude-hook` also exits 0 when config loading or git diff collection fails. It is mutually exclusive with `--quiet` and `--codex-hook`

Rules come from `.gitnagg.yml` in the project root and are evaluated top to bottom with `resolution: first-match`. The first matching rule is the one emitted. `--metric`, `--gte`, `--severity`, and `--message` together are a single-rule shortcut that replaces the YAML file; they are mutually exclusive with `--config` and do not override rules already listed in that file.
