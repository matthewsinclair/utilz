---
node: vc
name: Validation Claude
role: validation
session_id: 11981560-5612-4fe7-a136-6eae64636b64
heartbeat_at: 2026-09-10 09:08Z
status: active
focus: "ST0017 44/52, WP-03 10/12, doctor 0. THE MANIFEST GATE IS IN (9501b14, AT03/AC-3.14) and covers all three budgets, not the one AC-3.9 names. Next: cc's slide rows then the build verb; the canon holds both our writes and cc has the call on who commits it."
claims: [ST0017]
---

# Validation Claude (vc)

Validation node. cc builds, vc contracts and verifies, hv adjudicates. Full boards for 8 Sep in `.history/20260908/`, for 9 Sep in `.history/20260909/` (`wip-before-localfold-2.md` is the 30389-byte pre-fold original). **This board keeps ONE statement of each rule with the instance that earned it, not the day's narrative** -- and after hv's scope call, only rules that change what gets BUILT.

## DOING

**ST0017 -- showreel hoisted under `utilz prez showreel`. vc holds the contract, cc builds, snorkeltoast owns the
harness and the reference, hv adjudicates.** Localfolded 2026-09-10 08:45Z; 10 Sep narrative in `.history/20260910/`.

- **CONTRACT 43/51, 3 withdrawn, `intent doctor` 0.** WP-01 15/15 DONE. WP-02 16/17. WP-03 10/12. WP-04 0/2.
  WP-05 1/3. WP-06 1/2. `intent ac list ST0017` is the contract; **ids are `AC-<wp>.<seq>` and the group digit IS
  the work package.**
- **`serde_json` IS RULED, TAKEN AND CLOSED.** hv ruled take-it on the CORRECTED one-argument case; cc landed it at
  `0745d32` with **hv named in the commit** -- taken from hv DIRECTLY, not from vc's relay, which was right.
  Lock 79 to 81 entries, 77 to 79 names. **hv DECLINED the standing version, so every future crate returns to hv.**
- **45h BUILD 009 IS LIVE.** Two days of GitHub webhook 401s; hv force-resynced by hand. Verified by three
  observers across the boundary -- vc's byte hash, snorkeltoast's independent hash PLUS a payload parse, hv's eyes.
  **The webhook is STILL 401**: a push publishes nothing and says nothing.
- **cc's LANE, NONE STARTED:** the slide rows (minus `path` and `asset`); threading `Reel::embed_target()` to the
  embed site; the build verb (`_out/`, `plan::report`, `deliver::prune`, filling the producer stamp); then the
  first 45h build, coordinated, needing `SHOWREEL_THEME_PATH`.
- **THE COMPLETION METRIC IS MINE AND IT IS MECHANICAL:** `template::render`, `normalise::embed`, `deliver::prune`
  and `deliver::stamp` have NO production callers. **The build verb is done when all four acquire one**; any that
  does not was built and forgotten. Re-run the sweep at the delivery slice.

## TODO

- **THE FIRST BUILD POINTING AT 45h GRADES AC-2.1 leg 2, AC-5.1 AND AC-6.1 leg 3 IN ONE PASS, AND HAPPENS EXACTLY
  ONCE.** Tell cc and snorkeltoast before it happens -- a standing commitment to both. **F2 is 23**, from 009's
  config, unchanged. Read the first `compare` as **population (2)**: a green over half a pipeline.
- **VERIFY `producer-fallback-strips` AGAINST THE HARNESS AS IT WILL BE AT COMPARE TIME, NOT AS IT IS NOW.** It is
  in as `designed` (`f406346`) and predicts 23 of 23 against the reference's 22. **snorkeltoast was still editing
  `strip_reason` an hour after I read it.** My own condition; cc says hold it hardest.
- **AC-3.6 SATISFIES WHEN THE RED CONTROL RUNS**, not when the payload lands: flip `MAX_EASE_MS` to 3000, rebuild,
  the payload must follow. Template half already a gate and green.
