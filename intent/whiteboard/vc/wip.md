---
node: vc
name: Validation Claude
role: validation
session_id: 11981560-5612-4fe7-a136-6eae64636b64
heartbeat_at: 2026-09-09 17:12Z
status: active
focus: "ST0017: 35/51 satisfied, 3 withdrawn, doctor 0. AC-1.2 and AC-2.16 both closed this turn -- prez costs 17 third-party packages before WP-01 and 17 now, and the harness now CONSULTS a predicted-difference table rather than discovering a port change as a parity failure. snorkeltoast found AC-2.16 asserting a falsehood: the max_ease cap CLAMPS, it does not refuse. WP-03s build path is the only thing between here and hvs bar."
claims: [ST0017]
---

# Validation Claude (vc)

Validation node. cc builds, vc contracts and verifies, hv adjudicates. Full boards for 8 Sep in `.history/20260908/`, for 9 Sep in `.history/20260909/` (`wip-before-localfold-2.md` is the 30389-byte pre-fold original). **This board keeps ONE statement of each rule with the instance that earned it, not the day's narrative** -- and after hv's scope call, only rules that change what gets BUILT.

## DOING

**ST0017 -- showreel hoisted under `utilz prez showreel`. vc holds the contract, cc builds, snorkeltoast has closed.**
Localfolded 2026-09-09 16:51Z. Full boards for 8 Sep and earlier folds of 9 Sep in `.history/`.

- **Contract: 35 of 51 satisfied, 3 withdrawn, `intent doctor` 0.** `intent ac list ST0017` is the live contract;
  `design.md` carries the reasoning. **Ids are `AC-<wp>.<seq>` and the group digit IS the work package.**
- **WP-01 13/15. WP-02 14/17. WP-03 6/12. WP-04 0/2. WP-05 1/3. WP-06 1/2.**
- **`utilz prez showreel check <dir>` RUNS end to end**, both invocation forms, exit 0 against the live 45h reel.
  **WP-05's dispatch is done; WP-03's build path is the only thing between here and hv's bar** -- hv killed the
  Python shim fallback, so there is no relief valve.

## TODO

- **Mine and unblocked: AC-1.15**, and it is the hardest row left on my desk because it BINDS -- every red-proof in
  this thread must prove its injection applied before its result is read. **It cannot be discharged by restating the
  rule**, which is the one thing prose is guaranteed to do well. It needs the thread's red-proofs ENUMERATED and each
  checked, with the population stated and the failures named. Three instances are already on the record and one of
  them is mine.
- **Verify cc's build-path slices as they land.** The built-ins pull landed at `bbca403` plus an untracked
  `crates/showreel/themes/`; next is font + favicon emission, then admission, normalisation, `collect_segment`.
- **Waiting on WP-03 by construction:** AC-2.1's leg 2 (adjacency stops being a guess when the Rust build stamps its
  own identity) and AC-2.4. **AC-2.12 stands as a recorded limit, not work.**
- **Two harness entries flip from `designed` to `observed`** the moment cc's build path calls the theme loader --
  the missing-favicon refusal and the `.ttf` refusal. Nothing to do until then; noted so their silence is not read
  later as coverage.

## Holds

- **None.**

## Open with hv

- **Nothing.** Four rulings taken today and closed; the day's four are in `.history/20260909/`.

## Claims

- **ST0017** -- the contract. cc also claims it. Not a conflict: claim-by-ST cannot express "vc validates, cc builds".

## Live with other nodes

- **`cc`: ACTIVE on WP-03's build path.** Dispatch and R3 landed; design.md section 5 decides three dispositions
  before the code -- `load_theme`'s regex REPLACED not ported, a missing declared favicon REFUSED where the reference
  warned, a `.ttf` refused by name with the conversion command. **Their board carries the gate list this estate runs.**
- **`snorkeltoast`: REOPENED and built AC-2.16's expectation half at `03a44ce`** -- `PORT_EXPECTATIONS`, five
  entries, three KINDS, consulted by `compare` BEFORE the structure check and not only by the new `expect` verb.
  **They corrected the row while building it**: the row called the max_ease cap a refusal and the cap CLAMPS.
  `FLOORS.md` at `daaa503ad7db` remains the parity baseline and is FINAL -- `cmd_control` takes only the artifact,
  so cc's next build does not supersede it, it produces a different artifact needing its own run.
- **`intent-vc` / `devbin-vc` / `lamplight-vc`:** consulted on the AC id form and on TN001. Each corrected a premise.

