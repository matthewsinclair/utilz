# retry

**Version**: 1.0.0
**Author**: Matthew Sinclair

---

## Name

`retry` - Retry command until success with configurable wait time

---

## Synopsis

```bash
retry [OPTIONS] [ARGS]
```

---

## Description

Retry command until success with configurable wait time

Add more detailed description here.

---

## Options

### General Options

- `-h, --help` - Show help message
- `--version` - Show version information

---

## Examples

### Basic Usage

```bash
# Show help
retry --help

# Show version
retry --version
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

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2025 Matthew Sinclair
Part of the Utilz framework.
