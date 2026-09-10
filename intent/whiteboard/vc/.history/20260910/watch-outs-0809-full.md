# vc watch-outs, 8-9 Sep corpus, archived at the 2026-09-10 19:53Z localfold

The live board keeps each rule's HEADLINE; this file keeps the instance that earned it.

- **THE PUBLISHED SLOT CAN BE EDITED IN PLACE AT ANY TIME, INDEPENDENTLY OF PROMOTE -- snorkeltoast's PREMISE
  AFTER THEY REFUTED MINE.** I wrote "the promote path edits the artifact". **It does not.** Measured by them and
  re-measured by me at the repo: `096a676` 4,817,190 `<head>\n\n<meta`; `19e3f3f` 4,817,189, `8389486` 4,812,977
  and `b6ec9e6` 4,780,047 all `<head>\n<meta`. **Three of four promotes byte-faithful and so was the fourth** --
  I had verified `19e3f3f == _out` myself before writing the wrong version. **The edit is its OWN commit 93
  minutes later with its own message**, so it is a discrete in-place edit after publication. **Their premise is
  the more durable one: a lossy stage could be fixed once and forgotten; this recurs whenever anyone opens the
  file.** My two comparisons survive and are right for the better reason. **WHO did it is undetermined and stays
  that way** -- every commit in that repo carries hv's identity, there is no formatter config, no CI and no
  installed hook, and message style is too weak to discriminate.
- **THIRD PLAUSIBLE-CAUSE-INSTEAD-OF-MEASURED-CAUSE IN ONE DAY, AND THE RULE WAS MINE, FILED THIS MORNING.**
  cc's stale read (I said `state.is`), the promote path (I said the path, it was a later hand edit), and both
  caught by the peer rather than by me. **The rule survives every time and I keep not applying it to the NEXT
  one, because a cause only feels like a guess when somebody else measures it.** The mechanical form:
  **if I am about to write WHY something happened, the next command is the one that measures it, or the sentence
  does not go in.** Both peers now hold me to this and I have asked them to.

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

**`git commit --only` PLUS A REFORMATTING PRE-COMMIT HOOK LEAVES A FALSE `MM`, AND IT READS AS THE OPPOSITE OF
WHAT IT IS.** Seen three times today and diagnosed the third: `--only` stages the path into a temporary index, the
hook reformats the file, **the hook's version is what gets committed**, and the MAIN index keeps the version I
staged. Result: `HEAD..index` differs, `index..work` differs, and **`HEAD..work` is EMPTY** -- everything is
committed and the working copy is correct. `git restore --staged <path>` clears it. **The trap is that `MM` in a
shared tree reads as "I have uncommitted work" when the truth is that there is none**, and my own covering
discipline -- read the whole tree and expect it clean -- flags it every time. **Do not stop using `--only`**: it is
what stops a bare commit sweeping a peer's staged work, which is a real harm against a cosmetic one.

**FOUR SIBLINGS, AND THEY ARE ONE FAMILY: CORRECT-LOOKING WORK SUPPRESSING THE NEXT QUESTION.** Collected across
three nodes in one afternoon, and the fourth is snorkeltoast's and the sharpest. **(1) A DIFFERENCE RECORDED AS A
NUMBER STOPS BEING A QUESTION** -- "23 vs 22" sat in a state file for hours as an explained thing and the 1 had a
name nobody looked up. **(2) A CAVEAT PRINTED WHERE IT DOES NOT APPLY TRAINS THE READER TO SKIP IT**, and a caveat
nobody reads is worse than none because it still looks like diligence. **(3) A PRECISE MEASUREMENT OF THE WRONG
OBJECT STOPS ANYONE ASKING WHICH OBJECT** -- "byte-identical to 008" was correct bookkeeping of a local checkout
reported as a served page, and its precision is what stopped the question. **(4) A CORRECTION STOPS ANYONE ASKING
WHETHER THE CORRECTION IS RIGHT.** snorkeltoast's repair of (3) was a second population error inside the fix for the
first -- their `find` covered two roots and the artifact lived under a third -- and **the repair carries the
authority of having just been careful**, so the moment after being rigorous is exactly when nobody audits. **None of
the four is a careless act; all four are competent work whose competence is what closes the enquiry.**

