---
node: vc
name: Validation Claude
role: validation
session_id: 11981560-5612-4fe7-a136-6eae64636b64
heartbeat_at: 2026-09-10 06:45Z
status: active
focus: "ST0017: 43/51 -- AC-3.2 SATISFIED, the first row to move today, verified at source rather than from cc's report. WP-03 now 10/12. The stamp needs a filter const hoisted before any content lands, and its embed field cannot be graded by anything in this estate. serde_json still unruled."
claims: [ST0017]
---

# Validation Claude (vc)

Validation node. cc builds, vc contracts and verifies, hv adjudicates. Full boards for 8 Sep in `.history/20260908/`, for 9 Sep in `.history/20260909/` (`wip-before-localfold-2.md` is the 30389-byte pre-fold original). **This board keeps ONE statement of each rule with the instance that earned it, not the day's narrative** -- and after hv's scope call, only rules that change what gets BUILT.

## DOING

**ST0017 -- showreel hoisted under `utilz prez showreel`. vc holds the contract, cc builds, snorkeltoast has closed.**
Localfolded 2026-09-09 16:51Z. Full boards for 8 Sep and earlier folds of 9 Sep in `.history/`.

- **Contract: 42 of 51 satisfied, 3 withdrawn, `intent doctor` 0.** `intent ac list ST0017` is the live contract;
  `design.md` carries the reasoning. **Ids are `AC-<wp>.<seq>` and the group digit IS the work package.**
- **WP-01 15/15 DONE. WP-02 16/17. WP-03 9/12. WP-04 0/2. WP-05 1/3. WP-06 1/2.**
- **EVERYTHING JSON-FREE IN WP-03 IS BUILT**: theme, admission, normalisation, embed, the slide model, the plan,
  the template, the delivery naming. `check` resolves the live 45h reel to **23 slides and 14 assets**, matching the
  reference's own `plan()` on the same config. 247 tests.
- **cc IS BLOCKED AND IDLE, CORRECTLY.** Everything remaining needs the PAYLOAD -- `build_socials` with the
  stale-QR warning, `build_bug`, the slide rows, the limits block, and the `build` verb. No JSON emitter exists and
  the manifest requires hv's sign-off, named in the commit, for a crate. **hv killed the Python shim fallback, so
  there is no relief valve.**
- **EVERY OPEN ROW IS NOW AUDITED AHEAD OF ITS CODE**, which is the one move that reliably paid today. Nine open:
  AC-2.1 leg 2, AC-3.2, AC-3.4, AC-3.6, AC-4.1, AC-4.2, AC-5.1, AC-5.3, AC-6.1 leg 3.

**AFTER hv WENT AFK WITHOUT RULING, WITH THE PEN: ONE CONTRACT EDIT, TWO PEERS CORRALLED, ONE SWEEP.** 2026-09-09 20:24Z.

- **AC-2.1 GAINED THE STAMP SPECIFICATION (`59f33ec`).** `producer_stamp` (showreel-harness:226) reads
  `<meta name="showreel-producer" content="...">` and **NOTHING ON EITHER SIDE WRITES IT** -- four greps, all zero,
  with a control hit on `producer` at showreel:1006. That `:1006` hit is the trap: it is the reel's CREDIT LINE, a
  different thing under the same word, rendered by the shell as `add("Producer", REEL.producer)`.
  **The harness's own comment at :218-223 specifies the CONTENT and no row did**, so a stamp reading `rust` would
  meet AC-2.1's letter and defeat the instrument. Four rules measured both sides: 2560, 1920, Lanczos, JPEG_Q 86 --
  **three of four AGREE and the alpha rule is the deliberate divergence**, so alpha is the only one whose value
  distinguishes a Rust build over Python masters.
- **THE MECHANISM IS JSON-FREE, so it is cc's one piece of unblocked WP-03 work.** `MARKERS` and `subs` are two
  deliberately separate lists, so a fifth marker is already guarded by two existing tests. Only the EMISSION needs
  the payload. Sent with a three-option decision on the second template divergence; recommended (i), Rust-filled
  only, because absence-derives-Python is AC-4.1's established shape and a pull that drops the marker already fails
  `the_shell_declares_each_marker_exactly_once`.
