# Design - ST0002: Syncz - a simple directory-to-directory syncer

## Approach

Implement syncz as a bash script following the Utilz dispatcher pattern. The script wraps rsync with user-friendly options, conflict resolution strategies, and confirmation flows for destructive operations.

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

## Architecture

```
syncz (~280 lines)
  |
  +-- Config variables
  +-- usage()
  +-- resolve_path()         # Resolve to absolute path
  +-- validate_inputs()      # Dirs exist, not same, options valid
  +-- build_rsync_args()     # Construct rsync arg array from options
  +-- generate_summary()     # Run dry-run rsync, parse stats
  +-- prompt_yna()           # Y/N/A prompt helper
  +-- prompt_yn()            # Simple Y/N prompt for --just-do-it
  +-- execute_sync()         # Run rsync, handle exit code
  +-- Argument parsing       # while/case loop
  +-- Main flow
```

## Alternatives Considered

### Alternative 1: Pure bash cp/find implementation

Rejected because rsync handles edge cases (permissions, symlinks, timestamps, partial transfers) that would be extremely complex to replicate.

### Alternative 2: Using `-a` flag

Rejected because group/owner preservation produces warnings for non-root syncs and is rarely needed for user-level directory sync.

### Alternative 3: Interactive per-file conflict resolution

Rejected for simplicity. Three clear strategies (newer-wins, source-wins, dest-wins) cover the vast majority of use cases without the complexity of per-file prompting.
