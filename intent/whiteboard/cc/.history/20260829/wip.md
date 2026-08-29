# cc -- archived 2026-08-29

Session narratives lifted out of the live board at the ST0010 localfold.
They are settled history; the live board keeps only DOING, TODO, Watch-outs
and Decisions, because it is read on every pickup.

## Last session (2026-07-10)

Fixed mdagg issue-0001 (silent Unicode drop under C locale) + both follow-ups; added the `intent/issues/` tracker; added `expz` to CI; reconciled the stale tracking docs; cut and pushed release **v2.3.0** (todo utility + mdagg fix). Five commits + tag `v2.3.0` on both remotes. Full detail archived in `.history/20260710/wip.md`.

## This session (2026-07-29)

Picked up an uncommitted, ST-less refactor of `opt/utilz/lib/common.sh` left in the working tree. Triaged it as an orphan and blocked on hv rather than adopting or reverting it; `cdsync-cc` (the `cc` node of the **Cdsync** project, `../Cdsync`) then claimed provenance via `inbox.cdsync-cc.md` -- it had edited this tree from outside the project, hv-instructed, while this session was live and unaware. hv ruled: proceed and fix.

Landed as **ST0009** (WP-01 walker / WP-02 yq / WP-03 generator floor) plus **issue 0002**, and released as **v2.4.0**. The code was already green; the missing work was coverage. 12 new tests in `common_lib.bats`, verified red-first retrospectively against `HEAD` in a scratch copy -- 11 of 12 fail against the pre-change code. Also reconciled `docs/architecture.md`, `help/utilz.md`, `README.md`.

Then, at hv's request, a repo-wide ULTRATHINK audit of every utility -- "are there other dumb things in there I have missed?". Yes: **57 shellcheck findings including 3 hard errors, now 0**, plus four real defects that no tool found (they came out of reading): `clipz` copy/paste silently no-op'd and reported success (`local x=$(cmd) || exit 1` never fires -- `local` returns its own status, and an empty command with a redirect runs nothing and exits 0); `syncz execute_delete` printed "Delete complete" unconditionally after `rsync || true`, twelve lines from an `execute_sync` that already had the correct 0/23/else convention; `mdagg` carried a `--version` fallback that was unreachable, would have died on a top-level `local` if reached, and hardcoded a stale `v1.0.0`; `cleanz`'s trope detector collapsed grep exit 2 (invalid regex) into "no match", so a broken pattern silently stopped detecting. One structural gap too: CI's shellcheck step never saw `common.sh` (0644, and the step only collected executables) and was `|| echo "(non-blocking)"` -- it could not fail the build. Both fixed; the gate is blocking and was sequenced last so it never reddened CI. `ensure_venv()` extracted from pdf2md+xtrct (Highlander). Four commits: `cf45371`, `1cb66b2`, `0566bcc`, `ad6402d`. Suite 395 passing / 0 failures.

Closed with a health check hv asked for directly -- "is Utilz good?" -- run as measurement rather than recital: suite, the exact CI shellcheck collector, the shell critic, a bash 3.2 parse sweep, `gh run view` on the last push, doctor, `intent doctor`. All green, but reading the dispatcher on the way through turned up **three more defects**, filed and closed as issues **0003-0005** in `fe8eecf`. 0003: `utilz --version|--help|-h` all exited 1 with "Unknown command" while every utility and both nested verbs accepted the flag forms. 0004: the unknown-command "Installed utilities" list was a **sixth** open-coded `bin/*` walk that ST0009/WP-01 missed, carrying the exact `-L`-only drift ST0009 existed to remove (that sweep grepped `common.sh`; this copy lives in `bin/utilz`). 0005: doctor check 4 was `echo "$PATH" | grep -q "$UTILZ_HOME/bin"` -- one expression, two faults, rejecting a working symlink install and passing on any substring. 12 new tests, 6 genuinely red first. 407 passing (was 395).

Two claims in cdsync-cc's report were checked rather than taken at face value: its bash 3.2 belief (**correct** -- now verified under `/bin/bash 3.2.57`, it had explicitly flagged this as unverified) and its `opt/todo/todo.yaml` "fossil of a hand-fix" evidence (**wrong** -- `todo.yaml` was born `^2.0.0` in `03ccded` and all 13 utilities carry `^2.0.0`; the defect is purely latent and never bit this repo). Issue 0002 records the withdrawal.

