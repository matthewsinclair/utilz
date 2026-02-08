# WP05: Tests

BATS tests covering: basic flags (--help, --version, unknown option, missing args), validation (missing dirs, same dir, file-not-dir, conflicting flags), core sync (dry-run, force, default newer-wins, recursive), conflict resolution (source-wins, dest-wins, mutual exclusion), features (exclude, delete, backup, verbose, progress), confirm (Y/N/A prompt behavior via stdin pipe), just-do-it (single Y/N confirmation), edge cases (empty dirs, no overlap, trailing slashes).
