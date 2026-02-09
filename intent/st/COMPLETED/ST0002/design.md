# Design - ST0002: Syncz - a simple directory-to-directory syncer

**Status**: As-built (completed 08 Feb 2026)

## Approach

Implemented syncz as a bash script following the Utilz dispatcher pattern. The script wraps rsync with user-friendly options, conflict resolution strategies, and confirmation flows for destructive operations.

## Design Decisions

### rsync flag choice: `-rlptD` vs `-a`

We use `-rlptD` (recursive, links, permissions, timestamps, devices) instead of `-a` (archive) because `-a` includes `-g` (group) and `-o` (owner) which produce warnings when syncing as a non-root user. This is the most common use case.

### Conflict resolution strategies

Three mutually exclusive strategies:

- **Default (newer-wins)**: Uses `--update` - only overwrite if source is newer
- **Source-wins**: No `--update` - source always overwrites dest
- **Dest-wins**: Uses `--ignore-existing` - never overwrite existing dest files

### Confirmation flow design

Four modes for handling destructive operations:

1. **No flags**: Sync runs immediately with safe defaults (no deletions)
2. **`--confirm`**: Y/N/A prompt at each destructive step
3. **`--force`**: No prompts, overrides all safety checks
4. **`--just-do-it`**: Shows full summary, single Y/N prompt, then runs everything

### `--delete` safety gate

`--delete` requires one of `--confirm`, `--force`, or `--just-do-it`. Running `--delete` alone is an error. This prevents accidental data loss.

### Trailing slash normalization

syncz always adds trailing slashes to source and dest paths, ensuring rsync syncs directory *contents* rather than nesting the source directory inside the destination.

### Bash 3.2 compatibility

macOS ships with bash 3.2 which lacks namerefs (`local -n`, bash 4.3+) and lowercase expansion (`${var,,}`, bash 4.0+). We avoid both:

- `build_rsync_args()` uses a global `_RSYNC_ARGS` array instead of namerefs
- Prompt functions use `tr '[:upper:]' '[:lower:]'` instead of `${answer,,}`

## Architecture (as-built)

```
syncz (~555 lines)
  |
  +-- Config variables (OPT_DRY_RUN, OPT_FORCE, etc.)
  +-- usage()
  +-- resolve_path()         # Resolve to absolute path
  +-- validate_inputs()      # Dirs exist, not same, options valid
  +-- build_rsync_args()     # Construct rsync flags -> global _RSYNC_ARGS
  +-- generate_summary()     # Run dry-run rsync, parse stats
  +-- prompt_yna()           # Y/N/A prompt helper, sets CONFIRM_ALL
  +-- prompt_yn()            # Simple Y/N prompt for --just-do-it
  +-- execute_delete()       # Delete-only rsync pass (for --confirm mode)
  +-- execute_sync()         # Run rsync, handle exit code (incl. code 23)
  +-- Argument parsing       # while/case loop
  +-- Main flow              # dry-run -> force -> just-do-it -> confirm -> default
```

## Alternatives Considered

### Alternative 1: Pure bash cp/find implementation

Rejected because rsync handles edge cases (permissions, symlinks, timestamps, partial transfers) that would be extremely complex to replicate.

### Alternative 2: Using `-a` flag

Rejected because group/owner preservation produces warnings for non-root syncs and is rarely needed for user-level directory sync.

### Alternative 3: Interactive per-file conflict resolution

Rejected for simplicity. Three clear strategies (newer-wins, source-wins, dest-wins) cover the vast majority of use cases without the complexity of per-file prompting.
