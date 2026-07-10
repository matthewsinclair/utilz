---
verblock: "10 Jul 2026:v1.2: matts - ST0008 closed; issue tracker + mdagg 0001 fix landed"
---

# Restart Context

## Key Context (as of 10 Jul 2026)

- **No active steel thread.** All eight threads (ST0001-ST0008) are complete and filed under `intent/st/COMPLETED/`. `intent st list` is empty by design.
- **Framework version is `VERSION` = 2.2.0** (single source of truth). Do not confuse it with the `intent` tooling version (~2.14.x); the `2.13.0` in an older commit message is an Intent-tooling bump, not the framework.
- **13 utilities** (core `utilz` + 12 tools), all passing `utilz doctor` and `utilz test`. The `todo` utility (ST0008) is the newest; `cleanz` is at 1.2.0.
- **File-based issue tracker** lives at `intent/issues/` (`OPEN/` / `CLOSED/` / `_templ/`) for defects a single issue can drive without a steel thread. Issue **0001** (mdagg silent Unicode line-drop under C locale) is fixed and CLOSED.
- Two remotes: `local` (Dropbox) and `upstream` (GitHub) -- push to both (`git push local main && git push upstream main`).

## Project-wide Conventions

- **2-space indentation everywhere**, every language, every Intent project. Reindent any 4-space drift before adding new code. See memory `feedback_two_space_indent.md`.
- **Doc before code**: every non-trivial change starts with `intent st new` + `intent wp new` + `design.md` before any source edit. See `feedback_doc_before_code.md`. (Exception the hypervisor may grant: a tracked issue in `intent/issues/` can drive a focused bugfix without a full ST.)
- **Agnostic rule pack (Highlander / Thin Coordinator / PFIC / No Silent Errors) applies to elisp, shell, YAML** -- every language, not just those with dedicated rule skills. See `feedback_agnostic_rules_all_languages.md`.
- **Never manually wrap markdown prose**; paragraphs flow as single lines. Tables stay column-aligned.
- **No Claude attribution in git commits** (global rule; commits end with the `(C) hello@matthewsinclair.com` copyright footer).
- **bash 3.2 compatibility** (macOS ships an ancient bash): no namerefs, no `${var,,}`; guard `"${arr[@]}"` under `set -u`; avoid GNU-only sed/grep idioms (`\b`, `\u`, byte-fragile bracket classes) -- see issue 0001.

## Recent History

```
4c38cae  mdagg: portable title-case + anchored back-link strip (issue 0001 follow-ups)
7d3128c  mdagg: fix silent Unicode line-drop under C locale (issue 0001)
1a2f336  Fixing utils todo vs intent todo
81dbb03  utilz todo: refuse to create a default todo.md inside an Intent project (ST0008/WP-08)
d4f88e8  utilz todo: guard against clobbering intent todo files (ST0008/WP-08)
03ccded  Add todo utility: standalone DOING/TODO/DONE manager (ST0008)
```

## For Next Session

No active steel thread. Framework at v2.2.0, 13 utilities, editor-integration surface + Emacs bridge, and a live issue tracker. Opportunistic next candidates:

1. Tag `v2.2.0` (`git tag v2.2.0 && git push --tags` to both remotes) -- not yet tagged.
2. Potential future ST: VSCode / Zed / Vim integration families (same TSV manifest, new editor-specific installers).
3. Potential future ST: Emacs bridge v2 -- Transient grouped menu (deferred per ST0007 `design.md`).

### Verification checklist on fresh checkout

- `utilz version` -- expect `utilz v2.2.0`.
- `utilz doctor` + `utilz emacs doctor` -- both green.
- `utilz test` -- full suite green (covers all 13 utilities incl `todo`).
- `utilz integration commands | column -t -s$'\t'` -- one row per user-facing utility.
- Issue tracker: `ls intent/issues/OPEN` (currently empty), `ls intent/issues/CLOSED` (0001).