**A DUPLICATE THAT IS A SUBSET READS AS "NOT A DUPLICATE" UNTIL SOMEONE USES THE MISSING PART.** cc's, and it is a
real gap in how Highlander is normally checked. `main.rs` held the pace presets as a `match` returning dwell and
ease; the reference's `PACE` carries FIVE fields, so transition, motion and fit defaults were simply absent.
**Measured: 2 of 5, and the 2 that were there were CORRECT** -- which is exactly why it passed. A Highlander sweep
compares two homes and finds the present fields agree; the absent ones are not there to disagree. **Nothing reported
it because nothing consumed the missing three yet**, so the defect was scheduled rather than latent. The check that
would catch it is not "do the two homes agree" but "does the second home carry every FIELD of the first".

**A UNIFORM FAILURE READS AS CONFIRMATION WHEN THE TEST IS REFUSAL-SHAPED, AND ONLY A BASELINE SEPARATES THEM.**
Driving cc's five value-validation arms, my first fixture used `type: image`, which is not one of the twelve shapes,
so **all five arms exited 2 -- including the baseline.** Had I run only the three arms expected to refuse, three
refusals would have read as three confirmations over a fixture that was invalid for an unrelated reason. **The
mirror of the empty-population problem: there, everything passes; here, everything refuses**, and in both the
treatment and the control return the same answer. The corrected run brackets the three reds with two greens, and the
second green matters as much as the first -- it proves the refusals were caused by the injections rather than by
drift.

**AND I NEARLY MANUFACTURED A PREDICTED DIFFERENCE OUT OF A PARITY FIX.** cc's slice made `fit: cvoer` refuse where
the port had let it through to the player as a class name styling nothing, and my first move was to reach for
snorkeltoast's `PORT_EXPECTATIONS`. **The reference validates them too** -- `showreel:828`, vocabularies at :76-78 --
so the port was catching UP, not diverging. Measured rather than assumed: all three vocabularies are set-identical
between reference and port, with a control proving the comparison fires. **Recording a parity fix as a deliberate
difference would be a rationalisation with a good filing system, produced by the node that wrote the rule against
it.** The test that separates them is one command: does the reference do it too.

**`head` IS A SILENT SAMPLER, AND THAT IS WHY IT BELONGS IN THE SAME FAMILY AS EVERYTHING ELSE HERE.**
snorkeltoast's mechanism for my four-of-nine error, and it is better than my account of it: **`find | head -4` and a
directory that genuinely holds four files produce THE SAME BYTES.** `head` does not announce that it truncated, so
the output cannot tell you whether you saw a set or a sample. That is AC-1.15's own sentence -- a proof that did not
run and a proof that passed have the same output -- arriving in a shell pipeline. **The cure is not a bigger `head`;
it is printing the MEMBERS rather than the count**, because a count whose members you cannot see is a claim you
cannot check.

**A CAVEAT PRINTED UNCONDITIONALLY TRAINS THE READER TO SKIP IT.** snorkeltoast's, caught against their own new code:
their "a file below the cap is not evidence either way" line fired on every run, and on 45h there are ZERO such files,
so it warned about a population that does not exist there. **A caveat nobody reads is worse than no caveat, because
it still looks like diligence.** Guarded now. The pair to it: the line that IS true of every reel stays
unconditional, so the two kinds of statement are told apart by whether they are guarded.

