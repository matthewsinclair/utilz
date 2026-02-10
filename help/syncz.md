# syncz

**Version**: 1.3.0
**Author**: Matthew Sinclair

---

## Name

`syncz` - Simple directory-to-directory syncer using rsync

---

## Synopsis

```bash
syncz [OPTIONS] <source-dir> <dest-dir>
```

---

## Description

syncz wraps rsync to provide user-friendly directory-to-directory synchronization with conflict resolution strategies, confirmation prompts, and dry-run support.

By default, syncz uses a "newer-wins" strategy: only files where the source is newer than the destination are transferred. Two alternative strategies are available: `--source-wins` (always overwrite) and `--dest-wins` (never overwrite existing files).

syncz uses `-rlptD` instead of rsync's `-a` flag to avoid group/owner warnings for non-root user-level syncs.

---

## Options

### Conflict Resolution

| Flag             | Description                          |
|------------------|--------------------------------------|
| `--source-wins`  | Source always overwrites dest        |
| `--dest-wins`    | Dest files are never overwritten     |
| (default)        | Only overwrite if source is newer    |

### Safety Options

| Flag                        | Short | Description                                       |
|-----------------------------|-------|---------------------------------------------------|
| `--dry-run`                 | `-n`  | Show what would happen without doing it           |
| `--confirm [yes\|no\|all]`  | `-c`  | Prompt before destructive actions (Y/N/A). Optional arg auto-answers all prompts |
| `--force`                   | `-f`  | Force sync (no safety checks)                     |
| `--just-do-it`              |       | Show summary, single Y/N confirm, then run all    |

### Bidirectional Options

| Flag      | Description                                                |
|-----------|------------------------------------------------------------|
| `--bidi`  | Two-way sync with orphan detection                         |

### Feature Options

| Flag                        | Short | Description                                       |
|-----------------------------|-------|---------------------------------------------------|
| `--exclude PAT`             | `-x`  | Exclude files matching pattern (repeatable)       |
| `--delete`                  |       | Remove dest files not in source                   |
| `--backup`                  | `-b`  | Create .syncz-bak copies of overwritten files     |
| `--verbose`                 | `-v`  | Show detailed per-file output                     |
| `--progress`                | `-p`  | Show per-file transfer progress                   |

### General Options

| Flag                        | Short | Description                                       |
|-----------------------------|-------|---------------------------------------------------|
| `--help`                    | `-h`  | Show help message                                 |
| `--version`                 |       | Show version information                          |

---

## Confirmation Modes

### No flags (default)

Sync runs immediately with safe defaults. No deletions are performed.

### --confirm

