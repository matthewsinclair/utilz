---
verblock: "23 Apr 2026:v0.1: matts - Initial version"
wp_id: WP-02
title: "utilz emacs subcommand: commands, install, doctor"
scope: Small
status: Not Started
---

# WP-02: utilz emacs subcommand: commands, install, doctor

## Objective

Add the `utilz emacs <verb>` dispatcher subcommand with three verbs: `commands` (TSV emitter), `install` (copy / symlink `static/emacs/utilz.el` to a destination, print the loader line), and `doctor` (verify PATH, YAML parse, emacs-block presence, install parity). TSV format is the single cross-boundary contract with the elisp bridge. The TSV walker lives in `opt/utilz/lib/common.sh` as `emit_emacs_commands_tsv` — the _only_ place that walks the YAML corpus to produce the bridge's command catalogue (Highlander).

## Deliverables

- `opt/utilz/utilz` — new `emacs` case in the subcommand dispatch.
- `opt/utilz/lib/common.sh` — new `emit_emacs_commands_tsv` helper that reuses `get_util_metadata`.
- `opt/utilz/test/utilz.bats` — BATS tests covering TSV shape (column count, one row per utility with an emacs block, expected utility names present), install idempotency, doctor green/red paths.
- `help/utilz.md` — a "Subcommands" section documenting `emacs commands|install|doctor`.

## Acceptance Criteria

- [ ] `utilz emacs commands | column -t -s$'\t'` produces a readable table with 5 columns (`name`, `description`, `input`, `output`, `flags`) and one row per utility that has an `emacs:` block.
- [ ] `utilz emacs install --dest /tmp/utilz-test.el` copies `static/emacs/utilz.el` to the destination, prints the `(load "...")` suggestion, and is idempotent on re-run.
- [ ] `utilz emacs install --dest /tmp/utilz-test.el --symlink` creates a symlink instead of a copy.
- [ ] `utilz emacs doctor` exits zero on a clean local checkout; exits non-zero (with a clear diagnostic) if a utility lacks an `emacs:` block, or an install destination diverges from the repo copy.
- [ ] `utilz test utilz` passes on Linux + macOS (BATS suite green), including the new tests.
- [ ] `help/utilz.md` renders cleanly via `glow` / `bat` / `cat` fallback chain.
- [ ] Bash 3.2 compatible (no namerefs, array guards present, no `local` outside functions).

## Dependencies

- Depends on WP01 (the `emacs:` blocks must exist in the YAMLs).
- Must not create `static/emacs/utilz.el` yet — that lands in WP03. `utilz emacs install` should fail gracefully if the canonical file is absent (clear error, not a silent no-op) to prove No Silent Errors.