## Watch-outs

**MY OWN INSTRUMENT FAILED FOUR TIMES TODAY AND EVERY FAILURE PRODUCED A PLAUSIBLE FINDING ABOUT A PEER'S WORK.**
Not one was caught by suspicion; each was caught by running the query that would NAME the thing rather than argue for
it. **(1) A blank line.** `cargo tree --workspace --prefix none` separates member trees, the filter kept it, `wc -l`
counted it as a package -- cc's union looked like an arithmetic sum, the exact error under discussion. Caught because
an empty symmetric difference alongside differing counts is arithmetically impossible. **(2) A commit timestamp read
as a file time.** Binary at 17:11, cc's fix commit at 17:17, so the binary looked stale and their new freshness walk
looked broken -- the SOURCE was written at 17:10:21 and they built during gates before committing. **A commit
timestamp is when the commit was made, not when the source was written.** **(3) A shared instrument.** cc measured 47
/ 42 / 11 literal `**` in help output and vc reproduced 47 / 42 / 11 EXACTLY; both had piped stdout, and glow's
`notty` style has no bold. **EXACT agreement is a stronger trap than near-agreement -- one-apart makes you look,
byte-equal makes you stop.** Ask what two measurements SHARE before treating either as confirming the other. **(4) A
test that could not run.** `script -q /dev/null` failed with `tcgetattr/ioctl: Operation not supported on socket`,
captured 59 bytes of error, and `grep -c` scored it **0** -- one step from _the defect does not appear at a terminal_.
**A census zero over an empty population reads exactly like a detector zero over a full one**; the line count is what
gave it away, since one line of output for a 427-line help file is not a result. **When the environment cannot host
the test, change the instrument rather than trusting its zero.**

**THE NODE THAT HOLDS THE CONTRACT CAN MAKE ONE CLAIM NO BUILDER CAN, AND IT IS ORDERING.** snorkeltoast's
predicted-difference table asserts in its own header that the prediction existed FIRST -- and from inside their tree
that is an assertion, because their file cannot see when this contract decided anything. **From here it is arithmetic
on commit times**: the disposition led the code by 1h50m and 2h24m on two entries, and on three more the code does
not exist at all. **Their two `observed` rows cite the CODE as their source and not the disposition, so the table's
central claim is checkable from git and not from the table** -- raised with them, one field. The general form: when a
peer builds the instrument, ask what its own evidence CANNOT reach, and supply that rather than re-running theirs.
**And a peer correcting a row of mine is worth more than a peer agreeing with it** -- snorkeltoast read AC-2.16,
found it asserting that a CLAMP refuses, and the row had been on the contract all day with two nodes reading it.

**A ROW NAMING TWO HALVES IS NOT SATISFIED BY VERIFYING ONE OF THEM THOROUGHLY, AND THOROUGHNESS INSIDE THE WRONG
POPULATION FEELS EXACTLY LIKE COMPLETENESS.** AC-3.5 says it implements R2 **and R3**. vc verified R2's three surfaces
at the artifact in four arms with a control and out-of-band exit codes, and never asked what R3 was; it was marked
satisfied for an hour. **The answer was written down in two places before the error was made** -- the row already
carried vc's own sentence _the surfaces are the instances and not the criterion_, and design.md already stated that a
half-built row stays unsatisfied. Caught only because cc mentioned R3 in passing about a row vc had closed.

**WHEN A VERB ONLY REPLACES, COMPOSE THE NEW WHOLE AND PASS IT.** `intent issues edit --body` replaces, and wanting to
APPEND is what sent vc to hand-edit canon JSON directly, minutes after using the verb correctly. Doctor caught it in
one command (`residue: model-inconsistent`); the repair was to read canon and re-issue the whole body THROUGH the verb
rather than run a destructive `sync --to-store`. **Do not reach around a verb because the shape of your edit is
incremental.**

**A ZERO HAS THREE KINDS AND THE THIRD READS EXACTLY LIKE THE FIRST TWO.** CENSUS -- nothing was there to count; sound, nothing to prove. DETECTOR -- nothing fired; sound **only if it could have fired**. TAUTOLOGY -- the branch was never reached; **worth nothing**, and it passes a per-detector history check because the detector HAS fired, in other runs. **Reachability is a property of the RUN.** Instances: FLOORS.md's `0 undecided` (unreachable once a magnitude is named); vc's `bare line NNN: none` (detector written in the command that ran after the fix -- red-proved retroactively, and it held).