- **THE TAUTOLOGY SWEEP RAN AND CAME BACK CLEAN, WHICH IS ITSELF THE RESULT.** 42 satisfied rows, 10 already
  carrying population language, 32 triaged, **16 refusal-shaped**; 4 read in depth (AC-1.4, AC-1.12, AC-3.1,
  AC-3.3 -- all driven, AC-3.3's compile-error injection exemplary). Structural pass over **36 Rust pub fn and 90
  Python defs**. **NO SATISFIED ROW ON EITHER SIDE IS GRADED ON MACHINERY NOTHING CALLS** -- the class that bit
  AC-3.5 once has not recurred. Coverage stated honestly: the other 12 refusal-shaped rows got the structural pass
  only.
- **ONE FINDING, IN snorkeltoast'S TREE, AND IT IS NOT A REGRADE.** `content_fraction` (showreel-harness:1298) and
  `BLANK_FRACTION` (:1295) are referenced nowhere -- a superseded proxy for the presence gate, which lives at
  :1614-1627 and is **structurally stronger**: a differential control against a content-stripped re-render, not a
  modal-colour proxy. **AC-2.8 stands.** What makes it worth reporting is that the DEAD copy carries the fullest
  statement of the doctrine in the file, including the Slide-1 worked example -- and the proxy it teaches would
  give a different answer from the mechanism that ships.

- **cc CORRECTED MY BOARD AND WAS RIGHT (20:11Z).** My focus said "cc is FULLY BLOCKED AND IDLE" while my own TODO
  said "AC-3.2 WAITS ONLY ON `report_unused`" -- **only one can be true, and the detailed row was the accurate
  one.** I wrote the focus line from the payload's SHAPE rather than from the rows. **The summary drifted from the
  detail it was summarising, and the detail was right** -- which is the argument for grading against rows and not
  against a narrative, applied to me.
- **RULED FOR cc ON `exclude:` (`2a11e54`).** An excluded file is NOT a dropped segment input: an instruction
  obeyed, not an accident. **Two attempts to break it failed** -- the textual one succeeds against the ROW'S WORDS
  and not the property, so the words changed. A wrong `exclude:` is a real hazard, is not this row's, and is
  recorded as a stated limit.
- **SEQUENCING DECISION, MINE: THE EMITTER STAYS HELD.** cc offered to hand-roll it while hv is away. **Building
  the thing under decision pre-empts the decision** -- and biases it toward the sunk cost. cc refused to spend
  hv's vague "rock on as needed" on a crate; **I will not launder it either.** Holding is free now that two
  JSON-free rows are live. What I DID take from their argument: the reference's field order gets a stated home in
  design.md now, which survives either ruling.
- **hv'S WINDOW CLOSED AT ~20:13Z AND cc FLAGGED IT.** The four items were **surfaced in person and hv left
  without ruling** -- delivered-and-undecided, which is NOT the same as queued and must not be recorded as it.
  The durable channel holds them again; the next live window is the next chance.

- **THE STAMP THREAD WENT THREE WAYS IN THIRTY MINUTES AND EVERY LEG CORRECTED SOMETHING.** cc built the
  mechanism straight off the spec -- `player.html:7` is `content="__PRODUCER__"`, `MARKERS` is 5 -- and **added two
  refusals nobody specified**: an empty producer, and one carrying a quote that would break the tag. The empty case
  is the one I would have missed, because **the harness cannot tell empty content from no stamp at all.**
- **snorkeltoast RAISED A HAZARD cc HAD ALREADY CLOSED, AND IT WAS THE RIGHT HAZARD.** `showreel:1018-1022` builds
  the artifact as `player.html` plus four `.replace()` calls, and cc PULLS that template -- so a tag shipping a
  real VALUE in the shared shell would have been inherited verbatim, and `population_source` would have flipped
  from "adjacency (UNVERIFIED)" to "stamp". **An honest refusal upgraded into a confident wrong answer**, believed
  precisely because a stamp outranks adjacency. Verified in cc's working copy before relaying. **The residue is
  snorkeltoast's and is unclosed: an artifact whose stamp is still the literal token must REFUSE, not warn.**
- **TWO MEASURED CORRECTIONS TO MY FIELD LIST (`23a9871`).** `edge=2560` is INIT's constant and does not belong in
  a BUILD stamp -- stage-mixing, and exactly the case in play. `embed` must be the reel's ACTUAL target
  (`showreel:989`, `cfg.get("target", TARGET_DEFAULT)`), not the default, or a reel carrying `target: 1440` stamps
  a lie. **And every value interpolated from the live constant, never written out** -- a hardcoded `q=86` is a flag
  wearing a stamp's clothes.
- **THE ONE-SHOT NEEDS THREE STEPS, NOT ONE, AND I RAISED IT.** FLOORS.md is 22 slides and the live config plans
  23, so `compare` refuses on structure before grading; `cmd_control` takes only the artifact, so cc's build needs
  its OWN 14-minute control run first. **"The first compare" is build, then control, then compare.** Unsequenced,
  the moment is spent waiting rather than measuring.

- **cc IS NO LONGER BLOCKED AND BOTH SLICES ARE COMMITTED.** The stamp (`player.html:7`, `content="__PRODUCER__"`,
  MARKERS 5) and **AC-3.2's drop clause** (`ec3b211`, source only -- no contract edit, clean boundary).
  `Plan` now carries `dropped`, `plan::report` starts `out` as `dropped.to_vec()` so the lines **EXTEND**
  `report_unused` rather than duplicating it, and `main.rs:155` is the production caller. **AC-3.2 looks
  dischargeable and I am NOT grading it mid-flight** -- cc's design.md is still uncommitted. Fire on claim.
- **cc'S REFUSAL COMMENT MADE AN ARGUMENT I WOULD NOT HAVE FOUND.** An EMPTY stamp matches snorkeltoast's regex,
  yields `""`, and under Python truthiness at `showreel-harness:1236` grades **identically to an unstamped
  artifact**. Both that and a quote-carrying value fail SILENTLY at the reading side, which is what makes them the
  writing side's to refuse. Their instrument, reasoned about correctly by the other implementation.
- **MY SEQUENCING NOTE WAS WRONG AND snorkeltoast CORRECTED IT AT SOURCE.** I said build, then control, then
  compare. **The control is the REFERENCE's**: `showreel-harness:1943` compares `ctl["artifact_sha256"]` against
  `ref_m["artifact_sha256"]` and only `info()`s -- verified before accepting. So cc's build needs a **capture**,
  the fast one, and the 14-minute Chrome pass hangs off **hv's rebuild**, not cc's build. I had the dependency
  backwards. **The binding constraint is structural and is hv's**: 22 against 23 refuses whoever's floors we hold,
  so hv's rebuild and cc's build must come from the SAME config.
- **TWO SATISFIED ROWS NOW CARRY THE LIMIT THAT NOTHING ENFORCES THEM (`170668a`).** **AC-3.9** says the manifest
  carries exactly hv's budget "and nothing else" -- and NO test reads `Cargo.toml`, no gate names a crate, and the
  only `manifest.sha256` is devbin's. True today, verified at the manifest; **false and silent the moment a crate
  lands.** **AC-2.18** already contains "a provenance line that cannot be followed is most of a provenance line
  missing", and FLOORS.md cites a `control.json` that exists nowhere -- three text mentions, zero files. **Neither
  reopened**, both silences recorded.
- **gtools-vc'S ELEVEN-DAY HOLD IS CLOSED AND IT WAS MY DEFECT.** They were waiting on an AT-to-AC map from a
  previous vc session for a Utilz WP-04 validation job. **ST0010 -- whose WP-04 IS the validation package -- closed
  Completed on 2026-09-07, 19/19, PASS**, and three of its criteria are `computed` from ATs that actually run, so
  it closed on measurement rather than assertion. Told them to drop it.

- **AC-3.2 SATISFIED (`fe9fc62`) -- 43/51, WP-03 to 10/12, THE FIRST ROW TO MOVE TODAY.** Verified at source and
  not from cc's report, which is what a row refused once deserves: six admission sites COUNTED (`slide.rs` :284,
  :298, :321, :350, :444, :449) over one private `classify()` with two public shapes; the drop surviving a
  successful segment; `plan::report` EXTENDING rather than duplicating with `main.rs:155` the production caller.
  **Both new tests checked for NON-VACUITY rather than counted** -- the ordering test's two `.expect()`s mean a
  missing line fails, and cc built my `exclude:` ruling a control (`slides.len() == 1` proves the exclude FIRED).
  **I re-ran `check` on the live reel myself**: 23 slides, 14 assets, exit 0, silent at both altitudes.
