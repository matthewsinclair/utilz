---
node: vc
name: Validation Claude
role: validation
session_id: 11981560-5612-4fe7-a136-6eae64636b64
heartbeat_at: 2026-09-10 19:57Z
status: active
focus: "ST0017 49/54, doctor 0, WP-01 and WP-03 DONE. The first 45h compare ran: AC-2.1, AC-3.15, AC-5.1 and AC-6.1 all closed today, and hv accepted the encoder divergence. Five rows open, none in flight, all waiting on hv sequencing WP-04. Both peers folded."
claims: [ST0017]
---

# Validation Claude (vc)

Validation node. cc builds, vc contracts and verifies, hv adjudicates. Full boards for 8 Sep in `.history/20260908/`, for 9 Sep in `.history/20260909/` (`wip-before-localfold-2.md` is the 30389-byte pre-fold original). **This board keeps ONE statement of each rule with the instance that earned it, not the day's narrative** -- and after hv's scope call, only rules that change what gets BUILT.

## DOING

**ST0017 -- showreel hoisted under `utilz prez showreel`. vc holds the contract, cc builds, snorkeltoast owns the
harness and the reference, hv adjudicates.** Localfolded 2026-09-10 19:53Z on hv's call; the day's narrative and
the pre-fold board are in `.history/20260910/`.

- **CONTRACT 49/54, 3 withdrawn, `intent doctor` 0. COMPUTED 2026-09-10 19:53Z, NOT CARRIED.** WP-01 15/15,
  WP-02 17/18, WP-03 13/14, WP-04 0/2, WP-05 2/3, WP-06 2/2. **`intent ac list ST0017` IS the contract** -- ids
  are `AC-<wp>.<seq>` and **the group digit IS the work package**, so per-WP is computed from it and never typed.
- **THE FIRST 45h COMPARE HAS RUN. AC-2.1, AC-3.15, AC-5.1 AND AC-6.1 ALL CLOSED TODAY.** The harness now knows
  what it graded by DERIVATION -- `population_source = stamp` against the reference's `adjacency (UNVERIFIED)` --
  and the pixel compare FAILED on six artwork JPEGs, which hv adjudicated as an accepted divergence. **Both
  outcomes are correct and the row carries both.**
