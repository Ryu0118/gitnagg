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

Thresholds are resolved in order: CLI options > `.gitnagg.yml` > built-in defaults (100/100/3).

- `.gitnagg.yml` — Project-level config file, auto-loaded from cwd
- `--config <path>` — Explicit config path override
- `--added`, `--deleted`, `--files` — Per-invocation CLI overrides

## Code Style

- Swift 6.0 strict concurrency (`Sendable` required)
- Default access level is `package` (`public` only for CLI entry)
- Use `logger` (swift-log) for all output. No `print` statements
- Add doc comments to non-trivial types and functions whose role is not obvious from the call site

## Testing

- Tests live in `Tests/GitNaggKitTests/`
- Git operations are mocked via `GitDiffProvider` protocol + `MockGitDiffProvider`
- Use Swift Testing framework (`import Testing`, `#expect`, `#require`)
- Use parameterized tests (`@Test(arguments:)`) with `CustomTestStringConvertible` for scenarios

## CI/CD

- `.github/workflows/test.yml` — SwiftLint + macOS unit tests on push/PR
- `.github/workflows/publish-release.yml` — workflow_dispatch で macOS universal binary をビルドし GitHub Release を作成

## Hook Integration

gitnagg is intended to be used as a Claude Code Hook executable in `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "gitnagg check --quiet"
          }
        ]
      }
    ]
  }
}
```

Thresholds come from `.gitnagg.yml` in the project root. CLI options are only needed to override.
