---
node: cc
name: Control Claude
role: control
session_id: 536a4f85-7490-4324-8c8d-6c09420b6de3
heartbeat_at: 2026-07-29T21:48Z
status: paused
focus: "Released at fe8eecf. v2.4.0 shipped, repo-wide shell audit landed, then a health check found three more dispatcher/doctor defects (issues 0003-0005) -- all fixed, closed, 407 tests green. Nothing in flight; fe8eecf + c5694d6 unpushed."
claims: []
---

# Control Claude (cc)

## DOING

- (idle) Nothing in flight at `fe8eecf`. ST0009 complete, v2.4.0 tagged + pushed, reply delivered to cdsync-cc, whiteboard at SOTA, repo-wide shell audit landed, issues 0003-0005 fixed and closed.

## Last session (2026-07-10)

Fixed mdagg issue-0001 (silent Unicode drop under C locale) + both follow-ups; added the `intent/issues/` tracker; added `expz` to CI; reconciled the stale tracking docs; cut and pushed release **v2.3.0** (todo utility + mdagg fix). Five commits + tag `v2.3.0` on both remotes. Full detail archived in `.history/20260710/wip.md`.

## This session (2026-07-29)

Picked up an uncommitted, ST-less refactor of `opt/utilz/lib/common.sh` left in the working tree. Triaged it as an orphan and blocked on hv rather than adopting or reverting it; `cdsync-cc` (the `cc` node of the **Cdsync** project, `../Cdsync`) then claimed provenance via `inbox.cdsync-cc.md` -- it had edited this tree from outside the project, hv-instructed, while this session was live and unaware. hv ruled: proceed and fix.

Landed as **ST0009** (WP-01 walker / WP-02 yq / WP-03 generator floor) plus **issue 0002**, and released as **v2.4.0**. The code was already green; the missing work was coverage. 12 new tests in `common_lib.bats`, verified red-first retrospectively against `HEAD` in a scratch copy -- 11 of 12 fail against the pre-change code. Also reconciled `docs/architecture.md`, `help/utilz.md`, `README.md`.

Then, at hv's request, a repo-wide ULTRATHINK audit of every utility -- "are there other dumb things in there I have missed?". Yes: **57 shellcheck findings including 3 hard errors, now 0**, plus four real defects that no tool found (they came out of reading): `clipz` copy/paste silently no-op'd and reported success (`local x=$(cmd) || exit 1` never fires -- `local` returns its own status, and an empty command with a redirect runs nothing and exits 0); `syncz execute_delete` printed "Delete complete" unconditionally after `rsync || true`, twelve lines from an `execute_sync` that already had the correct 0/23/else convention; `mdagg` carried a `--version` fallback that was unreachable, would have died on a top-level `local` if reached, and hardcoded a stale `v1.0.0`; `cleanz`'s trope detector collapsed grep exit 2 (invalid regex) into "no match", so a broken pattern silently stopped detecting. One structural gap too: CI's shellcheck step never saw `common.sh` (0644, and the step only collected executables) and was `|| echo "(non-blocking)"` -- it could not fail the build. Both fixed; the gate is blocking and was sequenced last so it never reddened CI. `ensure_venv()` extracted from pdf2md+xtrct (Highlander). Four commits: `cf45371`, `1cb66b2`, `0566bcc`, `ad6402d`. Suite 395 passing / 0 failures.

Closed with a health check hv asked for directly -- "is Utilz good?" -- run as measurement rather than recital: suite, the exact CI shellcheck collector, the shell critic, a bash 3.2 parse sweep, `gh run view` on the last push, doctor, `intent doctor`. All green, but reading the dispatcher on the way through turned up **three more defects**, filed and closed as issues **0003-0005** in `fe8eecf`. 0003: `utilz --version|--help|-h` all exited 1 with "Unknown command" while every utility and both nested verbs accepted the flag forms. 0004: the unknown-command "Installed utilities" list was a **sixth** open-coded `bin/*` walk that ST0009/WP-01 missed, carrying the exact `-L`-only drift ST0009 existed to remove (that sweep grepped `common.sh`; this copy lives in `bin/utilz`). 0005: doctor check 4 was `echo "$PATH" | grep -q "$UTILZ_HOME/bin"` -- one expression, two faults, rejecting a working symlink install and passing on any substring. 12 new tests, 6 genuinely red first. 407 passing (was 395).

Two claims in cdsync-cc's report were checked rather than taken at face value: its bash 3.2 belief (**correct** -- now verified under `/bin/bash 3.2.57`, it had explicitly flagged this as unverified) and its `opt/todo/todo.yaml` "fossil of a hand-fix" evidence (**wrong** -- `todo.yaml` was born `^2.0.0` in `03ccded` and all 13 utilities carry `^2.0.0`; the defect is purely latent and never bit this repo). Issue 0002 records the withdrawal.

## TODO

- Two items live **outside this repo**, both hv's to land: Intent issue `0008` is filed but uncommitted in `../Intent/intent/issues/OPEN/0008/` (`intent agents sync` writes an unconditional `- Bash 4.0+, POSIX-compliant shell` into every AGENTS.md; source `intent/plugins/agents/bin/intent_agents:323`), and the reply to Cdsync sits uncommitted at `../Cdsync/intent/whiteboard/cc/TEMP-from-utilz-cc-20260729.md`.
- Once the Intent fix lands, re-run `intent agents sync` here, in Lamplight and in Baize. `AGENTS.md:13` is wrong today and must NOT be hand-edited -- it is generated, and the next sync would revert the edit.