**THE DOMINANT FAILURE OF 9 SEP WAS MINE AND IT HAS ONE SHAPE: I SPECIFIED AGAINST IMPLEMENTATIONS I HAD NOT READ.** Four instances in one afternoon, every one a locally reasonable sentence. **(1) I told cc a pattern with no `{nnn}` was already refused by the reference, citing `:532` and `:547`. Both TEST `if NNN not in stem` and NEITHER refuses** -- one returns `[]`, the other returns the fixed path under the comment _a pattern without {nnn}_, a supported configuration I would have made illegal. **A CONDITION IS NOT A CONSEQUENCE**, and I had the `if` on screen and never scrolled to the `return`. **(2) I specified a refusal for any substituted value containing a template marker.** `render()` reads every offset from the UNMODIFIED shell and slices, so the hazard was structurally absent and my guard would have rejected a title the port renders CORRECTLY. **(3) I told cc two of six admission sites were unexercised.** It is one: I had read a list of eight config FIELDS as the site enumeration. **A count of fields is not a count of call sites. (4) I nearly assigned snorkeltoast work they had already finished** -- checking whether the payload's limits enter `signature()` -- which was built, kind BLIND, with the reasoning I was going to ask for written out. **A gap I infer from a peer's design and a gap that exists produce the same plan.** THE CURE IS NOT CARE. **Read what the code DOES, never what its guard clause TESTS; and when specifying a refusal, name the input it would reject and go check that nobody ships it.** Two of the four would have cost a working input; the fourth would have cost a peer's afternoon.

**A CITATION CAN EXPIRE WITHOUT DECAYING, AND NOTHING IS WATCHING FOR THAT.** Two forms, both live. **(1) A CONCLUSION CONTINGENT ON A DEFECT BEING UNFIXED** -- I cited snorkeltoast's `shipped-max-ease` row as AC-3.6's negative half, and `_shipped_max_ease` returns `[]` the moment Python's `max_ease` reaches 2400, **which is hv item 2, which I am carrying to hv.** It would have dangled on a GOOD day, from a fix I asked for. Staleness announces itself with a date, a moved line, a renamed symbol; this announces nothing, because nothing decayed. **ASK WHAT HAS TO STAY BROKEN FOR THIS CITATION TO KEEP WORKING**, and cite the durable FACT rather than the contingent conclusion resting on it. **(2) A PEER'S LANDING STALES A TREE-WIDE ROW WITH NOBODY ERRING.** AC-6.1 leg 1 is a claim about the whole tracked tree, graded before cc's pull put a 45 KB `player.html` into it. **Re-run when the tree GROWS a file, not only when someone edits the subject.** The row survived; the first instinct -- grep the whole tree for the token -- was itself a wrong population, since documents DISCUSSING popupart are not the theme.

**THE FIXTURE'S SILENCE IS NOT THE SUBJECT'S, AND 45h IS THE PROOF.** **45h is the only real config and it is a WELL-FORMED one, so it cannot exercise a single refusal path.** cc counted three arms with empty populations on it; it is at least five -- AC-3.4's artifact half (no opaque RGBA exists: six art files are JPEG, one location PNG is colour type 2, and the two RGBA brand files are genuinely transparent); the bug embed (`bug.file` IS the logo segment's file, so the total agrees for the wrong reason); AC-4.2's stale-QR warning (all five QRs stamped, every stamp matching its config exactly); AC-3.2's `files:` site; and AC-3.2's sort ordering (1 of 40 on APFS, 0 where the filesystem returns sorted entries). **THIS IS THE CONVERSE OF "TEST AGAINST SOMETHING YOU DID NOT WRITE" AND MUST SIT NEXT TO IT:** the live reel caught the missing `#[serde(rename = "loop")]` and is worth NOTHING for any detector. **Two populations wearing one fixture.** Every such arm needs a constructed fixture and the row must SAY so. Same family, different cause: **`find` does not follow a symlinked root** -- `find ~/Dropbox` returned nothing for the live reel twice, because it is a symlink to `~/Library/CloudStorage/Dropbox`, and **the output is byte-identical to a tree that holds no such file.**

**A REFUSING APPLIER THAT DOES NOT CLEAN UP ON REFUSAL IS WORSE THAN ONE THAT NEVER REFUSES**, and it is on AC-1.15 now. cc's injection anchor collided with an unrelated match arm, the post-check refused **after the write with the revert on the success path only**, and the tree sat injected while the harness printed REFUSED. **The word REFUSED reads exactly like nothing happened**, and reassurance is what stops the next look. **The blast radius is not one proof:** every subsequent measurement in that session -- gates, counts, binary sizes, any `strings` census -- is suspect and not one would look wrong. **The revert goes in a `finally`.** Both nodes use this pattern. Its sibling from the same commit: **a fixture whose values cannot distinguish two orderings tests neither** -- zero-padded revisions made lexical and numeric sort coincide, so the assertion held under either.

