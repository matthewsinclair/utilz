---
node: cc
name: Control Claude
role: control
session_id: 221775b1-d498-41c0-b937-4d10094711a8
heartbeat_at: 2026-09-08 07:15Z
status: active
focus: "ST0014 COMPLETE -- ALL SEVEN WPs DONE. vc holds the pen and I have followed both of their 8 Sep instructions in their order: the AC15 deletion (hv reversed honour-and-announce; the dispatcher now ignores an inherited UTILZ_HOME) then WP-13, utilz use dev|opt over relink with the manifest carrying source-tree. Both their 06:41Z findings actioned: AT07/AT08 labels, and install_manifest_check surfaced as doctor check 7 of 7. 183 core + 23 prez tests, 0 failures, doctor 0 findings. THE ESTATE IS A VERSION BEHIND: ~/Devel/opt/utilz is vc's 06:30Z publish with no use verb; one utilz upgrade from the source fixes it and that is hv's to run."
claims: [ST0014]
---

# Control Claude (cc)

## DOING

**ST0014 IS COMPLETE. ALL SEVEN WORK PACKAGES DONE. vc HOLDS THE PEN and both of their 8 Sep instructions are followed, in their order.**

| WP  | Commit    | Ships                                                                   |
| --- | --------- | ----------------------------------------------------------------------- |
| 01  | `aa6ed56` | the pure half: owned set, prefix reader, manifest write and check       |
| 02  | `5a15b81` | `utilz install`: five refusals, the announcement before them, the copy  |
| 04  | `cc155d4` | AC12 provenance, AC13 test refusal, AC09 prez shim                      |
| 03  | `c0b34c8` | `utilz upgrade`: reported, left alone, install-time row preserved       |
| 05  | `fec87d1` | AC01 end to end with the source removed                                 |
| 12  | `c01dcae` | `utilz relink`, and AC11's never-implicitly half                        |
| 13  | `c6088f8` | the AC15 DELETION, then `utilz use dev\|opt` over relink                |
|     | `f598a36` | `install.prefix: ~/Devel/opt/utilz`, its own commit so it reverts alone |

**183 core tests, 23 prez tests, 0 failures. shellcheck, critic and doctor all clean. All fifteen utilities dispatch. NO AT set by me -- AT07 and AT08 are green, set by vc against the artefact.**

**AC15 WAS REVERSED BY hv AND THE REVERSAL DELETED WORK RATHER THAN ADDING IT.** The dispatcher always derives from `$0` and ignores an inherited `UTILZ_HOME`. vc's diagnosis of their own error is the part worth keeping: their five-load-bearing-sites measurement was about the LIBRARY and was applied to the DISPATCHER, and the only divergent dispatcher invocations in the tree were the two tests of the announcement itself. Both deleted with the branch.

**TWO THINGS THE LIVE RUN FOUND THAT MY TESTS HAD NOT, both mine.**

- **Bare `utilz use` reported `(no install, so unknown)` against an install that exists** -- vc's 06:30Z publish, made before `source-tree` existed. Two facts with two remedies printing as one line. Three answers now, and a test after the fact because a test would have caught it.
- **AT01's grep began failing, correctly**, because the manifest now records the source path. The exemption is narrow, justified in the test, and asserts the row is really present so it cannot come to cover nothing.

**AND ONE SHARED-FIXTURE DEFECT OF MINE.** The AT15 legs wrote a marker VERSION into the file-scoped install, so doctor's new integrity check **failed in a full run and passed in isolation**. The fixture is read-only now and the invariant is stated in the file rather than left as etiquette.

**THE ESTATE IS A VERSION BEHIND AND THAT IS hv's TO FIX.** `~/Devel/opt/utilz` is vc's 06:30Z publish: no `use` verb, no `relink` fix, no `source-tree` row, old dispatcher. `~/.local/bin` serves it, so `utilz use` from a normal shell answers `Unknown command: use` -- measured, not assumed. One command from the source tree fixes all of it, and I have not run it:

```
~/Devel/prj/Utilz/bin/utilz upgrade
```