- **THE STAMP HAS A FIELD NOTHING IN THIS ESTATE CAN GRADE, AND I MEASURED IT WORSE THAN cc DID.** cc found 45h
  sets `target: 1920`, which is exactly `normalise::TARGET`, so a build reading the CONSTANT instead of the CONFIG
  is byte-identical on the live reel. **I checked the pinned fixture: it sets 1920 too.** So it is BOTH members of
  the config population -- including the fixture pinned under "test against something you did not write". **On
  AC-2.1 as a REQUIREMENT, not a stated limit**, and the line is drawn explicitly against AC-3.2's two limits:
  there the gap is an input class nobody uses; here it is the exact discrimination the field exists to make.
- **THE FILTER HOIST IS ONE PAIRED PREREQUISITE ON BOTH SIDES, NOT TWO LINES -- snorkeltoast ASKED FOR IT KEPT
  TOGETHER AND THEY ARE RIGHT** (same reason the selftest rider travels with hv item 2). A stamp reading
  `filter=lanczos3` off a literal records what somebody TYPED rather than what RAN: **the flag-versus-stamp
  distinction reappearing INSIDE the stamp.** Three of the four rules already have named owners in the reference
  (`showreel:51`, `:52`, `:53`); the fourth has none on EITHER side.
  **BUT THEY DIFFER IN KIND.** cc's is ONE unnamed inline site (`normalise.rs:175`) -- a NAMING problem. The
  reference's is **TWO byte-identical resize lines** (`showreel:314`, `:447`) with nothing binding them -- a
  DUPLICATION problem, strictly worse. **And vc confirmed BY FUNCTION that they sit on the seam already known to
  diverge**: `normalise_image` (:294) carries the alpha probe at :308 AND the filter at :314; `data_uri` (:440)
  carries the filter at :447 AND the alpha test at :449. Anyone repairing the alpha asymmetry edits both functions
  and can touch one resize and not the other, with nothing reporting it.
  **NEITHER IS BEING FIXED NOW AND THE REASONING IS THIS BOARD'S OWN:** both say LANCZOS today -- latent, not
  manifest -- and editing the reference mid-port moves cc's target and touches what builds the live reel days from
  the event. cc's lands now because it is new code; snorkeltoast's travels with Python's own stamp after hv's
  window. Recorded on AC-2.1 at `45a7419`.
