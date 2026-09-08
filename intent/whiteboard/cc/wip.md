---
node: cc
name: Control Claude
role: control
session_id: 221775b1-d498-41c0-b937-4d10094711a8
heartbeat_at: 2026-09-08 14:14Z
status: active
focus: "IDLE, RESUMED AFTER THE COMPACT -- status stayed active throughout, as a compact is not a session ending. ST0013 closed and dehydrated; every version reduced to one home on hv's ruling; install published at 2f76209, 126 paths, doctor 7/7. Nothing claimed, nothing held, holding on hv."
claims: []
---

# Control Claude (cc)

## DOING

**Nothing. ST0013 is closed, dehydrated and verified.**

Theme addressing split three ways: `--theme` takes a NAME (search path, then built-ins, **never the cwd**), `--theme-file` takes a PATH in either shape, `--theme-path` PREPENDS onto `PREZ_THEME_PATH`. Front matter splits the same way. prez is **2.0.0** -- breaking change by semver -- and its version now has **one home**, `crate/Cargo.toml`, because cargo requires it there and a home you cannot delete is the one to keep.

**hv published the install at `f3470b9` and I verified it by BEHAVIOUR, not by its version string**: the cwd no longer shadows, clause (f) fires from `present`, and `--theme-path` announces itself as the mechanism. A version that agrees is not the same claim as behaviour that agrees -- geodica spent a verification round on a binary reporting 1.0.0 that already had the new behaviour.

Full record is in canon, not here: `intent st show ST0013`, `design.md` D1-D14.

## TODO

**Empty.**

## Holds

**None.**

## Watch-outs

**Measurement discipline. Each of these produced a green that meant nothing.**

- **A BLOCK YOU DID NOT MEASURE IS A CLAIM.** I told hv I was blocked on vc for AC ids before writing `design.md`. I was not: every line I later wrote could have been written before a single AC existed. **I invented the dependency and reported it as an external one.** Before saying blocked, name the artefact that is missing and what specifically cannot be written without it.

- **A CONSTRUCT THAT DID NOT DO WHAT YOU READ IT AS, FOLLOWED BY A GREEN, READS EXACTLY LIKE SUCCESS.** Three instances now. A `perl -0pi -e` that silently matched nothing, after which the suite went green because the ORIGINAL test still passed. A `grep -q` verification whose own pattern was wrong, reporting a landed patch as failed. And an **unquoted heredoc**, where every backtick in prose ran as a command -- it compiled C into a file named `hv` and left a stray in the repo root. **The rule: after any in-place rewrite, grep for the NEW text and fail loudly if absent. Quote every heredoc delimiter that carries prose. Prove a new assertion bites by injecting the regression it is meant to catch.**

- **A WAIT CONDITION EVALUATED OVER A POPULATION THAT INCLUDES THE WAITER NEVER TERMINATES.** vc's, 8 Sep. `until ! pgrep -f 'utilz test'; do sleep 10; done` has the literal string `utilz test` in its OWN command line, so the waiter matches itself, concludes the thing is still running, and sleeps forever. **`utilz[ ]test` is the one-character fix.** The cost is not a wrong answer, it is NO ANSWER EVER -- silent and permanent, where the other two unconstrained-population errors today failed loudly (too wide) and would have failed greenly (too narrow).

- **AND THE POPULATION ERROR IS SO EASY THAT I COMMITTED IT INSIDE THE CHECK FOR IT.** Sweeping for my own strays with `pgrep -fl "221775b1|utilz[ ]test|acceptance[.]sh|bats "`, the `bats ` alternative matched **an unrelated project's Claude session** whose SYSTEM PROMPT contains the word. Four instances in one day between two nodes. **Treat any `pgrep -f` pattern as matching prose, not just commands.**

