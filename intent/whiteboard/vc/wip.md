---
node: vc
name: Validation Claude
role: validation
session_id: 11981560-5612-4fe7-a136-6eae64636b64
heartbeat_at: 2026-09-10 17:22Z
status: active
focus: "ST0017 47/52, doctor 0. hv released BOTH gated items -- snorkeltoast is running the fidelity compare (299 renders, AC-2.1 the only open row it grades) and landing the two-row flip. cc parked. WP-04 NOT read as opened; hv told that is my reading."
claims: [ST0017]
---

# Validation Claude (vc)

Validation node. cc builds, vc contracts and verifies, hv adjudicates. Full boards for 8 Sep in `.history/20260908/`, for 9 Sep in `.history/20260909/` (`wip-before-localfold-2.md` is the 30389-byte pre-fold original). **This board keeps ONE statement of each rule with the instance that earned it, not the day's narrative** -- and after hv's scope call, only rules that change what gets BUILT.

## DOING

**ST0017 -- showreel hoisted under `utilz prez showreel`. vc holds the contract, cc builds, snorkeltoast owns the
harness and the reference, hv adjudicates.** Localfolded 2026-09-10 08:45Z; 10 Sep narrative in `.history/20260910/`.

- **CONTRACT 47/52, 3 withdrawn, `intent doctor` 0 -- MEASURED 2026-09-10 17:19Z, not carried.** WP-01 DONE.
  WP-03's rows are all closed. Open: AC-2.1 (the compare, running), AC-3.4 / AC-4.1 / AC-4.2 (WP-04), AC-5.3 (WP-05).
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
- **THE COMPLETION METRIC IS DISCHARGED AT `8bef628`, AND MY OWN WORDING FOR IT WAS THE WEAKER PREDICATE.** All
  four now have production callers AND their results are read: `template::render` at `build.rs:193` into `html`,
  written at `:215`; `deliver::stamp` at `:176` into `date`, consumed by `deliver::stem` at `:202`;
  `deliver::prune` at `:232` into `(drop, warn)` -- `drop` iterated and unlinked, `warn` drained into `said`;
  `normalise::embed` at `payload.rs:166/305/338` into the payload. **I wrote the metric as "acquire a CALLER",
  and cc flagged that a warning channel needs "is its RESULT READ" -- which is AC-3.2's own finding, three days
  old, about `admit::Scan::report` passing a caller sweep while its caller discarded the result.** My metric would
  have passed exactly that. **The rule I minted was written in the form the row had already refuted.** Both
  predicates applied here; the second is the one that has teeth.

## TODO

- **THE 45h BUILD HAS RUN AND TWO OF ITS THREE ROWS ARE CLOSED -- THIS WAS A PREDICTION AND IS NOW MOSTLY A
  MEASUREMENT.** As at 2026-09-10 17:22Z. **AC-5.1 and AC-6.1 are SATISFIED** (`f2046f9`), both driven by me
  through both command forms rather than taken from cc. **AC-2.1 leg 2 is the only part still owed**, and it is
  observed inside `capture()`, which is snorkeltoast's run. **F2 = 23 held**: the build reports 23 slides from
  15 segments, matching the reference's own `plan()`. Both peers were told before it happened, which was the
  standing commitment. **Read the first `compare` as population (2): a green over half a pipeline.**
- **DISCHARGED 2026-09-10 17:22Z: `producer-fallback-strips` VERIFIED AGAINST THE HARNESS AS IT WILL BE AT
  COMPARE TIME.** My own condition and it is met, not waived. **snorkeltoast pinned the harness to BYTES** --
  sha256 `f58829961dd7...`, 144,465, which I re-hashed at the file rather than taking -- and established that
  neither named change route touches `strip_reason`. **Measured in both directions:** the probe returns 1 on
  both reference-built artifacts and 0 on a port-built one, with cc's positive control firing. **The prediction
  it carries -- 23 gradeable against the reference's 22 -- is still a PREDICTION**, because it is observed at
  capture and capture has not returned.
- **STANDING: TELL hv WHEN TO FORCE A LAKSA RESYNC.** Fires on anything published into the site repo -- in
  practice snorkeltoast promoting a build into the `-001` slot. **AND THE VERIFICATION IS TWO COMPARISONS, NOT
  ONE -- CORRECTED 2026-09-10 09:24Z BEFORE IT EVER RAN IN ANGER.** The recorded method was _fetch the served
  bytes, hash them against what was BUILT, and read the payload_, and **it would have reported a false alarm on
  the reel that is live right now.** `_out` and the site repo's `19e3f3f` hash identically at `ae90d9e8...`; HEAD
  is `096a676`, ONE BLANK LINE inserted between `<head>` and `<meta charset>`, and **production serves that** --
  `c38fbc53...`, etag `c38fbc533984cf1ade2430f854a107fa`, its first 16 bytes. Production is CURRENT and the old
  check calls it stale. **SO: hash the served bytes against THE SITE REPO AT HEAD -- that is the deploy question;
  and SEPARATELY diff `_out` against the published slot -- that is the promote question.** One comparison was
  answering neither cleanly. Reading the payload stays, because hash equality says nothing about correctness.
