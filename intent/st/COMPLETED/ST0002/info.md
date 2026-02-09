---
verblock: "09 Feb 2026:v0.2: matts - Marked complete, added as-built notes"
intent_version: 2.2.0
status: Completed
created: 20260208
completed: 20260208
---
# ST0002: Syncz - a simple directory-to-directory syncer

## Objective

Create a Utilz utility that wraps rsync to provide user-friendly directory-to-directory synchronization with conflict resolution strategies, confirmation prompts, and dry-run support.

## Context

Users frequently need to sync directories - project folders, backups, deployments - but rsync's flag complexity makes it error-prone for casual use. syncz provides sensible defaults with three conflict resolution strategies (newer-wins, source-wins, dest-wins), a confirmation flow for destructive operations, and a `--just-do-it` mode for experienced users who want a single confirm-and-go.

Key design principles:

- Default behavior is safe (newer-wins, no deletions)
- Destructive operations (`--delete`) require explicit opt-in via `--confirm`, `--force`, or `--just-do-it`
- Uses `-rlptD` instead of `-a` to avoid group/owner warnings for non-root syncs
- Trailing slashes are always normalized for predictable behavior

## Outcome

Released as Utilz v1.2.0 on 08 Feb 2026. Single bash script (~555 lines), 45 BATS tests, full documentation. All CI passing on both macOS and Linux after fixing bash 3.2 compatibility issues (namerefs and lowercase expansion).

## Related Steel Threads

- ST0001: cleanz - established patterns for Utilz utility implementation, testing, and documentation
