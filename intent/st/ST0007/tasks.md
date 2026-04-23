# Tasks - ST0007: Emacs bindings for Utilz utilities

## Tasks

Phase 0 — documentation (this change):

- [x] Provision ST0007 (`intent st new`)
- [x] Write info.md objective + context
- [x] Write design.md (approach, decisions, architecture, alternatives)
- [x] Write impl.md skeleton
- [ ] Create four work packages via `intent wp new ST0007 "..."`
- [ ] Commit docs-only change

Phase 1 — code (each WP ends on green tests and `intent wp done`):

- [ ] WP01 — YAML metadata + `metadata.tmpl` update
- [ ] WP02 — `utilz emacs` subcommand (`commands` / `install` / `doctor`) + BATS tests
- [ ] WP03 — `static/emacs/utilz.el` elisp bridge
- [ ] WP04 — End-to-end verification + README + CHANGELOG

## Task Notes

- Doc before code. Phase 0 is committed before any source file under `opt/`, `static/emacs/`, or `help/` is touched.
- Each WP's `info.md` is populated via `intent wp new`, never hand-created.
- Agnostic rule vigilance (Highlander, Thin Coordinator, PFIC, No Silent Errors) applies to bash and elisp alike — see memory `feedback_agnostic_rules_all_languages.md`.

## Dependencies

- WP02 depends on WP01 (TSV emitter consumes the `emacs:` block).
- WP03 depends on WP02 (elisp consumes the TSV).
- WP04 depends on WP03 (E2E verification needs the full bridge).
