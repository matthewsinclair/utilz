# Design - ST0006: Move syncz to use unison with rsync fallback

## Approach

Thin bidi-only wrapper — syncz calls unison for `--bidi` mode with sensible defaults, passes through its output, and keeps rsync for everything else. This is deliberately NOT a feature-complete unison wrapper (no unison for uni-mode).

## Design Decisions

### Unison for bidi only — rsync stays for uni mode

The original spec (R2) proposed mapping all syncz options to unison equivalents for both uni and bidi modes. This was rejected in favor of a thin approach:

- **Uni-mode rsync works perfectly** — no reason to change a working backend
- **Unison output parsing is fragile** — format varies between versions, locale, etc.
- **Flag mapping is awkward** — rsync and unison have fundamentally different models (rsync: source→dest push; unison: symmetric replica sync). Forcing unison into rsync's uni-mode mental model adds complexity for no benefit.

### Dry-run via mutation blocking (not unison's -dryrun)

The original spec assumed unison had a `-dryrun` flag. It does not. Instead, dry-run is implemented by running unison with all mutations blocked on both sides:

```bash
-nocreation "$dir1" -nocreation "$dir2"
-nodeletion "$dir1" -nodeletion "$dir2"
-noupdate "$dir1" -noupdate "$dir2"
```

Unison still detects changes and reports them as `skipped:` lines. These are parsed into a human-readable format with `[new]`, `[changed]`, and `[CONFLICT]` tags.

### Path display with D1/D2/Dir labels

Cloud sync scenarios often have long paths with a common suffix (e.g., `/Users/x/Dropbox/Projects/A3` vs `/Users/x/GDrive/Projects/A3`). `_compute_path_labels()` finds the longest common directory suffix and splits the display:

```
  D1:  /Users/x/Dropbox
  D2:  /Users/x/GDrive
  Dir: Projects/A3/
```

### SYNCZ_ROOTS_SHOWN env var for wrapper scripts

The `bin/sync` wrapper invokes syncz multiple times in a loop (one per subdirectory). Without suppression, each invocation would print its own D1/D2 header. Setting `SYNCZ_ROOTS_SHOWN=1` tells syncz to skip the header — the wrapper prints roots once at the top.

### --delete is a no-op in unison bidi

Unison state-tracks deletions automatically via its archive. The `--delete` flag (which in rsync bidi meant "prune orphans") is semantically meaningless in unison mode. Rather than silently ignoring it, syncz prints a notice explaining why.

### --fresh flag instead of --ignore-archives

The original spec suggested `--no-state` as an alternative name. `--fresh` was chosen as shorter and more intuitive ("fresh sync" = "ignore history, treat as first time").

### --no-metadata for cloud filesystem sync

Cloud filesystems (Dropbox, Google Drive) stamp their own extended attributes and resource forks onto files. This causes false conflicts in unison — the file content is identical but the metadata differs. `--no-metadata` maps to `-xattrs=false -rsrc=false`, telling unison to ignore these. Initially `-xattrs=false` was hardcoded; `-rsrc=false` was added after discovering macOS resource fork mismatches, then both were moved behind the `--no-metadata` flag (caller policy, not hardcoded) since they're only needed for cloud sync scenarios.

### --prefer for conflict resolution

Unison's `-prefer` flag resolves conflicts by picking one side. syncz maps `d1`/`d2` to the actual directory paths (first/second positional arg), `newer` passes through directly. This is particularly useful for initial sync where one side is canonical. Raw unison path values are also accepted as a passthrough.

### --ignore FILE for exclude patterns from file

Rather than requiring many `--exclude` flags on the command line, `--ignore FILE` reads patterns from a file (one per line, `#` comments supported, blank lines ignored). Each pattern is added to the same `EXCLUDE_PATTERNS` array used by `--exclude`. This parallels `.gitignore` conventions.

### Dispatcher intercepts --version

The utilz dispatcher (`bin/utilz`) handles `--version` before dispatching to the utility script. Custom per-utility version output (like showing backend info) is not possible without modifying the dispatcher. This was accepted as a non-issue — `utilz doctor` shows dependency status.

## Architecture

```
syncz
├── arg parsing (--backend, --fresh, --prefer, --no-metadata, --ignore FILE)
├── validate_inputs()
├── select_backend()               ← sets SYNCZ_BACKEND
├── backend-aware validations      ← --fresh+rsync warning
│
├── bidi dispatch
│   ├── unison
│   │   ├── unison_bidi_dryrun()   ← mutation-blocking dry-run
│   │   └── unison_bidi()          ← real sync
│   └── rsync → execute_bidi()     ← unchanged
│
├── _compute_path_labels()         ← D1/D2/Dir path display
├── _unison_build_common_args()    ← shared arg builder
│
└── uni-mode (always rsync, unchanged)
```

## Alternatives Considered

### Full unison wrapper (rejected)

Map all syncz options to unison for both uni and bidi modes. Rejected: high complexity, fragile output parsing, awkward uni-mode flag mapping, for no real benefit over rsync in uni mode.

### Custom state file for rsync bidi (rejected)

Build archive-based state tracking for the rsync two-pass approach. Rejected: reimplementing what unison already does well; maintenance burden of a custom state format.

### Replace syncz entirely with unison alias (rejected)

Just alias `syncz --bidi` to `unison`. Rejected: loses utilz integration (yaml metadata, BATS tests, help system, common.sh), loses rsync uni-mode features, loses confirmation workflow.

### Refuse dry-run in unison mode (rejected, then implemented differently)

Initial implementation refused `--dry-run` with an error message. This was replaced with the mutation-blocking approach after discovering that unison's `-nocreation/-nodeletion/-noupdate` flags effectively create a read-only dry-run.
