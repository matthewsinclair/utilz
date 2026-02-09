---
verblock: "09 Feb 2026:v0.4: matts - Updated after syncz v1.2.0 release"
---
# Work In Progress

## Current Focus

**No active work** - All tasks complete.

The syncz utility (ST0002) was completed and released as Utilz v1.2.0 on 08 Feb 2026.

## Active Steel Threads

None - All steel threads complete.

## Recently Completed

- ST0002: syncz - Directory-to-Directory Syncer (DONE 08 Feb 2026)
  - rsync wrapper with conflict resolution (newer-wins, source-wins, dest-wins)
  - Confirmation modes: --confirm (Y/N/A), --force, --just-do-it
  - --delete with safety gate, --backup, --exclude, --dry-run
  - 45 tests, all passing on macOS and Linux CI
  - Released as Utilz v1.2.0

- ST0001: cleanz - LLM Text Cleaner Utility (DONE 28 Dec 2025)
  - Pure bash implementation (~690 lines with image mode)
  - Text mode: removes hidden Unicode, HTML attrs, normalizes whitespace
  - Image mode: strips C2PA/AI metadata via exiftool
  - 55 tests, all passing on macOS and Linux CI
  - Released as Utilz v1.1.0

## Upcoming Work

No planned work. Ready for new requests.

## Notes

The Utilz framework is stable at v1.2.0 with 9 utilities:
- cleanz  - LLM text cleaner + C2PA image metadata (v1.1.0)
- clipz   - Cross-platform clipboard
- cryptz  - GPG encryption wrapper
- gitz    - Git multi-repo operations
- macoz   - macOS utilities (bg, setpicfor)
- mdagg   - Markdown aggregator
- retry   - Retry command utility
- syncz   - Directory-to-directory syncer (NEW in v1.2.0)
- utilz   - Core framework

## Context for LLM

This document captures the current state of development on the project. When beginning work with an LLM assistant, start by sharing this document to provide context about what's currently being worked on.

### How to use this document

1. Update the "Current Focus" section with what you're currently working on
2. List active steel threads with their IDs and brief descriptions
3. Keep track of upcoming work items
4. Add any relevant notes that might be helpful for yourself or the LLM

When starting a new steel thread, describe it here first, then ask the LLM to create the appropriate steel thread document using the STP commands.
