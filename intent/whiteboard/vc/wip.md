---
node: vc
name: Validation Claude
role: validation
session_id: 11981560-5612-4fe7-a136-6eae64636b64
heartbeat_at: 2026-09-09 08:14Z
status: active
focus: "ST0017 claimed, contract mine, cc builds. Thread docs landed: objective + context in canon, design.md attached and hydrated, six WPs minted, doctor 0. Ruled the one decision cc and snorkeltoast put to me -- port the CONSISTENT normalisation policy, not the Python asymmetry, because match-exactly means porting a defect on the path carrying the brand marks on every build. Six things are hv's, the dependency budget being the big one: AC02 says comrak and nothing else, and the port needs five or six crates."
claims: [ST0017]
---

# Validation Claude (vc)

Validation node. cc builds, vc contracts and verifies, hv adjudicates. Full boards for 8 Sep are in `.history/20260908/` -- FOLD 5 holds the 32006-byte pre-compression original. This board keeps ONE statement of each rule with the instance that earned it, not the day's narrative.

## DOING

**ST0017 -- showreel hoisted under prez. vc holds the contract; cc builds against it; snorkeltoast advises from the reference implementation.**

- **Thread docs landed 2026-09-09.** Objective + context written into canon and rendered; `design.md` attached and hydrated (375 lines); WP-01..06 minted; `intent doctor` 0 findings.
- **The architecture, in one line:** one Cargo workspace, three member crates (`artifact/` shared, `prez/` untouched, `showreel/` with its own budget), two binaries, and the existing shim gains one dispatch branch. **AC02 survives by construction rather than by exception** -- prez's `[dependencies]` is not touched, and showreel's budget is a new ruling on a new manifest.
- **Why that beats both options HOIST.md weighed.** Its fallback was "shared name, no shared code -- do not merge the implementations", which was the best trade for a PYTHON showreel. Rust makes shared name AND shared code AND unmerged binaries reachable at once. The instruction is honoured exactly: the binaries stay apart, the duplicated library half merges.
- **RULED: consistent normalisation policy, not the Python's asymmetry.** `data_uri`'s PNG branch is the default path for hand-placed brand marks and has no opaque-collapse, so a fully-opaque RGBA ships full-size where `init` would have made it a JPEG -- the mascot and the wordmark, every build. Match-exactly means porting that. **It costs the blanket RMSE and the cost is paid explicitly**: a named exemption list, the difference stated as a DIRECTION, plus cc's sum control and membership control, because an exemption list is a population narrowing and too narrow fails greenly.
- **Contract drafted, NOT minted.** 22 rows across SHARE / FID / PORT / HOIST. Minting is blocked on the id format -- see the new watch-out.

## TODO

- **Mint the 22 contract rows** once hv or `intent-vc` names the id form.
- **Answer cc's two open items**: whether snorkeltoast writes the harness now (yes, once the assertions are specified -- they now are) and cc's `inline.rs` assessment, which is unblocked.

**Carried, and all of it hv's to decide. None of it blocks ST0017.**

- **`.intentfiles` header is the root of an entire wasted afternoon and is still wrong.** It is the hand-written 2026-08-26 original -- "organize --default was not yet built" -- and names `st hydrate` **zero times**. Four of us hunted a verb the file said nothing about. The current Intent template names it and lists every writer. hv's to refresh.
- **ST0016 is still hydrated** and `.intentfiles` declares a Completed thread while the header says only OPEN ones are. Either `organize --apply` finishes it as ST0015 was finished, or the policy changed and the header should say so. hv's call, unblocked now that nothing is unclaimed.
- **Issue 0007 needs hv for TWO reasons, and clearing the first would not release it.** Its stated home ST0010/WP-05 is Cancelled -- recorded, not re-homed. But the fix also answers a question the issue raises and leaves open (does the 4.5:1 floor bind `aria-hidden` decorative chrome?), and it changes output hv page-turned and approved: the counter inherits its colour, so it is `opacity: 0.45` carrying it under the floor, and correcting the colour alone will not lift it. The colour half is small and fenced and is written into the record.
- **AC16's per-theme note, which its own evidence names as missing.** hv's 2026-09-08 page-through of all seven -- "they all LGTM, including tables and images" -- is exactly the catalogue the recorded attestation says it does not hold, and it is unfiled. **Not filed by me on purpose:** `ac` has no append, so amending it is `unsatisfy` then `satisfy`, which CLEARS hv's own attestation wording and momentarily unsatisfies an AC on a Completed thread. Attestation is hv's to give and hv's to reword.
- **The closed-thread evidence gap** -- Intent's, via `intent-vc`. Issue 0011's fix is the third instance: it changed a test whose green is recorded in ST0014's dehydrated canon, and nothing re-verified or re-attached it.

## Done since the fold