---

## Afternoon: ST0010 WP-02/WP-03 closed, then hv's runtime

**WP-02** (`0ebfa85`) put Rust under the framework: the `opt/*/crate/target/` gitignore fence landed before any in-tree build could run, `intent lang init rust`, two CI jobs (rust matrix + blocking clippy), the three-source test driver in `common.sh`, and doctor's conditional cargo line. `95b650a` fixed CI red on `main` -- `05bca08 Installed devbin` had pointed the blocking shellcheck gate at 33 vendored files, all SC1091, none Utilz-owned.

**WP-03** hoisted the crate (`64d375b`) at pin `3e16597` via `git archive`, renamed `geopres`->`prez` atomically across 19 files, and added the shim. Then `8a53457` AC14 announce-on-resolve, `93702cb` AT13 + the AC18(b) `PREZ_TEST_BROWSER` override, `844f1aa` help/README/23 shim BATS.

**The load-bearing discovery of the day**: AC14 lives only in Utilz by vc's own design, so the crate stopped being a mirror of the pin. The board's standing instruction -- "re-archive, do not patch forward" -- would have silently eaten AC14, AT13 and the AC18(b) hook, with the build still green and the suite still passing, because the tests proving them would have gone in the same stroke. Built `hoist-rebase.sh` (archive both pins, adapt both, `git merge-file` with the old pin as common ancestor), pushed back on vc's re-archive ruling, and they adopted it. The pin landed as a merge at `673e4db` -- upstream touched exactly one file, `test/acceptance.sh`, which is the file carrying both Utilz additions. Zero conflicts.

Three findings building it, all from running rather than reading: `git apply --3way` is useless on a `diff -ruN` patch (no blob hashes) and its atomicity turns one bad hunk into a silent no-op; `-p2` was one component too many; adapting must precede diffing or the delta is 110 occurrences of rename noise.

**Issue 0006** (`406af49` + vc's `d39422e`): adding any 14th utility reddened the suite whichever way it declared. `bridge.bats` asserted exactly 13 integration rows while `emacs doctor` failed on a utility without a block -- no value of `prez.yaml` satisfied both. Both halves fixed, 0006 CLOSED. 0007 was drafted for the doctor half and withdrawn: vc's fix cited 0006 and hv ruled there.

**hv's runtime**, over four commits. `4ed491e` the key bar (`?`/`h`), `q`/`i`/`r`/`g`, esc closing instead of toggling the index. `c3307c5` enter/space committing the highlighted slide in the index, plus AT17's browserless logic probe. `f5253a9` AC19 (window geometry, `--start-fullscreen` removed as demonstrably inert) and AC20 (close shortcut resolved at view time). `5de4b0e` the presenting output -- Chrome's chatter discarded, the line naming the deck instead of a temp path.

Two real defects surfaced underneath that work. `assemble()` chained four `.replace()` calls, so `{{style}}` went in first and the next call expanded placeholders inside the stylesheet it had just injected -- a theme author documenting `{{slides}}` in a comment would have shipped every slide twice inside their own CSS. And the shim hardcoded its binary path while cargo honoured `CARGO_TARGET_DIR`, so isolation was accepted and ignored: an empty target dir stayed empty while the build "succeeded" off the warm binary.

**Corrections made and received.** I told vc I had committed their in-flight canon; they had committed it themselves three minutes earlier, and I corrected the inbox. The clock guard refused a commit where I typed a heartbeat from memory rather than reading `date -u`. vc retracted a symlink-shadowing report, a "pin is stalled" report and a re-archive ruling; I verified each rather than taking it, which is how the pin turned out to exist.

**Nothing launched a browser all day.** AC18(c)'s keychain dialog reached hv's screen in the morning and the fix was still in the pin; after it landed, "no dialog appeared on someone else's screen" remained unobservable from a shell. AT04, AT18's browser half, the eleven skipped acceptance checks and the AC17 cold build are all queued behind one authorisation from hv.
