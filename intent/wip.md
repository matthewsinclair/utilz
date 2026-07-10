---
verblock: "10 Jul 2026:v1.2: matts - ST0008 closed; issue tracker + mdagg 0001 fix landed"
---

# Work In Progress

## Current Focus

No active steel thread. Framework at **v2.3.0** with 13 utilities (core `utilz` + 12 tools, plus the `todo` utility added by ST0008), an editor-integration surface, and the Emacs bridge. All eight steel threads (ST0001-ST0008) are complete and live under `intent/st/COMPLETED/`. Repo is clean and pushed to both remotes. Next work is opportunistic (backlog triage).

## Just Landed

- **v2.3.0 released.** `VERSION` bumped 2.2.0 -> 2.3.0 (additive minor: the new `todo` utility), CHANGELOG `## [2.3.0]` entry, annotated tag `v2.3.0` pushed to both remotes. (The prior `v2.2.0` tag already existed at the ST0007 close; the todo utility + mdagg fixes had accumulated on top of it unreleased.)
- **expz added to the CI Linux loop** (`.github/workflows/tests.yml`). No secret needed: the expz BATS suite is entirely offline -- every test exercises arg/schema-validation paths that return before the `ANTHROPIC_API_KEY` check, so it passes with the key unset (verified). macOS CI already ran it via `utilz test`; this closes the Linux gap. The long-standing "needs ANTHROPIC_API_KEY in CI" note was a stale assumption.
- **Issue 0001 (mdagg silent Unicode line-drop under C locale)** -- fixed at source and closed. `mdagg`'s `strip_back_links` used a `[←↑]` bracket class that, under `LC_ALL=C`, degraded to a byte set and silently deleted any content line holding a U+2000-U+2FFF character (`→ ∥ ∈ — ...`). Fixed with an anchored, byte-safe ERE (`grep -vE '^[[:space:]]*\[(←|↑)'`) that also tightens the strip to genuine link lines; the sibling GNU-sed title-case (`\b`/`\u`, a no-op on BSD sed) was replaced with portable POSIX awk and the duplicated derivation extracted into `derive_title()` (Highlander). Commits `7d3128c` + `4c38cae`; 31 mdagg BATS green; issue recorded in the new tracker.
- **File-based issue tracker** introduced at `intent/issues/` (`OPEN/`, `CLOSED/`, `_templ/`). Lightweight, git-tracked, ST-independent -- for defects that a single issue can drive without a full steel thread.
- **ST0008: `utilz todo`** (completed 2026-07-03, 8 WPs). A standalone DOING/TODO/DONE manager forked from `intent todo`; the `todo.md` is the source of truth (not an ST projection). WP-08 added the `utilz todo <-> intent todo` mutual guard: `utilz todo` stamps `generator: utilz todo` and refuses to clobber an Intent-owned `todo.md`, but only when Intent is actually present, so it stays a zero-dependency standalone tool. Acceptance contract in `intent/st/COMPLETED/ST0008/acceptance.md`.
- **ST0007: Emacs bindings** (closed 23 Apr 2026). Metadata-driven bridge exposing Utilz commands inside Doom Emacs via `M-x utilz`; editor-neutral `integration:` YAML block + `utilz integration commands` + `utilz emacs {install,doctor}` + canonical elisp at `static/emacs/utilz.el`.

## Active Steel Threads

None. ST0001-ST0008 all complete (`intent/st/COMPLETED/`). `intent st list` is empty by design -- completed threads are filed under `COMPLETED/`.

## Upcoming Work

- Follow-on issue-0001 hygiene is done; no open mdagg items.
- Potential future STs: VSCode / Zed / Vim integration families (same TSV manifest); Emacs bridge v2 (Transient grouped menu, deferred per ST0007 design.md).

## Notes

- **Version disambiguation.** The Utilz _framework_ version is `VERSION` = **2.3.0** (single source of truth). The `intent` _tooling_ version (~2.14.x) is separate; don't conflate them. The `2.13.0` in commit `e000db5`'s message refers to an Intent-tooling bump, not the framework.
- Editor-integration shape: every user-facing utility declares an `integration:` block in its YAML (`input`, `output`, `flags`); the single walker `emit_integration_tsv` in `opt/utilz/lib/common.sh` emits the only cross-boundary contract (TSV). `utilz integration commands` is the neutral entry point; `utilz emacs {install,doctor}` is the first editor-specific installer.

## Context for LLM

This document captures the current state of development. Read it first, then `intent/restart.md` for cross-session continuity. Completed steel threads live under `intent/st/COMPLETED/<ID>/`; open defects live under `intent/issues/OPEN/`.

### How to use this document

1. Update "Current Focus" with what is currently being worked on.
2. List active steel threads with their IDs and brief descriptions.
3. Keep track of upcoming work items.
4. Add relevant notes that might be helpful for yourself or the LLM.