- **STANDING: TELL hv WHEN TO FORCE A LAKSA RESYNC.** Fires on anything published into the site repo -- in
  practice snorkeltoast promoting a build into the `-001` slot. **Verify snorkeltoast's way: fetch the served
  bytes, hash them, AND read the payload.** Hash equality proves the served bytes are the BUILT bytes and says
  nothing about whether they are correct.
- **Two harness entries flip `designed` to `observed`** when cc's build path calls the theme loader. Nothing to do
  until then; noted so their silence is not later read as coverage.

## Holds

- **TELL hv WHEN TO FORCE A LAKSA RESYNC -- hv'S STANDING INSTRUCTION, 2026-09-10.** CONDITION: anything published
  into `~/Devel/prj/Sites/snorkeltoast` that must reach production, in practice snorkeltoast promoting a build into
  the `-001` slot. **The webhook is still 401: a push publishes nothing AND SAYS NOTHING**, and Laksa's own health
  check reads "secret present" as "webhook configured", so it reports the site healthy throughout. The resync is
  not a fallback, it is the only path. **A push nobody follows with a resync is a publish that did not happen.**
- **AC-5.3, HELD ON vc'S OWN CALL and cc agrees.** Genuinely JSON-free and genuinely not startable: no showreel
  manifest, no `bin/` symlink, `common.sh` silent on showreel. CONDITION: **WP-05's dispatch shape decided.**
  Opening WP-05 at WP-03 10/12 to fill an idle gap is inventing adjacent work. hv can overrule.
- **The reference's `Image.LANCZOS` hoist and Python's own stamp -- snorkeltoast's, and NOT vc's to chase.**
  CONDITION: **a compiler change being safe, ie not while 009 is the reference cc is building against.** They have
  made zero compiler changes all day, deliberately, so cc's target does not move mid-port.

## Open with hv

**TYPED BY WHETHER hv OWES A RULING**, on cc's point that an FYI dressed as a decision spends the attention the real decision then does not get.

### Decisions hv owes

- **RE-PROVISION THE LAKSA WEBHOOK -- snorkeltoast calls it the highest-value open item anywhere and it is not
  theirs.** 401 since 2026-09-09 14:43Z. One DB column holds two mutually exclusive credentials: the HMAC key that
  validates pushes and the token used to clone. Setting it to a token to fix cloning silently kills push delivery.
  **The clone half IS deployed** -- proved free by the resync scanning 80 files. Trigger half outstanding.
- **`max_ease` 3000 AGAINST `min_dwell` 2500 in Python's `LIMITS`.** Unruled since 09-09, latent in the LIVE
  artifact at the same magnitudes it was latent in the old one, untouched by the promote. Its rider travels with
  it, not as a third item: capping to 2400 turns WP-02's `shipped-max-ease` selftest red BY DESIGN, one small
  follow-up in snorkeltoast's tree. A consequence, not an argument against.
- **THE PUBLIC-REPO FIXTURES.** Two pinned fixtures carry a named individual and a customer brand into a public
  repo. `upstream` frozen, so nothing is published and it is decidable first. **Recommend (b) de-identify the reel
  config if unsure** -- one edit, keeps every testing property except the name.
- **DROPPING THE REFERENCE PLAYER'S BRAND FALLBACK** (new). `add("Producer", REEL.producer || "Snorkeltoast")`.
  cc already dropped it in their copy and thereby fixed slide 1's ungradeability. It is a PRODUCT decision, not an
  instrument one. **Recommend DEFER until after the 19th and after cc's first compare** -- doing it now moves slide
  1's gradeability under everyone's feet and invalidates floors measured today. Owed, not urgent, nothing blocked.
- **SHOULD THE NEW SIDE BE CONTROLLED TOO?** A design question vc is deliberately keeping open. One control, on the
  reference; if the NEW build is noisier a real regression can sit inside the reference's floors unseen. Cost: a
  second 14-minute Chrome pass per build. **snorkeltoast has explicitly taken no position and neither has vc.**

### FYI -- no ruling wanted

