---
verblock: "29 Jul 2026:v1.3: matts - ST0009 closed; v2.4.0 released; whiteboard to SOTA"
---

# Restart Context

## Key Context (as of 29 Jul 2026)

- **No active steel thread.** All nine threads (ST0001-ST0009) are complete and filed under `intent/st/COMPLETED/`. `intent st list` is empty by design.
- **Framework version is `VERSION` = 2.4.0** (single source of truth; tagged `v2.4.0`, 2026-07-29). Do not confuse it with the `intent` tooling version (2.17.3); the `2.13.0` in an older commit message is an Intent-tooling bump, not the framework.
- **13 utilities** (core `utilz` + 12 tools), all passing `utilz doctor` and `utilz test`. The `todo` utility (ST0008) is the newest; `cleanz` is at 1.2.0.
- **`yq` is a HARD dependency as of v2.4.0.** The grep YAML fallback is gone -- `utilz list` now fails loudly with an install hint where it previously degraded silently. `utilz doctor` must still complete without `yq`, because that is the command you run to discover it is missing; do not "tidy" it to gate on `require_yq`.
- **File-based issue tracker** lives at `intent/issues/` (`OPEN/` / `CLOSED/`) for defects a single issue can drive without a steel thread. Both 0001 (mdagg Unicode/C-locale) and 0002 (generator floor) are CLOSED; `OPEN/` is empty.
- **Whiteboard has two nodes**: `hv` (Workstream Zero, the human) and `cc`. Roster in `intent/whiteboard/README.md`. `cc/inbox.vboot-cc.md` is an external correspondent from the Vboot project, not a workstream here.
- **`languages` is `["shell"]` only.** `elixir` was removed on 2026-07-29 -- declared but never used, and it was loading two Elixir skills into every `/in-session`.
- Two remotes: `local` (Dropbox) and `upstream` (GitHub) -- push to both (`git push local main && git push upstream main`). Releases tag the `release:` commit itself, not the session's final HEAD.

## Project-wide Conventions

- **2-space indentation everywhere**, every language, every Intent project. Reindent any 4-space drift before adding new code. See memory `feedback_two_space_indent.md`.
- **Doc before code**: every non-trivial change starts with `intent st new` + `intent wp new` + `design.md` before any source edit. See `feedback_doc_before_code.md`. (Exception the hypervisor may grant: a tracked issue in `intent/issues/` can drive a focused bugfix without a full ST.)
- **Agnostic rule pack (Highlander / Thin Coordinator / PFIC / No Silent Errors) applies to elisp, shell, YAML** -- every language, not just those with dedicated rule skills. See `feedback_agnostic_rules_all_languages.md`.
- **Never manually wrap markdown prose**; paragraphs flow as single lines. Tables stay column-aligned.
- **No Claude attribution in git commits** (global rule; commits end with the `(C) hello@matthewsinclair.com` copyright footer).
- **bash 3.2 compatibility** (macOS ships an ancient bash): no namerefs, no `${var,,}`; guard `"${arr[@]}"` under `set -u`; avoid GNU-only sed/grep idioms (`\b`, `\u`, byte-fragile bracket classes) -- see issue 0001.

## Recent History

```
3cbda7f  docs: correct the bash floor to 3.2 across the remaining READMEs
294e3b9  chore(whiteboard): provision hv, add the roster README (Lamplight/Baize SOTA)
3bc17ca  chore(intent): drop the unused elixir language pack
4d5a7b6  chore(whiteboard): deliver the vboot-cc reply, drop the local draft
014a5b5  issues: close 0002 -- generator floor fixed and shipped in v2.4.0
703baab  release: v2.4.0 (framework core -- ST0009, issue 0002)   <- tag v2.4.0
b468636  fix(core): one bin walker, one YAML parser, derived generator floor (ST0009)
bac04e5  docs(st): ST0009 + issue 0002 -- paperwork for the framework-core triple
19de6d5  chore(intent): install shell rule pack, regen AGENTS.md (intent 2.17.3)
```

## For Next Session

No active steel thread. Framework at v2.4.0, 13 utilities, editor-integration surface + Emacs bridge, and a live issue tracker with nothing open. Opportunistic next candidates:

1. Potential future ST: VSCode / Zed / Vim integration families (same TSV manifest, new editor-specific installers).
2. Potential future ST: Emacs bridge v2 -- Transient grouped menu (deferred per ST0007 `design.md`).

Carried out of this session, both outside this repo and neither blocking:

- **Intent issue 0008** is filed but **uncommitted** in `../Intent` (`intent/issues/OPEN/0008/`). It covers the unconditional `Bash 4.0+` line that `intent agents sync` writes into every project's `AGENTS.md`. When it is fixed, re-run `intent agents sync` here to pick up the correction -- `AGENTS.md:13` is wrong today and must not be hand-edited.
- The reply to the Vboot node was delivered as `../Vboot/intent/whiteboard/cc/TEMP-from-utilz-cc-20260729.md` (uncommitted there, theirs to file or bin). Nothing here depends on it.

### Verification checklist on fresh checkout

- `utilz version` -- expect `utilz v2.4.0`.
- `utilz doctor` + `utilz emacs doctor` -- both green (`doctor` warns if `$UTILZ_HOME/bin` is not on `$PATH`; that is environmental).
- `utilz test` -- full suite green, 14 suites. Takes several minutes; do not assume a timeout means a failure.
- `utilz integration commands | column -t -s$'\t'` -- one row per user-facing utility.
- Issue tracker: `ls intent/issues/OPEN` (empty), `ls intent/issues/CLOSED` (0001, 0002).
- Sanity-check the v2.4.0 behaviour change: with `yq` off `PATH`, `utilz list` must fail loudly with a single install hint, and `utilz doctor` must still complete and name `yq` as missing.