**PUT THE CAVEAT WHERE THE NUMBER IS PRODUCED, NOT WHERE IT IS REPORTED.** snorkeltoast's, and it is the only answer to a caveat and a number travelling at different speeds. **A document can be quoted without its caveat; the instrument's own output cannot.**

**A NARROWED VIEW AGREEING WITH ITSELF.** An explicit pathspec drops your own work while the tree stays consistent; a scoped `git status --short <dir>` reports clean while the REPOSITORY is not. **The failure is in neither command: it is asking a question whose scope already excludes the answer.** Covering discipline: stage explicitly, then read the WHOLE tree and expect it clean. Also: **a population drawn from the disk answers for the disk -- the code's population is its CALL SITES.**

**THE RULE WAS ALWAYS PRESENT; THE PROMPT TO APPLY IT WAS NOT.** Counted over vc's twenty corrections today: **9 caught by a peer, 10 by an instrument vc ran on its own work, 1 by rereading** -- and that one was prompted by writing it down for someone else. Both nodes carried `IN-AG-RED-CONTROL-001` all day, both filed under injections, and neither pointed it at a NEGATIVE until the other did. **Peers prompt a look, instruments make it conclusive, rereading does neither.**

**ASK WHICH DIRECTION THE ERROR RUNS, AND BUILD THE CASE THAT ATTACKS THE ANSWER YOU EXPECT.** Five cases all said the CSS-grammar mismatch over-refuses; the sixth, built to break the hypothesis, found a live href shipping out of `layout.html` (issue 0018). **The cheap discipline is not more samples; it is one sample designed to lose.** Its pair: a wrong mechanism fails either on **a sign it could not produce** (checkable alone, in one line) or on **a correlation it did not own** (not checkable without running something), and **an explanation that fits suppresses the test that would separate it from the true one.**

**A STRUCTURAL MODEL PREDICTS THE CASE IT WAS NOT BUILT ON; UNTIL THEN IT IS A DESCRIPTION WEARING A MECHANISM'S CLOTHES.** AC-2.3 said "two endpoints rounding independently", which predicts FOUR states -- and both nodes read it as an explanation of the two it was written from for six hours, with `predicted D=(1,0)` on the page. **An unread prediction, not a missing one**, same as the stale `:613` across three sessions. **And an exact re-derivation is neither measurement nor prediction: it is the most dangerous of the three because it is CORRECT.**

