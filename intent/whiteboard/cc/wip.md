---
node: cc
name: Control Claude
role: control
session_id: 7b111465-0f7d-406c-a6ac-1ff28917efdb
heartbeat_at: 2026-07-10T15:09Z
status: active
focus: "issue-0001 FIXED (mdagg silently dropped Unicode lines under C locale): grep -vF at opt/mdagg/mdagg:121 + 2 C-locale regression tests; suite green, shellcheck clean, issue CLOSED. Uncommitted -- awaiting hv commit/push go."
claims: [ST0008]
---

# Control Claude (cc)

## DOING

- issue-0001 (mdagg unicode-drop under C locale) -- FIXED + verified, issue moved to intent/issues/CLOSED/. Uncommitted; awaiting hv commit/push decision. Two flagged follow-ups (NOT done): title-case `sed \u\1` locale fragility (~mdagg:238/275) + tightening the strip to only link-structured lines.

## Done this session

- FOLLOW-UP FIX `81dbb03` (pushed): first-use bug -- bare `utilz todo` created a stray `./todo.md` inside an Intent project (default paths differ: utilz `./todo.md` vs intent `intent/todo.md`, so the overwrite guard never fired). Now creation on the default path is gated by the same intent-aware checks (+ `DEFAULT_PATH` flag): refuses inside an Intent project, points to `intent todo` / `--file`/`-g`. Existing utilz files, `--file`/`-g`, read-only queries, non-Intent dirs unaffected. 31 BATS green; e2e reproduced + fixed. NB: user has a stray `~/Devel/prj/Intent/todo.md` from the failed first use (their repo, not touched).
- WP-08 COMPLETE + committed `d4f88e8` (pushed). Stamp `generator: utilz todo` + intent-aware guard in `opt/todo/todo` (guard at write_file + cmd_prune + cmd_edit; `_in_intent_project` file-dir-rooted; `_intent_present` with `UTILZ_TODO_INTENT_PRESENT` test seam). 29 BATS green (5 new); shellcheck clean (only pre-existing SC1010/SC1091, non-blocking in CI); real e2e verified -- refused inside this repo's Intent project (intent 2.16.1), took over + stamped outside. Docs: help/todo.md + README "Interop with intent todo". WP-08 done, ST0008 re-completed. Left uncommitted for hv: `intent upgrade` changes (config.json, AGENTS.md), incidental `intent/todo.md`, this whiteboard.

## TODO

- Confirm doc-before-code path: reopen ST0008 with a new WP vs new ST for the cross-tool guard (needs hv ruling; `intent st list` is empty because STs sit under intent/st/COMPLETED/).
- Change 1: stamp `generator: utilz todo` into the frontmatter `write_file()` emits (alongside title:/history:).
- Change 2: add symmetric guard mirroring intent's `guard_foreign_todo()` -- before overwrite, read existing file's `generator:`; proceed silently if absent or == "utilz todo"; on a foreign marker (eg "intent todo") refuse ONLY when intent is actually installed (`command -v intent`), else proceed silently.
- Tests: add BATS coverage in opt/todo/test/todo.bats for stamp + refusal + fresh/own-file pass-through.
- Docs: help/todo.md + README note on the shared-file ownership contract.

## Watch-outs

- Formats cross-parse: utilz item_re parses intent's `- [x] STID: title` lines as items, so a `utilz todo sync` on an intent file would silently clobber it. That cross-parse is exactly why the guard (not merge) is the seam.
- Every `write_file()` is currently preceded by `parse_file()` in the same invocation -- verified across all cmd_*. Guard belongs at the single writer seam (top of `write_file()`), self-contained so a future call site can't bypass it.
- Intent-aware: utilz is standalone. The STAMP is unconditional (always write `generator: utilz todo`), but the REFUSAL is the only error path and must fire only when intent is present. Where intent isn't installed, utilz must be fully silent and never fail -- no probing emissions, no error, even on an intent-marked file.
- Guard never shells out to `intent` except a silent `command -v intent`; the common own/fresh-file paths return before any intent probe at all.
- No Claude attribution in commits (project + global rule). 2-space indent, bash 3.2 compat.

## Decisions

- (2026-07-09) Guard's Intent-project test is anchored on the **target file's directory** (walk up from `dirname($TODO_FILE)`), NOT cwd. Deliberate divergence from Intent's cwd-based `find_project_root`: the guard protects the file being overwritten, so `--file`-ing at another project's `intent/todo.md` from outside still refuses. No false refusals -- own/unmarked files short-circuit on the marker check before the project test runs. (hv-confirmed.)