- **A CORRECT OUTPUT CARRIES NO INFORMATION ABOUT WHETHER THE INSTRUMENT WORKED, ONCE THE SOURCE IT READS HAS STOPPED CHANGING.** The strongest thing on this board and it cost two corrections to reach. I cited a watcher's `ok=554 notok=0`, matching the log exactly, as proof it had completed. **It had not.** Measured: `final3.log` last written 12:21Z, its watcher still alive and self-matching at 12:42Z -- **21 minutes after its condition went false**, where a sound loop exits within its 10-second sleep. It never exited; the harness timed it out and the write flushed on termination, the same mechanism as the heredoc two hours earlier, reading as a success. **The numbers were right because the log had been complete and unchanged for 21 minutes, so a grep of it at ANY moment returns the right answer.** A hung watcher and a working watcher produce BYTE-IDENTICAL output here. **The discriminator is a timestamp, not the value** -- and I had read the value as evidence for a hypothesis it is equally consistent with the opposite of.

- **CORRECTED IN PLACE RATHER THAN DELETED, because the wrong reading is the lesson.** This entry previously said one of the two monitors "had in fact COMPLETED and reported the correct 554/0". vc measured the mtimes and broke the tie against it; I re-measured before accepting. **Both of us corrected the other within ten minutes, and both times the correction was measurement rather than argument.** vc's own "two immortal sleepers" also over-claimed -- the LOOP cannot exit, which the timestamps confirm, but the PROCESS is terminable, so neither was resolved, they were killed.

- **A BLOCKED PROCESS HOLDING AN UNFINISHED WRITE IS NOT INERT, AND TERMINATING IT COMPLETES THE WRITE.** 8 Sep, found during a tidiness sweep two hours after the fact: the zsh from that morning's unquoted-heredoc accident was STILL ALIVE, started 10:28:30, blocked. I killed it as cleanup -- and on termination it flushed its heredoc and appended **45 corrupted lines to a peer's inbox**, stamped with a stale 09:28Z, every backticked span command-substituted and the output of `intent issues list`, `ls` and `intent doctor` spliced into the prose. **The cleanup action caused the damage the cleanup was for.** Caught because `git status` was checked immediately after; the diff was additions-only so HEAD was intact and `git checkout --` discarded only the garbage. **Before killing a stray, know what it has open and check the tree immediately after.**

- **THIS TREE HAS THREE CONCURRENT WRITERS AND A `git status` FROM EARLIER IS NOT A BASELINE.** On 8 Sep I saw ST0012 and ST0014 flip to Completed, concluded a shell accident of mine had done it, and was one command from reverting vc's finished work. **The mtimes settled it -- their canon writes were nine minutes before my accident.** Check mtimes and the artefact before attributing a change to yourself or anyone. Commit with an explicit pathspec, never `-A`.

- **AN ASSERTION PHRASED AS "NAMES X" LICENSES A SUBSTRING CHECK, AND A SUBSTRING CHECK CANNOT SEE A MALFORMED STRING THAT CONTAINS X.** vc's generalisation, 8 Sep, from a defect of mine: I built two refusal remedies from one `{remedy}={value}` template, which printed `for a path, use 'theme-file:'=./x.css` -- not front matter and not anything else. **Every unit test and all six ATs stayed green**, because each greps `theme-file:` as a substring and the malformed string contains it. The contract's own wording permitted it, so the test was not weaker than the criterion; the criterion was. **Where the SHAPE of a message is the requirement, the row has to say the shape** -- and the way I found it was running the case and READING the output rather than matching on it.

- **"IT ANSWERS" AND "IT ANSWERS WITH THE RIGHT VALUE FROM THE RIGHT SOURCE" ARE DIFFERENT CLAIMS, AND THE FIRST IS THE EASY ONE.** 8 Sep, verifying the version publish: I checked every utility ANSWERS a version and carries the framework line -- liveness. vc checked the answer EQUALS THE BYTES of the file its yaml points at -- the Highlander claim. **Two numbers agreeing by luck pass mine and fail theirs.** When two people verify the same change, agreeing on the instrument wastes one of them; pick the claim the other did not make.

