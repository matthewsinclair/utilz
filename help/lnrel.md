# lnrel

**Version**: 1.0.0
**Author**: Matthew Sinclair

---

## Name

`lnrel` - Create symlinks with relative paths

---

## Synopsis

```bash
lnrel <target> [<link_name>]
```

---

## Description

lnrel creates symlinks using relative paths instead of absolute ones. Given a target and an optional link name, it computes the relative path from the link's directory to the target using GNU `realpath`, then creates a symlink with that relative path.

Relative symlinks are portable — they survive directory tree moves, making them ideal for projects, dotfile repos, and any situation where absolute paths would break.

The target does not need to exist; `lnrel` uses `realpath -m` to resolve paths without requiring the file to be present, allowing creation of dangling symlinks for future targets.

---

## Options

| Flag        | Short | Description              |
|-------------|-------|--------------------------|
| `--help`    | `-h`  | Show help message        |
| `--version` |       | Show version information |

---

## Arguments

| Argument      | Required | Description                                           |
|---------------|----------|-------------------------------------------------------|
| `<target>`    | Yes      | Path to the symlink target (file or directory)        |
| `<link_name>` | No       | Path for the symlink (default: basename of target in cwd) |

---

## Examples

### Default link name (basename in current directory)

```bash
# Creates ./config.yaml -> relative path to /opt/shared/config.yaml
lnrel /opt/shared/config.yaml
```

### Explicit link name

```bash
# Creates my-link.txt -> relative path to ../data/file.txt
lnrel ../data/file.txt my-link.txt
```

### Cross-directory

```bash
# Creates ./data/db.sqlite -> relative path to /opt/data/db.sqlite
lnrel /opt/data/db.sqlite ./data/db.sqlite
```

### Non-existent target (dangling symlink)

```bash
# Creates placeholder.txt -> ../future/file.txt (target need not exist)
lnrel ../future/file.txt placeholder.txt
```

---

## Platform Requirements

| Platform | Requirement              | Install                  |
|----------|--------------------------|--------------------------|
| macOS    | GNU coreutils            | `brew install coreutils` |
| Linux    | coreutils (pre-installed)| Usually built-in         |

macOS ships BSD `realpath` which lacks the `-m` and `--relative-to` flags. `lnrel` automatically detects `grealpath` (installed by Homebrew coreutils) and falls back to `realpath` if it supports the required flags.

---

## Files

- `$UTILZ_HOME/opt/lnrel/lnrel` - Implementation
- `$UTILZ_HOME/opt/lnrel/lnrel.yaml` - Metadata
- `$UTILZ_HOME/bin/lnrel` - Symlink to dispatcher

---

## Environment

| Variable    | Description                       |
|-------------|-----------------------------------|
| `UTILZ_HOME`| Root directory of Utilz framework |

---

## Exit Status

- `0` - Success
- `1` - Error (missing arguments, directory not found, realpath not available, ln failed)

---

## See Also

- `utilz` - Utilz framework dispatcher
- `ln(1)` - Make links between files
- `realpath(1)` - Return resolved physical path

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2026 Matthew Sinclair
Part of the Utilz framework.