## Watch-outs

- **`each_utility()` now has six consumers, one of them in `bin/utilz`.** ST0009's sweep missed that file because it grepped `common.sh` only. The check that proves there is no seventh copy is `grep -rn 'UTILZ_HOME"/bin/\*' bin/utilz opt/utilz/lib/common.sh` -- it must return exactly two hits, the walker's own loop and nothing else open-coded. Run it after any change that adds a listing surface.
- **`utilz test` is not safe to run concurrently.** The test helper's `create_test_utility` mutates `$UTILZ_HOME/bin`, so two suites corrupt each other -- observed as a 2h18m hang stalled at `common_lib.bats` test 22 on 2026-07-29, caused by an orphaned background run, not a code defect. One suite at a time; kill strays before starting.
- Verify shell tooling under `/bin/bash` with an array, never under zsh with an unquoted variable. `shellcheck -x $FILES` in zsh does not word-split, so shellcheck receives one bogus path, errors, and the empty output reads as a pass. That mistake produced a false "all 15 clean" against a real 57 findings on 2026-07-29.
- Do not use `perl -0pi -e` for replacements whose text contains `$(` -- Perl interpolates `$(` as the GID variable and silently corrupts the file (it mangled `gitz` this way). Use the Edit tool.
- `each_utility()` must be consumed with process substitution -- `while IFS= read -r name; do ...; done < <(each_utility)` -- never a pipe. `run_doctor` and `run_tests` accumulate into arrays; a pipe subshells the loop body and both would silently report nothing.
- `require_yq` must be called ONCE before a loop, never per-iteration. `get_util_metadata` runs inside command substitution, so it cannot memoise -- a subshell's variables die with it. The first cut memoised and reprinted the install hint 13 times. AT-02.2 pins this.
- `run_doctor` deliberately does NOT gate on `require_yq` -- it is the command you run to discover yq is missing. It resolves `have_yq` once up front and branches. Check 6 reports yq by hand and first, because parsing YAML to discover the YAML parser is missing does not work.
- A peer node in another project may edit this working tree. `cdsync-cc` did so on 2026-07-29 while this session was live, so a `git status` taken mid-session is not a stable baseline. Re-verify before trusting measurements taken earlier in a session.
- mdagg strip + title-case are locale/BSD-sed sensitive -- see `intent/issues/CLOSED/0001`. Byte-safe rule of thumb: match multibyte literals with `grep -F` or an ERE alternation `(←|↑)`, never a `[←↑]` class (degrades to bytes under C locale); title-case with POSIX awk, not GNU sed `\b`/`\u` (no-ops on BSD sed).
- todo guard: utilz `item_re` parses intent's `- [x] STID: title` lines as items, so a `utilz todo sync` on an intent file would silently clobber it -- that cross-parse is why the guard (not merge) is the seam. The STAMP is unconditional; the REFUSAL fires only when intent is present. Where intent is absent, utilz must be fully silent and never fail.
- No Claude attribution in commits (project + global rule). Commits end with the `(C) hello@matthewsinclair.com` footer. 2-space indent, bash 3.2 compat.

## Decisions

- (2026-07-29) `-v` stays **unbound** on the `utilz` dispatcher. It reads as a verbose flag and no utility binds it, so binding it to `version` would foreclose the obvious future use. Pinned by a test asserting it still fails, so the next "while we're here" change has to argue with a test rather than quietly take the name.
- (2026-07-29) A set of small, independent, already-diagnosed defects may be driven by one issue each rather than a steel thread, even when fixed in a single commit -- extending the 0001/0002 precedent from one issue to a batch. The commit body carries the narrative; each issue carries its own root cause, evidence and resolution. Doc-before-code still holds for feature work.
- (2026-07-29) Whiteboard brought to the Lamplight / Baize standard: `hv` provisioned via `intent claude ws new hv` (Workstream Zero is present in every Intent project), plus a hand-authored `README.md` roster. Roster deliberately stays at two nodes -- Utilz is single-stream, and nodes are made to order, not in anticipation. An external correspondent (`cdsync-cc`) gets an inbox but no node directory, because it has no workstream here.
- (2026-07-29) A shipped defect fixed inside a steel thread still gets its own `intent/issues/` entry (0002 alongside ST0009/WP-03), following the 0001 precedent. The ST carries the work; the issue carries the defect record.
- (2026-07-29) Retroactive paperwork is the remediation for a doc-before-code violation when the code is already correct and verified -- not reverting it. Red-first is then proven retrospectively by running the new tests against `HEAD` in a scratch copy, and the retrospective verification is stated as such in `acceptance.md` rather than presented as genuine red-first.
- (2026-07-10) A tracked issue in `intent/issues/` may drive a focused bugfix without a full ST (hv-approved for issue 0001). Doc-before-code still holds for feature work.
- (2026-07-09) todo guard's Intent-project test is anchored on the **target file's directory** (walk up from `dirname($TODO_FILE)`), NOT cwd. Deliberate divergence from Intent's cwd-based `find_project_root`: the guard protects the file being overwritten, so `--file`-ing at another project's `intent/todo.md` from outside still refuses. Own/unmarked files short-circuit before the project test. (hv-confirmed.)