- **AND VERIFY THE ARTIFACT, NOT ONLY THE TREE THAT TESTS IT.** Both my guards run against the checkout. vc ran the equivalent against the published INSTALL -- 31 help files and READMEs, 0 literals, pointer present in all 31 -- which is the only way to know a fix REACHED the shipped tree. Pair it with a negative control proving the pattern bites before trusting a zero.

- **A CONTROL OVER A SUBSET READS EXACTLY LIKE A CONTROL OVER THE WHOLE.** vc's, 8 Sep, from a defect of mine. Pairing an assert-absence with an assert-presence is **necessary and not sufficient**: my absence check spanned 33 files and its presence control counted 16 of them, so deleting the version line from the other 17 passed BOTH. **The pair has to consume ONE population, computed once**, or the control is a subset wearing the costume of the fix.

- **A SUITE RUN AT ONE INDEX STATE SAYS NOTHING ABOUT ANOTHER, BECAUSE `git ls-files` READS THE INDEX AND NOT THE WORKTREE.** 8 Sep: 14 new `VERSION` files were STAGED when a full suite ran, so `install_owned_paths` found them and the install gate passed **honestly**. They were untracked twenty minutes later, and a publish would have shipped sixteen yamls pointing at files that were not there. **Nothing was wrong with that green -- it simply stopped describing the tree.** One level below "a `git status` from earlier is not a baseline", and sharper, because there the reading was already stale and here it was correct when taken.

- **ANY CONTROL THAT READS THE WORKTREE CANNOT SEE A PACKAGING DEFECT.** The check built to prove every utility resolves a version sourced `common.sh` against the CHECKOUT, where the files exist on disk whether or not git knows about them. Green in the checkout, broken in the install: **the two-tree trap firing on the control built to prevent the thing.** Only `install_guards.bats`, which builds an install through `install_owned_paths` and runs every link, could see it -- and it did.

- **A check placed before the thing it measures passes for the wrong reason**, and a red-first probe that did not APPLY is not a red-first proof. **A grep-based check must target a string the artifact can only contain if the thing is really there** -- never a token the file might legitimately discuss. **Never pipe a command whose exit code is the assertion**; `$?` is the last stage's.

- **A SHARED FIXTURE THAT ANY TEST MUTATES IS A FLAKE GENERATOR.** The AT15 legs wrote a marker VERSION into the file-scoped install, so doctor's integrity check failed in a full run and passed in isolation. Mutating tests copy first.

- **A CAPTURED STREAM THAT NO ASSERTION READS IS WORSE THAN ONE PRINTED ONLY ON FAILURE.** vc's finding 8 Sep, checked against my own surface and confirmed sharper here. vc redirected per-theme stderr to a file and printed it only when a build failed; all seven exited 0, so seven identical warnings sat unread and hv found them by running the command in a terminal. **My acceptance suite does not print it even then.** `acceptance.sh:403` sends AT03's build stderr to `$WORK/at03.err` and nothing ever greps that file -- the redirect exists to keep the terminal tidy. Measured, paired: the pre-fix demo deck emits **165 bytes on stderr and exits 0**; the fixed deck emits **0 bytes, same command, same exit code**. So issue 0012's warning was written into the harness's own capture on every run of the suite and read by nobody. **Exit-0-plus-noise is structurally invisible to a suite that only asserts what it already suspected.** CI escapes this by shape rather than by design -- `tests.yml:324` merges stderr into stdout and `tee`s it, so a noisy success does reach the log.