- **snorkeltoast SHARPENED cc'S EMPTY-STAMP CATCH INTO THE ASYMMETRY THAT MATTERS.** Empty is falsy so the VERDICT
  stays right and only the diagnosis is lost; **`__PRODUCER__` is TRUTHY**, so `population_source` flips to "stamp"
  and the token becomes the producer of record -- a population the harness was TOLD rather than guessed, and being
  told is what suppresses the provisional marking. **Empty loses a diagnosis; the token loses the verdict.** Both
  refuse on their side at `ecfbd00`. And their rejection of the tempting fix is the load-bearing half: degrading a
  broken builder to UNVERIFIED folds it into the one state guaranteed to stay quiet forever.

- **I VOUCHED FOR HALF AN ARGUMENT THAT WAS WRONG, AND CORRECTED hv MYSELF (`dbc5c71`).** I told hv twice that a
  hand-rolled emitter keeps "the reference's field ORDER in a second home", and said I had CHECKED cc's reasoning
  rather than relayed it. **I checked the half that was right.** cc's design.md 4.6 measured it: `compare_structure`
  iterates `sorted(set(a) | set(b))` -- it SORTS BEFORE COMPARING -- `signature()` reads only `payload["slides"]`,
  and `artist`/`session` pass through from user YAML so their order was never reproducible by a struct in either
  language. **The order is not the risk; the SET is, and it is already graded precisely.** hv now has the
  one-argument version. Recommendation unchanged -- the escaping half was always the stronger.
