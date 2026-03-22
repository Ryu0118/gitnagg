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

By default, gitnagg exits with code **1** only when the matched rule uses `severity: error`. This can block Claude Code hooks or CI pipelines for the rules you consider hard stops.

With `--quiet`, gitnagg still prints the matched message to stderr but always exits with code **0**. Use this in hooks so the warning is visible without interrupting the workflow.

### `exit_code` (YAML)

By default, gitnagg exits with code **1** when an error rule matches. Claude Code hooks require exit code **2** for blocking errors whose message is visible to the assistant. Set `exit_code: 2` in `.gitnagg.yml` to enable this:

```yaml
version: 1
exit_code: 2
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
| 1 | An `error` rule matched without `--quiet` (default) |
| 2 | An `error` rule matched with `exit_code: 2` — Claude Code sees the message as a blocking error |

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

Set `exit_code: 2` in `.gitnagg.yml` so Claude Code receives the matched message as a **blocking error** — the assistant will see the full warning and can decide to commit before continuing:

```yaml
exit_code: 2
```

Without `exit_code: 2`, the hook exits with code 1 and Claude Code only sees a generic error label without the message content.

Rules are read from `.gitnagg.yml` in the project root automatically.

## License

MIT
