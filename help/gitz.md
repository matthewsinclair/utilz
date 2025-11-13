# gitz

**Version**: 1.0.0
**Author**: Matthew Sinclair

---

## Name

`gitz` - Git multi-repository operations

---

## Synopsis

```bash
gitz <command> [args]
```

---

## Description

Git multi-repository operations - recursively find and check git repositories.

Excludes repositories with '_' or '.work' in their path.

---

## Commands

- `status-all [path]` - Show git status for all repositories (default: current directory)
- `status [path]` - Alias for status-all

---

## Options

### General Options

- `-h, --help` - Show help message
- `--version` - Show version information

---

## Examples

### Check Repositories

```bash
# Check all repos in current directory
gitz status-all

# Check all repos in specific path
gitz status-all ~/Projects

# Using the alias
gitz status
```

---

## Files

- `$UTILZ_HOME/opt/gitz/gitz` - Implementation
- `$UTILZ_HOME/opt/gitz/gitz.yaml` - Metadata
- `$UTILZ_HOME/bin/gitz` - Symlink to dispatcher

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
- [gitz README]($UTILZ_HOME/opt/gitz/README.md) - Detailed documentation

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2025 Matthew Sinclair
Part of the Utilz framework.