- **AC-2.1'S TARGET FINDING IS RECLASSIFIED FROM "REQUIREMENT" TO "BLIND" (`12a606d`), snorkeltoast'S CORRECTION
  AND IT IS A BETTER ANSWER THAN MINE.** Two counts. **(1)** The two blind configs are in TWO ESTATES with one
  config each, not one population with two members. **(2)** The embed field IS gradeable today with no fixture at
  all -- the artifact carries its slides as data URIs and **their long edge is MEASURABLE**, so the stamp's claim
  can be graded against the pixels it describes. **Deriving from contents rather than comparing two self-reports**,
  which is the same move that makes `population_source` worth having, one level down. **I jumped from "cannot be
  checked" to "a fixture is required" without asking whether a different instrument could reach it.**
- **AND THE SENTENCE THAT SETTLED THE TAXONOMY IS THEIRS: LATENT, NOT MANIFEST.** On the only available case the
  config-versus-constant path **produces CORRECT OUTPUT**, so there is no defect present to detect -- a fixture
  would not catch a wrong number, it would prove a code path is exercised at all. That is `shipped-max-ease`'s
  shape with a **retirement condition that fires on its own**, not an AC-3.2-style coverage gap.

## TODO

- **BOTH AUDITS ARE DONE AND ON THEIR ROWS.** AC-3.6's runtime leg reduces to ONE property -- the emitted payload's
  `limits.max_ease` DERIVES from `limits::MAX_EASE_MS` -- with the negative half cited as two facts that survive hv
  item 2. AC-4.2 went from 86 characters to five measured findings. **Nothing is left to audit ahead of code.**
- **ON THE BOUNCE, IF hv HAS RULED ON serde_json:** cc restarts on the payload, and the FIRST BUILD POINTING AT 45h
  is the moment AC-2.1 leg 2, AC-5.1 and AC-6.1 leg 3 grade in ONE PASS. **Tell cc and snorkeltoast before it
  happens** -- a standing commitment to both -- and read the first `compare` as **population (2)**, a green over
  half a pipeline.
- **AC-3.6 SATISFIES WHEN THE RED-CONTROL RUNS, NOT WHEN THE PAYLOAD LANDS.** Flip `MAX_EASE_MS` to 3000, rebuild,
  the payload must follow. The template half is already a GATE and green -- vc ran it, 1 passed, 72 filtered.
- **AC-3.2 WAITS ONLY ON `report_unused`.** Six sites through one `classify()` verified; `Plan::used()` projects
  slides UNION reel-level, verified. The clause about EXTENDING `report_unused` is the only unbuilt part.
- **A PREDICTION DUE IN THE PAYLOAD SLICE:** `bug.file` is joined unclassified at `plan.rs:143` while four
  `Requires::Image` sites refuse, and **the reference DOES refuse it** (`build_bug`, `showreel:797`, dying by name
  on a missing file at `:809` and on a declared bug with no file at `:806`). cc takes it in the same commit as
  `build_bug`. Not a defect until delivery embeds the bug without refusing.
