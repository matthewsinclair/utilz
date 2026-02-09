# Implementation - ST0002: Syncz - a simple directory-to-directory syncer

**Status**: As-built (completed 08 Feb 2026)

## Implementation

syncz is implemented as a single bash script (~555 lines) at `opt/syncz/syncz` following the Utilz dispatcher pattern established by cleanz and other utilities.

### Key Files

| File                         | Purpose                            |
|------------------------------|------------------------------------|
| `opt/syncz/syncz`            | Main implementation                |
| `opt/syncz/syncz.yaml`       | Metadata (rsync dependency)        |
| `opt/syncz/test/syncz.bats`  | 45 BATS tests                      |
| `opt/syncz/README.md`        | Utility README                     |
| `help/syncz.md`              | Help file (via `utilz help syncz`) |
| `bin/syncz -> utilz`         | Dispatcher symlink                 |

### rsync Flag Mapping

| syncz mode                 | rsync flags                         | Behavior                        |
|----------------------------|-------------------------------------|---------------------------------|
| default (no conflict flag) | `-rlptD --update`                   | Copy only where source is newer |
| `--source-wins`            | `-rlptD` (no `--update`)            | Source always overwrites        |
| `--dest-wins`              | `-rlptD --ignore-existing`          | Only copy new files to dest     |
| `--dry-run`                | adds `--dry-run`                    | No transfers, just report       |
| `--verbose`                | adds `--itemize-changes`            | Per-file action output          |
| `--delete`                 | adds `--delete`                     | Remove extraneous dest files    |
| `--backup`                 | adds `--backup --suffix=.syncz-bak` | Backup overwritten files        |
| `--exclude PAT`            | adds `--exclude='PAT'`              | Exclude matching files          |
| `--progress`               | adds `--progress`                   | Per-file transfer progress      |

### Key Design Choices

1. **Path resolution**: Uses `(cd "$dir" && pwd)` for portable absolute path resolution
2. **Trailing slash normalization**: Always appends `/` to source and dest for consistent rsync behavior
3. **Summary generation**: Runs rsync with `--dry-run --stats` to get file counts before actual sync
4. **CONFIRM_ALL state**: The `prompt_yna()` function sets a global `CONFIRM_ALL` flag when user answers "A", skipping subsequent prompts
5. **Global array for args**: `build_rsync_args()` populates a global `_RSYNC_ARGS` array instead of using bash 4.3+ namerefs, for macOS bash 3.2 compatibility
6. **Portable lowercase**: Prompt functions use `tr '[:upper:]' '[:lower:]'` instead of bash 4.0+ `${var,,}` expansion

## Challenges & Solutions

### Challenge: rsync stats parsing across versions

macOS rsync outputs `Number of files transferred:` while newer versions use `Number of regular files transferred:`. Solved with regex: `grep -E "^Number of (regular )?files transferred:"`.

### Challenge: Delete safety

Solved by requiring `--confirm`, `--force`, or `--just-do-it` with `--delete`. This is validated in `validate_inputs()` before any sync occurs.

### Challenge: /dev/tty blocking in tests

`read -r answer </dev/tty 2>/dev/null || read -r answer` blocks when stdin is piped because `/dev/tty` exists and blocks (doesn't error). Solved by checking `-t 0` (is stdin a terminal?) to decide read source.

### Challenge: bash 3.2 compatibility (macOS CI)

macOS CI runners use bash 3.2 which lacks namerefs (`local -n`, bash 4.3+) and lowercase expansion (`${var,,}`, bash 4.0+). Solved by using global `_RSYNC_ARGS` array and `tr` for case conversion.

### Challenge: rsync exit code 23

Exit code 23 means partial transfer due to permission warnings (common for non-root syncs). Treated as a warning, not an error.

### Challenge: `local` outside functions

`local` keyword cannot be used outside functions in bash. Extracted delete logic into `execute_delete()` helper function.
