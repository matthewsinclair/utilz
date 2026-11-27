# gitz

**Version**: run `gitz --version`
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

gitz finds each `.git` directory under the path and runs `git status` in its repository. It skips a repository when a path component starts with `_`, or when the path contains `.work`. A `.git` file (eg a linked worktree or a submodule) is not a match. When it finds no repository, gitz warns and exits 0.

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

`gitz` reads no environment variables of its own.

---

## Exit Status

- `0` - Success
- `1` - Error, eg unknown command or `git` not found

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