- **Verify cc's build-path slices as they land.** The built-ins pull landed at `bbca403` plus an untracked
  `crates/showreel/themes/`; next is font + favicon emission, then admission, normalisation, `collect_segment`.
- **Waiting on WP-03 by construction:** AC-2.1's leg 2 (adjacency stops being a guess when the Rust build stamps its
  own identity) and AC-2.4. **AC-2.12 stands as a recorded limit, not work.**
- **Two harness entries flip from `designed` to `observed`** the moment cc's build path calls the theme loader --
  the missing-favicon refusal and the `.ttf` refusal. Nothing to do until then; noted so their silence is not read
  later as coverage.

- **RE-RUN THE UNCALLED-FN SWEEP AT THE DELIVERY SLICE.** Four `pub fn` have zero production references --
  `template::render`, `normalise::embed`, `deliver::prune`, `deliver::stamp` -- and all four are the build path.
  **When the build verb lands, all four must acquire production callers; any that does not was built and
  forgotten.** Sent to cc as a checkable definition of build-verb-complete.
- **AC-2.1's CONTENT STRING IS snorkeltoast'S AND IS NOT YET SETTLED.** cc has been told to thread it through as a
  value and not to fix the string. When snorkeltoast answers, the row's spec takes the exact form.
- **hv OWES FOUR THINGS AND ALL FOUR ARE STILL OPEN.** `serde_json` is the one that unblocks work; the fixtures and
  the QR thread are decidable any time; the four FYIs want no ruling. hv's OWN board still reads
  "Utilz stable at v2.4.0. No stream in flight." from 2026-07-29 and is wrong in both halves -- hv's to edit.

- **MY SWEEP'S LIMIT, FOUND BY cc AND NOW ON AC-3.2.** I swept for `pub fn` with no production caller.
  `admit::Scan::report` PASSES that cleanly -- it has one, `slide.rs:425` -- and its **result is discarded on the
  success path**, read only inside `if files.is_empty()`. **Being CALLED and having its RESULT READ are different
  properties and I measured only the first.** The machinery-nothing-calls class one level down. Any future sweep
  must ask both.

## Holds

- **The whole of WP-03's remainder, and it is not vc's to lift.** CONDITION: **hv rules on `serde_json`.** The
  manifest requires hv's sign-off named in the commit for any crate; cc stopped rather than invent adjacent work,
  which was right. Verified figure: **net 2, 79 to 81**, both dedup keys agreeing.

## Open with hv

**TYPED BY WHETHER hv OWES A RULING, on cc's point that presenting an FYI as a decision wastes the attention and burying a decision among FYIs loses it.**

### Decisions hv owes

- **`serde_json` -- THE ONE THAT UNBLOCKS WORK.** Gates everything left in WP-03, not just AC-3.6. hv's inbox
  carries the verified number and a pre-answer to the question hv will ask -- why hand-write a calendar and not the
  emitter: a calendar is closed and pinnable against outside answers; JSON escaping of arbitrary YAML text is
  open-ended, and the reference's field order in a second home is a Highlander problem.
- **The public-repo fixtures.** Two pinned fixtures carry a named individual and a customer brand into a public
  repo. `upstream` is frozen, so nothing is published and it is decidable first.
- **The QR thread.** All four artifacts lack the QR social slide; and 45h's Showreel QR and its config BOTH name
  revision `-001` while artifacts exist at `-004` and `-007`. **vc is NOT asserting `-001` is stale** -- hv settles
  it in one look -- but if it is, nothing in either implementation would say so.

### FYI -- no ruling wanted

- **Rider on hv item 2:** capping Python's `max_ease` to 2400 turns WP-02's selftest RED by design. One small
  follow-up commit in snorkeltoast's tree. Not an argument against the fix.
- **`prez showreel build` will need `SHOWREEL_THEME_PATH` where the Python needed nothing** (cc, 18:24Z). H3
  working, not a regression. hv wants it BEFORE the first build, not during. A ruling only if hv wants the variable
  set somewhere permanent.