- **`prez showreel build` needs `SHOWREEL_THEME_PATH`** where the Python needed nothing. H3 working, not a
  regression. A ruling only if hv wants the variable set somewhere permanent.
- **AN INTENT DEFECT, NOT A UTILZ ONE: `intent ac edit --text ""` DESTROYS A CRITERION SILENTLY.** vc hit it and
  lost AC-2.1's 16,839 characters at `c628c39`, recovered at `5d4d39e` and verified against the last good commit.
  A length guard is now in vc's path, which is discipline where a gate belongs.
- **Issue 0016** remains hv's WP-05 rider. No action.

## Claims

- **ST0017** -- the contract. cc also claims it. Not a conflict: claim-by-ST cannot express "vc validates, cc builds".

## Live with other nodes

- **`cc`: FOLDED AND HOLDING.** HEAD `0585f7b`, 273 tests, clippy 0, 43/51, pushed to `local`; `upstream` frozen at
  `60153d8`. Landed today: `serde_json` with hv named, the payload's non-slide half, the limits invariant, the
  producer stamp with its content and three red-proofs. **On the bounce their default is the slide rows then the
  build verb, and they take vc's sequencing over that default.**
- **`snorkeltoast`: FOLDED AND HOLDING.** WP-02 16/17, selftest green across nine case families, six expectation
  rows. **Zero compiler changes all day, deliberately.** Landed: the limits consistency check, the floors renderer,
  re-derived floors plus the first `control.json` that has ever existed, and `producer-fallback-strips`.
- **`laksa-vc`: SOLVED THE DEPLOY AND OWNS THE REMEDY'S OTHER HALF.** They read GitHub's delivery log -- the
  observable none of us could see -- and routed their own guard gap as a P0.
- **`intent-vc` / `devbin-vc` / `lamplight-vc` / `gtools-vc`:** consulted on the AC id form and TN001. gtools-vc's
  eleven-day hold on a Utilz WP-04 job is CLOSED: ST0010 completed 2026-09-07, 19/19 PASS, three criteria
  `computed` from ATs that actually run.

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

### THE FAMILY OF 10 SEP: AN INSTRUMENT REPORTING SOMETHING ADJACENT TO WHAT WAS NEEDED

**SEVEN INSTANCES IN ONE DAY ACROSS THREE NODES, AND EVERY ONE LOOKED CORRECT AT THE TIME.** cc's framing, and it
is the right one to head a fold with: the reading was never absurd, never sloppy, and never announced itself. It
answered a question ADJACENT to the one asked, and adjacency reads as an answer.

- **A MATCH RULE NARROWS A POPULATION SILENTLY.** Sweeping for uncalled `pub fn`, `name\s*\(` missed every
  function passed as a VALUE -- `flat_map(Slide::assets)` -- so 3 of 7 "dead" functions were live. **AC-3.8's own
  evidence refuted my measurement, because it cited `main.rs:123` by file and line.** The corrected rule then
  matched `fast_image_resize`, a CRATE name, as a test name. **Two rules wrong in opposite directions: the honest
  output is a BRACKET, not a number.** Same shape on the admission sites -- a bare identifier gave 9 by matching
  two doc comments; requiring the paren gave the true 7.
- **A CONTROL WITH AN EMPTY POPULATION IS NOT A CONTROL.** I claimed comment-exclusion as the control on that
  count and it excluded ZERO -- the paren did all the work. **A control returning zero needs a positive case
  proving it CAN return one**, and cc made the identical error with a strings census over a shell the linker had
  dropped. Neither of us built the positive case before quoting the result.
- **"VERIFIED INDEPENDENTLY" OVER A MULTI-PART CLAIM IS A CLAIM ABOUT THE WHOLE AND A MEASUREMENT OF A PART.**
  Twice to hv in two days, and **both times the half I highlighted as checked was the false one**: cc's
  field-order argument, refuted by their own 4.6; and "the lock is 79 by name AND by name+version", when it is 81
  entries against 79 names. **Both conclusions survived and both proofs did not** -- which is what makes it
  dangerous, because nothing downstream fails. **The tell is the word "independently": it did rhetorical work
  both times.**
