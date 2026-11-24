# retry

**Version**: run `retry --version`
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

retry joins all its remaining arguments with spaces and runs the result with `eval` in a subshell. The command's stderr goes to stdout. The first run counts as one attempt.

---

## Options

- `-w, --wait <seconds>` - Wait time between retries, a whole number (default: 10)
- `-r, --retries <count>` - Maximum attempts, including the first run, 0 for unlimited (default: 0)
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
- `1` - Error: no command, unknown option, or a bad `--wait` or `--retries` value
- Other - The command's own exit status from the last attempt, when the attempts run out

---

## See Also

- `utilz help` - Utilz framework help

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2025 Matthew Sinclair
Part of the Utilz framework.
