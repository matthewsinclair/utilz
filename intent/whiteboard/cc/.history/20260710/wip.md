---
archived_from: cc/wip.md
archived_at: 2026-07-10T15:45Z
---

# cc board archive -- 2026-07-10

Prior-session (2026-07-09) DONE work and superseded TODO, rolled out of the live board during the 2026-07-10 localfold. Not reloaded on pickup.

## Done (2026-07-09 session)

- FOLLOW-UP FIX `81dbb03` (pushed): first-use bug -- bare `utilz todo` created a stray `./todo.md` inside an Intent project (default paths differ: utilz `./todo.md` vs intent `intent/todo.md`, so the overwrite guard never fired). Now creation on the default path is gated by the same intent-aware checks (+ `DEFAULT_PATH` flag): refuses inside an Intent project, points to `intent todo` / `--file`/`-g`. Existing utilz files, `--file`/`-g`, read-only queries, non-Intent dirs unaffected. 31 BATS green; e2e reproduced + fixed. NB: user has a stray `~/Devel/prj/Intent/todo.md` from the failed first use (their repo, not touched).
- WP-08 COMPLETE + committed `d4f88e8` (pushed). Stamp `generator: utilz todo` + intent-aware guard in `opt/todo/todo` (guard at write_file + cmd_prune + cmd_edit; `_in_intent_project` file-dir-rooted; `_intent_present` with `UTILZ_TODO_INTENT_PRESENT` test seam). 29 BATS green (5 new); shellcheck clean (only pre-existing SC1010/SC1091, non-blocking in CI); real e2e verified -- refused inside this repo's Intent project (intent 2.16.1), took over + stamped outside. Docs: help/todo.md + README "Interop with intent todo". WP-08 done, ST0008 re-completed.

## Superseded TODO (all shipped as WP-08; archived 2026-07-10)

These were pre-WP-08 planning notes. WP-08 was subsequently created, implemented, and completed, so every item is done and shipped:

- Confirm doc-before-code path: reopen ST0008 with a new WP vs new ST for the cross-tool guard. RESOLVED -- WP-08 was created and completed under ST0008.
- Change 1: stamp `generator: utilz todo` into `write_file()` frontmatter. DONE (WP-08).
- Change 2: symmetric guard mirroring intent's `guard_foreign_todo()`. DONE (WP-08).
- Tests: BATS coverage for stamp + refusal + fresh/own-file pass-through. DONE (AT-08.1..08.7 green).
- Docs: help/todo.md + README shared-file ownership contract. DONE (WP-08).
