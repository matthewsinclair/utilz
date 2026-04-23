---
verblock: "23 Apr 2026:v1.0: matts - ST0007 closed, framework at 2.2.0"
---

# Restart Context

## Key Context (as of 23 Apr 2026)

- **ST0007 CLOSED** (Emacs bindings for Utilz utilities). All four WPs plus the 4-to-2-space reindent committed. Framework bumped to 2.2.0. Emacs bridge live in user's Doom (`~/.config/doom/custom/160-utilz.el` -> symlink to `static/emacs/utilz.el`). 34-test batch E2E + live Doom spot-check both green.
- Framework version is still **2.1.0** (ST0007 will land in v2.2.0 on close).
- 12 utilities installed, all passing `utilz doctor` and `utilz test`.
- Two remotes: `local` (Dropbox) and `upstream` (GitHub) — push to both.

## Project-wide Conventions (re-confirmed this session)

- **2-space indentation everywhere**, every language, every Intent project. Any 4-space drift you find is drift — reindent it before adding new code. See memory `feedback_two_space_indent.md`.
- **Doc before code, always**: every non-trivial change starts with `intent st new` + `intent wp new` + `design.md` committed before any source edit. See memory `feedback_doc_before_code.md`.
- **Agnostic rule pack (Highlander / Thin Coordinator / PFIC / No Silent Errors) applies to elisp, shell, YAML** — every language, not just those with dedicated rule skills. See memory `feedback_agnostic_rules_all_languages.md`.
- **Never manually wrap markdown prose**; paragraphs flow as single lines. Tables stay column-aligned.
- **No Claude attribution in git commits** (existing global rule; reiterated).

## Recent Decisions (this session)

- YAML integration-metadata block is named **`integration:`** (editor-neutral), not `emacs:`. Future VSCode / Zed / Vim consumers read the same block.
- Subcommands split by scope: **`utilz integration commands`** (neutral TSV emitter, one Highlander walker) + **`utilz emacs {install,doctor}`** (Emacs-specific). Future integrations slot as parallel `utilz <editor>` families.
- Canonical elisp file name: **`static/emacs/utilz.el`** (Emacs-convention, `(provide 'utilz)`). User symlinks it into `~/.config/doom/custom/160-utilz.el`.
- `utilz emacs install` requires `--dest PATH`; does not edit `config.el` for the user; prints the `(load ...)` line to paste.
- Output handling defaults: `cleanz` (stdin/replace) silently replaces region/buffer with single `undo-boundary`; non-zero exit leaves text alone and pops stderr (No Silent Errors).
- Emacs bridge v1 is `completing-read` only (Vertico). Transient menu is a future enhancement, out of scope.
- Project-wide 4-space → 2-space reindent landed as its own commit (`9c9c439`) — 32 files, pure mechanical.

## Commit Graph This Session

```
<WP04 commit — pending>  ST0007/WP04: E2E verification + docs + VERSION bump to 2.2.0 + close ST
2a5b743  ST0007/WP03: elisp bridge static/emacs/utilz.el
c75381a  ST0007: update wip.md and restart.md for mid-ST compact
eb7264e  ST0007/WP02: utilz integration + utilz emacs subcommands
9c9c439  Reindent bash from 4-space to 2-space (Intent project standard)
7e97cb7  ST0007/WP01: integration metadata on 12 utilities + template + doc rename
631b604  ST0007: Emacs bindings for Utilz -- Phase 0 design + WP01-04
```

`.intent/config.json` (Intent 2.8.1 → 2.8.2 bump) is still uncommitted — pre-existing, not mine to commit.

## For Next Session

No active steel thread. Framework at v2.2.0 with 12 utilities + editor integration surface + Emacs bridge. Opportunistic next candidates:

1. Add `expz` to CI test loop in `.github/workflows/tests.yml` (carry-over from prior session).
2. Consider tagging v2.2.0 (`git tag v2.2.0 && git push --tags`).
3. Potential future ST: VSCode / Zed / Vim integration families (same TSV manifest, new editor-specific installers).
4. Potential future ST: Emacs bridge v2 — Transient grouped menu (currently deferred to future enhancement per design.md §3).

### Verification checklist on fresh checkout

- `utilz version` — expect `utilz v2.2.0`.
- `utilz doctor` + `utilz emacs doctor` — both green.
- `utilz test` — expect 13 suites green (70 tests utilz.bats + bridge.bats; full suite covers all 12 utilities).
- `utilz integration commands | column -t -s$'\t'` — 12-row table.
- Optional batch E2E: `UTILZ_HOME=$PWD emacs -Q --batch -l static/emacs/e2e-smoke.el` — expects `34 PASS / 0 FAIL / exit 0`.