Prompts before each destructive action using Y/N/A responses (see also [--confirm optional argument](#--confirm-optional-argument) for non-interactive use):

- **Y** = proceed with this action
- **N** = skip/abort
- **A** = proceed with all remaining actions (no further prompts)

### --force

No prompts. Overrides all safety checks. Skips all confirmation.

### --just-do-it

Shows a complete summary of all planned actions, then asks a single Y/N confirmation. If Y, executes everything (including destructive ops) without further prompts.

### --delete safety

`--delete` requires one of `--confirm`, `--force`, or `--just-do-it`. Using `--delete` alone is an error to prevent accidental data loss.

### --confirm optional argument

`--confirm` accepts an optional `yes`, `no`, or `all` argument that auto-answers all prompts, making syncz fully scriptable:

- `--confirm yes` or `--confirm all` — auto-answer yes to all prompts
- `--confirm no` — auto-answer no to all prompts (skip destructive actions)
- `--confirm` (no arg) — interactive prompts as before

This works in both unidirectional and bidirectional modes.

---

## Bidirectional Mode

`--bidi` enables two-way sync between two directories. Instead of source→dest, both directories are treated symmetrically.

### How it works

1. **Orphan detection** — Files that exist on only one side are identified using `find` + `comm`
2. **Orphan resolution** — Orphans are handled based on flags (see below)
3. **Pass 1** — dir1 → dir2 (newer-wins rsync, no `--delete`)
4. **Pass 2** — dir2 → dir1 (newer-wins rsync, no `--delete`)

### Orphan handling

| Flags                   | Behavior                              |
|-------------------------|---------------------------------------|
| `--bidi`                | Interactive prompt per orphan (Y/n/a) |
| `--bidi --delete`       | Silently delete all orphans           |
| `--bidi --confirm yes`  | Auto-answer yes = delete all orphans  |
| `--bidi --confirm no`   | Auto-answer no = keep all (sync copies them) |
| `--bidi --confirm all`  | Same as `--confirm yes`               |
| `--bidi --dry-run`      | List orphans + show what would sync   |

### Restrictions

- `--source-wins` and `--dest-wins` are errors in bidi mode (only newer-wins makes sense)
- `--delete` does NOT require `--confirm`/`--force`/`--just-do-it` in bidi mode
- rsync `--delete` is never passed to rsync in bidi mode (orphan resolution handles deletions)

---

## rsync Flag Mapping

| syncz mode                 | rsync flags                          | Behavior                           |
|----------------------------|--------------------------------------|------------------------------------|
| default (no conflict flag) | `-rlptD --update`                    | Copy only where source is newer    |
| `--source-wins`            | `-rlptD`                             | Source always overwrites           |
| `--dest-wins`              | `-rlptD --ignore-existing`           | Only copy new files to dest        |
| `--dry-run`                | adds `--dry-run`                     | No transfers, just report          |
| `--verbose`                | adds `--itemize-changes`             | Per-file action output             |
| `--delete`                 | adds `--delete`                      | Remove extraneous dest files       |
| `--backup`                 | adds `--backup --suffix=.syncz-bak`  | Backup overwritten files           |
| `--exclude PAT`            | adds `--exclude=PAT`                 | Exclude matching files             |
| `--progress`               | adds `--progress`                    | Per-file transfer progress         |
| `--bidi`                   | does NOT add `--delete`              | Orphan resolution handles deletions |

---

## Examples

### Basic Usage

```bash
# Preview what would be synced
syncz --dry-run ~/Documents/project /backup/project

# Sync directories (newer-wins)
syncz ~/src /dst

# Sync with confirmation prompts
syncz --confirm ~/src /dst

# Force sync, no prompts
syncz --force ~/src /dst
```

### Conflict Resolution

```bash
# Source always wins (even if dest is newer)
syncz --source-wins ~/src /dst

# Only copy new files, never overwrite existing
syncz --dest-wins ~/src /dst
```

### Destructive Operations

```bash
# Delete extra files in dest (with confirmation)
syncz --confirm --delete ~/src /dst

# Delete extra files in dest (force, no prompts)
syncz --force --delete ~/src /dst

# Delete with single confirm-and-go
syncz --just-do-it --delete ~/src /dst
```

### Bidirectional

```bash
# Two-way sync with interactive orphan prompts
syncz --bidi ~/dir1 ~/dir2

# Preview bidi sync (dry-run)
syncz --bidi --dry-run --verbose ~/dir1 ~/dir2

# Bidi sync, auto-delete orphans
syncz --bidi --delete ~/dir1 ~/dir2

# Bidi sync, keep all orphans (copy to both sides)
syncz --bidi --confirm no ~/dir1 ~/dir2

# Fully non-interactive bidi with orphan deletion
syncz --bidi --confirm yes ~/dir1 ~/dir2
```

### Advanced

```bash
# Exclude patterns
syncz --exclude "*.tmp" --exclude ".git" ~/src /dst

# Backup overwritten files
syncz --force --backup ~/src /dst

# Verbose output with progress
syncz --verbose --progress ~/src /dst

# Full pipeline: backup, delete, confirm, verbose
syncz --confirm --delete --backup --verbose ~/src /dst
```

---

## Files

- `$UTILZ_HOME/opt/syncz/syncz` - Implementation
- `$UTILZ_HOME/opt/syncz/syncz.yaml` - Metadata
- `$UTILZ_HOME/bin/syncz` - Symlink to dispatcher

---

## Environment

- `UTILZ_HOME` - Root directory of Utilz framework

---

## Exit Status

- `0` - Success
- `1` - Error (invalid option, missing directory, etc.)

---

## Dependencies

- `rsync` (required) - Pre-installed on most systems; `brew install rsync` on macOS

---

## See Also

- `utilz` - Utilz framework dispatcher
- `rsync(1)` - Remote file copy program

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2026 Matthew Sinclair
Part of the Utilz framework.
