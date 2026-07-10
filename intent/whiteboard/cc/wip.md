---
node: cc
name: Control Claude
role: control
session_id: 7b111465-0f7d-406c-a6ac-1ff28917efdb
heartbeat_at: 2026-07-10T16:10Z
status: paused
focus: "Session closed 2026-07-10. v2.3.0 released; mdagg issue-0001 fixed; expz->CI; docs reconciled. All landed + pushed. Detail in .history/20260710/."
claims: [ST0008]
---

# Control Claude (cc)

## DOING

- (idle) Session closed, board released. Nothing in flight.

## Last session (2026-07-10)

Fixed mdagg issue-0001 (silent Unicode drop under C locale) + both follow-ups; added the `intent/issues/` tracker; added `expz` to CI; reconciled the stale tracking docs; cut and pushed release **v2.3.0** (todo utility + mdagg fix). Five commits + tag `v2.3.0` on both remotes. Full detail archived in `.history/20260710/wip.md`.

## TODO

- _(none)_

## Watch-outs

- mdagg strip + title-case are locale/BSD-sed sensitive -- see `intent/issues/CLOSED/0001`. Byte-safe rule of thumb: match multibyte literals with `grep -F` or an ERE alternation `(←|↑)`, never a `[←↑]` class (degrades to bytes under C locale); title-case with POSIX awk, not GNU sed `\b`/`\u` (no-ops on BSD sed).
- todo guard: utilz `item_re` parses intent's `- [x] STID: title` lines as items, so a `utilz todo sync` on an intent file would silently clobber it -- that cross-parse is why the guard (not merge) is the seam. The STAMP is unconditional; the REFUSAL fires only when intent is present. Where intent is absent, utilz must be fully silent and never fail.
- No Claude attribution in commits (project + global rule). Commits end with the `(C) hello@matthewsinclair.com` footer. 2-space indent, bash 3.2 compat.

## Decisions

- (2026-07-10) A tracked issue in `intent/issues/` may drive a focused bugfix without a full ST (hv-approved for issue 0001). Doc-before-code still holds for feature work.
- (2026-07-09) todo guard's Intent-project test is anchored on the **target file's directory** (walk up from `dirname($TODO_FILE)`), NOT cwd. Deliberate divergence from Intent's cwd-based `find_project_root`: the guard protects the file being overwritten, so `--file`-ing at another project's `intent/todo.md` from outside still refuses. Own/unmarked files short-circuit before the project test. (hv-confirmed.)
