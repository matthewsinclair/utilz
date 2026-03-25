---
verblock: "25 Mar 2026:v0.7: matts - Updated after expz v1.0.0 and framework v2.1.0"
---

# Work In Progress

## Current Focus

**No active work** - All tasks complete.

expz v1.0.0 released as Utilz v2.1.0 on 25 Mar 2026.

## Active Steel Threads

None - All steel threads complete.

## Upcoming Work

- Add expz to CI test loop in `.github/workflows/tests.yml` (Ubuntu + macOS)
- Consider whether other utilities should bump their `utilz_version` to `^2.0.0` in a follow-up

## Notes

The Utilz framework is at v2.1.0 with 12 utilities:

- cleanz - LLM text cleaner + C2PA image metadata (v1.1.0)
- clipz - Cross-platform clipboard
- cryptz - GPG encryption wrapper
- expz - Batch expense receipt PDF extraction to CSV (v1.0.0)
- gitz - Git multi-repo operations
- lnrel - Portable relative symlinks
- macoz - macOS utilities (bg, setpicfor)
- mdagg - Markdown aggregator
- pdf2md - PDF to Markdown converter
- retry - Retry command utility
- syncz - Directory-to-directory syncer with bidi/unison mode (v2.0.0)
- xtrct - Schema-driven semantic data extraction

## Context for LLM

This document captures the current state of development on the project. When beginning work with an LLM assistant, start by sharing this document to provide context about what's currently being worked on.

### How to use this document

1. Update the "Current Focus" section with what you're currently working on
2. List active steel threads with their IDs and brief descriptions
3. Keep track of upcoming work items
4. Add any relevant notes that might be helpful for yourself or the LLM

When starting a new steel thread, describe it here first, then ask the LLM to create the appropriate steel thread document using the STP commands.
