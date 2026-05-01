# gitnagg - Nag you to commit when uncommitted changes pile up.

[![Language](https://img.shields.io/badge/Language-Swift-F05138?style=flat-square)](https://www.swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey?style=flat-square)](https://github.com/Ryu0118/gitnagg/releases/latest)
[![License](https://img.shields.io/badge/License-MIT-007ec6?style=flat-square)](LICENSE)

A CLI tool that monitors uncommitted git changes and warns you when ordered rules match. Designed for local use and as a hook executable for **Claude Code** and **Codex**.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Ryu0118/gitnagg/main/install.sh | bash
```

To update, run the same command. It skips the download if already up-to-date.

```bash
# Install a specific version
curl -fsSL https://raw.githubusercontent.com/Ryu0118/gitnagg/main/install.sh | VERSION=0.1.0 bash

# Force reinstall
curl -fsSL https://raw.githubusercontent.com/Ryu0118/gitnagg/main/install.sh | FORCE=1 bash
```

### Other methods

#### Nest ([mtj0928/nest](https://github.com/mtj0928/nest))

```bash
nest install Ryu0118/gitnagg
```

#### Mise ([jdx/mise](https://github.com/jdx/mise))

```bash
mise use -g ubi:Ryu0118/gitnagg
```

#### Build from source

Requires Swift 6.0+ and macOS 15+.

```bash
git clone https://github.com/Ryu0118/gitnagg.git
cd gitnagg
swift build -c release
# Binary at .build/release/gitnagg
```

## Configuration

### Config file (`.gitnagg.yml`)

Place a `.gitnagg.yml` in your project root. gitnagg automatically reads it when no `--config` option is given.

Rules are evaluated from top to bottom. With `resolution: first-match`, the first matching rule wins. That makes the priority explicit in the YAML itself.

```yaml
version: 1
resolution: first-match

rules:
  - severity: error
    message: Commit now. This diff is already painful to review.
    when:
      or:
        - metric: added
          gte: 300
        - metric: deleted
          gte: 180
        - metric: files
          gte: 12

  - severity: warning
    message: This is a good checkpoint. Commit before the diff gets harder to reason about.
    when:
      and:
        - metric: added
          gte: 100
        - metric: deleted
          gte: 50
        - metric: files
          gte: 3

  - severity: warning
    message: The diff is spreading out. Make a checkpoint commit soon.
    when:
      or:
        - metric: added
          gte: 180
        - metric: files
          gte: 8

  - severity: info
    message: You have enough local change to justify a checkpoint commit.
    when:
      metric: added
      gte: 80
```

### Rule semantics

- `rules` are ordered. The first matching rule is the one that is emitted.
- `when` supports a single condition, `and`, or `or`.
- Supported metrics are `added`, `deleted`, and `files`.
- The only comparison operator today is `gte` (`>=`).
- There are no built-in default rules. If you configure nothing, gitnagg does nothing.
- In normal CLI mode, `severity: error` exits with the configured `exit_code` (default: `2`) unless `--quiet` is used.
- In normal CLI mode, `info` and `warning` rules stay at exit code `0`.
- In hook modes (`--claude-hook` or `--codex-hook`), gitnagg always exits with code `0` and emits hook JSON to stdout only when a rule matches.

## Usage

```bash
# Uses .gitnagg.yml if present
gitnagg check

# Use a custom config file
gitnagg check --config path/to/config.yml

# Simple one-condition rule from the CLI
gitnagg check \
  --metric added \
  --gte 150 \
  --severity warning \
  --message "Good checkpoint. Commit before the diff grows further."

# Quiet mode (exit 0 even when thresholds exceeded, just print warning)
gitnagg check --quiet

# Claude Code PostToolUse hook mode
gitnagg check --claude-hook

# Codex PostToolUse hook mode
gitnagg check --codex-hook
```

The CLI rule options are intentionally limited to one simple condition. Use YAML for ordered multi-rule setups or `and`/`or` conditions.

### Hook flags

Use `--claude-hook` or `--codex-hook` when gitnagg is called from an agent hook.

Both flags:

- Always exit with code **0**, including config or git-diff errors.
- Emit `{"decision":"block","reason":"..."}` to stdout when a rule matches.
- Emit nothing when no rule matches.
- Are mutually exclusive with each other and with `--quiet`.

The output schema is intentionally compatible with Claude Code and Codex `PostToolUse` hooks. Claude Code treats `decision: "block"` as a blocking hook response. Codex treats it as a replacement tool result that the model reads before continuing.

### `--quiet` flag

By default, gitnagg exits with code **2** when the matched rule uses `severity: error`.

With `--quiet`, gitnagg still prints the matched message to stderr but always exits with code **0**. Use hook flags instead of `--quiet` for Claude Code or Codex integration.

### `exit_code` (YAML)

The default exit code is **2**. To use a different exit code (e.g., `1` for traditional CI pipelines), set `exit_code` in `.gitnagg.yml`:

```yaml
version: 1
exit_code: 1  # override default (2) for CI pipelines
rules:
  - severity: error
    message: Diff too large. Split before continuing.
    when:
      metric: added
      gte: 700
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | No rule matched, a non-error rule matched, or `--quiet` flag was used |
| 2 | An `error` rule matched without `--quiet` (default; configurable with `exit_code`) |

Hook modes always exit with code `0`.

### Example Output

If the second rule in the sample config matches:

```text
This is a good checkpoint. Commit before the diff gets harder to reason about.
```

## Hook Integration

### Claude Code

Add to `.claude/settings.json` (project or user level):

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

When a rule matches, gitnagg emits hook JSON like this to stdout:

```json
{"decision":"block","reason":"Commit now. This diff is already painful to review."}
```

Claude Code receives that as a blocking `PostToolUse` response. The process still exits with code `0`, which keeps the JSON parseable by the hook runtime.

### Codex

Enable hooks in Codex and call gitnagg with `--codex-hook` from a `PostToolUse` command hook:

```toml
[features]
codex_hooks = true

[[hooks.PostToolUse]]
matcher = "Edit|Write"

[[hooks.PostToolUse.hooks]]
type = "command"
command = "gitnagg check --codex-hook"
timeout = 30
```

Codex uses the same JSON shape, but `decision: "block"` is provided back to the model as the tool result instead of pausing the session.

Rules are read from `.gitnagg.yml` in the project root automatically.

## License

MIT
