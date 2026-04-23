---
verblock: "23 Apr 2026:v1.0: matts - ST0007 closed; framework bumped to 2.2.0"
---

# Work In Progress

## Current Focus

No active steel thread. Framework at v2.2.0 with 12 utilities + editor integration surface and Emacs bridge landed. Next work is opportunistic (add expz to CI loop, backlog triage).

## Just Landed

**ST0007: Emacs bindings for Utilz utilities** — metadata-driven bridge exposing Utilz commands inside Doom Emacs via `M-x utilz` (Vertico `completing-read`). Editor-neutral `integration:` YAML block + `utilz integration commands` + `utilz emacs {install,doctor}` subcommands + canonical elisp bridge at `static/emacs/utilz.el`. User symlinks it into `~/.config/doom/custom/160-utilz.el`.

### WP status (all DONE)

- **WP01** (commit `7e97cb7`): Added `integration:` block to all 12 utility YAMLs. Template stub updated. Editor-agnostic naming so future VSCode / Zed / Vim can consume the same manifest.
- **Reindent** (commit `9c9c439`): Project-wide bash reindent from 4-space to 2-space. 32 files, pure mechanical change.
- **WP02** (commit `eb7264e`): `utilz integration commands` (TSV emitter) + `utilz emacs install` + `utilz emacs doctor`. Helpers in `common.sh`. 15 BATS tests in `opt/utilz/test/bridge.bats`. `help/utilz.md` updated.
- **WP03** (commit `2a5b743`): `static/emacs/utilz.el` — thin coordinator, PFIC-shaped alist dispatch, byte-compiles clean. `bridge.bats` updated (16 tests).
- **WP04** (commit `<final>`): README "Using Utilz from Emacs" section + CHANGELOG v2.2.0 entry + VERSION bump 2.1.1 -> 2.2.0. Live Doom E2E confirmed by user (`M-x utilz` -> cleanz on region works). Batch E2E (34 PASS / 0 FAIL) covers every declared input/output kind, the No-Silent-Errors failure path, and path-arg shell-quoting. ST0007 closed via `intent st done ST0007`.

## Active Steel Threads

- ST0007 (WIP) — Emacs bindings for Utilz utilities. See `intent/st/ST0007/design.md` for the canonical design.

## Upcoming Work

- Finish ST0007 (WP03 + WP04).
- Add expz to CI test loop in `.github/workflows/tests.yml` (carry-over from prior session).
- Consider bumping framework to v2.2.0 on ST0007 close (new subcommand families are an additive minor bump).

## Notes

Utilz 2.1.0, 12 utilities. Framework stable. ST0007 is the first non-trivial addition in this cycle.

### Editor integration shape (for future plugin authors)

- Every utility with a user-facing invocation declares an `integration:` block in its YAML: `input: stdin | file | path | none`, `output: replace | buffer | message | discard`, `flags: []`.
- The single walker is `emit_integration_tsv` in `opt/utilz/lib/common.sh`. The TSV is the only cross-boundary contract. Editor plugins never parse YAML directly.
- `utilz integration commands` is the neutral public entry point. `utilz emacs {install,doctor}` is the first editor-specific installer. Future `utilz vscode / zed / vim` subcommand families slot in parallel.

## Context for LLM

This document captures the current state of development. Read it first, then `intent/restart.md` for cross-session continuity, then `intent/st/ST0007/` for the active ST.

### How to use this document

1. Update "Current Focus" with what's currently being worked on.
2. List active steel threads with their IDs and brief descriptions.
3. Keep track of upcoming work items.
4. Add relevant notes that might be helpful for yourself or the LLM.
