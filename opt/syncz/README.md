# syncz

**Version**: 2.0.0
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

Simple directory-to-directory syncer with dual-backend architecture. Uses rsync for unidirectional sync and unison (when available) for state-tracked bidirectional sync. Provides conflict resolution strategies, confirmation prompts, and dry-run support.

---

## Installation

As part of the Utilz framework, `syncz` is automatically available once the symlink is created:

```bash
cd $UTILZ_HOME/bin
ln -s utilz syncz
```

---

## Usage

```bash
syncz [OPTIONS] <source-dir> <dest-dir>
syncz --bidi [OPTIONS] <dir1> <dir2>
```

For detailed help: `utilz help syncz`

---

## Examples

```bash
# Preview what would be synced
syncz --dry-run ~/src /dst

# Sync with confirmation prompts
syncz --confirm ~/src /dst

# Force sync with deletions and backups
syncz --force --delete --backup ~/src /dst

# Quick confirm-and-go
syncz --just-do-it --delete ~/src /dst

# Source always wins, exclude .git
syncz --source-wins --exclude ".git" ~/src /dst

# Two-way sync (auto-selects unison if available)
syncz --bidi ~/dir1 ~/dir2

# Preview bidi sync
syncz --bidi --dry-run ~/dir1 ~/dir2

# Cloud filesystem sync (ignore xattrs/resource forks)
syncz --bidi --no-metadata ~/Dropbox/project ~/GDrive/project

# Force dir1 to win all conflicts
syncz --bidi --fresh --prefer d1 ~/dir1 ~/dir2

# Use an ignore file for exclude patterns
syncz --bidi --ignore .synczignore ~/dir1 ~/dir2

# Force rsync backend
syncz --bidi --backend rsync ~/dir1 ~/dir2
```

---

## Implementation

### Architecture

```
syncz
├── Invoked via: $UTILZ_HOME/bin/syncz (symlink)
├── Dispatched by: $UTILZ_HOME/bin/utilz
├── Has access to: $UTILZ_HOME/opt/utilz/lib/common.sh
└── Help from: $UTILZ_HOME/help/syncz.md
```

### Key Functions

| Function                      | Purpose                                             |
| ----------------------------- | --------------------------------------------------- |
| `resolve_path()`              | Resolve directory to absolute path                  |
| `validate_inputs()`           | Check dirs exist, not same, options valid           |
| `select_backend()`            | Auto-detect unison for bidi, validate availability  |
| `build_rsync_args()`          | Construct rsync flag array from options             |
| `generate_summary()`          | Run dry-run rsync, parse stats for summary          |
| `_compute_path_labels()`      | Split paths into D1/D2 roots + common Dir suffix    |
| `_unison_build_common_args()` | Shared unison arg builder for dry-run and real sync |
| `unison_bidi_dryrun()`        | Mutation-blocking dry-run with parsed output        |
| `unison_bidi()`               | Bidirectional sync via unison                       |
| `detect_orphans()`            | Find files on only one side (rsync fallback)        |
| `resolve_orphans()`           | Delete, prompt, or skip orphaned files (rsync)      |
| `execute_bidi()`              | Orchestrate rsync bidi: orphans → pass 1 → pass 2   |

### Dependencies

**Required:**

- Bash 4.0+ or Zsh
- rsync

**Optional:**

- unison — Bidirectional sync engine with state tracking (`brew install unison`)

---

## Testing

```bash
# Run tests
utilz test syncz

# Run tests directly
cd opt/syncz/test
bats syncz.bats
```

78 tests covering: basic flags, validation, core sync, conflict resolution, features, confirmation prompts, just-do-it mode, edge cases, bidirectional sync, --confirm optional argument, backend selection, and unison bidi sync.

---

## License

Part of Utilz framework. Personal use.
Copyright (c) 2026 Matthew Sinclair

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [syncz Help](../../help/syncz.md) - Run: `utilz help syncz`