- **THREE CHECKS IN A ROW RETURNED A CLEAN-LOOKING ZERO THAT WAS A TOOL ERROR, inside the check for the lesson above.** `opt/*/test/*.sh` matched nothing under zsh, which prints `no matches found` and yields empty. `mapfile` is a bash 4 builtin and `/bin/bash` here is **3.2.57**, the project's own stated floor, so the array stayed empty and the script reported `harness files found: 0` and continued. `git show --stat --name-only` included the commit MESSAGE, which quotes a path, so the filename variable became two lines of prose. **Only the third failed loudly, and only because I had added an explicit zero-count refusal after the second.** That refusal is the whole generalisation and it is one line: **a sweep prints its population count and refuses at zero.** Without it, "no matches" and "no problems" are the same output. **And its sibling, vc's, 8 Sep, from their own miscount: a PARTITION prints its remainder and refuses when the parts do not sum to the whole.** Their four categories summed to 66 against their own stated total of 74 and were published anyway -- **self-refuting before anyone else looked at it**, and the check is one subtraction. The zero-count refusal catches an EMPTY population; this catches a wrongly DECOMPOSED one. I used it in the corrected table (`remainder 0 -- fully accounted`) without naming it as a rule.

- **TWO DIFFERENT WRONG POPULATIONS LANDED WITHIN ONE OF EACH OTHER, AND THE COINCIDENCE LICENSED A CONFIDENT WRONG EXPLANATION.** 8 Sep. I sized a fix at "~45 redirect sites"; vc corrected it to 8 and explained my number as "the 44 `2>&1` merges plus change". **It was not.** My grep was `2>[^&1]`, which excludes merges BY CONSTRUCTION -- they were never in my count. It counted 48 non-merge occurrences across BOTH harnesses, including the deliberate `/dev/null` discards. So two wrong populations, arrived at by different errors, differed by one, and the near-miss made a wrong reconstruction look obvious. **When someone explains where your number came from and the explanation fits, re-derive the number anyway** -- agreement on a value is not agreement on a population.

- **AND THE SUBSTRING LESSON CAME BACK INSIDE THE CHECK FOR IT, IN BOTH THE SCRIPT AND THE GREP WRITTEN TO VERIFY THE SCRIPT.** Counting reads per capture file, `e.err` scored 4 writes and 7 reads against a true 1 and 1 -- because **`e.err` is a substring of `refuse.err`, `name.err` and `theme.err`**, which were correspondingly under-counted. Unanchored, it is not a filename, it is a suffix. `(?<=[/"])` was the fix. **Four tool errors in one investigation** -- zsh glob, bash-4 `mapfile` under 3.2.57, `--name-only` swallowing the commit message, and this -- **and only the one after I added a zero-count refusal failed loudly.** A short name is a substring of a longer one far more often than it feels, and every one of these produced a plausible number rather than an error.

- **A NEW ASSERTION THAT WOULD HAVE BEEN RED AN HOUR AGO MUST BE WATCHED GOING RED, NOT ADOPTED GREEN.** vc's framing on the AT03 stderr assertion -- "this assertion could not have been added before the fix it would have caught" -- reads as a constraint and is the opposite. **Red-first says a check that goes red on the existing defect is the ideal case**: add it, watch it bite, then fix. Adding it AFTER 0012 landed gives a green that has never been observed to fail, which is `IN-AG-RED-CONTROL-001` exactly, and my own board's "a check placed before the thing it measures passes for the wrong reason" with the order reversed. **The sequence that proves it: re-inject the `class: escape` line, confirm red, remove, confirm green.**

- **THE CASE WITH NOTHING EXPECTED ON THE STREAM IS THE CASE THAT GETS NO CHECK, AND IT IS EXACTLY WHERE UNEXPECTED OUTPUT HIDES.** 8 Sep, measured after vc landed issue 0013. Of the 16 stderr captures in `acceptance.sh`, **15 carry an assertion requiring CONTENT** -- every one is a refusal or warning leg where stderr is expected to be non-empty, so a needle-based read always had something to reach for. **`at03.err` was the only build expected to be SILENT, and it was the only capture nobody read.** The absence of an expectation is why no assertion got written, and silence is precisely the condition under which unexpected noise is invisible. **Where you expect nothing, assert nothing-ness explicitly; that is the only place the assertion has to be about the whole stream rather than a needle in it.**

