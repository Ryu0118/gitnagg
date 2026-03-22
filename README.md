# gitnagg - Nag you to commit when uncommitted changes pile up.

[![Language](https://img.shields.io/badge/Language-Swift-F05138?style=flat-square)](https://www.swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey?style=flat-square)](https://github.com/Ryu0118/gitnagg/releases/latest)
[![License](https://img.shields.io/badge/License-MIT-007ec6?style=flat-square)](LICENSE)

A CLI tool that monitors uncommitted git changes and warns you when thresholds are exceeded. Designed as a hook executable for **Claude Code Hooks**.

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

```yaml
# .gitnagg.yml
added: 100     # Max added lines before nagging
deleted: 100   # Max deleted lines before nagging
files: 3       # Max changed files before nagging
```

### Threshold resolution order

1. **CLI options** (`--added`, `--deleted`, `--files`) — highest priority
2. **YAML config file** (`.gitnagg.yml` or path given by `--config`)
3. **Built-in defaults** — `added: 100`, `deleted: 100`, `files: 3`

CLI options override YAML values per-field. Unspecified fields fall through to YAML, then to defaults.

## Usage

```bash
# Uses .gitnagg.yml if present, otherwise built-in defaults
gitnagg check

# Override specific thresholds via CLI
gitnagg check --added 200 --deleted 150 --files 5

# Use a custom config file
gitnagg check --config path/to/config.yml

# Quiet mode (exit 0 even when thresholds exceeded, just print warning)
gitnagg check --quiet
```

### `--quiet` flag

By default, gitnagg exits with code **1** when any threshold is exceeded. This can block Claude Code hooks or CI pipelines.

With `--quiet`, gitnagg still prints the warning to stderr but always exits with code **0**. Use this in hooks so the warning is visible without interrupting the workflow.

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All clear, or `--quiet` flag used |
| 1 | Thresholds exceeded (without `--quiet`) |

### Example Output

```
[gitnagg] Uncommitted changes are piling up! Consider committing.

  ⚠ Added lines: 150 (threshold: 100)
  ⚠ Changed files: 5 (threshold: 3)

  Stats: +150 -20 in 5 file(s)
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
            "command": "gitnagg check --quiet"
          }
        ]
      }
    ]
  }
}
```

Thresholds are read from `.gitnagg.yml` in the project root automatically. No need to pass `--added`/`--deleted`/`--files` in the hook command if the config file exists.

When thresholds are exceeded, a warning is printed to stderr as hook output, reminding Claude (and you) to commit.

## License

MIT
