---
node: cc
name: Control Claude
role: control
session_id: 7b111465-0f7d-406c-a6ac-1ff28917efdb
heartbeat_at: 2026-07-10T15:45Z
status: active
focus: "issue-0001 (mdagg C-locale Unicode drop) + both follow-ups fixed & pushed; doc reconciliation done (wip/restart/acceptance refreshed, board localfolded). Idle."
claims: [ST0008]
---

# Control Claude (cc)

## DOING

- (idle) All this-session work is landed and pushed. Nothing in flight.

## Done this session (2026-07-10)

- **issue-0001** (mdagg silently dropped Unicode content lines under `LC_ALL=C`) FIXED + CLOSED. Primary `7d3128c`: `[←↑]` bracket class -> byte-safe grep. Follow-ups `4c38cae`: anchored the strip to link structure (`grep -vE '^[[:space:]]*\[(←|↑)'`), replaced the GNU-sed `\b`/`\u` title-case (a no-op on BSD sed -> un-cased titles on macOS) with portable POSIX awk, and extracted the duplicated title derivation into `derive_title()` (Highlander). 31 mdagg BATS green, shellcheck net-zero vs baseline, e2e verified under `LC_ALL=C`.
- Introduced the **file-based issue tracker** at `intent/issues/` (`OPEN/` / `CLOSED/` / `_templ/`); 0001 recorded, resolved, filed under CLOSED.
- **Doc reconciliation**: `intent/wip.md`, `intent/restart.md`, `.claude/restart.md` refreshed to reality (framework v2.2.0, 13 utilities incl `todo`, all STs COMPLETE, issue tracker). `ST0008/acceptance.md` WP-08 heading WIP->Done. This board localfolded (prior-session content -> `.history/20260710/`).

## TODO

- (opportunistic) Add `expz` to the CI loop -- blocked on an `ANTHROPIC_API_KEY` CI secret + skip-when-absent decision. Needs hv.
- (opportunistic) Tag `v2.2.0` -- shipped but untagged.

## Watch-outs

- mdagg strip + title-case are locale/BSD-sed sensitive -- see `intent/issues/CLOSED/0001`. Byte-safe rule of thumb: match multibyte literals with `grep -F` or an ERE alternation `(←|↑)`, never a `[←↑]` class (degrades to bytes under C locale); title-case with POSIX awk, not GNU sed `\b`/`\u` (no-ops on BSD sed).
- todo guard: utilz `item_re` parses intent's `- [x] STID: title` lines as items, so a `utilz todo sync` on an intent file would silently clobber it -- that cross-parse is why the guard (not merge) is the seam. The STAMP is unconditional; the REFUSAL fires only when intent is present. Where intent is absent, utilz must be fully silent and never fail.
- No Claude attribution in commits (project + global rule). Commits end with the `(C) hello@matthewsinclair.com` footer. 2-space indent, bash 3.2 compat.

## Decisions

- (2026-07-10) A tracked issue in `intent/issues/` may drive a focused bugfix without a full ST (hv-approved for issue 0001). Doc-before-code still holds for feature work.
- (2026-07-09) todo guard's Intent-project test is anchored on the **target file's directory** (walk up from `dirname($TODO_FILE)`), NOT cwd. Deliberate divergence from Intent's cwd-based `find_project_root`: the guard protects the file being overwritten, so `--file`-ing at another project's `intent/todo.md` from outside still refuses. Own/unmarked files short-circuit before the project test. (hv-confirmed.)