- **AND THE LANDED CHECK IS CORRECT BECAUSE IT AVOIDED THIS HARNESS'S OWN HELPER, WHICH A TIDIER WILL PUT BACK.** `acceptance.sh:75` defines `file_size()` as `stat -c %s ... || stat -f %z ... || echo 0` -- it **returns 0 for a MISSING file**. The assertion at AT03 uses `wc -c < "$WORK/at03.err"`, which yields EMPTY for a missing file and therefore fails. Measured both: `file_size(missing) = 0`, `wc form = <empty>`. So the check as written distinguishes **"the build was silent"** from **"the build never ran"**; rewritten to use the file's own neighbouring helper -- the obviously more idiomatic, more consistent choice, sitting 330 lines above -- it would **pass trivially if the build line were ever deleted or renamed.** `$WORK` is `mktemp -d` per run, so a stale file cannot satisfy it either. **A correct check one refactor away from a silent one, where the refactor looks like tidying.**

**The estate, changed 8 Sep and worth knowing at the prompt.**

- **`utilz` ON PATH IS AN INSTALL, NOT THIS CHECKOUT.** `~/.local/bin` holds 16 links; `~/Devel/opt/utilz` is the published tree. `utilz use` reports which is live, `utilz use dev|opt` switches. **`utilz version` names the tree that answered**, so never guess which one produced a behaviour. The dispatcher ignores an inherited `UTILZ_HOME` entirely and always derives from `$0`.
- **EVERY VERSION HAS ONE HOME AND NOTHING RESTATES IT** (hv, 8 Sep). Framework: `./VERSION`. Each utility: `opt/<name>/VERSION`, pointed at by `version_file`. **prez is the exception and is not an exception to the rule** -- cargo requires the version in `[package]`, so that home cannot be deleted, which makes it the one to keep. **Point at the one home you cannot delete**, never "use this filename". Two guards in `common_lib.bats` hold it; do not "fix" prez into compliance.
- **`utilz test` refuses from an install** and is not concurrency-safe anywhere. **`utilz help <anything>` HANGS when stdin is a TTY** (glow's pager); `< /dev/null` fixes it.

**Framework internals that have bitten.**

- **The `each_utility` tripwire that this board documented until 7 Sep was FALSE-RED.** The correct tree returns ONE hit for `grep -c 'UTILZ_HOME"/bin/\*' opt/utilz/lib/common.sh` -- the walker itself. A reader running the old documented form reads that as a walker gone missing and re-adds one, which is the exact duplication it exists to prevent.
- `each_utility` must be consumed with process substitution, never a pipe. `require_yq` ONCE before a loop. `run_doctor` deliberately does NOT gate on it -- it is how you discover yq is missing.
- **`prez --version` and `--help` never reach the shim**; the dispatcher answers from `prez.yaml` -- which as of 8 Sep carries NO version and points at `crate/Cargo.toml` with `version_file`. A test meaning to exercise the binary must use a real verb.
- Verify shell tooling under `/bin/bash` with an ARRAY -- zsh does not word-split, so `shellcheck -x $FILES` errors on one bogus path and the empty output reads as a pass.
- Run prettier yourself before committing markdown, or the pre-commit hook is an unnamed third writer.

## Decisions

- (2026-07-29) `-v` stays **unbound** on the dispatcher. It reads as a verbose flag and no utility binds it, so binding it to `version` would foreclose the obvious future use. Pinned by a test asserting it still fails.
- (2026-07-09) todo guard's Intent-project test is anchored on the **target file's directory**, not cwd: the guard protects the file being overwritten, so `--file`-ing at another project's `intent/todo.md` from outside still refuses. hv-confirmed.
