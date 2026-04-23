---
verblock: "23 Apr 2026:v0.8: matts - ST0007 WP01/WP02 complete; WP03 up next"
---

# Work In Progress

## Current Focus

**ST0007: Emacs bindings for Utilz utilities** — metadata-driven bridge exposing Utilz commands inside Doom Emacs via `M-x utilz` (Vertico `completing-read`). Two small additions on the Utilz side (editor-neutral `integration:` YAML block + new `utilz integration commands` + `utilz emacs {install,doctor}` subcommands) plus one canonical elisp file (`static/emacs/utilz.el`) that the user symlinks into `~/.config/doom/custom/160-utilz.el`.

### WP status

- **WP01 — DONE** (commit `7e97cb7`): Added `integration:` block to all 12 utility YAMLs per the design matrix. Template stub updated. Rename from initial `emacs:` to editor-agnostic `integration:` so future VSCode / Zed / Vim can consume the same manifest.
- **Reindent — DONE** (commit `9c9c439`): Project-wide bash reindent from 4-space to 2-space (Intent project standard). 32 files, pure mechanical change, all 332 tests green.
- **WP02 — DONE** (commit `eb7264e`): `utilz integration commands` (TSV emitter) + `utilz emacs install` + `utilz emacs doctor` dispatchers. Helpers in `common.sh`. 15 new BATS tests in `opt/utilz/test/bridge.bats`. `help/utilz.md` updated.
- **WP03 — NEXT**: Write `static/emacs/utilz.el` (the elisp bridge itself). Thin coordinator, PFIC-shaped input/output dispatch, reads TSV from `utilz integration commands`. Target ~150-200 lines. `(provide 'utilz)`.
- **WP04 — PENDING**: End-to-end verification in real Doom, plus README "Using Utilz from Emacs" section and CHANGELOG entry.

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