- **A STAT IS NOT A DIFF.** `c628c39` emptied AC-2.1's 16,839 characters to nothing -- a heredoc raised, the
  scratch file was never written, `cat` failed, and `intent ac edit --text ""` accepted the empty string. I read
  `1 insertion, 1 deletion` and committed; the commit itself said 29 deletions. **Three guards available, all
  three defeated in one command, hours after telling cc to read the canon diff.** Recovered at `5d4d39e` and
  verified rather than assumed. **Any generated text that OVERWRITES gets a length assertion before the write.**
- **A CLAIM ABOUT AN INSTRUMENT UNDER ACTIVE EDIT HAS A SHELF LIFE OF MINUTES.** Three of us reasoned about
  `strip_reason` inside one hour and two quoted a version that had already moved. **A source read carries no
  timestamp, so a stale one and a live one are indistinguishable** -- the same property that makes a stale line
  number invisible, which is the lesson written in a comment two lines above the code we both misread. **RE-READ
  THE LOAD-BEARING LINE IN THE SAME CALL THAT WRITES THE CLAIM**, so no window exists. That saved AC-2.14 by
  accident, and accident is not a control.
- **cc'S TWO, SAME FAMILY:** an assertion SOURCING the constant it was testing (`embed={}` from `normalise::TARGET`
  -- both sides moved together and it stayed green, inside the test written to prevent exactly that); and a
  NEGATIVE assertion, `!e.message.contains("missing")`, which **passes on almost any failure**. Their rule is the
  best sentence of the day: **THE VACUOUS FORM IS THE ONE THAT LOOKS MOST RIGOROUS.** Writing the constant in
  looks like sourcing the value; typing `1920` looks lazy. It is the other way round.

### A NAME SET IS NOT A BUDGET, AND THE GATE THAT CHECKS NAMES STAYS GREEN THROUGH THE BREACH

**RULE: when a written budget is denominated in one currency, check the thing the currency is
denominated in, not the thing that is easy to enumerate.** AC-3.9's budget is denominated in
LOCKFILE PACKAGES. The obvious gate reads the `[dependencies]` keys, which is a different quantity
that usually moves with it.

**INSTANCE, MEASURED 2026-09-10 WHILE BUILDING AC-3.14.** Drop `default-features = false` from
showreel's `image` line and the dependency NAME SET is byte-identical -- nine names before, nine
after, `diff` empty -- while the budget goes from five decoders to every decoder in the crate, +35
packages. A name-set gate is green the whole way through. So the gate asserts the whole normalised
LINE for every entry, and its brittleness to cosmetic edits is the feature: any change returns to hv,
which is what AC-3.9 already said in words.

**AND IT IS THE SAME FAMILY ONE TABLE UP.** The name set is not wrong; it is ADJACENT -- it reports a
real quantity that is not the one the rule is about, and it looks exactly like coverage. That is the
seventh instance's shape, found while building the instrument that closes the sixth.

**MECHANICAL TEST FOR THE NEXT ONE: read the rule's own words for its unit.** "Carries exactly the
budget" is denominated in whatever the budget counts. If the gate counts something else and they
usually agree, find the case where they do not before shipping it -- there was one here and it took
one `sed` to produce.

### ASK THE ARTIFACT: a rule fixed in advance is wrong the moment two artifacts differ

**snorkeltoast's, earned TWICE in one day in two different tables, and the correction was the same sentence both
times.** _"Every payload must carry `limits`"_ would have refused the sound PUBLISHED build, which carries no
`limits` key, embeds the old player and applies the floors inline. _"A session crawl is unstrippable"_ would have
reported a false ungradeable on cc's artifact, whose player drops the brand fallback so the row genuinely strips.

**BOTH ARE WORSE THAN THE BLIND SPOT THEY REPLACE.** A blind spot fails to catch a defect; these remove a sound
artifact and a gradeable slide from consideration quietly, **with a reason attached that reads as diligence.**

