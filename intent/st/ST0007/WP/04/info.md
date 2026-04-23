---
verblock: "23 Apr 2026:v0.1: matts - Initial version"
wp_id: WP-04
title: "End-to-end verification and user docs"
scope: Small
status: Not Started
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

- [ ] Bridge symlinked into `~/.config/doom/custom/160-utilz.el`, `(load "160-utilz.el")` added to `config.el`, Doom restarted.
- [ ] `M-x utilz` -> `cleanz` on a region with LLM artefacts -> region replaced; `C-/` reverts.
- [ ] `M-x utilz` -> `xtrct` on a region -> `*utilz-xtrct*` opens with JSON.
- [ ] `C-u M-x utilz` -> flag prompt appears; `--no-dashes` (or similar) passes through and is reflected in output.
- [ ] Non-zero exit path: `M-x utilz` -> `pdf2md` on a non-PDF buffer -> stderr buffer pops, region untouched.
- [ ] `utilz test utilz` green locally; CI matrix (Linux + macOS) green on PR.
- [ ] README section reads cleanly and covers the motivating `cleanz --detrope` workflow end-to-end.
- [ ] CHANGELOG entry present and dated.
- [ ] ST0007 marked `Done` via `intent st done ST0007`.

## Dependencies

- Depends on WP03 (the elisp bridge must exist and be symlinkable).
- Depends on WP02 (the `utilz emacs install` command must work for the install instructions to be accurate).
