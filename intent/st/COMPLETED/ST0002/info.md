---
verblock: "08 Feb 2026:v0.1: matts - Initial version"
intent_version: 2.2.0
status: Completed
created: 20260208
completed:
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

## Related Steel Threads

- ST0001: cleanz - established patterns for Utilz utility implementation, testing, and documentation

## Context for LLM

This document represents a single steel thread - a self-contained unit of work focused on implementing a specific piece of functionality. When working with an LLM on this steel thread, start by sharing this document to provide context about what needs to be done.

### How to update this document

1. Update the status as work progresses
2. Update related documents (design.md, impl.md, etc.) as needed
3. Mark the completion date when finished

The LLM should assist with implementation details and help maintain this document as work progresses.
