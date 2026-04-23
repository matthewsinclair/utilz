---
verblock: "23 Apr 2026:v0.1: matts - Initial version"
wp_id: WP-04
title: "End-to-end verification and user docs"
scope: Small
status: WIP
---

# WP-04: End-to-end verification and user docs

## Objective

Run the end-to-end verification checklist from the ST0007 design against the real Doom install, then ship user-facing documentation (README section and CHANGELOG entry). Close out ST0007 with `intent st done ST0007` (CLI, not manual edit) once all WPs are green.

## Deliverables

- `README.md` — new "Using Utilz from Emacs" section covering install (symlink or `utilz emacs install`), the `(load ...)` line, and one example per input/output kind.
- `CHANGELOG.md` — entry under the next minor version (v2.2.0) describing the `utilz emacs` subcommand and the elisp bridge.
- (Optional, if value is clear) short excerpt in `help/utilz.md` pointing users to the README section.
- Close-out: `intent st done ST0007`, final commit, tag bump considered but deferred (not automatic).

## Acceptance Criteria

- [x] Bridge symlinked into `~/.config/doom/custom/160-utilz.el`, `(load "160-utilz.el")` added to `config.el`, Doom restarted. User confirmed in live Doom session.
- [x] `M-x utilz` -> `cleanz` on a region -> region replaced cleanly (user confirmed in live Doom; batch E2E independently confirms dispatch path — ZWSP-contaminated buffer -> exactly `"helloworld\n"` after replace, one `undo-boundary`).
- [x] `M-x utilz` -> `xtrct` (and every other utility): every declared input/output kind has a registered resolver/handler. Batch E2E asserts `(assq ikind utilz--input-dispatch)` and `(assq okind utilz--output-dispatch)` for every one of the 12 manifest rows.
- [x] `C-u` flag-prompt path: code-inspection green (entry-point reads raw prefix via `(interactive "p")`, branches on `>= 4` for `read-string`, `>= 16` for `yes-or-no-p`). Interactive prefix is out of reach for batch Emacs; user sign-off on the live session covers it.
- [x] Non-zero exit path: batch E2E runs `utilz--run "false" ...` and confirms it returns nil, pops a stderr buffer, and leaves the source buffer byte-identical.
- [x] `utilz test utilz` green locally (70 tests across `utilz.bats` + `bridge.bats`, 16 bridge tests including happy-path install + `--symlink` + doctor "canonical present").
- [x] Batch E2E (`UTILZ_HOME=$PWD emacs -Q --batch -l static/emacs/e2e-smoke.el`): 34 PASS, 0 FAIL, exit 0. Script preserved in the repo for regression re-runs.
- [x] README "Using Utilz from Emacs" section — installer invocation, `(load ...)` line, usage table covering every input/output kind, prefix-arg semantics, `M-x utilz-refresh`, `C-c u` keybinding, pointer to `intent/st/ST0007/design.md`.
- [x] CHANGELOG v2.2.0 entry dated 2026-04-23, covering the `integration:` YAML block, `utilz integration commands`, `utilz emacs install`, `utilz emacs doctor`, the elisp bridge, the 4-to-2 space reindent, and the `bridge.bats` test additions.
- [x] VERSION bumped 2.1.1 -> 2.2.0 (additive minor bump per SemVer).
- [x] ST0007 marked `Done` via `intent st done ST0007`.

## Behavioural criteria deferred from WP03 (verified here)

- [x] `completing-read` menu with annotations — user confirmed in live Doom; structural integrity confirmed by batch manifest parse (12 rows, correct plist shape).
- [x] `M-x utilz-refresh` re-reads TSV — batch E2E calls `utilz-refresh` directly and asserts the alist is populated.
- [x] PFIC shape / no monolithic cond — verified by code inspection of `static/emacs/utilz.el`: input dispatch via `utilz--input-dispatch` alist, output dispatch via `utilz--output-dispatch` alist. Only `pcase` is inside `utilz--run` over two branches (stdin vs. non-stdin), because `call-process-region` and `call-process` have different arities — structural, not business logic.

## Dependencies

- Depends on WP03 (the elisp bridge must exist and be symlinkable).
- Depends on WP02 (the `utilz emacs install` command must work for the install instructions to be accurate).
