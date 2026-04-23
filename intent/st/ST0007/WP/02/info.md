---
verblock: "23 Apr 2026:v0.1: matts - Initial version"
wp_id: WP-02
title: "utilz emacs subcommand: commands, install, doctor"
scope: Small
status: Not Started
---

# WP-02: utilz emacs subcommand: commands, install, doctor

## Objective

Add two new dispatcher subcommand families, split by scope:

- `utilz integration commands` — editor-neutral TSV emitter. One row per utility that declares an `integration:` block. Consumed by the Emacs bridge and by any future VSCode / Zed / Vim integration.
- `utilz emacs install` / `utilz emacs doctor` — Emacs-specific verbs. `install` copies (or symlinks) `static/emacs/utilz.el` to a destination and prints the loader line. `doctor` verifies PATH, YAML parse, `integration:`-block presence, and install parity.

TSV format is the single cross-boundary contract between Utilz and any integration. The TSV walker lives in `opt/utilz/lib/common.sh` as `emit_integration_tsv` — the _only_ place that walks the YAML corpus to produce the integration catalogue (Highlander). Editor-specific installers never re-walk the corpus; they shell out to `utilz integration commands`.

## Deliverables

- `opt/utilz/utilz` — new `integration` and `emacs` cases in the subcommand dispatch.
- `opt/utilz/lib/common.sh` — new `emit_integration_tsv` helper that reuses `get_util_metadata`.
- `opt/utilz/test/utilz.bats` — BATS tests covering TSV shape (column count, one row per utility with an `integration:` block, expected utility names present), install idempotency, doctor green/red paths.
- `help/utilz.md` — a "Subcommands" section documenting `integration commands`, `emacs install`, `emacs doctor`.

## Acceptance Criteria

- [ ] `utilz integration commands | column -t -s$'\t'` produces a readable table with 5 columns (`name`, `description`, `input`, `output`, `flags`) and one row per utility that has an `integration:` block.
- [ ] `utilz emacs install --dest /tmp/utilz-test.el` copies `static/emacs/utilz.el` to the destination, prints the `(load "...")` suggestion, and is idempotent on re-run.
- [ ] `utilz emacs install --dest /tmp/utilz-test.el --symlink` creates a symlink instead of a copy.
- [ ] `utilz emacs doctor` exits zero on a clean local checkout; exits non-zero (with a clear diagnostic) if a utility lacks an `integration:` block, or an install destination diverges from the repo copy.
- [ ] `utilz test utilz` passes on Linux + macOS (BATS suite green), including the new tests.
- [ ] `help/utilz.md` renders cleanly via `glow` / `bat` / `cat` fallback chain.
- [ ] Bash 3.2 compatible (no namerefs, array guards present, no `local` outside functions).

## Dependencies

- Depends on WP01 (the `integration:` blocks must exist in the YAMLs).
- Must not create `static/emacs/utilz.el` yet — that lands in WP03. `utilz emacs install` should fail gracefully if the canonical file is absent (clear error, not a silent no-op) to prove No Silent Errors.