- **DONE 2026-09-10 09:54Z: `favicon-missing` AND `font-not-woff2` ARE OBSERVED, AND MY CONDITION FOR THEM WAS THE WRONG
  ONE.** I had written that they flip _"when cc's build path calls the theme loader"_. **I read snorkeltoast's
  `unobserved` field -- which answers "why could this not be observed" -- as if it answered "what would
  SUFFICE to observe it".** Adjacent field, plausible value, wrong question. The loader running was never the
  condition; a fixture that trips each refusal was, **and the refusals turned out to have been implemented for
  some time** (`theme.rs:262-271` and `:189-191` via `read_asset` at `:172-179`). Driven with a PASSING
  CONTROL -- real popupart rc=0 "is valid"; a declared-but-absent favicon rc=2 refused by name; a `.ttf` in
  `fonts[]` rc=2 refused by name with the fontTools command in the remedy. **Without the control a refusal for
  an unrelated reason is indistinguishable from the one under test.** Reported to snorkeltoast; their entries,
  their edit. Nothing written into their tree.

## Holds

- **WP-04 CONDITION -- AN ENUMERATION, NOT A PATTERN, WHICH IS cc'S SETTLING MOVE AND IT REPLACES MINE.** The
  fixture recipe's safety rests on the port having no write path into a reel directory outside `_out`.
  **BASELINE, VERIFIED: production code calls SEVEN `fs::` functions and exactly THREE of them write** --
  `create_dir_all` 1, `write` 1, `remove_file` 1, all in `build.rs`; and `read_to_string` 4, `metadata` 3,
  `read_dir` 2, `read` 2, which do not. `grep -n 'join("_out")' build.rs` returns ONE production hit, the only
  reel-derived write target. `pdftoppm` and `".raster"` appear nowhere in either crate. **TRIGGER: an eighth
  function, a fourth write site, or any write whose target is not derived from `_out`.** WP-04's init trips it.

      for f in <port>/src/*.rs; do t=$(grep -n '#\[cfg(test)\]' "$f" | head -1 | cut -d: -f1); t=${t:-999999}
        awk -v t="$t" 'NR<t' "$f" | grep -oE 'fs::[a-z_]+'; done | sort | uniq -c | sort -rn

  **WHY AN ENUMERATION AND NOT THE TIGHTENED REGEX I HAD: WHEN TWO MATCH RULES DISAGREE, THE ANSWER IS USUALLY
  NOT A THIRD MATCH RULE.** cc and I counted one crate and produced FOUR honest numbers -- 43 and 36 flat, 3 and
  8 filtered. I answered with a better pattern; cc stopped tuning and listed what the code actually calls.
  **A pattern answers "does this line match a rule I chose"; an enumeration answers "what does the code call",
  and someone who does not share my rule can audit the second.** My tightened pattern and cc's original produce
  identical numbers -- **and only because this crate calls neither `fs::copy` nor `fs::rename`, which I checked
  rather than banked.** Mine catches them, theirs would miss them silently, and on this crate that difference
  is invisible.

- **AND THE FOUR NUMBERS CAME FROM ONE LOST PAIR OF PARENTHESES: `fs::(write|create_dir|remove)` GROUPS THE
  PREFIX AND `fs::write|create_dir|remove` BINDS IT TO THE FIRST ALTERNATIVE ONLY**, so a bare `remove` matches
  `format!("cannot remove {}: {e}")`. Grouped: flat 43, filtered 3. Ungrouped: flat 52, filtered 8. **The
  pattern that ARRIVED in cc's message had no parentheses and I ran what arrived and quoted it back unchanged;
  cc says their shell had them.** I cannot see their shell and **will not assign the loss to either end -- that
  would be the wrong-cause error a third time, about a peer, in my own favour.** What is checkable: **the only
  channel between the two shells is a prose message, and the structure did not survive it.**
  **RULE: A REGEX IS CODE, AND QUOTING CODE IN PROSE LOSES STRUCTURE SILENTLY.** Parentheses, escaping and
  whitespace all go without a diagnostic -- the same family as the whiteboard header guard's escape problem.
  **Send the command, or send the ANSWER; a pattern re-typed into a sentence is a different pattern.**
- **AND I FILED THE WRONG CAUSE FOR IT BEFORE ASKING -- MY OWN RULE, TWICE IN ONE DAY.** I wrote up "cc quoted
  an unpinned pattern". The better and more general finding is theirs: **a pattern does not survive being
  re-typed into a message.** cc declined to score it and said they would rather I kept going than got careful,
  which is the right instinct and does not make the instance less mine.
- **TELL hv WHEN TO FORCE A LAKSA RESYNC -- hv'S STANDING INSTRUCTION, 2026-09-10.** CONDITION: anything published
  into `~/Devel/prj/Sites/snorkeltoast` that must reach production, in practice snorkeltoast promoting a build into
  the `-001` slot. **The webhook is still 401: a push publishes nothing AND SAYS NOTHING**, and Laksa's own health
  check reads "secret present" as "webhook configured", so it reports the site healthy throughout. The resync is
  not a fallback, it is the only path. **A push nobody follows with a resync is a publish that did not happen.**
- **AC-5.3, HELD ON vc'S OWN CALL and cc agrees.** Genuinely JSON-free and genuinely not startable: no showreel
  manifest, no `bin/` symlink, `common.sh` silent on showreel. CONDITION: **WP-05's dispatch shape decided.**
  Opening WP-05 while WP-03 was at 10/12 (AS AT 2026-09-10 MORNING) to fill an idle gap is inventing adjacent work. hv can overrule.
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

- **`cc`: PARKED, NOTHING OWED, NOTHING IN FLIGHT.** As at 2026-09-10 17:19Z. Landed today: `serde_json` with hv
  named, the payload and the slide rows, the build verb, the `round_ties_even` fix, and four self-caught reading
  errors corrected in their own words rather than edited away. **They will not open WP-04 or WP-05 without hv
  sequencing it, and that is their call and it is right.**
- **`snorkeltoast`: FOLDED AND HOLDING.** WP-02 16/17, selftest green across nine case families, six expectation
  rows. **Zero compiler changes all day, deliberately.** Landed: the limits consistency check, the floors renderer,
  re-derived floors plus the first `control.json` that has ever existed, and `producer-fallback-strips`.
- **`laksa-vc`: SOLVED THE DEPLOY AND OWNS THE REMEDY'S OTHER HALF.** They read GitHub's delivery log -- the
  observable none of us could see -- and routed their own guard gap as a P0.
- **`intent-vc` / `devbin-vc` / `lamplight-vc` / `gtools-vc`:** consulted on the AC id form and TN001. gtools-vc's
  eleven-day hold on a Utilz WP-04 job is CLOSED: ST0010 completed 2026-09-07, 19/19 PASS, three criteria
  `computed` from ATs that actually run.

## Watch-outs

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
- **THE HARNESS WE GRADE WITH IS IN THE POPULATION, NOT OUTSIDE IT -- cc'S, AND THE SHARPEST OF THE DAY.** Their
  injection applier proved a mutation had landed with `assert after.count(old) == 0`, which is invalid whenever
  the replacement CONTAINS the anchor -- every append-style injection. **The check fires on the applier's own
  success**, so injection 1 raised inside the `try`, the `finally` reverted, and nothing landed. Corrected to:
  assert the file CHANGED and the new text is present, and claim "anchor gone" only when the anchor is not part
  of the replacement. **My eight manifest probes pass the same test only by luck of shape** -- a `sed` that
  matched nothing yields a GREEN, not a false RED, because a clean file produces no failing assertion to misread.
- **A FIELD ADJACENT TO THE ANSWER, IN THE FILE WE BOTH READ FOR ANSWERS -- cc'S, WITH THEIR NAME ON IT.**
  Checking a claim of mine, cc walked the canon for AT03 and printed `x.get('state')`. It returned `None`, which
  reads exactly like "AT03 has no state, vc is wrong" -- and **the key is `status`, not `state`.** Verified at the
  committed canon: an AT row's keys are `covers,file,id,kind,status`, with no `state` at all. **`dict.get` ON THE
  WRONG KEY IS A SILENT ZERO, AND A SILENT ZERO THAT AGREES WITH YOU IS THE DANGEROUS KIND** -- cc's sentence, and
  they caught it only because `None` was too convenient. The criterion rows next door DO carry `state`, which is
  what makes the wrong key plausible; and `state.is` on those reads `computed`, which is provenance sitting where
  a verdict would sit. **THE VERDICT IS WHAT THE CLI COMPUTES; THE CANON FIELD IS WHERE IT COMPUTES IT FROM.**
- **A RECORDED INSTANCE WITH THE WRONG CAUSE TEACHES THE WRONG GUARD, AND I FILED ONE TODAY.** I read cc's "AC-3.14
  is `satisfied: no`" as them reading `state.is` raw, and wrote it up that way. **It was not.** They ran
  `intent ac list`, which was RIGHT when they ran it: the store had no AT03 yet, and I created it across their
  eight-minute-old read. The guard my version implied is "read the computed answer, not the raw field"; the guard
  they actually needed is **RE-READ IN THE SAME COMMAND THAT WRITES THE CLAIM** -- their own watch-out, written
  yesterday, violated the same day, with the STORE in place of the harness. **A plausible cause is not a measured
  one, and the whole value of an instance is the guard it points at.** Ask the party that made the error before
  writing down why they made it.
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

### NAME WHAT YOU INCLUDE. AN EXCLUSION LIST DECAYS IN THE DANGEROUS DIRECTION

**RULE: A SET-MINUS IS A RULE FIXED IN ADVANCE ABOUT WHAT A DIRECTORY CONTAINS, AND EVERY FUTURE ENTRY JOINS
IT BY DEFAULT, SILENTLY.** My fixture recipe said _symlink every entry of `45h/showreel` EXCEPT
`showreel.yaml` and `_out`_. That directory also holds `.raster` -- mode `drwx------`, the compiler's PDF
raster cache, a directory that gets WRITTEN -- and `.DS_Store`. **Following my text literally symlinks a
private write cache into snorkeltoast's tree**, which is a wider hole than the one excluding `_out` closed.

**AND THE MECHANISM IS THE FOURTH KIND OF ZERO IN ITS PUREST FORM: THE SHELL PROTECTED ME AND I WROTE DOWN
THE RULE IT WAS NOT FOLLOWING.** My loop was `for a in "$REEL"/*`, and the zsh glob EXCLUDES DOTFILES BY
DEFAULT. I did not decide to exclude `.raster`; I never saw it. **Measured after: `reel-goodcopy` holds
exactly two entries, one symlink to `assets` and a real `showreel.yaml`.** So what I RAN was safe and what I
DOCUMENTED was not, and nothing in the run could have told me -- the instrument narrowed the population and
the write-up described the instrument I thought I had.

**SECOND CORRECTION, AND IT IS THE ONE THAT MATTERS MORE: MY PROTECTION WAS REAL AND MY REASON FOR IT WAS
FALSE.** I said the symlinked assets were _read-only from the fixture's side_. **The target is writable** --
a symlink is a two-way door, not a barrier. What actually protects the tree is that `check` writes nothing
and `_out` was never linked, so a `build` lands in scratch. **A reproducer leans on the stated reason the
moment they change the verb**, which is exactly when a false reason costs something.

**AND A DATE ON THE HAZARD, MEASURED RATHER THAN LEFT GENERAL:** `.raster` is written by the REFERENCE at
`showreel:354`, and the PORT has NO `.raster` write path today -- every "raster" hit in its source is prose
in `admit.rs` refusing documents. **So the hole is unreachable by today's port and reachable by the
reference now and by the port the moment WP-04 lands**, since init is the verb that shells out to
`pdftoppm`. **A recipe outlives the version of the tool current when it was written**, so a rule safe only
against today's verb set is the same defect as the exclusion list itself.

### A PATH IS AN IDENTIFIER; THE FIXTURE IS THE THING -- AND A RECIPE NOBODY RAN IS AN UNOBSERVED FIELD

**RULE: EVIDENCE RECORDS THE RUN CONDITION AS FACT AND HANGS REPRODUCTION OFF A RECIPE, NEVER OFF A PATH.**
My fixture root was `/private/tmp/.../<session-id>/scratchpad/vc-themes/themes`. **That session id outlives
nothing** -- when the scratch is cleaned the path resolves to nothing and the evidence line becomes
unreproducible SILENTLY, exactly the way a stale `unobserved` goes stale. snorkeltoast's framing, and it is
the third instance of one shape: **the path is an identifier, the fixture is the thing** -- same failure as
`player.html:613` decaying to `:628` and same failure as `control.json`'s `artifact_sha256` naming the
artifact that was GRADED while a reader takes it for the one SERVED.

**AND THE REMEDY GOT THE REMEDY'S OWN TREATMENT: I RAN THE RECIPE RATHER THAN READING IT.** Fresh
`mktemp -d`, nothing reused, all three outcomes identical -- goodcopy rc=0 `is valid`, nofavicon rc=2 on the
favicon, ttffont rc=2 on the Bangers `.ttf`. **A recipe nobody has run is the same class of claim as an
unobserved field**, which is snorkeltoast's own rule turned on snorkeltoast's own fix.

**RUNNING IT IS WHAT FOUND THE GAP: THE RECIPE STATED THE THEMES AND NOT THE REELS.** Three fixture themes
with nothing to check them against produce nothing. The missing fourth step is the one carrying the assets
-- a reel per theme, symlinking every entry of `45h/showreel` except `showreel.yaml` and `_out`, with the
config rewritten one line. **A recipe that is 75% complete reads exactly like a recipe.**

**COROLLARY ON DURABILITY, MEASURED RATHER THAN ASSUMED: the recipe's INPUTS are already durable**
(`themes/popupart` and `45h/showreel` both live in snorkeltoast's tree). Only my COPY was ephemeral --
**and the recipe is precisely what makes the copy not worth keeping.** So no durable fixture home is needed
and none is being asked of hv; noted to them as an FYI rather than a third decision, because two decisions
wanting one word must not be diluted by a nice-to-have.

### A CONTROL THAT SHARES THE REAL PATH IS NOT A CONTROL OVER THE FIXTURE MACHINERY

**RULE: THE CONTROL MUST DIFFER FROM THE TEST IN EXACTLY THE ONE THING UNDER TEST, AND "REAL" IS NOT THE
SAME AS "IDENTICAL BUT FOR THAT".** My first control for the two theme refusals was the REAL popupart theme,
in its real location, driven against the real 45h reel. It proves the config reads and parses -- which is
what rules out the two refusals that fire in `open()` BEFORE the theme is touched (`read_to_string` and
`config::parse`, snorkeltoast's correction of my "nothing runs before the theme" overstatement). **It does
NOT rule out my own copy-and-symlink machinery having broken something**, because it never went through it.

**FIXED BY BUILDING A THIRD FIXTURE RATHER THAN ARGUING THE POINT:** `goodcopy`, an unmodified copy of
popupart through the SAME copy, the SAME symlinked reel, the SAME rewritten config and the SAME theme root.
rc=0, `is valid`, 15 segments, 23 slides, 14 assets, 4 socials. **Now everything is held identical but the
one mutation, and the two rc=2s are attributable to it alone.**

**AND THE FALSE-CONFIRMATION RISK snorkeltoast RAISED IS REAL AND NARROWER THAN EITHER OF US FIRST SAID --
MEASURED, NOT REASONED.** Without `SHOWREEL_THEME_PATH` a fixture reel returns rc=2 from a theme function
about a theme, which they called the wrong refusal passing as the right one. **Driven: the message is
`no theme 'nofavicon'.` and lists the directories it did not search.** The two messages share no word but
"theme". **So a reproducer comparing the MESSAGE cannot be fooled and one comparing the EXIT CODE can.**
The clause belongs in the evidence line, and what it defends against is not a disguised alarm -- it is an
evidence line reproducible by exit code alone. **An evidence line that rc alone can satisfy is
under-specified; quote the message and the ambiguity closes itself.**

### A PREDICTION THAT CAME TRUE IS NOT A PREDICTION, AND A SECTION LABEL DECAYS TOO

**RULE, cc'S: A SECTION WRITTEN ENTIRELY IN THE FUTURE TENSE BECOMES UNREADABLE IN BOTH DIRECTIONS ONCE PART
OF IT HAS HAPPENED** -- you cannot tell what is still owed. They found it on their own "what the first
compare is expected to show", where the structural half had run and returned zero, the strippability
precondition was measured, and only the 23-of-23 outcome remained predicted. **Three states wearing one
tense.**

**APPLIED HERE RATHER THAN AGREED WITH, AND MY TODO HAD TWO.** _"The first build pointing at 45h grades
AC-2.1 leg 2, AC-5.1 and AC-6.1 leg 3 in one pass"_ -- **two of those three closed at `f2046f9` and the line
still read as future.** And _"VERIFY `producer-fallback-strips` against the harness as it will be at compare
time"_ -- **discharged**: snorkeltoast pinned the harness to bytes, I re-hashed it at the file, and the probe
is measured in both directions. **An imperative left standing after it is satisfied is a claim that work is
owed when it is not**, which costs a reader exactly as much as a stale number.

**AND A THIRD THING I FOUND WHILE LOOKING, WHICH IS NOT cc'S AND IS ITS OWN CLASS: THE SECTION LABEL HAD
STOPPED DESCRIBING THE CONTENTS.** My `## TODO` had accumulated a promote-path FINDING and a
plausible-cause FINDING -- neither of them work anybody was going to do. **Findings belong in Watch-outs;
TODO is queued work.** Moved, not copied. **A heading is a claim about everything under it**, and it rots the
same way a number does, silently, while every individual entry beneath it stays true.

**THE COMMON SHAPE OF ALL THREE: THE ENTRY IS RIGHT AND ITS FRAME IS WRONG.** Tense, label, or clock -- the
container makes an assertion the contents no longer support, and nothing checks a container.

### A NUMBER IN PROSE HAS NO EDGE TO THE THING IT NAMES, AND PEER-STATE HAS THE SHORTEST HALF-LIFE OF ALL

**RULE, cc'S, EARNED ON THEIR OWN BOARD: A CLAIM CAN BE MEASURED, CORRECT AND SPECIFIC WHEN WRITTEN AND ROT
IN PLACE, AND NO GATE ANYWHERE CAN SEE IT.** Their board carried showreel's release binary at 535,968 --
right when taken, _"up 16 bytes from 535,952"_, that specific. **Re-measured this evening: 1,981,888. Stale
by 3.7x**, through four commits that all touched showreel. Not sloppiness; **a number in prose has no
dependency edge to the binary it names.** The load-bearing half survived and they said so as loudly as the
correction: **prez is UNMOVED at 4,384,912, which is the whole of AC02** -- verified by me in one command
across both binaries.

**SO I SWEPT MY OWN BOARD FOR CURRENT-STATE NUMBERS RATHER THAN AGREEING WITH THEIRS, AND FOUND THREE.** The
DOING header said **`CONTRACT 43/51 ... WP-03 10/12`** when it is 47/52 with WP-03's rows all closed -- **the
most-read line on the board, stale.** A decision rationale cited `WP-03 10/12` as if current when it is the
reason a MORNING call was made. And the peer-state section had cc at _"FOLDED AND HOLDING, HEAD 0585f7b,
273 tests, 43/51"_ -- **wrong on four counts at once.**

**AND THE THIRD ONE IS STRUCTURAL RATHER THAN CARELESS: A SECTION DESCRIBING A PEER'S STATE HAS THE SHORTEST
HALF-LIFE OF ANYTHING ON A BOARD.** It is cc's rule one step further out -- **not only no dependency edge to
the thing it names, but no edge you could ever build**, because the thing is another session's tree and
nobody notifies you. `Live with other nodes` is the highest-rot surface I keep. **Every entry in it now
carries the clock reading it was true at**, which does not stop the rot and does stop it being read as
current -- the same move as dating a historical figure instead of deleting it.

**COROLLARY THAT DECIDES WHICH NUMBERS ARE ALLOWED TO SIT: A NUMBER ABOUT A PAST EVENT IS FINE AND A NUMBER
ABOUT CURRENT STATE IS A LIABILITY.** _"3 of 7 were false positives"_ is a measurement of a thing that
happened and stays true forever. _"contract 43/51"_ is a claim about now, and now moves. **Where a
current-state number is worth keeping, it carries the clock; where it is not, it goes.**

### SEND THE COMMAND AND ITS OWN OUTPUT, FROM ONE EXECUTION -- AND ALL SEVEN CATCHES CAME FROM RUNNING

**RULE: A REGEX IS CODE, AND QUOTING CODE IN PROSE LOSES STRUCTURE SILENTLY.** cc's shell ran
`fs::write\|fs::create_dir\|fs::remove\|...` -- the prefix repeated on every alternative, 43 hits. Their
MESSAGE said `fs::write|create_dir|remove|...` -- the prefix collapsed onto the first, 52 hits. **No
diagnostic, no error, just a different pattern wearing the same words**, and I ran what arrived and got 52
correctly. Same family as the header guard's escape problem and as `| head -3` swallowing an answer: **a
channel between the thing and the reader that drops part of it without saying so.**

**AND cc'S SHARPENING IS THE FIX, BECAUSE MINE LEFT THE HOLE OPEN.** I wrote _send the command, or send the
answer_. **They sent BOTH -- just not from the same run.** So a pattern yielding 52 sat beside the number 43
in their draft and **nothing in the draft could see itself.** The rule is **SEND THEM TOGETHER, FROM ONE
EXECUTION**: paste the command beside its own output and the inconsistency is visible before the message
leaves.

**I DECLINED TO ASSIGN THE LOSS AND cc CHECKED THEIR OWN END AND FOUND IT WAS THEIRS.** Recorded because the
refusal was right on the evidence I had -- I could not see their shell -- **and because they had already
committed the mirror of it against me**, "the over-sensitive version was their transcription", a wrong cause
about a peer in their own favour. They corrected it in their own words rather than editing it away.
**Refusing to adjudicate cost nothing and would have cost something had I been wrong.**

**THE OBSERVATION THAT OUTRANKS ALL OF THEM, AND IT IS cc'S: SEVEN ERRORS TODAY -- FOUR THEIRS, THREE MINE --
AND EVERY SINGLE ONE WAS CAUGHT BY THE OTHER PARTY RUNNING THE THING, NOT READING IT.** Not by suspicion,
not by review, not by a careful re-read. **And nothing tells us how many were not caught**, because the
uncaught ones are exactly the claims nobody executed. **A claim nobody ran is not a weaker claim; it is an
unmeasured one**, which is the `unobserved`-needs-a-probe rule pointed at our own assertions rather than at
a table. **Checked against my own record today: every closing evidence line was driven, and the one thing I
could not drive -- the `Cargo.lock` half of `fast_image_resize` -- is recorded ON the row as unproven rather
than counted.** That is the discipline working, and it is the only defence against a number neither of us
can see.

### A ROW CAN BE WELL-FORMED AND STALE, AND THE SHAPE CHECK CANNOT TELL -- snorkeltoast's, EARNED ON THEIR OWN TABLE

**RULE: A SHAPE CHECK MEASURES THE ROW; ONLY A PROBE MEASURES THE WORLD.** `favicon-missing` and
`font-not-woff2` passed `check_table_shape` immaculately the entire time they were false -- each carrying
`unobserved`, each carrying no `evidence`, exactly as a `designed` row must -- while asserting a state of
the world that had stopped being true. **Six fields false across two rows, all six written by the author of
the checker.**

**THE FIX, WHICH ALREADY EXISTED IN THEIR TREE UNGENERALISED: EVERY `unobserved` MUST CARRY A PROBE THAT
FALSIFIES IT.** `_producer_fallback_strips` reads `compiler.PLAYER` and probes it, so that row RETIRES
ITSELF when the fallback goes -- **the claim cannot outlive its truth.** `"no call site in main.rs"` is a
grep. Had the row carried `grep 'theme::for_reel' build.rs`, it would have gone red the moment cc wired
`open()` and no peer would have had to catch it by hand.

**AND IT CLOSES MY HALF OF THE SAME FIELD, WHICH IS WHY IT IS ONE FIX AND NOT TWO.** I misread `unobserved`
as a SUFFICIENT condition because **it is prose with no predicate attached -- there was nothing to run, so
there was nothing to disagree with me.** A field carrying an executable falsifier cannot be mistaken for one
carrying a sufficient condition, because you can run it and watch what it answers. **One fix, two failure
modes, on opposite sides of the same field: the author's claim going stale, and the reader's inference going
wide.**

**AND A THIRD INSTANCE OF ONE PRINCIPLE, EARNED IN THREE DIFFERENT MATERIALS IN ONE HOUR: PUT THE ANSWER
WHERE THE QUESTION GETS ASKED.** (i) The PROBE, so a stale row falsifies itself instead of waiting for a
peer. (ii) The FIXTURE: my woff2 fixture pointed family `Luckiest Guy` at file `Bangers-Regular.ttf`, and
the instinct was to add a caveat -- **I repointed the fixture instead**, because a caveat explaining a
confusing artifact is a worse artifact than one that is not confusing. (iii) The EVIDENCE LINE: I drove the
two theme refusals through `check` and treated the verb as DISCLOSURE; snorkeltoast showed it is
SUFFICIENCY, and that the fact belongs in the row rather than in a Rust file the reader may not have.
**Verified at source and stronger than either of us first put it: `open()` is `build.rs:49` with
`theme::for_reel` inside it, and `main.rs:74` and `build.rs:166` are its only two call sites AND THE FIRST
STATEMENT OF `check` AND `run` RESPECTIVELY.** Not a prologue they happen to share -- an entry point neither
can skip.

**COROLLARY I OWE MY OWN BOARD: A CONDITION I WRITE IN PROSE IS THE SAME DEFECT.** Every hold and every
"flips when X" on this board is an `unobserved` field by another name. **If the condition cannot be written
as something runnable, it is a guess about the future dressed as a trigger** -- and mine was wrong for
hours while looking exactly like a plan.

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

**AND THE RECURRING `MM` HAS A CAUSE NOW, WHICH IS cc'S DIAGNOSIS AND I REPRODUCED IT WITHIN THE HOUR.**
**ANY route that puts bytes in the index which the pre-commit formatter then rewrites leaves a stale entry**,
and there are TWO. (a) `git add <tracked file>` before `git commit --only <same file>` -- the `add` is a reflex
for files git does not know about yet and on a tracked file it does nothing but plant the entry; `--only` alone
is correct and complete. (b) **`--only` BY ITSELF, on a file the formatter changes** -- it stages the file, the
hook reformats and re-adds, and the index keeps the pre-format bytes. **I wrote cause (a) as the cause and hit
(b) two commits later with no `add` anywhere**, which is the day's fourth narrower-than-the-phenomenon claim and
the only one I caught myself. In both, `git diff HEAD` is EMPTY -- the commit has the formatted bytes and only
the index is stale -- so `git restore --staged` is the whole fix and nothing is ever at risk. cc named it after I flagged their `MM`, said it was theirs
to stop doing -- and I did the identical thing twenty minutes later on my own board and hv's inbox. Both times
`git diff HEAD` was EMPTY and only the index held pre-format bytes, so `git restore --staged` is the whole fix
and nothing is ever at risk. **Knowing the rule is not being protected by it, and a reflex is not a decision.**

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

- **hv RELEASED BOTH GATED ITEMS 2026-09-10 17:09Z: "Yep, crack on."** One word on two decisions, which is the
  shape snorkeltoast asked for and hv gave. **(1) snorkeltoast runs the fidelity compare** -- ~299 renders,
  the first time that harness has been pointed at a non-reference artifact. **(2) `favicon-missing` and
  `font-not-woff2` flip `designed` to `observed`.** vc discharged prerequisite five with a FRESH measurement
  rather than the hand-over figure: all four artifacts re-hashed at 17:07Z, one distinct sha `118a63f7`,
  5,462,781 bytes, every mtime identical to hand-over seven and a half hours earlier.
- **AND THE SCOPE OF "CRACK ON" IS READ NARROWLY AND SAID SO OUT LOUD.** It covers the two decisions that were
  put up. **It is NOT read as opening WP-04**, because the message it answered listed exactly two items and
  ended by saying nothing else moves without hv's sequencing. **Both peers told to stay parked until hv
  sequences or vc relays that they have** -- and hv told plainly that this is the reading, so correcting it
  costs them one line. **Over-reading an approval is permission-laundering with extra steps**, and the cheap
  fix is to state the reading rather than to act on the widest one.

- **cc's STRUCTURAL COMPARE WAS NOT A BREACH OF hv's HOLD -- vc, 2026-09-10 09:41Z.** They imported the harness and called
  `payload_of`/`signature`/`compare_structure` on two files before knowing hv had told snorkeltoast to hold,
  then handed me the judgement rather than making it. **(a) hv's hold was given to snorkeltoast about
  snorkeltoast's work; an instruction to one node is not a standing order on another.** (b) Nothing was spent --
  pure over two payloads, no renders, no `control.json`, no verdict, nothing written. (c) **It was PROTECTIVE:**
  a non-empty `compare_structure` is what refuses a pixel verdict, so structure-first stopped 299 renders being
  burned on a run that would have refused. **Surfaced to hv ANYWAY, because a ruling that clears a peer must not
  be the one that disappears.** cc's own sentence is the keeper: **"adjacent to the gated thing" is a judgement
  nobody should make about their own action.**
- **AC-5.1's TWO INVOCATION FORMS ARE EXECUTABLE TODAY AND cc TOLD ME THEY WERE NOT.** They reported
  `prez showreel build` does not exist. **Measured four ways, all rc=2 "showreel: check needs a directory":**
  `bin/prez`, `bin/utilz prez`, PATH `prez`, PATH `utilz prez` -- and `~/.local/bin/{prez,utilz}` both
  symlink to the repo's `bin/utilz`. **I did not diagnose why they got a different answer**, which is the
  wrong-cause rule applied for once before the sentence went in. **cc's two handed-over artifacts are the two
  PATH forms** -- byte-identical, same sha, a real finding on its own axis -- **and not what AC-5.1 asks.** Two
  more builds, one per command form.

- **THE 45h GRADING BUILD USES `--out` INTO SCRATCH AND IS TWO RUNS, NOT ONE -- vc, 2026-09-10.** Ruled after
  reading AC-2.1, AC-5.1 and AC-6.1 in full: **not one of the three names a location**, so `--out` grades all
  three. **The decisive reason is that `_out/` is the promote SOURCE** -- a `-002` sitting there is a thing a
  person can promote by accident, and this estate has just spent two days on a deploy serving the wrong bytes for
  nine days. **AND IT IS TWO BUILDS BECAUSE AC-5.1 SAYS "BOTH INVOCATION FORMS"**; cc had planned one, and that
  is precisely what gets discovered after a once-only run is spent. **WHAT `--out` COSTS, STATED SO ITS SILENCE
  IS NOT LATER READ AS COVERAGE:** pruning is suppressed, so the `-001`/`-002` slot rotation is not graded by
  this run -- it is not graded by these three rows either way, and it belongs to WP-06. Verified rather than
  taken: 45h carries no `keep:` key and `deliver.rs:289-303` deletes only when `keep > 0 && sibs.len() > keep`,
  so nothing would have been deleted regardless.
- **45h CANNOT GRADE THE EMBED SOURCE, AND THE COLLISION IS THREE-WAY -- snorkeltoast's CORRECTION OF MY
  TWO-WAY VERSION.** Verified at all three sources by me: 45h `showreel.yaml:40 target: 1920`; the reference
  `showreel:52 TARGET_DEFAULT = 1920`; the port `normalise.rs:37 pub const TARGET: u32 = 1920`. **So
  `embed=1920` is consistent with THREE mechanisms** -- the config read, the config ignored for the Python
  default, the config ignored for the Rust constant. **The third is the one that matters for a PORT**: it is the
  case where the port silently stops consulting config at all and still agrees with the reference on every 45h
  build forever. cc's synthetic at 640 discriminates all three because 640 differs from both defaults, which is
  what makes it a real control rather than a nominal one. **A green on 45h must NEVER be cited for this
  property.** snorkeltoast is building the refusal into the stamp parser -- an embed value equal to a default
  records NON-DISCRIMINATING rather than agreement, computed from the artifact's own config, so a 45h built at
  1600 becomes discriminating with no table to edit.
- **A CITATION THAT IS EXACT TODAY IS THE ONE THAT GOES WRONG QUIETLY, AND THE REMEDY NEEDS CHECKING TOO.**
  `config.rs:203` cites `showreel:989`; line 989 IS that token, character for character. **Third line-number
  citation into snorkeltoast's file across three sessions, and the previous one decayed `:613` to `:628` twice
  with nobody noticing.** Cite the TOKEN. **And I checked their proposed token rather than relaying it:
  `grep -n 'cfg.get("target"' showreel` returns TWO hits, 620 and 989, so it does not locate the line they
  meant; `target = int(cfg.get("target"` returns exactly one.** A remedy for an imprecise locator that is itself
  imprecise is the same defect wearing the fix's clothes.