**THE TEST, THEIRS, AND IT IS MECHANICAL: IF THE QUESTION NEEDS A POLICY, A VERSION TABLE, OR AN AGREEMENT BETWEEN
TWO SESSIONS, IT IS BEING ASSERTED RATHER THAN ASKED.** Both halves ship in the same file; both were answerable
from the artifact alone. The sound forms retire themselves -- the `limits` check stops asking when a player gains
a guard, and `producer-fallback-strips` predicts nothing the day the reference drops its literal, **proved by
pointing the predicate at cc's file and getting zero sites** rather than by claiming it.

### I cited my own row as authority, and its analogy contradicted its claim

**AC-4.1 said: "the ABSENCE of that stamp derives (2) -- exactly as the absence of a producer stamp already
derives adjacency (UNVERIFIED)". `adjacency (UNVERIFIED)` IS A REFUSAL TO DERIVE.** So the sentence cited a
refusal-to-derive as the model for a positive derivation. **"Exactly as" did the work of an argument without being
one**, and the analogy pointed the other way from the thing it was supporting.

**I WROTE THAT SENTENCE, AND THEN QUOTED IT TO cc AS ESTABLISHED SHAPE.** That is the trap and it is worse than the
error: **self-citation launders an assertion into a precedent.** A row I authored became, hours later, a thing I
cited rather than a thing I was still responsible for -- and the citation carried more weight in the second
conversation than the claim had earned in the first.

**snorkeltoast CAUGHT IT FROM THE QUOTE, WITHOUT HAVING READ THE ROW**, and said so: _"I may be reading a shorthand
as a claim."_ **The quotation was easier to falsify than the row**, because it arrived without the surrounding
paragraphs that made it feel settled. So: when a peer quotes your own work back at you, read it as a stranger
would. And when you cite a row, check whether you are citing evidence or your own past confidence.

The mechanism survived and the justification did not, which is the honest split -- **but nothing about the code
would have revealed it**, because absence semantics live in the harness and were already right.

**AND THE PROPAGATION COUNT IS THE PART THAT MAKES IT MORE THAN A MESSAGE-LEVEL ERROR.** cc took the withdrawn
sentence and put it in **three** places -- `design.md` 4.5, section 5's row, and `template.rs`'s module doc -- and
corrected all three at `0155150` by going looking rather than patching where I pointed. **A cited assertion does
not stay in the conversation it was cited in.** It lands in code comments and design documents, where it reads as
settled because it arrived as a citation, and the author of the original sentence is the last person who will
recognise it.

### `git commit --only` does not reach a file that two nodes both write

**`intent/.canon/st/ST0017.json` is ONE file carrying vc's criteria AND cc's design.md attachment.** My AC-3.2
grading commit took cc's attach text with it -- exactly as cc predicted before I read their message. Nothing was
lost (doctor 0 IS the attachment-drift check, and it is green), but the point survives the clean outcome.

**We have both been trusting `--only` as the guard against sweeping a peer's work, and it guards against sweeping
other FILES.** On the one file where two writers genuinely collide it is silent. That is not a rule either of us
broke; it is a rule that does not reach, which is the harder kind to notice because compliance feels identical.

**Convention proposed to cc and adopted here: whoever commits canon NAMES IN THE MESSAGE what else rode along.**
Cheap, and it converts a silent collision into a visible one. Applied at `12a606d`, which carries only my own edit
and says so.

### An ask creates a tracked condition on the RECEIVER and nothing on the ASKER

**gtools-vc carried a hold for ELEVEN DAYS whose condition was a message from me. My board carried nothing at
all** -- gtools-vc was not in "live with other nodes", there was no outbound-obligation entry, and nothing on my
side would ever have fired. Meanwhile this project completed the work internally and closed the thread.

**The asymmetry is the bug, not the forgetting.** A hold has a condition the waiter can check at every pickup, so
the receiver's bookkeeping is sound and self-checking. The asker's side has no corresponding structure, so **the
only mechanism that closes a stale ask is the waiter eventually asking** -- which is what happened, after eleven
days, and only because they were disciplined enough to challenge their own hold rather than keep carrying it.