- **Issue 0011 CLOSED** (`6200ac2`) -- AT12 asserted live `git rev-parse HEAD` against a fixture-time install. Red-proofed first: undisturbed both forms pass, diverged the live-HEAD form fails. **The one-line fix would have been tautological** -- the runtime reads `source-commit` from the manifest, so a test reading the same row proves the plumbing and nothing about whether the right commit was recorded, which is the half live HEAD accidentally covered. Two assertions instead, the second in its own test so its `skip` cannot take AT12's down with it. Controlled: a wrong `source-commit` leaves AT12 green and reddens the new one.
- **Issue 0010 CLOSED** (`ca1e924`) -- and **its stated diagnosis was wrong**. It said the generator was clean and this was "not a code change"; `common.sh` was still filling `{{IMPL_PATH}}` with absolute paths, so the next `utilz generate` would have minted the ninth. Root cause was one variable doing two jobs: the filesystem target the generator writes through and the string that ships in README.md. `install_e2e.bats` then dropped its `! -name '*.md'` exemption, so the strict property covers the whole owned set instead of only files that run.
- **Issues 0007 and 0013 records corrected** (`b413b41`) -- 0013 closed one write-only capture, not the class, and said otherwise; 0007's blockers are now written down.

## Claims

- **ST0017** -- the contract. cc builds; no peer claimed it.

## Holds

- **None.**

## Open with hv

- The two `.intentfiles` items above, which are one decision.
- Whether `--help` diverging on a DIRECTLY executed utility is worth a thread. cc reported it and correctly did not fold it into ST0016.

## Live with other nodes

- **`cc`: folded for a compact, status active, nothing claimed.** Built ST0013, ST0015 and ST0016 today against contracts I wrote.
- **`intent-vc`: three Intent issues from this estate today** -- 0282 (ws hygiene thresholded the wrong bytes, FIXED), 0283 (a closed thread's view goes stale and both messages misdescribe it), 0284 (27 leaked `intentd`, high, cleared).

## Watch-outs

**THE AC MINT REFUSES NOTHING AND THE RENDERER GROUPS NOTHING, SO "CONFORMING ID" CANNOT BE INFERRED FROM BEHAVIOUR.** Measured on ST0017 today: `intent ac new` accepted `AC-HOIST-01`, `HOIST-AC-01` AND `AC01`, and the renderer then made every one its own group. Unenforced in both directions. **With no rename verb, a wrong mint is permanent** -- so the contract is drafted in `design.md` and minted only when the form is named. **Partial relief, also measured: dropping rows from `intent/.canon/st/<ID>.json` and running `intent sync --to-store` retracts them cleanly** -- no tombstone, no `withdraw`, doctor 0 after. Un-ratified rows only; the sync warns it OVERWRITES and the satisfied-row case was not tested.

**FIND THE RECORD BEFORE FORMING THE HYPOTHESIS. THIS IS THE BIGGEST MISS OF THE DAY AND IT IS MINE.** Files were vanishing from `intent/st/`. I theorised through git hooks, `intent doctor`, an unnamed concurrent writer, and finally 27 leaked `intentd` daemons -- which I ESCALATED TO hv AS THE ROOT CAUSE. It was none of them. `intent/.cache/intent.db` holds an `event_log` table naming every disk mutation with a timestamp, and an `attachments` table that showed the actual defect. **Two `sqlite3` queries would have ended it before the first theory.** A real anomaly is not automatically YOUR anomaly: the daemon leak was genuine and unrelated, and I attached my symptoms to it because it was the only strange thing in view.

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

- (2026-09-08) **hv: no `v` in any version string, anywhere, including the git tag.** `utilz:2.8.0` solo, `utilz:2.8.0/<util>:<version>` paired. Historical prose and quoted cargo output are records of what something WAS and are left alone; `docs/developer-guide.md` was teaching the v-form and was fixed, because a doc that teaches it re-seeds it. Nothing in this repo globs `v*`, so the non-uniform tag series costs a reader's eye and nothing else -- measured, and hv accepted it twice.
- (2026-09-08) **A closed thread's contract may gain a row, and the gate going BLOCKED is the thread admitting it closed incomplete.** ST0016 went 7/7 PASS to 7/8 BLOCKED when AC08 landed, and back to 8/8 when its test did. Not a regression; the honest signal.
- (2026-09-08) **AC03 stays with the thread that paid for it** -- hv's ruling: a thread's cost of proof belongs to that thread, even when the proof is built somewhere the title does not name.
- (2026-09-07) **THE VARIABLE IS NOT THE DEFECT; THE SILENCE IS.** Ruled against my own prior recommendation.
- (2026-09-07) **NEVER IMPLICITLY, ALWAYS AVAILABLE EXPLICITLY.** AC11 and AC16 are one policy from two sides.
- (2026-08-29) **Two checks measuring the same PROPERTY by different mechanisms are duplication; two measuring DIFFERENT properties are not.**
- (2026-08-29) **A criterion pins properties, not enumerations.**
- (2026-08-29) **No fallback message names as its remedy the case in which it fired.**
