---
verblock: "23 Apr 2026:v0.1: matts - Initial version"
wp_id: WP-02
title: "utilz emacs subcommand: commands, install, doctor"
scope: Small
status: Done
---

# WP-02: utilz emacs subcommand: commands, install, doctor

## Objective

Add two new dispatcher subcommand families, split by scope:

- `utilz integration commands` — editor-neutral TSV emitter. One row per utility that declares an `integration:` block. Consumed by the Emacs bridge and by any future VSCode / Zed / Vim integration.
- `utilz emacs install` / `utilz emacs doctor` — Emacs-specific verbs. `install` copies (or symlinks) `static/emacs/utilz.el` to a destination and prints the loader line. `doctor` verifies PATH, YAML parse, `integration:`-block presence, and install parity.

TSV format is the single cross-boundary contract between Utilz and any integration. The TSV walker lives in `opt/utilz/lib/common.sh` as `emit_integration_tsv` — the _only_ place that walks the YAML corpus to produce the integration catalogue (Highlander). Editor-specific installers never re-walk the corpus; they shell out to `utilz integration commands`.

## Deliverables

- `bin/utilz` — new `integration` and `emacs` cases in the subcommand dispatch (the dispatcher lives in `bin/`, not `opt/utilz/`).
- `opt/utilz/lib/common.sh` — new `emit_integration_tsv`, `emacs_doctor`, `emacs_install` helpers (plus `_emacs_install_usage`, `_emacs_install_hint`).
- `opt/utilz/test/bridge.bats` — new BATS file covering TSV shape (column count, row count, cleanz spot-check, utilz-core exclusion), subcommand verb routing (help, unknown verbs), and Emacs-install error paths (No Silent Errors).
- `help/utilz.md` — new sections documenting `utilz integration <verb>` and `utilz emacs <verb>`.

## Acceptance Criteria

- [x] `utilz integration commands | column -t -s$'\t'` produces a readable table with 5 columns (`name`, `description`, `input`, `output`, `flags`) and one row per utility that has an `integration:` block (12 rows on clean checkout).
- [x] `utilz emacs install` without `--dest` errors with a clear diagnostic (pre-WP03 happy-path deferred to WP04 E2E once canonical file exists).
- [x] `utilz emacs install --dest PATH` with a missing canonical source errors with a clear No Silent Errors diagnostic ("Canonical elisp file not found...") rather than silently doing nothing.
- [x] `utilz emacs doctor` exits zero on a clean local checkout; the `emacs_doctor` function flags utilities without an `integration:` block or with invalid input/output values (coverage exercised by the `missing[@]` / `invalid[@]` code paths).
- [x] `utilz test utilz` passes locally (70 tests, 15 new in `bridge.bats`). CI matrix check lands with WP04 E2E.
- [x] `help/utilz.md` updated; renders cleanly via the existing `glow` / `bat` / `cat` fallback chain.
- [x] Bash 3.2 compatible: no namerefs, array iteration guarded with `${#arr[@]} -gt 0`, no `local` outside functions.

## Dependencies

- Depends on WP01 (the `integration:` blocks must exist in the YAMLs).
- Must not create `static/emacs/utilz.el` yet — that lands in WP03. `utilz emacs install` should fail gracefully if the canonical file is absent (clear error, not a silent no-op) to prove No Silent Errors.
