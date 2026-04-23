---
verblock: "23 Apr 2026:v0.1: matts - Initial version"
wp_id: WP-03
title: "Elisp bridge static emacs utilz el"
scope: Small
status: Done
---

# WP-03: Elisp bridge static emacs utilz el

## Objective

Write `static/emacs/utilz.el` — the canonical elisp file that powers the bridge. Thin Coordinator: parse intent, call `utilz <n>`, render result. PFIC-shaped dispatch: small composable helpers per `input` kind and per `output` kind, composed by a single entry function, not a monolithic `cond`. No YAML parsing in elisp — only TSV from `utilz integration commands`.

## Deliverables

- `static/emacs/utilz.el` — the canonical bridge file, `(provide 'utilz)` at the bottom. Target ~150-200 lines.
- Exposed interactive commands: `utilz` (entry point, `completing-read` picker), `utilz-refresh` (re-read manifest).
- Keybinding: `C-c u` -> `utilz` (user can override).
- Internal helpers (one per kind): `utilz--input-stdin`, `utilz--input-file`, `utilz--input-path`, `utilz--input-none`; `utilz--output-replace`, `utilz--output-buffer`, `utilz--output-message`, `utilz--output-discard`.
- Cache: `utilz--commands-alist`, populated from `utilz integration commands` TSV.

## Acceptance Criteria

Behavioural criteria (exercised end-to-end in WP04 against real Doom):

- [ ] `M-x utilz` produces a Vertico `completing-read` menu of the TSV rows, annotated with descriptions. (→ WP04)
- [ ] `cleanz` on a region: region replaced by stdout; single `C-/` reverts cleanly (one `undo-boundary`). (→ WP04)
- [ ] `cleanz` with no region active: whole buffer is the input; buffer replaced by stdout. (→ WP04)
- [ ] `xtrct` on a region: stdout opens in `*utilz-xtrct*` (read-only, `special-mode`-ish). (→ WP04)
- [ ] `C-u M-x utilz` -> picks a utility -> prompts for extra flags via `read-string`. (→ WP04)
- [ ] `C-u C-u M-x utilz` -> picks a utility -> shows full command line in a yes/no confirm before running. (→ WP04)
- [ ] Non-zero exit: region/buffer untouched; stderr buffer pops up. (→ WP04)
- [ ] `M-x utilz-refresh` re-reads the TSV (useful after adding a new utility). (→ WP04)

Structural criteria (verified now):

- [x] No external packages required (Vertico + `shell-command-on-region` / `call-process-region` ship with Doom). Byte-compile with `emacs -Q --batch` succeeds with zero warnings, confirming no unresolved symbols.
- [x] File is idempotent on `M-x eval-buffer`: all top-level forms are `defgroup` / `defcustom` / `defvar` / `defun` / `defconst` / `global-set-key` / `provide` — re-evaluation is a no-op.
- [x] PFIC shape: `utilz` entry point is a thin coordinator (parse -> resolve -> run -> render). Input kind dispatches via `utilz--input-dispatch` alist; output kind dispatches via `utilz--output-dispatch` alist. The only `pcase` is inside `utilz--run` over two branches (stdin vs. non-stdin) because `call-process-region` and `call-process` have different arity — that is structural, not business logic.

Bridge-test regression (post-WP03 reality, updated in this WP):

- [x] `opt/utilz/test/bridge.bats` updated: pre-WP03 tests that asserted "canonical elisp absent" replaced with happy-path install + symlink + doctor "present" tests. 16 tests green locally.
- [x] `utilz emacs doctor` passes with all three checks green (PATH, integration metadata, canonical elisp present).
- [x] Full `utilz test` suite (13 suites) green locally.

## Dependencies

- Depends on WP02 (requires `utilz integration commands` to be available in PATH).
- Verification step (acceptance criteria) requires the user to symlink the file into `~/.config/doom/custom/160-utilz.el` and add the `(load ...)` line. Documented in WP04.
