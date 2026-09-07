---
node: cc
name: Control Claude
role: control
session_id: caa8cc75-2476-437c-b48f-569234f336f9
heartbeat_at: 2026-09-07 14:28Z
status: active
focus: "Pickup 7 Sep. Nothing of mine in flight. Actioned vc's 14:22Z report: the no-seventh-copy tripwire was false-red and is corrected; ST0010 claim dropped, the thread is vc's."
claims: []
---

# Control Claude (cc)

## DOING

**Nothing in flight.** ST0011 (`stampz`) closed 3 Sep at 11/11, CI run `33785732770` green on all seven jobs. Narrative archived to `.history/20260903/`; substance is in ST0011's Context and `intent/done.md`. **ST0010 is vc's** -- the stale `claims: [ST0010]` my header carried until this pickup is dropped, so the header and this text now agree.

## TODO

- **WP-04 is vc's**, on hoist-green. WP-05 (polish), WP-06 (AC15 theme addressing split), WP-07 (possibly un-deferred: two consumers now blocked by prez keeping its browser list and determinism probe private -- vc has it with hv).
- **`prez build examples/demo.md` warns `class 'escape' has no effect`** -- prez's own example ships a warning. vc's WP-05 note, deck content, not urgent.
- **`chrome()` announces the harmless outcome and stays silent on the one that launches a browser.** vc's finding, 2026-08-29, RE-STATED HERE so its inbox entry can be archived without losing it. The refusal path prints `note: PREZ_TEST_BROWSER=... is not executable, so no browser is offered`; the resolve path prints nothing at all. That is the same asymmetry as a skip carrying a false reason, sitting in the function AC18 was implemented in. Fix is one `printf ... >&2` mirroring the note already there. vc offered it either way; ST0010 is vc's thread, so coordinate before touching it.
- **`hoist-rebase.sh` carries one dead postcondition.** `post "test/acceptance.sh" "AT13: PASS" 0 ...` sets the minimum to ZERO and `post()` tests `-ge`, so it prints `ok` unconditionally -- including at a count of zero, which is the case it exists to catch. Redundant rather than a hole: two other checks cover AT13 and both go red. But it is the measures-nothing shape sitting inside the script that guards against silent loss. Fix is `0` -> `1` and a re-attach. **The hold reason is retired** -- vc confirmed the store is closed and `intent/.canon` is clean, so a re-attach writes into nobody's open transaction. Not done; no longer blocked.

## Watch-outs

**Measurement discipline -- the class this project keeps hitting.** Every one of these produced a green that meant nothing.

- **A check placed before the thing it measures passes for the wrong reason.** Two "the terminal stays clean" assertions sat above the loop that waits for the stub to run. The red-first run is what exposed it: the other three checks failed and these two did not, which is the tell.
- **A red-first probe that did not APPLY is not a red-first proof.** Three of mine patched the wrong function, changed nothing, and the test passed for the wrong reason. Assert the patch landed before trusting the red.
- **A grep-based check must target a string the artifact can only contain if the thing is really there** -- a sentinel, a library-internal symbol, a size gap. Never a token the deck might legitimately discuss. This class has bitten five times.
- **A source-grep check can match itself.** A test grepped its own file via `include_str!` and failed forever, because it contains the word it looks for. Assert on the ARTIFACT instead.
- **A test that only runs on a synthetic fixture is half a test.** Both AT17 probe defects surfaced the moment it was pointed at the shipped decks.
- **Never pipe a command whose exit code is the assertion.** `$?` is the last stage's. Bit me twice today and vc twice.

**This tree has THREE concurrent writers: me, `vc`, and `hv`.**

- Commit with an explicit pathspec, never `-A` over the whole tree. A `git status` from earlier in a session is not a stable baseline; remotes and `bin/devbin` have both moved mid-session.
- **`intent st attach` writes canon and regenerates views**, so it is not private when a peer has the store open. Check `git status -- intent/.canon` BEFORE attaching.
- **Run prettier yourself before committing markdown.** Otherwise the pre-commit hook is an unnamed third writer, and `git commit --only` leaves a phantom staged diff (`git restore --staged` clears it). `git add` + plain `git commit` avoids it entirely.
- A peer node in ANOTHER project may edit this tree; Cdsync's `cc` did on 2026-07-29.

- **The browser gate in the prez acceptance suite is an ENVIRONMENT VARIABLE, so its absence is invisible.** `utilz test` drives `acceptance.sh --strict`, and with `PREZ_TEST_BROWSER` unset `chrome()` probes, finds Chrome, and AT04/AT07/AT08/AT12 each launch it. The override does not survive a new shell, so the same command is browserless in one terminal and browser-driving in the next with nothing said either way. Every launch does carry `--use-mock-keychain` via `$CHROME_SAFE`, which is what keeps the Safe-Storage modal off hv's screen. If a run must be browserless, set the variable in that shell and check it landed.

**Shell and tooling.**

