---
verblock: "23 Apr 2026:v0.1: matts - Initial version"
wp_id: WP-03
title: "Elisp bridge static emacs utilz el"
scope: Small
status: Not Started
---

# WP-03: Elisp bridge static emacs utilz el

## Objective

Write `static/emacs/utilz.el` — the canonical elisp file that powers the bridge. Thin Coordinator: parse intent, call `utilz <n>`, render result. PFIC-shaped dispatch: small composable helpers per `input` kind and per `output` kind, composed by a single entry function, not a monolithic `cond`. No YAML parsing in elisp — only TSV from `utilz emacs commands`.

## Deliverables

- `static/emacs/utilz.el` — the canonical bridge file, `(provide 'utilz)` at the bottom. Target ~150-200 lines.
- Exposed interactive commands: `utilz` (entry point, `completing-read` picker), `utilz-refresh` (re-read manifest).
- Keybinding: `C-c u` -> `utilz` (user can override).
- Internal helpers (one per kind): `utilz--input-stdin`, `utilz--input-file`, `utilz--input-path`, `utilz--input-none`; `utilz--output-replace`, `utilz--output-buffer`, `utilz--output-message`, `utilz--output-discard`.
- Cache: `utilz--commands-alist`, populated from `utilz emacs commands` TSV.

## Acceptance Criteria

- [ ] `M-x utilz` produces a Vertico `completing-read` menu of the TSV rows, annotated with descriptions.
- [ ] `cleanz` on a region: region replaced by stdout; single `C-/` reverts cleanly (one `undo-boundary`).
- [ ] `cleanz` with no region active: whole buffer is the input; buffer replaced by stdout.
- [ ] `xtrct` on a region: stdout opens in `*utilz-xtrct*` (read-only, `special-mode`-ish).
- [ ] `C-u M-x utilz` -> picks a utility -> prompts for extra flags via `read-string`.
- [ ] `C-u C-u M-x utilz` -> picks a utility -> shows full command line in a yes/no confirm before running.
- [ ] Non-zero exit: region/buffer untouched; stderr buffer pops up.
- [ ] `M-x utilz-refresh` re-reads the TSV (useful after adding a new utility).
- [ ] No external packages required (Vertico + `shell-command-on-region` / `call-process-region` ship with Doom).
- [ ] File is idempotent on `M-x eval-buffer` (can be re-evaluated without error).
- [ ] PFIC shape: verify `utilz-run` dispatches via `pcase` or alist lookup on `input` / `output` kind; no single giant `cond`.

## Dependencies

- Depends on WP02 (requires `utilz emacs commands` to be available in PATH).
- Verification step (acceptance criteria) requires the user to symlink the file into `~/.config/doom/custom/160-utilz.el` and add the `(load ...)` line. Documented in WP04.
