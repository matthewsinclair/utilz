# retry

**Version**: 1.0.0
**Author**: Matthew Sinclair

---

## Name

`retry` - Retry command until success with configurable wait time

---

## Synopsis

```bash
retry [OPTIONS] <command>
```

---

## Description

Retry command until success with configurable wait time.

Executes a command repeatedly until it succeeds or max retries is reached.

---

## Options

- `-w, --wait <seconds>` - Wait time between retries (default: 10)
- `-r, --retries <count>` - Maximum retry attempts, 0 for unlimited (default: 0)
- `-h, --help` - Show help message
- `--version` - Show version information

---

## Examples

### Basic Usage

```bash
# Retry with defaults (10 second wait, unlimited retries)
retry "curl https://example.com"

# Retry with 5 second wait and max 3 attempts
retry --wait 5 --retries 3 "ping -c 1 google.com"

# Retry with unlimited attempts and 30 second wait
retry -w 30 "docker ps"

# Short options
retry -w 5 -r 10 "npm install"
```

---

## Files

- `$UTILZ_HOME/opt/retry/retry` - Implementation
- `$UTILZ_HOME/opt/retry/retry.yaml` - Metadata
- `$UTILZ_HOME/bin/retry` - Symlink to dispatcher

---

## Environment

- `UTILZ_HOME` - Root directory of Utilz framework

---

## Exit Status

- `0` - Success
- `1` - General error

---

## See Also

- `utilz(1)` - Utilz framework dispatcher
- `utilz-help(1)` - Show help for utilities
- [retry README]($UTILZ_HOME/opt/retry/README.md) - Detailed documentation

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2025 Matthew Sinclair
Part of the Utilz framework.
