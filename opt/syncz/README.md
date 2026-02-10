# syncz

**Version**: 1.3.0
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

Simple directory-to-directory syncer using rsync. Provides conflict resolution strategies, confirmation prompts, dry-run support, and bidirectional sync with orphan detection.

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

# Two-way sync between directories
syncz --bidi ~/dir1 ~/dir2

# Bidi sync, auto-delete orphans
syncz --bidi --delete ~/dir1 ~/dir2

# Bidi sync, fully scripted (keep orphans)
syncz --bidi --confirm no ~/dir1 ~/dir2
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

| Function             | Purpose                                        |
|----------------------|------------------------------------------------|
| `resolve_path()`    | Resolve directory to absolute path              |
| `validate_inputs()` | Check dirs exist, not same, options valid       |
| `build_rsync_args()` | Construct rsync flag array from options        |
| `generate_summary()` | Run dry-run rsync, parse stats for summary     |
| `prompt_yna()`      | Y/N/A prompt helper with CONFIRM_ALL state      |
| `prompt_yn()`       | Simple Y/N prompt for --just-do-it              |
| `execute_delete()`  | Delete-only rsync pass for --confirm mode       |
| `execute_sync()`    | Run rsync with built args                       |
| `detect_orphans()`  | Find files on only one side using find + comm   |
| `resolve_orphans()` | Delete, prompt, or skip orphaned files          |
| `execute_bidi()`    | Orchestrate bidi: orphans → pass 1 → pass 2     |

### Dependencies

**Required:**

- Bash 4.0+ or Zsh
- rsync

---

## Testing

```bash
# Run tests
utilz test syncz

# Run tests directly
cd opt/syncz/test
bats syncz.bats
```

66 tests covering: basic flags, validation, core sync, conflict resolution, features, confirmation prompts, just-do-it mode, edge cases, bidirectional sync, and --confirm optional argument.

---

## License

Part of Utilz framework. Personal use.
Copyright (c) 2026 Matthew Sinclair

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [syncz Help](../../help/syncz.md) - Run: `utilz help syncz`