**THE RULE: an outbound ask to another project gets an entry on MY board naming what I owe and to whom, or it does
not get sent.** This is the hv-inbox problem pointed the other way -- there the write had no named reader; here the
ask had no tracked ower. Both fail silently, and both are invisible from the side that succeeded.

## Decisions that still decide things

- (2026-09-10) **ITEM 1 CLOSED ON THE ARTIFACT AND THE CAUSE IS CONFIRMED: IT DEPLOYED BY HAND.** Build 009 is
  live -- verified three ways across three observers: vc's byte hash, snorkeltoast's independent hash PLUS a
  payload parse, and hv seeing it render. **But laksa-vc's delivery log shows 401 at `07:53:07Z`, no delivery
  since, and `last_response` unchanged.** hv ran a manual force resync, which bypasses the webhook entirely.
  **The automatic path is exactly as dead as it was this morning.**
- (2026-09-10) **THE CAUSE WAS WORTH CHASING AFTER THE GREEN, AND snorkeltoast REFUSED TO LET IT COLLAPSE.** Knowing
  it deployed is not knowing why. Had artifact and cause been ticked as one, this would have been filed fixed and
  the next failure would have arrived looking like a new bug -- **a green outcome with an unconfirmed cause is a
  bug with a quiet period.** The clone-side fix IS deployed, incidentally proven by the resync scanning 80 files.

- (2026-09-10) **hv RULED THE ORDER, NOT THE CRATE.** Rebuild for the QR social FIRST, while cc is blocked, then
  `serde_json`. **A sequencing choice is NOT the named sign-off the manifest requires**, so cc's hold stands and vc
  went back for the actual ruling rather than passing an ordering off as an answer -- the "rock on as needed" shape
  one turn later, pointed at vc instead of at cc.
- (2026-09-10) **THE QR FIX IS THE EVENT REBUILD IS THE FLOORS RE-DERIVATION -- ONE ACTION, NOT THREE.** They sat on
  three boards all day. `showreel build` makes a NEW reference artifact, which retires FLOORS.md by its own header,
  which triggers snorkeltoast's 14-minute control. **cc being blocked is what makes now the free window**, because
  the floors are the REFERENCE's (`showreel-harness:1943`) and hang off hv's rebuild, not cc's build.
- (2026-09-10) **vc HELD AC-5.3 RATHER THAN ASKING.** Genuinely JSON-free and not startable -- no showreel manifest,
  no `bin/` symlink, `common.sh` silent -- so it needs WP-05's dispatch shape first. Opening WP-05 at WP-03 10/12 to
  fill an idle hour is inventing adjacent work. hv told, hv can overrule.
- (2026-09-10) **vc IS NOT TREATING THE SEQUENCING AS AUTHORITY TO PUBLISH.** The QR fix's `cp` half puts a new
  artifact at a published address nine days before a live event. Build and control freely; the `cp` waits on hv
  saying that word specifically.

- (2026-09-09) **vc: take cc's `Stem`, AND refuse a pattern without exactly one `{nnn}` -- the inverse of the control vc withdrew an hour earlier.** Measured at the reference: `str.replace` (`showreel:550`) and `re.escape(stem).replace` (`:534`) both replace ALL occurrences, so `{nnn}-foo-{nnn}` yields `001-foo-001` and a two-group scanner regex. A prefix/suffix `Stem` from `split_once` leaves the SECOND `{nnn}` literal in the filename. **The reference handles it and the split structurally cannot**, so here the chosen implementation CREATES the hazard where the withdrawn control guarded one that was already structurally absent. Zero `{nnn}` is refused by the reference at `:532`/`:547`, so the check is exactly-one.
- (2026-09-09) **vc: `bug.file` is a PREDICTION for the delivery slice, not a defect today, and the reference was checked first.** `plan.rs:143` joins it unclassified while four `Requires::Image` sites refuse -- but the reference DOES refuse it, `build_bug` at `showreel:797` dying by name on a missing file (`:809`) and on a declared bug with no file (`:806`). Not a gap yet because the port has no bug embed path; it becomes one the moment delivery embeds without refusing. **Recorded before the code, because the identical sentence after it is a rationalisation.**

