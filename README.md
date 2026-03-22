# gitnagg - Nag you to commit when uncommitted changes pile up.

[![Language](https://img.shields.io/badge/Language-Swift-F05138?style=flat-square)](https://www.swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey?style=flat-square)](https://github.com/Ryu0118/gitnagg/releases/latest)
[![License](https://img.shields.io/badge/License-MIT-007ec6?style=flat-square)](LICENSE)

A CLI tool that monitors uncommitted git changes and warns you when ordered rules match. Designed as a hook executable for **Claude Code Hooks**.

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
- `severity: error` exits with code `1` unless `--quiet` is used. `info` and `warning` stay at exit code `0`.

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
```

The CLI rule options are intentionally limited to one simple condition. Use YAML for ordered multi-rule setups or `and`/`or` conditions.

### `--quiet` flag

By default, gitnagg exits with code **2** when the matched rule uses `severity: error`. This is designed for Claude Code hooks, where exit code 2 makes the message visible to the assistant as a blocking error.

With `--quiet`, gitnagg still prints the matched message to stderr but always exits with code **0**. Use this in hooks so the warning is visible without interrupting the workflow.

### `exit_code` (YAML)

The default exit code is **2**, which works out of the box with Claude Code hooks. To use a different exit code (e.g., `1` for traditional CI pipelines), set `exit_code` in `.gitnagg.yml`:

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
| 2 | An `error` rule matched without `--quiet` (default) — Claude Code sees the message as a blocking error |

### Example Output

If the second rule in the sample config matches:

```text
This is a good checkpoint. Commit before the diff gets harder to reason about.
```

## Hook Integration

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
            "command": "gitnagg check"
          }
        ]
      }
    ]
  }
}
```

The default exit code is **2**, so Claude Code receives the matched message as a **blocking error** out of the box — no extra configuration needed.

Rules are read from `.gitnagg.yml` in the project root automatically.

## License

MIT
