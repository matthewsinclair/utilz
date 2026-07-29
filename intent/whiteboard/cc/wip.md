---
node: cc
name: Control Claude
role: control
session_id: 536a4f85-7490-4324-8c8d-6c09420b6de3
heartbeat_at: 2026-07-29T11:05Z
status: active
focus: "ST0009 landed: the three framework-core defects vboot-cc fixed inline are now documented (ST + 3 WPs + design + issue 0002), tested (12 new BATS, 11 red at HEAD), doc-reconciled, and released as v2.4.0. Open: reply routing to vboot-cc (cross-repo), and the stale elixir language declaration."
claims: [ST0009]
---

# Control Claude (cc)

## DOING

- (idle) ST0009 complete, v2.4.0 cut. Two questions with hv -- see TODO.

## Last session (2026-07-10)

Fixed mdagg issue-0001 (silent Unicode drop under C locale) + both follow-ups; added the `intent/issues/` tracker; added `expz` to CI; reconciled the stale tracking docs; cut and pushed release **v2.3.0** (todo utility + mdagg fix). Five commits + tag `v2.3.0` on both remotes. Full detail archived in `.history/20260710/wip.md`.

## This session (2026-07-29)

Picked up an uncommitted, ST-less refactor of `opt/utilz/lib/common.sh` left in the working tree. Triaged it as an orphan and blocked on hv rather than adopting or reverting it; `vboot-cc` (the `cc` node of the **Vboot** project, `../Vboot`) then claimed provenance via `inbox.vboot-cc.md` -- it had edited this tree from outside the project, hv-instructed, while this session was live and unaware. hv ruled: proceed and fix.

Landed as **ST0009** (WP-01 walker / WP-02 yq / WP-03 generator floor) plus **issue 0002**, and released as **v2.4.0**. The code was already green; the missing work was coverage. 12 new tests in `common_lib.bats`, verified red-first retrospectively against `HEAD` in a scratch copy -- 11 of 12 fail against the pre-change code. Also reconciled `docs/architecture.md`, `help/utilz.md`, `README.md`.

Two claims in vboot-cc's report were checked rather than taken at face value: its bash 3.2 belief (**correct** -- now verified under `/bin/bash 3.2.57`, it had explicitly flagged this as unverified) and its `opt/todo/todo.yaml` "fossil of a hand-fix" evidence (**wrong** -- `todo.yaml` was born `^2.0.0` in `03ccded` and all 13 utilities carry `^2.0.0`; the defect is purely latent and never bit this repo). Issue 0002 records the withdrawal.

## TODO

- **Reply to vboot-cc is drafted but NOT delivered.** Its inbox would be `../Vboot/intent/whiteboard/cc/inbox.utilz-cc.md` -- another repo. Writing there unbidden is the same unannounced cross-project write vboot-cc apologised for, so it needs hv's routing call. vboot-cc is waiting on the framing ruling, so this is not cost-free to defer.
- **`languages: ["shell", "elixir"]` in `intent/.config/config.json` is stale.** No `mix.exs`, no `.ex`/`.exs`, pure bash -- yet `/in-session` loads two Elixir skills off that declaration every session, and `intent/llm/RULES-elixir.md` exists. Independently spotted from both sides (this node at pickup, vboot-cc from `config.json`). Fix is `intent lang remove elixir`, but removing a declared language is hv's call, not mine.

## Watch-outs

- `each_utility()` must be consumed with process substitution -- `while IFS= read -r name; do ...; done < <(each_utility)` -- never a pipe. `run_doctor` and `run_tests` accumulate into arrays; a pipe subshells the loop body and both would silently report nothing.
- `require_yq` must be called ONCE before a loop, never per-iteration. `get_util_metadata` runs inside command substitution, so it cannot memoise -- a subshell's variables die with it. The first cut memoised and reprinted the install hint 13 times. AT-02.2 pins this.
- `run_doctor` deliberately does NOT gate on `require_yq` -- it is the command you run to discover yq is missing. It resolves `have_yq` once up front and branches. Check 6 reports yq by hand and first, because parsing YAML to discover the YAML parser is missing does not work.
- A peer node in another project may edit this working tree. `vboot-cc` did so on 2026-07-29 while this session was live, so a `git status` taken mid-session is not a stable baseline. Re-verify before trusting measurements taken earlier in a session.
- mdagg strip + title-case are locale/BSD-sed sensitive -- see `intent/issues/CLOSED/0001`. Byte-safe rule of thumb: match multibyte literals with `grep -F` or an ERE alternation `(←|↑)`, never a `[←↑]` class (degrades to bytes under C locale); title-case with POSIX awk, not GNU sed `\b`/`\u` (no-ops on BSD sed).
- todo guard: utilz `item_re` parses intent's `- [x] STID: title` lines as items, so a `utilz todo sync` on an intent file would silently clobber it -- that cross-parse is why the guard (not merge) is the seam. The STAMP is unconditional; the REFUSAL fires only when intent is present. Where intent is absent, utilz must be fully silent and never fail.
- No Claude attribution in commits (project + global rule). Commits end with the `(C) hello@matthewsinclair.com` footer. 2-space indent, bash 3.2 compat.

## Decisions

- (2026-07-29) A shipped defect fixed inside a steel thread still gets its own `intent/issues/` entry (0002 alongside ST0009/WP-03), following the 0001 precedent. The ST carries the work; the issue carries the defect record.
- (2026-07-29) Retroactive paperwork is the remediation for a doc-before-code violation when the code is already correct and verified -- not reverting it. Red-first is then proven retrospectively by running the new tests against `HEAD` in a scratch copy, and the retrospective verification is stated as such in `acceptance.md` rather than presented as genuine red-first.
- (2026-07-10) A tracked issue in `intent/issues/` may drive a focused bugfix without a full ST (hv-approved for issue 0001). Doc-before-code still holds for feature work.
- (2026-07-09) todo guard's Intent-project test is anchored on the **target file's directory** (walk up from `dirname($TODO_FILE)`), NOT cwd. Deliberate divergence from Intent's cwd-based `find_project_root`: the guard protects the file being overwritten, so `--file`-ing at another project's `intent/todo.md` from outside still refuses. Own/unmarked files short-circuit before the project test. (hv-confirmed.)
