# syncz

**Version**: run `syncz --version`
**Author**: Matthew Sinclair

---

## Name

`syncz` - Simple directory-to-directory syncer

---

## Synopsis

```bash
syncz [OPTIONS] <source-dir> <dest-dir>
```

---

## Description

syncz provides user-friendly directory-to-directory synchronization with conflict resolution strategies, confirmation prompts, and dry-run support.

For **unidirectional** sync, syncz uses rsync with a "newer-wins" strategy by default. Two alternatives, which cannot be used together: `--source-wins` (always overwrite) and `--dest-wins` (never overwrite existing).

For **bidirectional** sync (`--bidi`), syncz uses [unison](https://www.cis.upenn.edu/~bcpierce/unison/) when available. unison keeps archive state, so it knows whether a file is new or was deleted since the last sync. When unison is not available, syncz falls back to rsync with a two-pass approach (no state tracking).

---

## Options

### Conflict Resolution

| Flag            | Description                       |
| --------------- | --------------------------------- |
| `--source-wins` | Source always overwrites dest     |
| `--dest-wins`   | Dest files are never overwritten  |
| (default)       | Only overwrite if source is newer |

### Safety Options

| Flag                       | Short | Description                                                                      |
| -------------------------- | ----- | -------------------------------------------------------------------------------- |
| `--dry-run`                | `-n`  | Show what would happen without doing it                                          |
| `--confirm [yes\|no\|all]` | `-c`  | Prompt before destructive actions (Y/N/A). Optional arg auto-answers all prompts |
| `--force`                  | `-f`  | Sync with no prompts; permits `--delete`                                         |
| `--just-do-it`             |       | Show summary, single Y/N confirm, then run all                                   |

### Bidirectional Options

| Flag                      | Description                                              |
| ------------------------- | -------------------------------------------------------- |
| `--bidi`                  | Two-way sync (uses unison when available)                |
| `--backend unison\|rsync` | Force a specific sync backend                            |
| `--fresh`                 | Ignore saved state, treat as first sync                  |
| `--prefer d1\|d2\|newer`  | Force conflict resolution (unison backend only)          |
| `--no-metadata`           | Ignore xattrs and resource forks (for cloud filesystems) |

### Feature Options

| Flag            | Short | Description                                                                                 |
| --------------- | ----- | ------------------------------------------------------------------------------------------- |
| `--exclude PAT` | `-x`  | Exclude files matching pattern (repeatable)                                                 |
| `--ignore FILE` |       | Read exclude patterns from file, one per line; `#` starts a comment, and spaces are removed |
| `--delete`      |       | Remove dest files not in source                                                             |
| `--backup`      | `-b`  | Create .syncz-bak copies of overwritten files                                               |
| `--verbose`     | `-v`  | Show detailed per-file output                                                               |
| `--progress`    | `-p`  | Show per-file transfer progress (rsync only)                                                |

### General Options

| Flag        | Short | Description              |
| ----------- | ----- | ------------------------ |
| `--help`    | `-h`  | Show help message        |
| `--version` |       | Show version information |

---

## Confirmation Modes

### No flags (default)

Sync runs immediately. A one-way sync deletes no files. A `--bidi` sync with unison also syncs deletions.

### --confirm

Prompts before each destructive action using Y/N/A responses (see also [--confirm optional argument](#--confirm-optional-argument) for non-interactive use):

- **Y** = proceed with this action
- **N** = skip/abort
- **A** = proceed with all remaining actions (no further prompts)

### --force

No prompts. The input checks still apply. `--force`, `--confirm` and `--just-do-it` cannot be used together in one-way sync.

### --just-do-it

Shows the number of files to copy and to delete, then asks a single Y/N confirmation. If Y, executes everything (including destructive ops) without further prompts.

### --delete safety

In one-way sync, `--delete` requires one of `--confirm`, `--force`, or `--just-do-it`. Using `--delete` alone is an error to prevent accidental data loss.

### --confirm optional argument

`--confirm` accepts an optional `yes`, `no`, or `all` argument that auto-answers all prompts, making syncz fully scriptable:

- `--confirm yes` or `--confirm all`: auto-answer yes to all prompts
- `--confirm no`: auto-answer no to all prompts. A one-way sync then copies nothing.
- `--confirm` (no arg): interactive prompts

This works in both unidirectional and bidirectional modes.

---

## Bidirectional Mode

`--bidi` enables two-way sync between two directories. Both directories are treated symmetrically.

### Backend selection

When `--bidi` is used, syncz automatically selects the best backend:

| Condition                     | Backend | Behavior                                |
| ----------------------------- | ------- | --------------------------------------- |
| unison available (default)    | unison  | State-tracked bidi with archive history |
| unison not available          | rsync   | Two-pass sync, no state tracking        |
| `--backend unison` (explicit) | unison  | Error if unison not installed           |
| `--backend rsync` (explicit)  | rsync   | Forces rsync even if unison available   |

### Unison backend (preferred)

Unison maintains archive state between runs, so it can distinguish new files from deleted files. This prevents the "initial sync wipes everything" problem that rsync bidi has.

- `--fresh`: ignore saved archives (`-ignorearchives`), treat as first sync
- `--dry-run`: show what would be synced, with all changes blocked (`-nocreation`, `-nodeletion`, `-noupdate` on both sides)
- `--prefer d1|d2|newer`: force conflict resolution: `d1` (or `dir1`) = first arg wins, `d2` (or `dir2`) = second arg wins, `newer` = most recently modified wins. Any other value goes to unison `-prefer` as given, eg a path
- `--no-metadata`: ignore extended attributes and resource forks (`-xattrs=false -rsrc=false`). Use it for cloud filesystems, where Dropbox, Google Drive and others stamp their own metadata onto files and cause false conflicts
- `--delete`: no-op, with a warning (unison state-tracks deletions)
- `--exclude PAT`: maps to unison `-ignore "Name PAT"`
- `--backup`: maps to unison `-backup "Name *" -backupsuffix .syncz-bak`
- `--verbose`: drops unison's `-terse`
- `--confirm` (bare): unison prompts per-file interactively
- `--confirm no`: aborts, with no changes
- `--just-do-it`: shows D1 and D2, asks one Y/N, then runs in batch mode
- Default, `--force`, `--confirm yes|all`: batch mode (`-batch -auto`)

For full unison documentation, see `man unison` or <https://www.cis.upenn.edu/~bcpierce/unison/>.

### Path display

With the unison backend, syncz displays paths using shortened labels to avoid repeating long common prefixes:

```
Bidirectional sync (unison)
===========================
  D1:  /path/to/root1
  D2:  /path/to/root2
  Dir: shared/subdir/
```

`D1` and `D2` show the unique root prefixes. `Dir` shows the common directory suffix (if any). These labels are also used in dry-run output (`[new]  D1 → D2`, `[new]  D2 → D1`).

### Dry-run output (unison)

```
Bidirectional sync (unison) — DRY RUN
======================================
  D1:  /path/to/root1
  D2:  /path/to/root2

  [new]  D1 → D2  reports/q4.pdf
  [new]  D2 → D1  notes/meeting.md
  [changed]  readme.md
  [CONFLICT]  config.yaml  (modified on both sides)

  4 file(s) would be synced.

ℹ Dry run - no changes made
```

### rsync backend (fallback)

The rsync backend uses a two-pass approach:

1. **Orphan detection**: files on only one side identified via `find` + `comm`
2. **Orphan resolution**: handled based on flags (see table below)
3. **Pass 1**: dir1 → dir2 (newer-wins rsync, no `--delete`)
4. **Pass 2**: dir2 → dir1 (newer-wins rsync, no `--delete`)

#### Orphan handling (rsync backend)

| Flags                  | Behavior                                                                                |
| ---------------------- | --------------------------------------------------------------------------------------- |
| `--bidi`               | Lists orphans, keeps all (synced to both sides)                                         |
| `--bidi --delete`      | Deletes all orphans with irreversibility warning, with no prompt, also with `--confirm` |
| `--bidi --confirm`     | Interactive per-file prompt (y/N/a, Enter=keep)                                         |
| `--bidi --confirm yes` | Auto-answer yes = delete all orphans                                                    |
| `--bidi --confirm no`  | Auto-answer no = keep all (sync copies them)                                            |
| `--bidi --confirm all` | Same as `--confirm yes`                                                                 |
| `--bidi --dry-run`     | List orphans + show what would sync                                                     |

### Restrictions

- `--source-wins` and `--dest-wins` are errors in bidi mode (only newer-wins makes sense)
- `--delete` does NOT require `--confirm`/`--force`/`--just-do-it` in bidi mode

---

## rsync Flag Mapping

| syncz mode                 | rsync flags                         | Behavior                            |
| -------------------------- | ----------------------------------- | ----------------------------------- |
| default (no conflict flag) | `-rlptD --update`                   | Copy only where source is newer     |
| `--source-wins`            | `-rlptD`                            | Source always overwrites            |
| `--dest-wins`              | `-rlptD --ignore-existing`          | Only copy new files to dest         |
| `--dry-run`                | adds `--dry-run`                    | No transfers, just report           |
| `--verbose`                | adds `--itemize-changes`            | Per-file action output              |
| `--delete`                 | adds `--delete`                     | Remove extraneous dest files        |
| `--backup`                 | adds `--backup --suffix=.syncz-bak` | Backup overwritten files            |
| `--exclude PAT`            | adds `--exclude=PAT`                | Exclude matching files              |
| `--progress`               | adds `--progress`                   | Per-file transfer progress          |
| `--bidi`                   | does NOT add `--delete`             | Orphan resolution handles deletions |

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
# Two-way sync (auto-selects unison if available)
syncz --bidi ~/dir1 ~/dir2

# Preview bidi sync (dry-run)
syncz --bidi --dry-run ~/dir1 ~/dir2

# First sync with fresh state
syncz --bidi --fresh ~/dir1 ~/dir2

# Cloud filesystem sync (ignore xattrs/resource forks)
syncz --bidi --no-metadata ~/Dropbox/project ~/GDrive/project

# Force dir1 to win all conflicts
syncz --bidi --fresh --prefer d1 ~/dir1 ~/dir2

# Use an ignore file for exclude patterns
syncz --bidi --ignore .synczignore ~/dir1 ~/dir2

# Force rsync backend
syncz --bidi --backend rsync ~/dir1 ~/dir2

# Interactive per-file confirmation (unison prompts)
syncz --bidi --confirm ~/dir1 ~/dir2
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

## Known Patterns

### .webloc conflicts

When syncing between cloud storage providers (eg Dropbox and Google Drive), `.webloc` bookmark files may appear as `[CONFLICT]` in dry-run output. Both providers rewrite bookmark metadata, so unison correctly identifies them as "modified on both sides." If you don't care about bookmark metadata differences, exclude them:

```bash
syncz --bidi --exclude "*.webloc" ~/dir1 ~/dir2
```

---

## Files

- `$UTILZ_HOME/opt/syncz/syncz` - Implementation
- `$UTILZ_HOME/opt/syncz/syncz.yaml` - Metadata
- `$UTILZ_HOME/bin/syncz` - Symlink to dispatcher

---

## Environment

| Variable            | Description                                             |
| ------------------- | ------------------------------------------------------- |
| `SYNCZ_ROOTS_SHOWN` | When set, suppresses D1/D2 header (for wrapper scripts) |

---

## Exit Status

- `0` - Success. This includes a unison run that skipped conflicts, an rsync partial transfer (rsync exit 23, with a warning), and a sync aborted at a prompt
- `1` - Error (invalid option, missing directory, etc.)
- Other - rsync's or unison's own exit code, when the sync itself fails

---

## Dependencies

- `unison` (optional): bidirectional sync engine with state tracking; `brew install unison`
- `rsync` (required): pre-installed on most systems; `brew install rsync` on macOS

---

## See Also

- `utilz` - Utilz framework dispatcher
- `rsync(1)` - Remote file copy program
- `unison(1)` - File synchronizer

---

## Author

Matthew Sinclair

---

## Copyright

Copyright (c) 2026 Matthew Sinclair
Part of the Utilz framework.