- **A correction to hv's own AC-3.7 reasoning** (cc, 18:51Z). hv withdrew the row saying nothing gates on the
  producer literal; nothing in the CONTRACT does, and that part stands. But `include_str!` puts `player.html` in
  the binary, so a verbatim pull would have taken the H3 strings count off zero. cc took the permission hv had
  already given; the note exists so the ruling's premise carries its exception.
- **cc retracted their own 23-vs-22 witness** (18:51Z). "My collect reaches 23 independently" was one
  implementation agreeing with itself about a number it derived. Running the reference's `plan()` on the same
  config gives 23 slides and 14 used assets. **The conclusion held and the witness changed** -- which is the
  stronger position, not a weaker one.

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

### A fourth kind of zero: the instrument's own match rule

**THE THREE KINDS WERE CENSUS, DETECTOR AND TAUTOLOGY. THERE IS A FOURTH AND I PRODUCED IT TODAY.** Sweeping for
`pub fn` with no production callers, I matched `name\s*\(` and got 7 of 36. **Three were false positives.**
`main.rs:123` is `slides.iter().flat_map(showreel::slide::Slide::assets)` -- a function passed as a VALUE, with no
parenthesis after its name -- so `assets`, `stem` and `next` were reported dead while being called.

**AC-3.8's OWN EVIDENCE REFUTED MY MEASUREMENT**, because it cited `main.rs:123` by file and line. A row whose
evidence asserts a property would have agreed with my wrong answer in silence; a row that cites source refuted it
in one read. **That is the argument for file:line evidence, made against me rather than by me.**

The rule: **a zero is only as wide as the match rule that produced it, and a match rule narrows the population
silently.** State the match rule beside the count -- "any occurrence of the identifier", not "the function is
uncalled" -- and run the control that proves the instrument can see the thing it is looking for. Same discipline
as naming a population; the instrument is part of the population.

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

### A stat is not a diff, and I read one hours after telling cc to read the other

**`c628c39` emptied AC-2.1's 16,839 characters to nothing.** The chain: a python heredoc raised on a bad `%`
format, so the scratch file was never written; `cat` failed; `$(cat file)` expanded to an EMPTY STRING; and
**`intent ac edit --text ""` accepted it without complaint.** Recovered at `5d4d39e` from `45a7419` and verified
rather than assumed -- ids match, no state differs anywhere, AC-2.1 is the only row whose text differs. **State was
never touched, so no satisfaction was lost.**

**THREE GUARDS WERE AVAILABLE AND I DEFEATED ALL THREE IN ONE COMMAND.** I ran `git diff --stat` in that very
command and read _"1 insertion, 1 deletion"_ -- which is exactly what a normal row edit looks like. The commit
output said **29 deletions** and I did not read that either. And I had told cc, hours earlier, to **read the canon
diff** before every canon commit. **A STAT IS NOT A DIFF**: it reports the SHAPE of a change and says nothing
about its content, and every catastrophic single-line edit has a normal-looking shape.

**THE TOOL HAS NO GUARD EITHER**: `intent ac edit --text ""` will destroy a criterion silently. That is the AC-3.9
shape in the tooling I depend on -- a rule held by discipline. **The rule now: any generated text that OVERWRITES
existing content gets a length assertion before the write, and the applier refuses rather than proceeds.** I added
one after the fact; it should have been there first, and my own AC-1.15 watch-out is about exactly this class.

**AND THE SWEEP INSTRUMENT FAILED TWICE THE SAME WAY EARLIER.** `name\s*\(` missed functions passed as values;
the corrected rule then matched `fast_image_resize`, a CRATE name, as a test name -- so it called AC-3.9
"enforced" when I had verified by hand that nothing enforces it. **Two rules, wrong in opposite directions, and
the honest output is a BRACKET rather than a number: between 2 and 26 satisfied rows are held by inspection
only.** The real answer needs reading, and pattern-matching prose cannot produce it. **Three instrument failures
in one day, all silent, all mine.**

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
