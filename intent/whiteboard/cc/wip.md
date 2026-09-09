---
node: cc
name: Control Claude
role: control
session_id: a30f9092-03ed-44ba-a659-b37813af12c7
heartbeat_at: 2026-09-09 07:55Z
status: active
focus: "Fresh-session pickup. 0011 and 0010 closed by vc after this board was last written, so one issue is open and it is hv's. The PUBLISHED INSTALL is 6 commits behind and the diff is NOT cosmetic -- it still carries the generator defect 0010 closed, and PATH now resolves to the install. Nothing claimed, inboxes empty."
claims: []
---

# Control Claude (cc)

## DOING

**Nothing claimed. The release this board tracked as in-flight is DONE -- the previous focus line was false and is corrected above.**

- **2.8.0 shipped while cc was compacting.** Annotated tag `2.8.0` on the release commit `9c2ed5f` itself (not on session HEAD, per hv's directive), on `local` and `upstream`. CI green on HEAD `ac6829a`.
- **The install is republished and verified BY BEHAVIOUR, not by reading its VERSION file**: both invocation forms answer `utilz:2.8.0/syncz:2.0.0`, and the provenance line reads `installed at /Users/matts/Devel/opt/utilz (6fb9de6)`.
- **The install is 7 commits behind HEAD and it does not matter -- measured, not assumed.** Those 7 touch exactly two owned files, `bin/.devbin/manifest.sha256` and `opt/utilz/test/help_dispatch.bats`. No user-facing behaviour differs. **State the diff, never the distance.**
- All 16 STs Completed; ST0013 4/4, ST0015 10/10, ST0016 8/8 all PASS.
- **`utilz` on PATH is still the CHECKOUT** (`dev 16 links, opt 0`) -- hv's 15:51 setting for release work, unchanged. Post-release, whether to flip to `opt` is hv's call and one command.

## TODO

**TWO OF THE THREE ARE CLOSED. vc took 0011 (`6200ac2`) and 0010 (`ca1e924`) after this board was last written, so the list below is one issue and one artefact defect, neither of them mine to start.**

- **THE PUBLISHED INSTALL STILL CARRIES THE DEFECT 0010 CLOSED, AND `utilz` ON PATH IS NOW THE INSTALL.** Measured this session, not carried forward: `manifest.sha256` records `source-commit 0c0af89`, six commits behind HEAD `60153d8`. **State the diff, never the distance -- and this time the diff is not cosmetic.** It contains `opt/utilz/lib/common.sh` (the install still fills `{{IMPL_PATH}}` from `$impl_path`, the checkout from `$impl_path_rel`), all eight corrected `opt/*/README.md`, and both install suites. `grep -rl '/Users/matts' opt/*/README.md`: **checkout 0, install 8.** So `utilz generate` run from PATH today mints hv's home path into a ninth README -- the exact thing `ca1e924` fixed. **Checkout-green and install-correct have come apart precisely where this board's own watch-out says they do.** Republish is one command; its timing is hv's.

- **0007 (low) -- prez slide counter contrast. ITS STATED HOME NO LONGER EXISTS**: the issue files the fix under ST0010/WP-05, and WP-05 is **Cancelled**. Re-homing is hv's call, not something to settle by picking somewhere convenient. Compiler change, not a theme change.

## Holds

**None.**

## Watch-outs

**One rule, stated once, with the instance that earned it. Every full instance from 8 Sep is in `.history/20260908/wip-part3-full-board-before-eod-fold.md`; this is the compression, not a summary.**

- **A CORRECT OUTPUT SAYS NOTHING ABOUT WHETHER THE INSTRUMENT WORKED.** I read a watcher's `ok=554 notok=0`, matching its log exactly, as proof it had completed. It had not -- it was still sleeping 21 minutes after its condition went false, and the numbers were right _because_ the log had been complete and unchanged for 21 minutes. **A hung watcher and a working watcher emit byte-identical output; the discriminator is a timestamp, not the value.** Generalises: any check reading a source that has stopped changing keeps returning the right answer long after the check itself has died.

- **POPULATION IS THE FAILURE MODE, IN FIVE DISTINCT DIRECTIONS, AND THEY DO NOT COST THE SAME.** Too WIDE fails loudly (a `*.md` glob reaching into `.backup/` reported 267 files and scared hv; real count was 1). Too NARROW fails GREENLY and ships. SELF-MATCHING never terminates (`pgrep -f 'utilz test'` matches the waiter). PATTERN-MATCHES-PROSE has no bound at all (`bats ` hit an unrelated project's system prompt; a marker that was a utility's own NAME appeared in both artifacts being told apart; a regex demanding `-h|--help)` missed `todo`'s `-h | --help)` with spaces). STALE-ON-ARRIVAL is correct when taken and wrong when read (`bats ./*.bats` expands its glob once, so a suite file created 67 seconds into a run is silently excluded -- and the unchanged total reads identically to "the new tests ran and added nothing"). **Every sweep prints its population count and refuses at zero; every partition prints its remainder and refuses when the parts do not sum.**

- **A CONTROL THAT HAS NEVER BEEN OBSERVED TO FAIL IS NOT A CONTROL.** Inject the regression each row exists to catch and watch it go red. This found two dead tests in one afternoon: a `refute_file_contains` that could NEVER fail, because `grep` parsed its `-`-leading pattern as an option and errored; and a fixture that leaked a generated utility into the shared tree when an assertion failed before its cleanup line, poisoning three later measurements with a population of 16. **Cleanup belongs in teardown, never after an assertion.**

- **VERIFY THE ARTIFACT, NOT ONLY THE TREE THAT TESTS IT.** Every suite here pins `UTILZ_HOME` from `test_helper.bash`, so it is structurally incapable of measuring a published install -- `UTILZ_HOME=/nonexistent/decoy bats` PASSES. Checkout-green and install-correct come apart, and the two-tree estate is where they do. A row that addresses an install must **name the tree it measured** before asserting anything about what that tree said.

- **AGREEMENT ON A VALUE IS NOT AGREEMENT ON A POPULATION, AND NEAR-AGREEMENT SUPPRESSES THE CHECK.** Twice in one day two of us reached the same conclusion from incompatible wrong reasoning. Once it cost a wrong number (two wrong populations landing one apart, which licensed a confident wrong explanation of where the first came from). Once it would have SHIPPED A HANG: both nodes blamed `glow`'s pager for opposite reasons, both were wrong, and the real cause -- an open stdin -- sat underneath the thing we were both arguing about. **When two accounts agree, check they are the same account.**

- **A STALE BINDING IS WORSE THAN A STALE VALUE, BECAUSE THE SENTENCE STAYS GRAMMATICAL.** vc and I disagreed about a commit's position and were both right, against "your last write" resolved eight minutes apart. A stale value looks like a measurement someone took; a stale binding reads as a fact about the TREE when it is only a fact about WHEN IT WAS SAID. **Name the commit, never "your last", "the latest", "current HEAD" or "now".** Corollary: a figure about the repository, measured before you commit to it, is invalidated by your own commit -- measure after your last write, or quote the command instead of the number.

- **PROSE DOES NOT FAIL.** A judgement recorded only in a design document is not enforceable. ST0016 deliberately KEPT the utilities' `--help` arms where ST0015 deleted their `--version` arms; that distinction lived in prose until vc made it a criterion, and two adjacent threads reading as one pattern is exactly how a later reader deletes fifteen arms that nothing replaces.

- **THE CASE WITH NOTHING EXPECTED ON THE STREAM IS THE ONE THAT GETS NO CHECK.** Of 16 stderr captures in one suite, 15 asserted CONTENT -- all refusal or warning legs, where a needle always had something to reach for. The 16th was the only build expected to be SILENT, and it was the only capture nobody read. **Where you expect nothing, assert nothing-ness explicitly**; it is the one place the assertion must cover the whole stream rather than a needle in it.

- **AND THE INVERSE, WHICH IS THE ONE I KEEP.** I described a 1226-line log from the SOURCE OF ONE LINE while the log sat on disk one grep away. All day the failure was trusting an artifact without checking the instrument; here I trusted the source over the artifact I had just produced. **Same root both directions: reaching for the more convenient authority instead of the direct evidence.** The source feels authoritative because it is causal; the artifact is authoritative because it is what happened.

- **THIS TREE HAS THREE CONCURRENT WRITERS.** A `git status` from earlier is not a baseline; `git ls-files` reads the INDEX, so a suite green at one index state says nothing about another. Commit with an explicit pathspec, never `-A`. **Never edit the tree while someone else is measuring it** -- and check mtimes before attributing a change to yourself.

- **BEFORE KILLING A STRAY, KNOW WHAT IT HAS OPEN.** A blocked process holding an unfinished write is not inert: terminating one flushed its heredoc and appended 45 corrupted lines to a peer's inbox. **The cleanup caused the damage the cleanup was for.** Check the tree immediately after.

- **EVERY BASH CALL IS A SEPARATE SHELL, SO `$$` IS A DIFFERENT NUMBER IN EACH ONE -- AND THE WRITE THAT LOST THE FILE STILL SUCCEEDED.** Splicing this board across two calls, I wrote the preserved tail to `/tmp/x.$$` in one and read it back in the next: different PID, no such file. `cat missing kept > board` then wrote the head ALONE, truncating 80 lines to 30, and the `rm` after it ran happily. **A partial `cat` is a partial success, and a redirect commits it before anything checks.** Git had the original, so the cost was two turns. Generalises past temp files: state does not survive between tool calls -- not `$$`, not `cd`, not a variable, not a trap. **Anything two calls share belongs in a path that names itself, and any splice guards its anchor and its line count BEFORE it redirects over the thing it is splicing.**

## The estate, as of 8 Sep EOD

- **`utilz` ON PATH IS THE INSTALL RIGHT NOW, NOT THE CHECKOUT -- INVERTED AGAIN SINCE 8 SEP.** `utilz use` this session: `opt 16 link(s), dev 0`; `utilz version` line three reads `installed at /Users/matts/Devel/opt/utilz (0c0af89)`. **This board has now been wrong about this in both directions, which is the argument rather than an embarrassment** -- do not carry either state forward, run `utilz use`. `utilz version`'s third line names the tree that answered and the commit it was cut from, which is the one command that tells a checkout from an install.
- **EVERY VERSION HAS ONE HOME AND NOTHING RESTATES IT** (hv). Framework `./VERSION`; each utility `opt/<name>/VERSION` via `version_file`. **prez is the exception and is not an exception to the rule**: cargo requires it in `[package]`, so that home cannot be deleted, which makes it the one to keep. **Point at the one home you cannot delete.** Do not "fix" prez into compliance.
- **NO `v` IN A VERSION, ANYWHERE, FROM 2.7.0 ONWARD** (hv, three times). `utilz:2.8.0` alone, `utilz:2.8.0/<util>:<version>` paired, and the git tag is bare. Tags before 2.7.0 keep the `v` they were published with -- those are records of a name a release actually had. Nothing in this repo consumes the prefix; the non-uniform series costs a reader's eye and nothing else.
- **`--version`, `--help` and `-h` are answered by ONE `predispatch_intercept`**, from both dispatch sites. The utilities' own `--help` arms are deliberately kept and are held by a criterion; their `--version` arms are gone. `expz` delegates to `show_help` and has no inline usage; `prez` is a shim whose binary answers.
- **`utilz test` refuses from an install** and is not concurrency-safe anywhere.
- **THE `glow` HANG IS STDIN, NOT THE PAGER. This board said "pager" until 8 Sep and it was wrong.** `-p` is opt-in and injecting it changed nothing; a bare `glow "$file"` with a terminal on stdin hangs. `show_help` now closes stdin on both renderer arms. **Not reproduced under a `script`-allocated pty** -- glow exits 1 emitting terminal-query escapes there, a third behaviour -- so the guard is asserted present rather than the hang claimed fixed.

## Framework internals that have bitten

- **The `each_utility` tripwire this board carried until 7 Sep was FALSE-RED.** The correct tree returns ONE hit for `grep -c 'UTILZ_HOME"/bin/\*' opt/utilz/lib/common.sh` -- the walker itself. A reader running the old documented form reads that as a missing walker and re-adds one, which is the duplication it exists to prevent.
- `each_utility` must be consumed with process substitution, never a pipe. `require_yq` ONCE before a loop. `run_doctor` deliberately does NOT gate on it -- that is how you discover yq is missing.
- **`acceptance.sh:75`'s `file_size` returns 0 for a MISSING file.** A check written with it passes when the thing under test never ran; `wc -c <` yields empty and fails correctly. A tidier swapping one for the other would silently disarm the check.
- Verify shell tooling under `/bin/bash` with an ARRAY -- zsh does not word-split, so `shellcheck -x $FILES` errors on one bogus path and the empty output reads as a pass. **`mapfile` is bash 4; `/bin/bash` here is 3.2.57.**
- **`$PIPESTATUS` is bash-only.** zsh spells it `$pipestatus`, **lowercase and 1-indexed**, and the array is destroyed by the next command. The real cure is neither spelling: redirect to a file and take `$?` with no pipe in the line, so the totals and the status are independent claims.
- `git log` prints LOCAL time. Stamps need `TZ=UTC git log --date=format-local:`; plain `--date=format:` prints local and appending a `Z` is an assertion, not a format.
- Run prettier yourself before committing markdown, or the pre-commit hook is an unnamed third writer.

## Decisions

- (2026-09-08) **`--help` renders the CURATED `help/<name>.md` from both forms**, not the terse inline usage. Agreement at the worse artifact is a strange reading of "make them agree".
- (2026-07-29) `-v` stays **unbound** on the dispatcher. It reads as a verbose flag and no utility binds it (issue 0003).
- (2026-07-09) todo guard's Intent-project test is anchored on the **target file's directory**, not cwd: the guard protects the file being overwritten.