- **WP-01 AND WP-03 ARE DONE. FIVE ROWS REMAIN AND NONE IS IN FLIGHT:** AC-2.19 (the floors derivation --
  snorkeltoast's instrument, their own finding against it), AC-3.4 / AC-4.1 / AC-4.2 (WP-04 by construction),
  AC-5.3 (WP-05's doctor line). **Both peers are folded and hold; neither opens WP-04 or WP-05 without hv.**

## TODO

- **THE FIRST THING ON THE BOUNCE IS hv'S SEQUENCING CALL, NOT WORK.** WP-04 before WP-05 is vc's read: three of
  the five open rows live there and AC-3.4 has waited longest. **Nothing starts without it and that is right.**
- **STANDING: TELL hv WHEN TO FORCE A LAKSA RESYNC -- AND CHECK WHETHER IT IS STILL NEEDED.** snorkeltoast
  reports 2026-09-10 that **hv has fixed the webhook in Laksa and a push publishes again**; vc has NOT verified
  that and it is not verifiable from this tree. **Until vc sees a push deploy without a manual resync, treat the
  duty as live.** Nothing needs publishing now: 009 is current, production serving `c38fbc53`.
- **THE VERIFICATION IS TWO COMPARISONS AND ONE WOULD HAVE FALSE-ALARMED ON THE LIVE REEL.** Served bytes against
  **THE SITE REPO AT HEAD** is the deploy question; `_out` against the published slot is the PROMOTE question.
  The old single check hashed served against BUILT and calls a current production stale, because `096a676` added
  one blank line after the promote. **Reading the payload stays: hash equality says nothing about correctness.**

## Holds

- **WP-04 CONDITION, WITH THE COMMAND ATTACHED -- FLAG IT THE MOMENT WP-04 OPENS, NOT WHEN THE DIFF ARRIVES.**
  cc asked for it that way: a condition known before the code is a design constraint, the same one raised after
  is rework. The fixture recipe's safety rests on the port having no write path into a reel dir outside `_out`.
  **BASELINE: production calls SEVEN `fs::` functions and exactly THREE write** -- `create_dir_all`, `write`,
  `remove_file`, all in `build.rs`, with `grep -n 'join("_out")' build.rs` the only reel-derived target.
  `pdftoppm` and `".raster"` appear nowhere. **TRIGGER: an eighth function, a fourth write site, or a target not
  derived from `_out`.** Init's masters and `pdftoppm` trip it.

      for f in <port>/src/*.rs; do t=$(grep -n '#\[cfg(test)\]' "$f" | head -1 | cut -d: -f1); t=${t:-999999}
        awk -v t="$t" 'NR<t' "$f" | grep -oE 'fs::[a-z_]+'; done | sort | uniq -c | sort -rn

- **AC-5.3, ON vc'S OWN CALL AND cc AGREES.** Genuinely not startable: no showreel manifest, no `bin/` symlink,
  `common.sh` silent on showreel. CONDITION: **WP-05's dispatch shape decided.**
- **THE REFERENCE'S `Image.LANCZOS` HOIST -- snorkeltoast'S, AND NOW HELD FOR A BETTER REASON THAN THE OLD ONE.**
  CONDITION was "not while 009 is the reference cc builds against". **It is now also load-bearing EVIDENCE:**
  today's finding makes the reference resampler part of what `jpeg-encoder-bytes` cites, so touching the
  compiler would invalidate floors that row rests on. They hold it deliberately rather than by gate.

## Open with hv

**TYPED BY WHETHER hv OWES A RULING**, on cc's point that an FYI dressed as a decision spends the attention the
real decision needs.

### Decisions hv owes

- **`max_ease` 3000 AGAINST `min_dwell` 2500 in Python's `LIMITS`.** Unruled since 09-09, latent in the LIVE
  artifact at the same magnitudes, untouched by the promote. **Its rider travels with it:** capping to 2400 turns
  WP-02's `shipped-max-ease` selftest red BY DESIGN -- and snorkeltoast has since built the row a VOID TEST, so
  it will **announce its own death rather than quietly become a lie.** A consequence, not an argument against.
- **THE PUBLIC-REPO FIXTURES.** Two pinned fixtures carry a named individual and a customer brand into a public
  repo. `upstream` frozen, so nothing is published and it is decidable first. **Recommend de-identifying the reel
  config if unsure** -- one edit, keeps every testing property except the name.
- **DROPPING THE REFERENCE PLAYER'S BRAND FALLBACK.** `add("Producer", REEL.producer || "Snorkeltoast")`. A
  PRODUCT decision, not an instrument one. **Recommend DEFER until after the 19th** -- doing it now moves slide
  1's gradeability and invalidates floors measured today.
- **`control.json`'s `artifact_sha256`: annotate the GRADED-versus-SERVED distinction?** snorkeltoast's, raised
  against their own file. It names the artifact they GRADED, which is the correct referent for a floors file, and
  it is one byte from the artifact SERVED. **An identifier is not the thing, and this one is theirs.**
- **SHOULD THE NEW SIDE BE CONTROLLED TOO?** One control today, on the reference; if the NEW build is noisier a
  real regression can sit inside the reference's floors unseen. Cost: a second ~14-minute pass per build.
  **Neither snorkeltoast nor vc has taken a position, deliberately.**

### FYI -- no ruling wanted

- **THE LAKSA WEBHOOK IS REPORTED FIXED** by snorkeltoast, 2026-09-10. **vc has not verified it** and the resync
  duty stays live until a push is seen to deploy without one.
- **`prez showreel build` needs `SHOWREEL_THEME_PATH`** where the Python needed nothing. H3 working, not a
  regression. A ruling only if hv wants it set somewhere permanent.
- **AN INTENT DEFECT, NOT A UTILZ ONE: `intent ac edit --text ""` DESTROYS A CRITERION SILENTLY.** Cost AC-2.1's
  16,839 characters at `c628c39`; recovered at `5d4d39e`. A length guard is now in vc's path, **which is
  discipline where a gate belongs.**
- **Issue 0016** remains hv's WP-05 rider. No action.

## Claims

- **ST0017** -- the contract. cc also claims it. Not a conflict: claim-by-ST cannot express "vc validates, cc builds".

## Live with other nodes

**EVERY ENTRY CARRIES THE CLOCK IT WAS TRUE AT, BECAUSE THIS IS THE HIGHEST-ROT SURFACE ON THE BOARD** -- no
dependency edge exists to another session's tree and none could be built. **The alternative to a fresh copy is
no copy, not a fresher one.**

- **`cc`: FOLDED AND COMPACTING, NOTHING OWED EITHER WAY.** As at 19:53Z. Landed today: `serde_json` with hv
  named, the payload, the slide rows, the build verb, and `round_ties_even`. **The encoder stays by hv's ruling
  and they said so from their side rather than leaving it look like work undone.**
- **`snorkeltoast`: FOLDED AND COMPACTING.** As at 19:53Z. Landed: the limits invariant, the floors renderer,
  the first `control.json`, the harness pinned to bytes, the two theme rows flipped to observed, and
  `jpeg-encoder-bytes` WITH A BOUND. **Their ledger for the bounce: a CONTROL run on the port artifact (which
  discharges a stale row AND tests the 23-of-23 prediction), the wording that rides with it, and the
  `Image.LANCZOS` hoist they are holding deliberately.**
- **`snorkeltoast` FLAGGED ONE OF THEIR OWN AS STALE ACROSS THE COMPACT:** `producer-fallback-strips` is
  `designed` on a FALSE `unobserved` -- it claims no Rust-built artifact exists and four do. **If the 23-of-23
  figure is cited as live before that control run, it is wrong and they said so first.**
- **`laksa-vc`: SOLVED THE DEPLOY.** They read GitHub's delivery log -- the observable none of us could see.

## Watch-outs

**FOUR THINGS THE FOLD'S OWN LOSS PROBE TURNED UP -- TWO CUT BY THE FOLD, TWO NEVER HERE AT ALL.** cc ran a
probe against their fold and found three losses, one of them mine; **I ran the same probe against mine.** The
distinction matters: a fold loss is a regression, **a gap was always a gap and looks identical afterwards.**

- **RESTORED (cut by the fold): `signature()` STRIPS `src` ENTIRELY**, so a venue slide LOSING its `src` is
  invisible to the harness -- `showreel-harness:358`, and `mark` is flattened to `<present>` beside it.
  **The payload test is the only thing over that half.** cc's finding and they named it as must-survive.
- **RESTORED (cut by the fold): the harness is PINNED at `f58829961dd7...` / 144,465 bytes.** My
  compare-time condition was discharged against those bytes, so **if the harness moves, the basis of that
  measurement moves with it** and `producer-fallback-strips` has to be re-read rather than assumed.
- **GAP, NEVER ON THIS BOARD: hv's `MAX_EASE_MS` 2400 CAP IS A STANDING SAFETY RULING, NOT A CLOSED ROW.**
  cc restored it to theirs and re-framed it, and the reasoning is why it belongs here too: **AC-3.6 being
  satisfied is exactly what makes it look safe to cut.** Anyone restoring the reference's 3000 for parity
  would be REVERSING A DECISION rather than fixing a divergence. The cap makes runtime ease unreachable above
  the dwell floor for every config, every speed and both pace modes.
- **GAP, NEVER ON THIS BOARD: `min_defect` IS 0.223607 AND IT IS WHY AC-3.15 SURVIVES AC-2.19.** All six
  divergent slides clear it by 4x to 13x, so **the FAIL does not depend on the floors defect being fixed** --
  which is precisely the shape that makes a defect easy to leave unfixed, and the reason AC-2.19 is a separate
  row rather than a retraction.

**THE 8-9 SEP CORPUS IS ARCHIVED AND ONLY ITS HEADLINES REMAIN HERE.** Each rule's earning instance is in
`.history/20260910/watch-outs-0809-full.md`. **The headline is the PROMPT TO APPLY, which is the half that was
measured missing** -- twenty corrections, and in every one the rule was already present and the prompt was not.

- **MY OWN INSTRUMENT FAILED FOUR TIMES TODAY AND EVERY FAILURE PRODUCED A PLAUSIBLE FINDING ABOUT A PEER'S WORK**
- **`git commit --only` PLUS A REFORMATTING PRE-COMMIT HOOK LEAVES A FALSE `MM`, AND IT READS AS THE OPPOSITE OF WHAT IT IS**
- **FOUR SIBLINGS, AND THEY ARE ONE FAMILY: CORRECT-LOOKING WORK SUPPRESSING THE NEXT QUESTION**
- **A DUPLICATE THAT IS A SUBSET READS AS "NOT A DUPLICATE" UNTIL SOMEONE USES THE MISSING PART**
- **A UNIFORM FAILURE READS AS CONFIRMATION WHEN THE TEST IS REFUSAL-SHAPED, AND ONLY A BASELINE SEPARATES THEM**
- **AND I NEARLY MANUFACTURED A PREDICTED DIFFERENCE OUT OF A PARITY FIX**
- **`head` IS A SILENT SAMPLER, AND THAT IS WHY IT BELONGS IN THE SAME FAMILY AS EVERYTHING ELSE HERE**
- **A CAVEAT PRINTED UNCONDITIONALLY TRAINS THE READER TO SKIP IT**
- **THE DOMINANT FAILURE OF 9 SEP WAS MINE AND IT HAS ONE SHAPE: I SPECIFIED AGAINST IMPLEMENTATIONS I HAD NOT READ**
- **A CITATION CAN EXPIRE WITHOUT DECAYING, AND NOTHING IS WATCHING FOR THAT**
- **THE FIXTURE'S SILENCE IS NOT THE SUBJECT'S, AND 45h IS THE PROOF**
- **A REFUSING APPLIER THAT DOES NOT CLEAN UP ON REFUSAL IS WORSE THAN ONE THAT NEVER REFUSES**
- **A REAL RATIO DEGRADES; A WRONG POPULATION COLLAPSES**
- **AND I SAMPLED FOUR OF NINE IN THE ROW THAT IS ABOUT POPULATIONS**
- **SIX ROWS NEEDED THEIR INSTRUMENT CORRECTED AT GRADING TIME TODAY, SO STOP WAITING FOR THE SEVENTH**
- **STAGING EXPLICIT PATHSPECS IS NOT SUFFICIENT, AND I HAD BEEN CARRYING THE RULE IN ITS INSUFFICIENT FORM**
- **A DETECTOR WHOSE POPULATION IS A STRICT SUBSET OF ITS OWN NAME, AND THE USUAL CONTROL DOES NOT CATCH IT**
- **THE NODE THAT HOLDS THE CONTRACT CAN MAKE ONE CLAIM NO BUILDER CAN, AND IT IS ORDERING**
- **A ROW NAMING TWO HALVES IS NOT SATISFIED BY VERIFYING ONE OF THEM THOROUGHLY, AND THOROUGHNESS INSIDE THE WRONG POPULATION FEELS EXACTLY LIKE COMPLETENESS**
- **WHEN A VERB ONLY REPLACES, COMPOSE THE NEW WHOLE AND PASS IT**
- **A ZERO HAS THREE KINDS AND THE THIRD READS EXACTLY LIKE THE FIRST TWO**
- **PUT THE CAVEAT WHERE THE NUMBER IS PRODUCED, NOT WHERE IT IS REPORTED**
- **A NARROWED VIEW AGREEING WITH ITSELF**
- **THE RULE WAS ALWAYS PRESENT; THE PROMPT TO APPLY IT WAS NOT**
- **ASK WHICH DIRECTION THE ERROR RUNS, AND BUILD THE CASE THAT ATTACKS THE ANSWER YOU EXPECT**
- **A STRUCTURAL MODEL PREDICTS THE CASE IT WAS NOT BUILT ON; UNTIL THEN IT IS A DESCRIPTION WEARING A MECHANISM'S CLOTHES**
- **A POPULATION IS THE CLAIM, NOT A DETAIL OF IT**
- **A COUNT CONTROL AND A SUM CONTROL CATCH DIFFERENT FAILURES, ONE SUBTRACTION APART**
- **AN ABSENCE ASSERTION NEEDS A PRESENCE ASSERTION OVER THE SAME POPULATION, OR IT IS A SUBSET CHECK WEARING THE COSTUME OF THE FIX**
- **PROVE IT RED AGAINST THE REAL DEFECT, AND GATE THE PROOF ON THE DEFECT BEING PRESENT**
- **A CHECK THAT READS A SOURCE WHICH HAS STOPPED CHANGING KEEPS RETURNING THE RIGHT ANSWER LONG AFTER THE CHECK ITSELF HAS DIED**
- **THE INSTRUMENT IS PART OF THE CLAIM, AND A CLEAN ZERO IS THE COMMONEST LIE**
- **THE ARTIFACT OUTRANKS THE SOURCE; THE SOURCE ONLY FEELS AUTHORITATIVE BECAUSE IT IS CAUSAL**
- **A STALE BINDING IS WORSE THAN A STALE VALUE, AND ITS TELL IS TWO CORRECT SENTENCES THAT CONTRADICT EACH OTHER**
- **NEAR-AGREEMENT SUPPRESSES THE CHECK THAT DISAGREEMENT WOULD FORCE, AND IT TAKES BOTH PARTIES**
- **WHEN TWO NODES VERIFY ONE CHANGE, AGREEING ON THE INSTRUMENT WASTES ONE OF THEM**
- **KNOWING A RULE IS MEASURABLY NOT THE SAME AS BEING PROTECTED BY IT, SO THE GUARD BELONGS IN THE CODE**
- **AN ASSERTION WEAK ENOUGH TO BE SATISFIED BY PROSE SPLITS A UNIFORM CHANGE INTO RED AND GREEN FOR UNRELATED REASONS**
- **A ROW MAY BE CORRECTED TO ITS INTENT; IT MAY NEVER BE WEAKENED TO FIT AN IMPLEMENTATION**
- **PROSE DOES NOT FAIL, SO A JUDGEMENT WORTH KEEPING NEEDS A ROW**
- **A CI LEG YOUR PLATFORM CANNOT REACH IS A BRANCH YOU HAVE NOT TESTED**
- **A REAL FINDING IS NOT AUTOMATICALLY YOUR FINDING, AND A FLAKE IS NOT A REGRESSION**
- **THE ESTATE, MEASURED TODAY**
- **INTENT'S OWN VERBS, LEARNED THE EXPENSIVE WAY**

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

### THE FAMILY OF THE EVENING OF 10 SEP: A CLAIM TRUE WHEN WRITTEN, AND AN AUDIT THAT CANNOT SEE IT

**THE SHAPE: NOTHING WAS WRONG WITH ANY OF THESE WHEN THEY WERE WRITTEN.** They were measured, correct and
specific, and they stopped being true with nothing attached to notice. **That is what the probe rule is
really about** -- not sloppy claims. Eleven instances across two nodes in one evening, all found by the other
party RUNNING something, none by reading.

- **A COUNT WITHOUT ITS MATCH RULE IS NOT A MEASUREMENT.** cc and I counted one write surface and produced
  four honest numbers -- 43 and 36 flat, 3 and 8 filtered. **The extra five were PROSE**: `format!("cannot
remove {}: {e}")` and the word in two doc comments. **AND WHEN TWO MATCH RULES DISAGREE THE ANSWER IS
  USUALLY NOT A THIRD MATCH RULE** -- cc stopped tuning and ENUMERATED: seven `fs::` functions in production,
  three of them writes. **A pattern answers "does this line match a rule I chose"; an enumeration answers
  "what does the code call", and someone who does not share my rule can audit the second.**
- **A REGEX IS CODE, AND QUOTING CODE IN PROSE LOSES STRUCTURE SILENTLY.** The four numbers came from one lost
  pair of parentheses -- `fs::(write|create_dir|remove)` groups the prefix, ungrouped it binds to the first
  alternative only. **No diagnostic.** cc checked their own end and found the loss was theirs. **RULE: SEND
  THE COMMAND AND ITS OWN OUTPUT, FROM ONE EXECUTION** -- they sent both, just not from the same run, so a
  pattern yielding 52 sat beside the number 43 and **nothing in the draft could see itself.**
- **A NUMBER IN PROSE HAS NO EDGE TO THE THING IT NAMES.** cc's board carried showreel's binary at 535,968 --
  right to sixteen bytes when taken, **stale by 3.7x** four commits later. Mine carried `CONTRACT 43/51` in
  the DOING HEADER, `WP-05 1/3` and `WP-06 1/2` in the same bullet, and cc as "folded and holding" at four
  wrong figures. **COROLLARY THAT DECIDES WHAT MAY SIT: a number about a PAST EVENT stays true forever; a
  number about CURRENT STATE is a liability, so it carries its clock or it does not get written.**
- **AND PEER-STATE HAS THE SHORTEST HALF-LIFE OF ANYTHING ON A BOARD** -- not merely no dependency edge, **no
  edge anyone COULD build**, because the referent is another session's tree and nobody notifies you. **The
  alternative to a fresh copy is NO copy, not a fresher one.** Every entry there now carries its clock.
- **AN AUDIT CONDUCTED BY READING HAS THE SAME BLIND SPOT AS THE CLAIMS IT AUDITS.** cc's, and the sharpest of
  the day: **reading cannot distinguish a number that IS right from one that WAS right -- they are the same
  characters.** They caught a binary figure by running `ls -l` and walked past a contract figure two bullets
  up. **I enumerated twenty numeric claims by grep, ground-truthed three, and classified the rest by eye** --
  both misses landed in the step I had not automated. **THE AUDIT IS AN INSTRUMENT AND IT IS IN THE
  POPULATION:** it needs a runnable form, a control, and a population it did not choose by eye.
- **COMPUTED AT WRITE TIME BEATS CHECKED AFTERWARDS, AND THE DIFFERENCE IS NOT DEGREE.** A number computed in
  the command that writes it CANNOT go stale; a number verified afterwards can only be CAUGHT going stale.
  Per-WP counts here are computed. **The rest of this board is the weaker form and saying so is the point.**
- **THE NEIGHBOUR OF A THING YOU JUST CORRECTED IS THE LEAST-EXAMINED THING ON THE PAGE.** Three instances in
  one evening, and it PREDICTS rather than apologises: attention narrows to the item it is holding.
  **PROCEDURE: when you correct something, the next thing you check is its neighbours, BY COMMAND.**
- **THE ENTRY IS RIGHT AND ITS FRAME IS WRONG -- TENSE, LABEL, OR CLOCK.** A section written in the future
  tense becomes unreadable in both directions once part of it happens (**a prediction that came true is not a
  prediction**, and an imperative surviving its own satisfaction claims work is owed when it is not). A
  heading is a claim about everything under it: my `## TODO` had accumulated two FINDINGS nobody would ever
  do. **Nothing checks a container -- a gate checks entries, and every entry passes.**
- **A ROW CAN BE WELL-FORMED AND STALE, AND THE SHAPE CHECK CANNOT TELL -- snorkeltoast's, on their own
  table.** Two rows passed `check_table_shape` immaculately the whole time they were false. **A shape check
  measures the ROW; only a probe measures the WORLD.** Their fix, which already existed ungeneralised in
  their tree: **EVERY `unobserved` MUST CARRY A PROBE THAT FALSIFIES IT.** `"no call site in main.rs"` is a
  grep. **AND IT CLOSES MY HALF OF THE SAME FIELD:** I misread `unobserved` -- _why could this not be
  observed_ -- as _what would SUFFICE to observe it_, **because it is prose with no predicate attached, so
  there was nothing to run and nothing to disagree with me.**
- **MY COROLLARY, WHICH GENERALISES FURTHER THAN THE TABLE: A PLAN WITH NO RUNNABLE TRIGGER IS A PREDICTION I
  HAVE AGREED TO STOP CHECKING.** Every hold and every "flips when X" on this board is an `unobserved` field
  by another name. One of mine was wrong for hours while looking exactly like a plan.
- **NAME WHAT YOU INCLUDE. AN EXCLUSION LIST DECAYS IN THE DANGEROUS DIRECTION.** My fixture recipe said
  _symlink every entry except `showreel.yaml` and `_out`_ -- and the directory also holds `.raster`, mode 700,
  a WRITE cache. **The zsh glob excluded dotfiles and I documented the decision I thought I had made:** what I
  RAN was safe, what I WROTE was not, and nothing in the run could have told me. **Second half and the worse
  one: my protection was real and my REASON was false** -- I called the symlinked assets read-only and the
  target is writable. **A reproducer leans on the stated reason the moment they change the verb.**
- **A PATH IS AN IDENTIFIER; THE FIXTURE IS THE THING.** My fixture root sat under this session's own id, so
  an evidence line pointing at it rots silently the moment the scratch is cleaned. **Evidence records the run
  condition as fact and hangs REPRODUCTION off a recipe.** And **A RECIPE NOBODY RAN IS AN UNOBSERVED FIELD**
  -- I ran mine from a clean `mktemp -d` and that is how I found it stated the themes and NOT the reels.
- **A CONTROL THAT SHARES THE REAL PATH IS NOT A CONTROL OVER THE FIXTURE MACHINERY.** "Real" is not
  "identical but for the one thing under test". Fixed by building `goodcopy` through the same copy, symlinks,
  config rewrite and theme root -- **one line different, `name:`, which snorkeltoast verified by diff rather
  than taking "unmodified copy".**
- **AND THE ONE THAT DECIDES WHAT AN INSTRUMENT MAY EXCUSE: A MATCHING STAMP IS NOT EVIDENCE OF MATCHING
  OUTPUT.** Both implementations declare `q=86` and Lanczos, both honour both, and every pixel-bearing slide
  still differs -- because **the stamp records the RULES.** An identifier is not the thing, and this time the
  identifier was the instrument built specifically to make that path checkable. **The record names what was
  measured; the MATCHER asks the artifact** -- six slide indices in a matcher would be right about 45h and
  wrong about the next reel.

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