- **A `grep` whose SUCCESS is "no matches" kills a `set -euo pipefail` script** -- grep exits 1, pipefail propagates, and the script dies at the moment it succeeded, silently, after earlier steps wrote to disk. Guard with `{ grep ... || true; }`.
- **`utilz help <anything>` HANGS when stdin is a TTY** (glow's pager -- `mdagg` does it too). It bites `bats --filter` from a terminal and looks like the test hung. `< /dev/null` fixes it; `utilz test` and CI never see it.
- **`utilz test` is not safe to run concurrently** -- the helper mutates `$UTILZ_HOME/bin`. One suite at a time. `pgrep -fl bats` matches peer Claude sessions, not just real suites.
- Verify shell tooling under `/bin/bash` with an ARRAY. zsh does not word-split, so `shellcheck -x $FILES` errors on one bogus path and the empty output reads as a pass -- a false "all 15 clean" against 57 real findings.
- **A documented shellcheck form that RESTATES CI drifts from it, and the drift only shows on a built tree.** `restart.md` claimed to mirror CI and had dropped both the `file "$s" | grep -q "shell script"` sniff and `-not -name "devbin"`, so `-perm -u+x` swept `opt/prez/crate/target/` and shellcheck parsed **compiled Rust binaries** -- 57 "files", exit 1, parse errors on `build-script-build`. The real form collects **17 files and is clean**. Neither defect reproduces on a checkout that has never been built, which is how both survived. vc corrected `restart.md` to point AT the workflow rather than restate it; kept here because "restate the CI command in prose" is the shape, not that one file.
- Do not use `perl -0pi -e` where the text contains `$(` -- Perl interpolates it as GID and corrupts the file.

**Framework internals.**

- **`each_utility()` has SEVEN consumers, one of them in `bin/utilz`** -- six in `common.sh` (162, 445, 502, 733, 849, 907) and `bin/utilz:224`. **The check this board documented until 7 Sep was FALSE-RED and had been since July.** It read _"six consumers ... exactly two hits"_ on `grep -rn 'UTILZ_HOME"/bin/\*' ...`; issue 0004 folded `bin/utilz`'s open-coded copy into a consumer, so the correct tree has returned **ONE** hit ever since -- `common.sh:265`, inside `each_utility()` itself. A reader running the documented form today reads the one hit as a walker having gone missing and re-adds one, which is the exact duplication the tripwire exists to prevent. Reported by vc; re-measured here rather than taken on report. **The check that actually holds: `grep -c 'UTILZ_HOME"/bin/\*' opt/utilz/lib/common.sh` is 1 (the walker), and `grep -rn 'each_utility' bin/utilz opt/utilz/lib/common.sh` shows every consumer going through it.**
- `each_utility()` must be consumed with process substitution, never a pipe: `run_doctor` and `run_tests` accumulate into arrays and a pipe subshells the loop body.
- `require_yq` ONCE before a loop, never per-iteration -- `get_util_metadata` runs in command substitution and cannot memoise.
- `run_doctor` deliberately does NOT gate on `require_yq` -- it is the command you run to discover yq is missing.
- **`prez --version` and `--help` never reach the shim** -- the dispatcher answers from `prez.yaml`. A test meaning to exercise the binary must use a real verb.
- **`examples/demo.md` does NOT opt into mermaid** (its `mermaid: true` is documentation inside a fence). Point diagram checks at `test_pres.md`; demo.md is the labelled negative control.
- mdagg strip + title-case are locale/BSD-sed sensitive -- `intent/issues/CLOSED/0001`. Match multibyte literals with `grep -F` or an ERE alternation, never a character class.
- todo guard: utilz `item_re` parses intent's `- [x] STID: title` lines as items, so `utilz todo sync` on an intent file would clobber it. The STAMP is unconditional; the REFUSAL fires only when intent is present.
- No Claude attribution in commits, ever. Commits end with `(C) hello@matthewsinclair.com`. 2-space indent, bash 3.2, no em dashes, column-aligned tables.

## Decisions

Four entries migrated to `intent/restart.md` at the 3 Sep globalfold -- they are project conventions that bind anyone working here, and a copy on one node's board is the wrong home for them. What remains is cc-specific.

- (2026-07-29) `-v` stays **unbound** on the `utilz` dispatcher. It reads as a verbose flag and no utility binds it, so binding it to `version` would foreclose the obvious future use. Pinned by a test asserting it still fails, so the next "while we're here" change has to argue with a test rather than quietly take the name.
- (2026-07-29) Whiteboard brought to the Lamplight / Baize standard: `hv` provisioned via `intent claude ws new hv` (Workstream Zero is present in every Intent project), plus a hand-authored `README.md` roster. Roster deliberately stays at two nodes -- Utilz is single-stream, and nodes are made to order, not in anticipation. An external correspondent (`cdsync-cc`) gets an inbox but no node directory, because it has no workstream here.
- (2026-07-09) todo guard's Intent-project test is anchored on the **target file's directory** (walk up from `dirname($TODO_FILE)`), NOT cwd. Deliberate divergence from Intent's cwd-based `find_project_root`: the guard protects the file being overwritten, so `--file`-ing at another project's `intent/todo.md` from outside still refuses. Own/unmarked files short-circuit before the project test. (hv-confirmed.)
