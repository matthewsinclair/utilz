# Implementation - ST0002: Syncz - a simple directory-to-directory syncer

## Implementation

syncz is implemented as a single bash script at `opt/syncz/syncz` following the Utilz dispatcher pattern established by cleanz and other utilities.

### rsync Flag Mapping

| syncz mode                 | rsync flags                          | Behavior                        |
|----------------------------|--------------------------------------|---------------------------------|
| default (no conflict flag) | `-rlptD --update`                    | Copy only where source is newer |
| `--source-wins`            | `-rlptD` (no `--update`)             | Source always overwrites        |
| `--dest-wins`              | `-rlptD --ignore-existing`           | Only copy new files to dest     |
| `--dry-run`                | adds `--dry-run`                     | No transfers, just report       |
| `--verbose`                | adds `--itemize-changes`             | Per-file action output          |
| `--delete`                 | adds `--delete`                      | Remove extraneous dest files    |
| `--backup`                 | adds `--backup --suffix=.syncz-bak`  | Backup overwritten files        |
| `--exclude PAT`            | adds `--exclude='PAT'`               | Exclude matching files          |
| `--progress`               | adds `--progress`                    | Per-file transfer progress      |

### Key Design Choices

1. **Path resolution**: Uses `(cd "$dir" && pwd)` for portable absolute path resolution
2. **Trailing slash normalization**: Always appends `/` to source and dest for consistent rsync behavior
3. **Summary generation**: Runs rsync with `--dry-run --stats` to get file counts before actual sync
4. **CONFIRM_ALL state**: The `prompt_yna()` function sets a global `CONFIRM_ALL` flag when user answers "A", skipping subsequent prompts

## Challenges & Solutions

### Challenge: rsync stats parsing

rsync `--stats` output format varies between versions. We parse the "Number of" lines which are consistent across versions.

### Challenge: Delete safety

Solved by requiring `--confirm`, `--force`, or `--just-do-it` with `--delete`. This is validated in `validate_inputs()` before any sync occurs.