**A REAL RATIO DEGRADES; A WRONG POPULATION COLLAPSES.** snorkeltoast's form, and it is checkable without knowing
anything about the subject: **if a measurement over a supposedly rich population returns EXACTLY NOTHING, suspect the
population before the subject.** Mine today: a `find` over the whole Snorkeltoast tree for `manifest.json` returned
ZERO, and for a moment that read as a peer's claim being unverified -- captures live in caller-supplied scratch that
is `rmtree`d per run and never enters the repository. **I asked the tree for something that lives outside it.** The
tell was not the subject; it was that the answer was zero rather than small.

**AND I SAMPLED FOUR OF NINE IN THE ROW THAT IS ABOUT POPULATIONS.** `find | head -4` returned four assets at 2560px
and I wrote "the reel's assets ARE init's masters". Nine exist; six are at the cap and three below it. **The
inference also runs only one way** -- `normalise_image` resizes only when the long edge exceeds the cap, so a file AT
the cap is evidence and a file below it is not. snorkeltoast caught both, and **the correction strengthened the
conclusion**: a Rust init caps at the same number, so the dimension cannot separate population (2) from (3) even in
principle, which turns the stamp from the neatest mechanism into the only one.

**SIX ROWS NEEDED THEIR INSTRUMENT CORRECTED AT GRADING TIME TODAY, SO STOP WAITING FOR THE SEVENTH.** AC-1.2
named the lockfile, now 79 entries. AC-1.3 named a byte diff of prez, which cannot tell a test that MOVED to the
shared crate from one that was DELETED. AC-3.10 named an edge set and still under-determined the answer by two,
because nobody had named the DEDUP KEY. AC-6.1 said no Utilz-tree file contains the popupart theme while
`popupart.theme.yaml` sat in the tree. **Every correction made the row STRICTER, which is the tell that the property
was right and only the instrument had aged.** The move that pays is auditing the UNGRADED rows before their code
lands: it caught AC-5.1 (fails against a bare invocation, correctly, because 45h names `theme: popupart`), AC-5.3
(no named population, and showreel is self-contained, so the row was satisfiable by reporting nothing), AC-3.2 (two
of six sites exercised by no real config) and AC-3.4 (**half its population is in WP-04** -- `normalise_image` is
init-only). **A row is cheap to fix before its code exists and expensive after, and the cost is not the edit -- it
is that the grading already happened in someone's head.**

**STAGING EXPLICIT PATHSPECS IS NOT SUFFICIENT, AND I HAD BEEN CARRYING THE RULE IN ITS INSUFFICIENT FORM.**
`git add <paths>` followed by a bare `git commit` commits **the INDEX, not the paths** -- cc staged `design.md` and
`main.rs` in the interval and my AC-1.16 commit took both, under my message. **`git commit --only <paths>` is the
form that holds**, verified twice since with cc's files staged and untouched through both. Not rewritten: `local` is
shared, cc may have built on it, and rewriting a shared branch to fix attribution is the worse trade. **The general
shape: a rule that names the WRITE does not cover the COMMIT, because the index is a third party to both.**

**A DETECTOR WHOSE POPULATION IS A STRICT SUBSET OF ITS OWN NAME, AND THE USUAL CONTROL DOES NOT CATCH IT.** Asking
whether six harness commits touched `redproof`'s machinery, I grepped for added or removed lines matching
`def cmd_redproof|def rmse|def capture|...` and got a clean ZERO across all six -- which would have licensed
satisfying AC-2.4 on a record from four hours earlier. **The pattern can only fire when a SIGNATURE changes**, and
none of those commits changed one, so it could not have fired however much the bodies moved. I had named it
_touches redproof machinery_ and built it to measure _changes a def line of redproof machinery_. **THE NAME
CONCEALED THE NARROWING.** And it would pass a has-it-ever-fired check, because it fires happily on any commit that
adds a function -- so the standard control is blind here. **The control that works is asking what the detector
CANNOT SEE**; for a line-pattern over a diff, that is everything inside a function body. The right instrument was
hunk CONTEXT (`@@ ... @@ def foo`), which answers the question actually asked: four of five call-graph members plus
the function itself.

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
