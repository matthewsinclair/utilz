---
verblock: "10 Feb 2026:v0.1: matts - Initial version"
intent_version: 2.2.0
status: Completed
created: 20260210
completed: 20260210
---
# ST0003: syncz --bidi mode and --confirm enhancement

## Objective

Add bidirectional sync mode (`--bidi`) with orphan detection/resolution, and a `--confirm [yes|no|all]` optional argument for fully scriptable operation. Write comprehensive tests for the new features, update all documentation, and bump framework version to 1.2.1.

## Context

syncz v1.2.0 (ST0002) delivered unidirectional sync with three conflict resolution strategies, confirmation modes, and safety gates. Users need two-way sync between peer directories (e.g. laptop ↔ NAS) where neither side is authoritative. The `--bidi` flag adds:

- Orphan detection via `find` + `comm`
- Orphan resolution: interactive prompts, `--delete` (silent), `--confirm yes/no/all` (scriptable)
- Two-pass rsync (dir1→dir2, dir2→dir1) with newer-wins strategy
- rsync `--delete` never passed in bidi mode (orphan resolution handles deletions)

The `--confirm` optional argument (`yes`, `no`, `all`) enables fully non-interactive operation in both uni and bidi modes.

## Related Steel Threads

- ST0002: syncz - Directory-to-Directory Syncer (predecessor, established unidirectional sync)

## Context for LLM

This document represents a single steel thread - a self-contained unit of work focused on implementing a specific piece of functionality. When working with an LLM on this steel thread, start by sharing this document to provide context about what needs to be done.

### How to update this document

1. Update the status as work progresses
2. Update related documents (design.md, impl.md, etc.) as needed
3. Mark the completion date when finished

The LLM should assist with implementation details and help maintain this document as work progresses.
