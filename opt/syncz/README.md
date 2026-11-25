# syncz

**Version**: run `syncz --version`
**Part of**: [Utilz Framework](../../README.md)

---

## Overview

Simple directory-to-directory syncer. It uses rsync for one-way sync, and unison, when it is available, for state-tracked two-way sync.

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

`syncz.yaml` declares them: `rsync` (required) and `unison` (optional). The script runs under bash 3.2, the bash that macOS ships.

---

## Testing

```bash
utilz test syncz
```

---

## License

MIT. See [LICENSE](../../LICENSE).

---

## See Also

- [Utilz Framework Documentation](../../README.md)
- [syncz Help](../../help/syncz.md) - Run: `utilz help syncz`