- (2026-09-09) **vc: GO on the template pull, and it is a TWO-row commit, not three.** vc told hv three -- AC-3.6's runtime leg, AC-6.1's leg 3, AC-3.7's drop -- and **AC-6.1 leg 3 is wrong**: it discharges when `prez showreel build` EXISTS and the warning is driven through it, and the build verb completes at DELIVERY. Corrected to both hv and cc. **AC-3.6 is verified at SOURCE in that commit and NOT satisfied there**: "derives" is a claim about what runs, and the red-control (flip `MAX_EASE_MS` to 3000, the payload must follow) needs a build to emit a payload. Three two-leg rows have already cost this contract; this is not the fourth.
- (2026-09-09) **vc: a marker-uniqueness control is necessary and not sufficient.** cc proposed "four markers each occurring exactly once" as proof a single-pass substitution equals four sequential replaces. It equals it **only if no replacement's OUTPUT contains a later marker** -- sequential can rewrite its own output and a single pass cannot. Two assertions, not one: each marker occurs exactly once in the template, AND no substituted value contains any marker.

- (2026-09-09) **vc: cc's used-set finding is AC-3.2's, and it was inside no SENTENCE of AC-3.2 -- one clause added, no row minted.** The clause named `report_unused` and never named its input, so the finding was a judgement two nodes held and the contract could not fail on. **The build's used set is a projection of the PLAN, not of the slide list**: cc measured the reference's `plan()` at fourteen used assets, ten per-slide and four reel-level, and the ten match `Slide::assets()` by name. A slide-derived `report_unused` names four files the build embeds and tells the operator to delete them -- a confident wrong instruction to destroy live inputs, not a missing warning. **AC-3.8 was NOT reopened and the error in it was mine**: the row's property (one walk) holds and improves once the plan is the source; what was false was a sentence in MY evidence claiming the recycler reads exactly what the build read. Evidence corrected through unsatisfy/satisfy. `982e7f0`.
- (2026-09-09) **vc: AC-3.6's runtime leg closes on two SOURCE checks, and that is the only mechanism rather than the neatest one.** `player.html:561` is `const LIM = REEL.limits`, so the cap comes off the payload; and snorkeltoast's `shipped-max-ease` row is kind **BLIND** -- `signature()` walks `payload['slides']` only and `capture` never passes `pace=`. So the harness predicted the difference AND predicted its own blindness to it. The leg is: the emitted payload's `limits.max_ease` DERIVES from `limits::MAX_EASE_MS`, and the pulled template still reads `LIM = REEL.limits`. **No `pace=ambient` capture arm** -- it would photograph a divergence already predicted, chosen and recorded, on a fixture built for the purpose. Same shape as AC-4.1's stamp.

- (2026-09-09) **vc: cc's WP-03 order STANDS; both proposed reorderings refused.** hv sent cc to vc for sequencing.
  **Do not build early to unblock AC-6.1 leg 3, AC-2.1 leg 2 and AC-5.1 -- those three rows are vc's, on vc's
  contract, and reordering cc's engineering so vc's scoreboard moves sooner is optimising the measurement instead of
  the thing.** The independent engineering argument agrees: a `build` emitting a knowingly-incomplete artifact feeds
  the harness differences that are NOT in `PORT_EXPECTATIONS`, every one lands as an unpredicted STRUCTURAL MISMATCH,
  and the instrument becomes noise **at exactly the moment its value is highest** -- after which harness red reads as
  "we are not done yet" and a real regression is invisible. **And do not pull AC-3.7's `|| "Snorkeltoast"` drop
  forward**: the 21-to-22 gradeability gain cannot be realised until there is an artifact to grade, and there cannot
  be one until the template is pulled, which is the commit the drop belongs in. vc had said "take it early" and was
  wrong about where early is.

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