**Still open with vc, unanswered since 21:36Z yesterday: the AC09-versus-AC11 reading** (`cargo build` writes into the source tree's gitignored `target/`, outside the prefix). Stated in `design.md` D7. One function if they read it the other way.

## TODO

**Mine, unblocked, verified this session against the artefact.**

- **`hoist-rebase.sh` carries one dead postcondition.** Extracted from canon and read: line 205 is `post "test/acceptance.sh" "AT13: PASS" 0 "AT13 (presence only)"`, and `post()` at line 193 tests `-ge`, so it prints `ok` at any count including the zero it exists to catch. **Redundant rather than a hole** -- line 204 covers block presence at min 1, and lines 222-229 count AT13's eight individual checks -- but it is the measures-nothing shape sitting inside the script that guards against silent loss. Fix is `0` -> `1` and a re-attach. The hold reason is retired. **ST0010 CLOSED at 17:26 on 7 Sep, so the re-attach now writes a closed thread's canon** -- that is a different proposition from the one this item was written under and needs hv's call before anyone touches it. The defect itself is unchanged and still real.

**ST0010 CLOSED 7 Sep**, while this fold was being written (`f8c560f`). WP-04 and WP-07 Done; **WP-05 and WP-06 CANCELLED**. WP-06's work moved to **ST0013** (`prez theme addressing: split --theme, --theme-file and --theme-path`, Triage). **WP-05's did not move anywhere, and one of its two items now has no tracked home:**

- **Issue `0007` (slide-counter contrast below 4.5:1 on dark) is still OPEN** and survives the cancellation, because an issue is a legitimate home on its own (hv, 2026-07-10). Fine.
- **The `prez build examples/demo.md` warning `class 'escape' has no effect` is NOT an issue and was only ever carried by WP-05.** With WP-05 cancelled it is tracked nowhere -- prez's own example ships a warning and nothing now says so. **Either open an issue or accept it deliberately**; what it must not do is quietly leave the record in a cancellation.

**ST0012** (estate file policy) and **ST0013** are vc's, both Triage.

**Opportunistic, needs hv's call.**

- **Em dashes, re-measured 7 Sep rather than carried.** All tracked files: 34 files / 201 occurrences. Excluding canon, `.history/`, closed issues and the crate (which moves with the pin): **27 files / 110 occurrences**, worst `usage-rules.md` (24) and `help/syncz.md` (21). **THREE OF THE 27 MUST NOT BE TOUCHED**: `opt/macoz/images/backgrounds/autumn-0{1,3}.png` are binaries where the byte sequence is coincidental, and `opt/cleanz/data/trope-indicators.txt` is a cleanz DETECTOR LIST -- the em dash there is the thing the utility hunts, so rewriting it breaks the utility. A blind `sed` over the sweep is a defect, not a tidy.
- **The Emacs bridge ordering limitation has no tracked home.** `intent/wip.md` carries it as TODO citing issue 0009, but **0009 is CLOSED** having deliberately accepted the limitation (a loud refusal beats a silent write to the wrong file). wip.md proposes a third option the issue never weighed -- the elisp appending the path BEFORE extra flags, which would make both work. No open issue, no ST, so doc-before-code blocks it. hv opens an issue or cuts the item.

## Watch-outs

**Measurement discipline -- the class this project keeps hitting.** Every one of these produced a green that meant nothing.

- **A PATCH THAT DID NOT LAND, FOLLOWED BY A GREEN SUITE, READS EXACTLY LIKE A PATCH THAT WORKED.** 7 Sep, WP-01: a `perl -0pi -e` substitution meant to strengthen a test silently matched nothing -- the escaping was wrong -- and the suite then went 16 of 16 green, because the ORIGINAL test still passed. Nothing failed, nothing warned, and the strengthened assertion did not exist. Caught only by reading the file back. **The rule: after any in-place rewrite, grep for the NEW text and fail loudly if it is absent, before running anything.** Then prove the new assertion bites by injecting the regression it is meant to catch and watching it go red. For multi-line blocks, splice by line number rather than fight perl's escaping -- `head -n $((s-1))` + the new block + `tail -n +$((e+1))` is ugly and it cannot silently no-op.

- **A BLOCK YOU DID NOT MEASURE IS A CLAIM, AND I MADE ONE AND REPORTED IT UPWARD.** On 7 Sep I told hv I was blocked on vc for AC ids before writing `design.md`. I was not: the design carries HOW and cites rows, the contract carries WHAT, and every line I later wrote could have been written before a single AC existed. **I invented the dependency and then reported it as an external one.** vc offered the generous diagnosis -- my heartbeat was stale, so they had reported me unblocked on the strength of having WRITTEN rather than of my heartbeat moving -- and that rule of theirs is real and worth keeping, but it is not what happened here and they now record mine instead. **"my board was stale" is a fix that changes nothing**, because a fresher heartbeat cannot prevent a dependency that was invented rather than encountered. The check before saying blocked: name the artefact that is missing and what specifically cannot be written without it.

- **A check placed before the thing it measures passes for the wrong reason.** Two "the terminal stays clean" assertions sat above the loop that waits for the stub to run. The red-first run is what exposed it: the other three checks failed and these two did not, which is the tell.
- **A red-first probe that did not APPLY is not a red-first proof.** Three of mine patched the wrong function, changed nothing, and the test passed for the wrong reason. Assert the patch landed before trusting the red.
- **A grep-based check must target a string the artifact can only contain if the thing is really there** -- a sentinel, a library-internal symbol, a size gap. Never a token the deck might legitimately discuss. This class has bitten five times.
- **A source-grep check can match itself.** A test grepped its own file via `include_str!` and failed forever, because it contains the word it looks for. Assert on the ARTIFACT instead.
- **A test that only runs on a synthetic fixture is half a test.** Both AT17 probe defects surfaced the moment it was pointed at the shipped decks.
- **Never pipe a command whose exit code is the assertion.** `$?` is the last stage's. Bit me twice today and vc twice.

**The 7 Sep history rewrite, and the one setting that caused it.**

- **`main` WAS REWRITTEN AND FORCE-PUSHED TO BOTH REMOTES ON 7 SEP, hv-AUTHORISED.** Ten commits (all `devbin` re-vendors, 1-6 Sep) carried a `Claude-Session: https://claude.ai/code/...` trailer injected by the Claude Code harness, which is forbidden by the global rule, `CLAUDE.md` and hv's standing directive. Bounded to `11ed17b..HEAD`, 50 commits, **messages only** -- HEAD tree `da1a98f` before and after, 50 commits in range both sides, and every tag untouched because they all precede the base. `main` went `b99cda3` -> `1357612`.
- **THE KILL SWITCH IS `attribution.sessionUrl: false` IN `~/.claude/settings.json`, AND IT DEFAULTS TO TRUE.** It is a THIRD field beside `attribution.commit` and `attribution.pr`; setting a custom `commit` string does NOT suppress it, and neither does the deprecated `includeCoAuthoredBy`. Found by grepping the CLI binary's own schema: _"Whether to append the claude.ai session link to commits and PRs created from web or Remote Control sessions (default: true)."_ The ten that landed were all sweeps run through that path, which is why ordinary cc commits never carried one and nobody noticed for five days.
- **`backup/pre-scrub-20260907` and `refs/original/refs/heads/main` are the ONLY surviving copies of the old messages. DO NOT DELETE THEM without hv.** Both local-only.
- **`git cat-file -e` IS NOT THE TEST FOR WHETHER A SHA SURVIVED A REWRITE.** The old objects are still in the object database via those backup refs, so an existence check returns a FALSE GREEN for every orphaned hash -- it told me two dead SHAs were alive. The test is reachability: `git merge-base --is-ancestor <sha> main`.
- **THIS IS NOT WRITTEN DOWN IN THE PROJECT YET.** It belongs in `intent/restart.md` as a convention that binds anyone working here, and `restart.md` is a globalfold file -- vc's, not mine. Flagged to hv at EOD; a copy on this board is the wrong permanent home for it.

**The commit gate, and the tooling that rewrites it (all measured 7 Sep).**

- **THE PRE-COMMIT GATE IS NOW EXEC-LIVE, NOT A FROZEN COPY, AND THERE IS A PROVENANCE PROBE.** hv ran `intent claude upgrade --apply`; `.git/hooks/pre-commit.intent` went **20899 -> 7332 bytes** and is now `pre-commit-shim.sh` byte-identical. It holds no gate logic and `exec`s `$INTENT_HOME/lib/templates/hooks/pre-commit.sh` live, so the gate can no longer go stale. **`.git/hooks/pre-commit.intent --where`** prints pointer, root and the resolved gate path -- reach for it before ever asking which copy is running again. Verified by running the gate read-only: `guards: 4 ran, 0 skipped` and `critic gate: 2 of 2 declared language(s) enforced (shell rust)`. Roster (in the install, not the carrier): both whiteboard guards, `canon-ignore-guard`, `append-only-guard`.
- **The advisory that led here was TRUE AND DID NOT MEAN WHAT IT LOOKED LIKE.** `intent doctor -v` reported the carrier stale by 16719 bytes; the obvious inference -- "so this repo runs August's guards" -- was wrong, because the carrier held no roster and delegated to the install. Chased it to the artefact rather than acting on the headline. **Doctor said so itself** (`not counted in the verdict`), which is the part worth keeping: an advisory is a finding someone already decided you do not owe anything for.
- **`intent claude upgrade --apply` REWRITES `CLAUDE.md`, and in v3 there is NO FLAG TO DECLINE `.claude/settings.json`.** v2's `--skip-settings` was not carried; the verb's flags are `--apply` and `--force`. The 7 Sep run rewrote `CLAUDE.md` (+14/-3) and reversed its standing position on the four principles -- they are now restated in `CLAUDE.md` rather than pointed at, because `AGENTS.md` is the one file the Claude Code agent never receives. **The new text asserts a byte-identity drift test and the claim holds here**: `CLAUDE.md:32-35` and `AGENTS.md:101-104` are byte-identical, and the upgrade did not touch `AGENTS.md`. Verify it again after any future run rather than assume it.
- **`intent/issues/{OPEN,CLOSED}/` on disk is a STALE RENDERING of canon.** Canon holds 9 issues; `OPEN/` is empty and `CLOSED/` holds only 0001-0006, while `intent issues show 0008`/`0009` both answer CLOSED. `intent doctor` counts canon and reports no skew, so nothing flags it. **Read issues with `intent issues list`, never with `ls`** -- the directory says zero open when 0007 is open.

**This tree has THREE concurrent writers: me, `vc`, and `hv`.** **On 7 Sep all three were visibly modifying it at once** -- vc landing AT20 (`crate/test/acceptance.sh` + an untracked `at20-window-probe.mjs`), hv re-vendoring `bin/devbin` and `bin/.devbin/**`, and my own board. A `git add -A` from any of us sweeps the other two into the commit.

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