**A POPULATION IS THE CLAIM, NOT A DETAIL OF IT.** Six ways it went wrong in one day: TOO WIDE fails loudly (36 tools in `~/.local/bin` when 15 are ours, 42 spurious failures, one minute); TOO NARROW fails greenly and ships (a control over 16 of 33 files); SELF-MATCHING fails silently and forever (`pgrep -f 'utilz test'` matching the waiter -- fix is `utilz[ ]test`); PATTERN-MATCHES-PROSE has no bound at all (`bats ` hit another project's SYSTEM PROMPT; `escape` matched a CSS comment; `session` matched ordinary commit text); DEFINED BY AUTHORSHIP misses other writers' commits; and FIXED AT INVOCATION measures a tree that moved (`bats ./*.bats` expands once -- eleven new tests silently excluded, total unchanged at 554, byte-identical to "they ran and added nothing").

**A COUNT CONTROL AND A SUM CONTROL CATCH DIFFERENT FAILURES, ONE SUBTRACTION APART.** A sweep prints its population and refuses at ZERO -- catches an empty population, where "no matches" and "no problems" are the same output. A partition prints its REMAINDER and refuses when the parts do not sum -- catches a wrongly decomposed one. Only the second caught my four categories summing to 66 against my own stated total of 74. **A partition that does not sum to its own total is self-refuting before anyone else looks at it.**

**AN ABSENCE ASSERTION NEEDS A PRESENCE ASSERTION OVER THE SAME POPULATION, OR IT IS A SUBSET CHECK WEARING THE COSTUME OF THE FIX.** Deleting every line satisfies an assert-absence exactly as well as fixing it does. Pairing them is necessary and NOT sufficient: the pair must consume ONE population, computed once.

**PROVE IT RED AGAINST THE REAL DEFECT, AND GATE THE PROOF ON THE DEFECT BEING PRESENT.** A green never observed to fail is `IN-AG-RED-CONTROL-001`. Best fixtures cost nothing: a stale published install red-proved AT09 at 28 failures; the pre-fix deck red-proved AT03's capture at 165 bytes. **My first injection silently did not apply** -- the anchor occurred twice, once inside a fenced example -- and I ran the suite anyway and read the resulting green as a result. Only the rewrite's own `count == 1` refusal caught it.

**A CHECK THAT READS A SOURCE WHICH HAS STOPPED CHANGING KEEPS RETURNING THE RIGHT ANSWER LONG AFTER THE CHECK ITSELF HAS DIED.** cc's hung suite watcher printed `ok=554 notok=0`, matching its log exactly, and cited that as proof of completion. It had been sleeping 21 minutes past the suite's end; the harness timed it out and the write flushed on termination. **A hung monitor and a working monitor emit byte-identical output.** Read the timestamp, not just the value.

**THE INSTRUMENT IS PART OF THE CLAIM, AND A CLEAN ZERO IS THE COMMONEST LIE.** `git grep -E` does not honour `\b` and matches nothing rather than saying so (0 vs 2 vs 2 on one file). `bash -n` cannot parse a `.bats` file and blamed a pre-existing line for my new code. `mapfile` is bash 4 against a 3.2.57 `/bin/bash`. Manifest paths are repo-root-relative -- I hashed **zero** files from the wrong cwd and reported `mismatches=0`, twice, months apart. **A zero from something you did not mean to invoke is the reading your own authorship makes you LEAST likely to question.** And it is not only zeros: on 8 Sep a sandbox check of a generated README came back correct because I ran it from INSIDE the sandbox, so the relative path I was testing resolved against cwd. The full estate caught what the check could not -- the real caller runs from anywhere, and generation failed outright. **A path check run from a convenient cwd measures the cwd.**

**THE ARTIFACT OUTRANKS THE SOURCE; THE SOURCE ONLY FEELS AUTHORITATIVE BECAUSE IT IS CAUSAL.** cc reasoned about a 1226-line log from one line of its source and concluded two suites were indistinguishable; line 811 prints the script path and the log carried both. Where an artifact exists, read the artifact.

**A STALE BINDING IS WORSE THAN A STALE VALUE, AND ITS TELL IS TWO CORRECT SENTENCES THAT CONTRADICT EACH OTHER.** "Your last write", "the latest", "current HEAD", "now" all resolve at READ time. cc and I each staled our own unpushed figure with our own commit, minutes apart, while discussing staleness. **Quote the command, not the number -- and where you must quote a number about a thing you are also changing, measure AFTER your last write. Otherwise you are the decay.**

**NEAR-AGREEMENT SUPPRESSES THE CHECK THAT DISAGREEMENT WOULD FORCE, AND IT TAKES BOTH PARTIES.** Twice today. Two counts one apart (45 vs 44) made a false reconciliation feel obvious; the truth was 78 and 1-of-16. And on the `glow` hang: mine "the pager breaks scripts", cc's "the pager is inert because stdout redirects" -- **both wrong about the pager, with the real defect (stdin) underneath the thing we were both arguing about.** We would have shipped agreeing.

**WHEN TWO NODES VERIFY ONE CHANGE, AGREEING ON THE INSTRUMENT WASTES ONE OF THEM.** Pick the claim the other did not make. cc verified every utility ANSWERS a version; I verified the answer EQUALS the bytes of its single home. Two numbers agreeing by luck pass the first and fail the second.

**KNOWING A RULE IS MEASURABLY NOT THE SAME AS BEING PROTECTED BY IT, SO THE GUARD BELONGS IN THE CODE.** Four instances in one day, each committed by someone who had written the rule down. **Where knowing demonstrably does not prevent the error, build the guard into the output** -- cc printed a local-time column under a literal `DO-NOT-TRUST` header rather than trusting themselves to recall which column was which.

**AN ASSERTION WEAK ENOUGH TO BE SATISFIED BY PROSE SPLITS A UNIFORM CHANGE INTO RED AND GREEN FOR UNRELATED REASONS.** Ten bats tests asserted the bare letter `"v"`; a change that rewrote every one of those lines turned only five red, because `stampz` and `lnrel` have a v in "every" and "relative". Where the SHAPE of a message is the requirement, the row must say the shape -- a substring check cannot see a malformed string that contains the substring.

**A ROW MAY BE CORRECTED TO ITS INTENT; IT MAY NEVER BE WEAKENED TO FIT AN IMPLEMENTATION.** The test is whether the intent held BEFORE the edit. AC07 said "redirect on every renderer arm"; three arms exist and `cat FILE` provably cannot block (exit 0 immediately vs exit 124 for bare `cat`), so the letter demanded a token that protects nothing and teaches a false lesson. Reworded to the property, exemption stated as measured.

**PROSE DOES NOT FAIL, SO A JUDGEMENT WORTH KEEPING NEEDS A ROW.** cc's D4 -- ST0016 keeps the `--help` arms that ST0015 deleted -- lived only in a design document. Two adjacent threads are exactly what a later reader flattens into one pattern. AC06 made the restraint enforceable.

**A CI LEG YOUR PLATFORM CANNOT REACH IS A BRANCH YOU HAVE NOT TESTED.** `macoz` guards on `uname != Darwin` before its arg loop, so `macoz --help` has never worked on Linux; my AC06 asserted platform-independent behaviour of a platform-specific utility. **Then my fix for that introduced the second failure**: an assignment from a command substitution takes that command's status, and under `set -e` it aborts THAT LINE before any `rc=$?` -- `|| rc=$?` is the fix. I had noted the branch was untested and pushed anyway. **A control over the pattern is not a control over the code path that uses it.**

**A REAL FINDING IS NOT AUTOMATICALLY YOUR FINDING, AND A FLAKE IS NOT A REGRESSION.** Before re-running a red CI job I checked: the Rust leg had passed in the three previous runs, and the commit touched one bats file that leg never reads. Re-run: green, same commit. **Establish that a failure is caused by your change before treating it as one, and that it is not before dismissing it.**

**THE ESTATE, MEASURED TODAY.** `utilz` on PATH is whichever tree `utilz use` last pointed at -- **run the command, never carry the answer**; the provenance line exists so that costs one command, and it earned itself twice. `utilz test` is not concurrency-safe. **`show_help` closes the renderer's stdin now**: a bare `glow FILE` with a terminal on stdin hangs (exit 124 under `timeout 5`, once killed at 120s), and it is NOT the pager -- `-p` is opt-in and it hangs without it. The hang was never reproduced under a `script`-allocated pty, so the guard is asserted PRESENT rather than the hang claimed fixed. **A part-compiled tool's `--version` answers for one half and is confidently wrong about the other**: `intent --version` reported a commit predating a fix that was live, because that path is a shell script read from source. Ask the behaviour.

**INTENT'S OWN VERBS, LEARNED THE EXPENSIVE WAY.** `intent st hydrate <ID>` adds a thread to `.intentfiles` and writes its files; `st dehydrate` is its inverse; **`st attach <ID> <path> --from <file>` puts an AUTHORED doc into the store, and until you do, `organize` reports it `unclaimed` and can never remove it -- which is why a closed thread's directory survives every dehydration.** `organize --apply` is a whole-tree reconcile that REMOVES; never point it at a tree whose declaration is unsettled. `intent edit st <ID> --path` writes a declaration as a SIDE EFFECT of printing a path. `sync --to-disk` syncs the store with the canon extract and does NOT regenerate views. **`intent/.cache/` is gitignored -- an attachment living only there is lost on a fresh clone; verify it reached `intent/.canon/` before deleting any file it claims to hold.**

## Decisions that still decide things

- (2026-09-09) **hv: NO PYTHON SHIM FALLBACK. "We're only doing work that moves this FORWARD and Python is a backwards
  step."** HOIST section 1's fallback -- a dispatcher over the reference implementation, measured by snorkeltoast at
  hours to hv's literal bar -- is DEAD. **The only path is WP-03's build half plus WP-05's dispatch, in Rust.** There
  is no relief valve, so WP-03's build half is load-bearing for the bar rather than merely next.
  **THE CONTRACT NEEDED NO CHANGE AND THAT WAS CHECKED, NOT ASSUMED**: seven rows mention Python or a fallback and all
  seven are incidental -- `python3 -c` as a red-proof mechanism, the 4000ms capture default, the `|| "Snorkeltoast"`
  template literal, HOIST.md provenance. **The one substantive mention is AC-2.16, where Python is the REFERENCE
  BEING PORTED FROM**, which hv's ruling strengthens rather than touches: a reference is a thing you port from, never
  a thing you ship.

- (2026-09-09) **hv: issue 0018's narrowing goes ahead -- the comment exemption becomes CSS-only.** The fix is
  DELETION, in code cc is already editing for AC-3.13, so it is not a special trip. **Per-surface JS and HTML comment
  grammars stay deferred to a population that does not exist** -- nine `theme.css` in the estate, no `theme.js` or
  `layout.html` at all.
- (2026-09-09) **hv: issue 0016 is a WP-05 rider, RECORD-ONLY.** `manifest.sha256` is already inside WP-05's scope.
  **The test that separates it from 0019, and it is the one to carry:** 0019's information already existed --
  `git show --stat` names every file in every commit -- so the guard would have been a second, worse copy. 0016's
  information exists NOWHERE: the manifest carries no gate state, `utilz test` refuses from an install, and every
  bats suite pins `UTILZ_HOME`, so nothing in the estate can tell a verified publish from a lucky one.
- (2026-09-09) **hv: issue 0007 CLOSED ON PRIORITY, NOT ON THE MERITS, and the policy question is DEFERRED rather
  than answered.** _Does 4.5:1 apply to `aria-hidden` decorative chrome_ has no answer on the record. Implementing a
  fix would have settled it silently in code; **closing it as "vc recommended no" would settle it just as silently in
  the other direction**, and hv ruled on neither. Reinstate condition is hv's and checkable: **someone asks, once
  showreel is published and available in utilz.**

- (2026-09-09) **hv: a dehydration made by side effect STANDS when the end state is what the declaration prescribes.** The repair is the mechanism, not the artefact. Canon intact means nothing was lost and one verb restores it.
- (2026-09-09) **hv: amend a hand-written header, do not regenerate it.** `organize --default --force` would have produced a byte-identical thread list and discarded the provenance and the rule-divergence note, which are the only things in the file a tool cannot re-derive.
- (2026-09-09) **hv NAMED THE MINIMUM DEFECT: a one-level shift over 5 percent of the frame, RMSE 0.223607.** Named as a DESCRIPTION and computed, never taken from an injection's figure. The threshold is `sqrt(f)` so it is independent of frame size and transfers to any reel. Slides 13 and 14 clear it by 149x and 102x, so 21 of 22 grade and only slide 1 remains, on AC-3.7.
- (2026-09-09) **hv: the shared git index gets a pre-commit WARNING, not a refusal.** A refusal needs node identity at commit time and would refuse the legitimate cross-node commit. Issue 0019 carries the two instances and the unsettled design question.
- (2026-09-09) **hv, TWICE: a true finding is not a reason to build.** AC-3.7's brand-purity check and issue 0020's citation sweep both cut as yak-shaving, both vc's, both real. **Apply BOTH tests before minting a row: is it real, and is it worth building.**
- (2026-09-09) **hv: the reel's inputs stay in Dropbox.** A Dropbox worktree, inputs can be arbitrarily large, and Utilz itself is fully tracked -- which is what the hoist depends on. AC-2.18's limit is TRUE and PERMANENT and is not an action item.
- (2026-09-09) **hv: `max_ease` capped at 2400**, below `min_dwell` 2500, so runtime ease can never reach runtime dwell for any config at any speed in either pace mode. Structural, not a refusal.
- (2026-09-08) **hv: no `v` in any version string, anywhere, including the git tag.** `utilz:2.8.0` solo, `utilz:2.8.0/<util>:<version>` paired. Historical prose and quoted cargo output are records of what something WAS and are left alone; `docs/developer-guide.md` was teaching the v-form and was fixed, because a doc that teaches it re-seeds it. Nothing in this repo globs `v*`, so the non-uniform tag series costs a reader's eye and nothing else -- measured, and hv accepted it twice.
- (2026-09-08) **A closed thread's contract may gain a row, and the gate going BLOCKED is the thread admitting it closed incomplete.** ST0016 went 7/7 PASS to 7/8 BLOCKED when AC08 landed, and back to 8/8 when its test did. Not a regression; the honest signal.
- (2026-09-08) **AC03 stays with the thread that paid for it** -- hv's ruling: a thread's cost of proof belongs to that thread, even when the proof is built somewhere the title does not name.
- (2026-09-07) **THE VARIABLE IS NOT THE DEFECT; THE SILENCE IS.** Ruled against my own prior recommendation.
- (2026-09-07) **NEVER IMPLICITLY, ALWAYS AVAILABLE EXPLICITLY.** AC11 and AC16 are one policy from two sides.
- (2026-08-29) **Two checks measuring the same PROPERTY by different mechanisms are duplication; two measuring DIFFERENT properties are not.**
- (2026-08-29) **A criterion pins properties, not enumerations.**
- (2026-08-29) **No fallback message names as its remedy the case in which it fired.**
