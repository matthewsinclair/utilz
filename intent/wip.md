---
verblock: "29 Jul 2026:v1.3: matts - ST0009 closed; v2.4.0 released; whiteboard to SOTA"
---

# Work In Progress

## Current Focus

No active steel thread. Framework at **v2.4.0** with 13 utilities (core `utilz` + 12 tools), an editor-integration surface, and the Emacs bridge. All nine steel threads (ST0001-ST0009) are complete and live under `intent/st/COMPLETED/`. Repo is clean and pushed to both remotes. Next work is opportunistic (backlog triage).

## Just Landed

- **v2.4.0 released (ST0009).** Three framework-core defects landed together: one `each_utility()` walker replacing five drifted copies; `yq` promoted to a hard dependency with the two-parser grep fallback removed; and `utilz generate` stamping a compatibility floor derived from `VERSION` instead of a hardcoded `^1.0.0` (issue 0002). Minor rather than patch because `utilz list` now fails loudly without `yq` where it previously degraded silently. 12 new tests, 11 of which fail against the previous code. Tagged `v2.4.0`, both remotes.
- **Provenance note worth keeping.** The ST0009 source edits were made by the `cc` node of the **Vboot** project (`../Vboot`), inline and hv-instructed, from outside this repo and while this project's own session was live. They were found uncommitted and ST-less during pickup triage and flagged as an orphan rather than adopted or reverted; Vboot's node then claimed provenance via `intent/whiteboard/cc/inbox.vboot-cc.md`. Two of its claims were checked rather than accepted -- its bash 3.2 caveat held (now verified under 3.2.57), its `opt/todo/todo.yaml` "fossil" evidence did not (that file was born `^2.0.0`), which is why issue 0002 is `severity: low`.
- **Whiteboard brought to the Lamplight / Baize standard.** `hv` node provisioned via `intent claude ws new hv` (Workstream Zero -- present in every Intent project; Utilz previously had nowhere for an escalation to land), plus a hand-authored `intent/whiteboard/README.md` roster. Roster stays at two nodes deliberately: Utilz is single-stream and nodes are made to order.
- **`elixir` dropped from `languages`.** Declared but never used -- no `mix.exs`, no `.ex`/`.exs` -- and live enough to matter, since `/in-session` was loading two Elixir skills into every session for a pure-bash project.
- **Bash floor corrected 4.0+ -> 3.2 in 10 files.** The project targets bash 3.2 (macOS ships 3.2.57, CI runs it) but ten hand-authored files claimed 4.0+. One instance survives in `AGENTS.md:13` and cannot be fixed here -- see Notes.
- **v2.3.0 released.** `VERSION` bumped 2.2.0 -> 2.3.0 (additive minor: the new `todo` utility), CHANGELOG `## [2.3.0]` entry, annotated tag `v2.3.0` pushed to both remotes. (The prior `v2.2.0` tag already existed at the ST0007 close; the todo utility + mdagg fixes had accumulated on top of it unreleased.)
- **expz added to the CI Linux loop** (`.github/workflows/tests.yml`). No secret needed: the expz BATS suite is entirely offline -- every test exercises arg/schema-validation paths that return before the `ANTHROPIC_API_KEY` check, so it passes with the key unset (verified). macOS CI already ran it via `utilz test`; this closes the Linux gap. The long-standing "needs ANTHROPIC_API_KEY in CI" note was a stale assumption.
- **Issue 0001 (mdagg silent Unicode line-drop under C locale)** -- fixed at source and closed. `mdagg`'s `strip_back_links` used a `[←↑]` bracket class that, under `LC_ALL=C`, degraded to a byte set and silently deleted any content line holding a U+2000-U+2FFF character (`→ ∥ ∈ — ...`). Fixed with an anchored, byte-safe ERE (`grep -vE '^[[:space:]]*\[(←|↑)'`) that also tightens the strip to genuine link lines; the sibling GNU-sed title-case (`\b`/`\u`, a no-op on BSD sed) was replaced with portable POSIX awk and the duplicated derivation extracted into `derive_title()` (Highlander). Commits `7d3128c` + `4c38cae`; 31 mdagg BATS green; issue recorded in the new tracker.
- **File-based issue tracker** introduced at `intent/issues/` (`OPEN/`, `CLOSED/`, `_templ/`). Lightweight, git-tracked, ST-independent -- for defects that a single issue can drive without a full steel thread.
- **ST0008: `utilz todo`** (completed 2026-07-03, 8 WPs). A standalone DOING/TODO/DONE manager forked from `intent todo`; the `todo.md` is the source of truth (not an ST projection). WP-08 added the `utilz todo <-> intent todo` mutual guard: `utilz todo` stamps `generator: utilz todo` and refuses to clobber an Intent-owned `todo.md`, but only when Intent is actually present, so it stays a zero-dependency standalone tool. Acceptance contract in `intent/st/COMPLETED/ST0008/acceptance.md`.
- **ST0007: Emacs bindings** (closed 23 Apr 2026). Metadata-driven bridge exposing Utilz commands inside Doom Emacs via `M-x utilz`; editor-neutral `integration:` YAML block + `utilz integration commands` + `utilz emacs {install,doctor}` + canonical elisp at `static/emacs/utilz.el`.

## Active Steel Threads

None. ST0001-ST0009 all complete (`intent/st/COMPLETED/`). `intent st list` is empty by design -- completed threads are filed under `COMPLETED/`.

## Upcoming Work

- No open issues. `intent/issues/OPEN/` is empty; 0001 and 0002 are both CLOSED.
- Potential future STs: VSCode / Zed / Vim integration families (same TSV manifest); Emacs bridge v2 (Transient grouped menu, deferred per ST0007 design.md).

## Notes

- **Version disambiguation.** The Utilz _framework_ version is `VERSION` = **2.4.0** (single source of truth). The `intent` _tooling_ version (2.17.3) is separate; don't conflate them. The `2.13.0` in commit `e000db5`'s message refers to an Intent-tooling bump, not the framework.
- **`AGENTS.md:13` still says "Bash 4.0+" and must not be hand-edited.** It is generated, and the string is an unconditional `echo` at `intent/plugins/agents/bin/intent_agents:323` in `../Intent` -- so every Intent project carries it regardless of language (Lamplight and Baize show the same line despite being Elixir/Rust/Swift/Lua). Raised as **Intent issue 0008**; the fix belongs there. When it lands, re-run `intent agents sync` here to pick it up.
- **Two contracts in `common.sh` that are silent when broken.** Consume `each_utility` with process substitution, never a pipe -- a pipe subshells the loop body and accumulator arrays are discarded, so `run_doctor` / `run_tests` would report nothing, successfully. And call `require_yq` once before a loop, never per-iteration and never memoised: `get_util_metadata` runs inside command substitution, so a memo dies with the subshell. Both are pinned by tests; see `intent/st/COMPLETED/ST0009/design.md`.
- Editor-integration shape: every user-facing utility declares an `integration:` block in its YAML (`input`, `output`, `flags`); the single walker `emit_integration_tsv` in `opt/utilz/lib/common.sh` emits the only cross-boundary contract (TSV). `utilz integration commands` is the neutral entry point; `utilz emacs {install,doctor}` is the first editor-specific installer.

## Context for LLM

This document captures the current state of development. Read it first, then `intent/restart.md` for cross-session continuity. Completed steel threads live under `intent/st/COMPLETED/<ID>/`; open defects live under `intent/issues/OPEN/`.

### How to use this document

1. Update "Current Focus" with what is currently being worked on.
2. List active steel threads with their IDs and brief descriptions.
3. Keep track of upcoming work items.
4. Add relevant notes that might be helpful for yourself or the LLM.
