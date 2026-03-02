---
verblock: "02 Mar 2026:v0.2: matts - Full requirements spec"
intent_version: 2.4.0
status: WIP
slug: move-syncz-to-use-unison-with-rsync-fallback
created: 20260302
completed:
---

# ST0006: Move syncz to use unison with rsync fallback

## Objective

Refactor `syncz` to use [unison](https://github.com/bcpierce00/unison) as its sync engine instead of rsync. Unison provides true bidirectional sync with state tracking (baseline snapshots), solving the fundamental problem that rsync-based bidi sync cannot distinguish "new file" from "deleted file." Retain rsync as a fallback engine when unison is not installed, preserving the current behavior.

## Context

### The problem

`syncz --bidi` currently uses rsync in a two-pass pattern (dir1→dir2, dir2→dir1) with manual orphan detection via `find` + `comm`. This approach has a critical flaw: files that exist on only one side are ambiguous — they could be new files that need copying, or deleted files that need pruning. Without a state file recording what existed after the last sync, there is no way to tell.

This was discovered during initial sync of Dropbox ↔ Google Drive for the A3 project, where ~4,669 "orphan" files would have been deleted from Dropbox by the default interactive prompt (which defaulted to delete-on-Enter). A hotfix was applied (safe defaults, keep orphans) but the underlying architecture is wrong.

### Why unison

Unison solves this correctly out of the box:

- **State tracking**: Stores archive files (`~/.unison/`) recording the state of both replicas after each successful sync. On subsequent runs, it diffs each side against the archive to determine new/modified/deleted files.
- **True bidirectional**: Single-pass, not two rsync passes. Handles conflicts (same file modified on both sides) with configurable resolution.
- **Battle-tested**: Maintained since the late 1990s, written in OCaml, widely used.
- **Already installed**: Available at `/opt/homebrew/bin/unison` (v2.53.8) on the target system.

### Why keep syncz (not just use unison directly)

syncz provides value as a wrapper:

- **Simplified CLI**: Friendlier than unison's raw interface for common cases
- **Utilz integration**: Sources `common.sh`, follows utilz patterns (yaml metadata, BATS tests, help system)
- **Consistent UX**: Summary output, dry-run, progress, `--just-do-it` workflow
- **Fallback**: Systems without unison still get rsync-based sync (unidirectional + best-effort bidi)

## Requirements Spec

### R1: Backend detection and selection

At startup, syncz must detect which backend is available:

```
if unison is found → use unison backend
else if rsync is found → use rsync backend (current behavior)
else → error and exit
```

- Check via `command -v unison` and `command -v rsync`
- When using rsync fallback in `--bidi` mode, print a warning: `"Warning: unison not found; falling back to rsync (no state tracking for bidi)"`
- Add `--backend unison|rsync` flag to force a specific backend (useful for testing)
- `syncz --version` should show which backend is active

### R2: Unison backend — unidirectional sync (`syncz src dst`)

Map syncz's current unidirectional options to unison flags:

| syncz option          | unison equivalent                                                                        |
| --------------------- | ---------------------------------------------------------------------------------------- |
| (default, newer-wins) | `unison src dst -force newer -batch`                                                     |
| `--source-wins`       | `unison src dst -force src -batch`                                                       |
| `--dest-wins`         | `unison src dst -force dst -batch` with `-nodeletion dst`                                |
| `-n, --dry-run`       | `-dryrun` (unison's built-in dry-run, shows plan without executing)                      |
| `-v, --verbose`       | Default unison output (it's already verbose); possibly `-terse` for non-verbose          |
| `-p, --progress`      | Already included in unison output                                                        |
| `-x, --exclude PAT`   | `-ignore 'Name PAT'` (repeatable)                                                        |
| `--delete`            | Default unison behavior (propagates deletions); without `--delete` use `-nodeletion dst` |
| `-b, --backup`        | `-backup 'Name *'` with `-backupdir` or `-backupsuffix .syncz-bak`                       |

**Confirmation modes:**

| syncz option    | unison equivalent                                            |
| --------------- | ------------------------------------------------------------ |
| `--force`       | `-batch` (no questions)                                      |
| `--confirm`     | `-batch` off, interactive (unison's default)                 |
| `--confirm yes` | `-batch -auto`                                               |
| `--confirm no`  | Don't run (abort)                                            |
| `--just-do-it`  | Show unison's plan summary, single Y/N prompt, then `-batch` |

**Summary output**: Before running unison, do a `-dryrun` pass to capture the plan, parse it into syncz's summary format (files to transfer, files to delete), then execute if not in dry-run mode.

### R3: Unison backend — bidirectional sync (`syncz --bidi dir1 dir2`)

This is the primary motivation for the refactor. Map to unison:

```bash
unison dir1 dir2 -batch -auto -times
```

Key unison behaviors that replace syncz's manual orphan handling:

| Scenario                    | unison behavior                                        | syncz flags needed                   |
| --------------------------- | ------------------------------------------------------ | ------------------------------------ |
| New file on one side        | Copies to other side                                   | Default — just works                 |
| File deleted on one side    | Deletes from other side                                | Default — just works (state-tracked) |
| File modified on one side   | Copies newer version                                   | Default with `-times`                |
| File modified on both sides | **Conflict** — requires resolution                     | See conflict handling below          |
| First sync (no archive)     | Treats as "both sides new" — copies in both directions | Works correctly                      |

**First-run behavior**: When no unison archive exists for a pair, unison treats all files as new and copies them to whichever side is missing them. This is exactly the correct behavior for initial sync (the scenario that broke rsync-based bidi).

**Conflict handling**: When the same file is modified on both sides:

- Default: skip conflicts, report them (user resolves manually)
- `--source-wins` is invalid in bidi mode (already enforced)
- Could add `--newer-wins` or `--prefer` flag in future; for now, default to reporting conflicts

**Orphan concept goes away**: With unison's state tracking, the "orphan" terminology and `detect_orphans()`/`resolve_orphans()` functions are no longer needed for the unison backend. Unison handles all of this internally. The rsync fallback retains the existing orphan logic.

**Delete handling in bidi**:

| syncz option                       | unison behavior                                     |
| ---------------------------------- | --------------------------------------------------- |
| `syncz --bidi dir1 dir2`           | Propagate deletions (state-tracked, safe)           |
| `syncz --bidi --confirm dir1 dir2` | Interactive mode — unison shows plan, user confirms |

Note: `--delete` has different semantics now. With rsync, `--delete` meant "prune orphans." With unison, deletions are automatically propagated because they're state-tracked. The `--delete` flag in bidi mode becomes unnecessary (and potentially confusing). Consider either: (a) ignoring it silently in unison+bidi mode, or (b) mapping it to `-nodeletion` when **absent** (i.e., `--bidi` without `--delete` suppresses deletion propagation). **Recommendation**: option (a) — let unison do its thing, `--delete` is a no-op in unison+bidi mode with a deprecation notice.

### R4: Unison archive management

- **Archive location**: Use unison's default (`~/.unison/`). Do not try to manage a custom `.syncz/` state directory — unison handles this internally.
- **`UNISON` env var**: Respect it if set (unison already does this).
- **`--ignore-archives`**: Map to unison's `-ignorearchives` flag. Useful for forcing a fresh comparison (equivalent to first-run behavior). Expose as `syncz --fresh` or `syncz --no-state`.

### R5: Rsync fallback behavior

When unison is not available, syncz falls back to rsync. The behavior should be identical to the current implementation (post-hotfix):

- **Unidirectional**: Unchanged (rsync wrapping works fine for one-way sync)
- **Bidirectional**: Current two-pass rsync with safe orphan defaults:
  - No flags → keep orphans, let rsync copy them
  - `--delete` → delete orphans with warning
  - `--confirm` → interactive prompt with default=keep (`[y/N/a]`)
- Print a one-time warning when entering bidi mode without unison

### R6: CLI changes

**New flags:**

| Flag                      | Description                                                         |
| ------------------------- | ------------------------------------------------------------------- |
| `--backend unison\|rsync` | Force a specific sync backend                                       |
| `--fresh`                 | Ignore saved state, treat as first sync (unison: `-ignorearchives`) |

**Changed semantics:**

| Flag                 | Old behavior                        | New behavior (unison)                                           |
| -------------------- | ----------------------------------- | --------------------------------------------------------------- |
| `--bidi`             | Two rsync passes + orphan detection | Single unison invocation with state tracking                    |
| `--delete` (in bidi) | Delete orphans                      | No-op (unison state-tracks deletions); print deprecation notice |

**Removed concepts:**

- "Orphan" terminology in unison mode (files are "new" or "deleted," unison knows which)
- `detect_orphans()` / `resolve_orphans()` — only used by rsync fallback

**Unchanged:**

- All unidirectional flags and behaviors
- `--exclude`, `--backup`, `--verbose`, `--progress`, `--dry-run`
- `--confirm`, `--force`, `--just-do-it` workflows
- Help text format, utilz integration, BATS test structure

### R7: Output format

syncz's output format should remain consistent regardless of backend:

```
Sync Summary
============
  Source:    /path/to/dir1/
  Dest:     /path/to/dir2/
  Mode:     newer-wins (default)
  Backend:  unison 2.53.8
  Files:    42 to sync
  Deleted:  3 to propagate
  Conflicts: 1 (skipped)

Changes:
  [new]      dir1 → dir2  reports/q4.pdf
  [new]      dir2 → dir1  notes/meeting.md
  [changed]  dir1 → dir2  README.md
  [deleted]  dir2          old-file.txt
  [CONFLICT] both modified config.yaml (skipped)
```

- Parse unison's `-dryrun` output to generate this format
- In verbose mode, show the full unison itemized output below the summary
- In dry-run mode, show the summary and exit (don't execute)

### R8: Testing

**Update existing BATS tests:**

- All 66 existing tests must continue to pass (they test the rsync backend)
- Add `--backend rsync` to existing tests to pin them to rsync behavior
- Add a parallel set of bidi tests using `--backend unison` that verify:
  - New files are copied (not flagged as orphans)
  - Deleted files are propagated (state-tracked)
  - Conflicts are detected and reported
  - `--fresh` flag works (ignores archive)
  - First-run behavior (no archive) copies all files correctly
  - Exclude patterns work
  - Dry-run shows plan without executing
- Add backend detection tests (unison available, rsync-only fallback)

**Test helper additions:**

- `create_unison_scenario()` — sets up dir pair with archive state from a prior sync
- `assert_unison_archive_exists()` — verifies archive was created after sync

### R9: Documentation philosophy

syncz docs should **not** duplicate unison's documentation. The approach:

- **syncz help/README**: Document syncz's own CLI flags and behaviors. Where syncz delegates to unison, state that briefly and link to unison's docs. Example: "In bidi mode, syncz uses unison for state-tracked synchronization. See `unison -doc basics` or <https://www.cis.upenn.edu/~bcpierce/unison/> for details on how unison's archive-based change detection works."
- **Flag mapping**: Document what syncz flags _do_, not how unison implements them. Users don't need to know that `--exclude` maps to `-ignore 'Name ...'` — they just need to know `--exclude` works.
- **Conflict/state behavior**: Briefly explain the _concept_ (unison tracks state, so it knows new-vs-deleted) and refer to unison docs for the full picture. Don't try to re-document unison's archive format, conflict resolution algorithms, etc.
- **Troubleshooting**: Link to unison docs for archive management, `--fresh` for the "nuclear option," and `unison -doc` for deep dives.

### R10: Version and metadata

- Bump version to `2.0.0` (breaking change: bidi semantics change with unison)
- Update `syncz.yaml` dependencies:

```yaml
dependencies:
  - name: unison
    required: false
    install: brew install unison
    purpose: Bidirectional sync engine with state tracking (preferred)
  - name: rsync
    required: true
    install: brew install rsync
    purpose: Unidirectional sync engine and bidi fallback
```

- Update `README.md` to document dual-backend architecture
- Update `help/syncz.md` with new flags and changed bidi semantics

## Implementation approach

### Code structure

Refactor `syncz` into backend-agnostic orchestration + backend-specific functions:

```
# Orchestration (unchanged)
usage(), validate_inputs(), parse args, main flow

# Backend dispatch
select_backend()          → sets SYNCZ_BACKEND=unison|rsync
dispatch_sync()           → calls unison_sync() or rsync_sync()
dispatch_bidi()           → calls unison_bidi() or rsync_bidi()

# Unison backend (new)
unison_build_args()       → construct unison CLI args from syncz options
unison_summary()          → run -dryrun, parse output into summary format
unison_sync()             → unidirectional sync via unison
unison_bidi()             → bidirectional sync via unison

# Rsync backend (existing, moved into namespaced functions)
rsync_build_args()        → current build_rsync_args()
rsync_summary()           → current generate_summary()
rsync_sync()              → current execute_sync()
rsync_bidi()              → current execute_bidi() + detect/resolve_orphans()
```

Keep it all in a single `syncz` file — no need to split into separate files for a bash script.

### Migration path

1. Refactor existing functions into `rsync_*` namespace (no behavior change)
2. Add `select_backend()` dispatch layer
3. Implement `unison_*` functions
4. Add `--backend` and `--fresh` flags
5. Update tests
6. Update docs, bump version

## Verification

After implementation, verify with the real A3 Dropbox ↔ GDrive sync:

```bash
# Step 1: Dry-run with unison backend
bin/sync -n -v 2>&1 | tee ~/tmp/20260302_sync_unison.log

# Expected: No orphan section. Files listed as [new] dir1→dir2. No delete prompts.
# Expected: unison creates archive in ~/.unison/ after first real run.

# Step 2: Real first sync
bin/sync -v 2>&1 | tee ~/tmp/20260302_sync_unison_run1.log

# Expected: All Dropbox files copied to GDrive. Archive created.

# Step 3: Second sync (should be fast, no changes)
bin/sync -v 2>&1 | tee ~/tmp/20260302_sync_unison_run2.log

# Expected: "Nothing to sync" or 0 files. Proves state tracking works.

# Step 4: Create a file on one side, delete on the other, re-sync
echo "test" > /path/to/gdrive/A3/test-new.txt
rm /path/to/dropbox/A3/some-existing-file.txt
bin/sync -n -v

# Expected: test-new.txt listed as [new] GD→DB.
# Expected: some-existing-file.txt listed as [deleted] from GD side.
# This is the test that proves state tracking works — rsync could never do this.
```

## Related Steel Threads

- None (standalone utility refactor)

## Risks and mitigations

| Risk                                                | Mitigation                                                  |
| --------------------------------------------------- | ----------------------------------------------------------- |
| Unison archive corruption                           | `--fresh` flag to reset; unison has `--ignorearchives`      |
| Unison output format changes between versions       | Pin to known output parsing; test against installed version |
| Cloud drive (GDrive) latency causes unison timeouts | Test with real GDrive paths; may need `-retry` flag         |
| Users expect rsync `--delete` semantics in bidi     | Deprecation notice; clear docs on state-tracked deletions   |
