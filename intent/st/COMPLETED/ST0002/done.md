# Completed Tasks - ST0002: Syncz - a simple directory-to-directory syncer

**Completed**: 08 Feb 2026
**Version**: 1.2.0

## WP01: Steel Thread Docs & Scaffolding

- [x] Fill in ST0002 info.md with objective and context
- [x] Fill in ST0002 design.md with design decisions
- [x] Fill in ST0002 impl.md with implementation approach
- [x] Fill in ST0002 tasks.md with task checklist
- [x] Create WP info.md files (WP01-06)
- [x] Run `utilz generate syncz "Simple directory-to-directory syncer" "Matthew Sinclair"`
- [x] Customize syncz.yaml with rsync dependency
- [x] Verify `syncz --help` and `syncz --version` work

## WP02: Core Sync Implementation

- [x] Argument parsing for all options (while/case loop)
- [x] Directory validation (exist, not same, resolve paths)
- [x] `build_rsync_args()` to construct rsync flags from options
- [x] `execute_sync()` to run rsync with built args
- [x] Basic sync flow: validate -> build args -> execute
- [x] `--dry-run` passthrough
- [x] `--force` mode (skip all prompts)
- [x] `--verbose` mode (itemized changes)
- [x] `--progress` mode (per-file transfer progress)

## WP03: Confirmation & Summary

- [x] `generate_summary()` using rsync `--dry-run --stats`
- [x] Formatted summary display (source, dest, mode, file counts)
- [x] `prompt_yna()` helper with Y/N/A and CONFIRM_ALL state
- [x] `prompt_yn()` helper for `--just-do-it`
- [x] `--confirm` flow with multi-step prompts (sync, then delete)
- [x] `--just-do-it` flow: show summary, single Y/N, run everything
- [x] `--delete` safety gate (requires `--confirm`, `--force`, or `--just-do-it`)

## WP04: Conflict Resolution & Extra Features

- [x] `--source-wins` (no `--update`, source always overwrites)
- [x] `--dest-wins` (`--ignore-existing`, only new files)
- [x] Mutual exclusivity check for conflict flags
- [x] `--exclude` pattern support (repeatable)
- [x] `--backup` with `.syncz-bak` suffix
- [x] `--delete` flag integration

## WP05: Tests

- [x] Basic tests: `--help`, `--version`, unknown option, missing args
- [x] Validation tests: missing dirs, same dir, file-not-dir, conflicting flags
- [x] Core sync tests: dry-run, force, default newer-wins, recursive
- [x] Conflict resolution tests: source-wins, dest-wins, mutual exclusion
- [x] Feature tests: exclude, delete, backup, verbose
- [x] Confirm tests: Y/N/A prompt behavior via stdin pipe
- [x] Just-do-it tests: single Y/N confirmation
- [x] Edge case tests: empty dirs, no overlap, trailing slashes
- [x] Total: 45 tests, all passing on macOS and Linux CI

## WP06: Documentation & CI

- [x] Write `help/syncz.md` with column-aligned tables
- [x] Write `opt/syncz/README.md` utility README
- [x] Update project `README.md` with syncz entry
- [x] Add syncz to Linux CI test loop in `tests.yml`
- [x] Add rsync dependency check in `utilz doctor` (common.sh)
- [x] Bump VERSION to 1.2.0
- [x] Update version refs in help/utilz.md, docs/index.md
- [x] Add v1.2.0 section to CHANGELOG.md
- [x] Commit, tag v1.2.0, push to all remotes
- [x] Create GitHub release

## Post-Release Fixes

- [x] Fix bash 3.2 compatibility: replace `local -n` namerefs with global `_RSYNC_ARGS` array
- [x] Fix bash 3.2 compatibility: replace `${answer,,}` with `tr '[:upper:]' '[:lower:]'`
- [x] Fix `/dev/tty` blocking in tests: use `-t 0` check for stdin terminal detection

## Notes

- WP01-04 were implemented together as a single script since the functions are tightly coupled
- rsync stats parsing handles both old format (`Number of files transferred:`) and new format (`Number of regular files transferred:`)
- Exit code 23 (partial transfer) treated as warning, not error
