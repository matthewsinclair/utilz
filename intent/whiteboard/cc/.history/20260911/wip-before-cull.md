---
node: cc
name: Control Claude
role: control
session_id: a30f9092-03ed-44ba-a659-b37813af12c7
heartbeat_at: 2026-09-11 08:23Z
status: active
focus: "ST0017 49/54 computed 2026-09-10 19:55Z, not carried. WP-03 CLOSED; the compare RAN and AC-2.1 and AC-3.15 closed with it. Localfolded 8; parked with nothing queued. Open rows are snorkeltoast's floors (AC-2.19), WP-04 (3) and WP-05 (1) -- NONE MINE without hv re-sequencing."
claims: [ST0017]
---

# Control Claude (cc)

## DOING

**NOTHING IS IN FLIGHT. I AM PARKED**, and the condition that releases it is: hv sequences WP-04 or WP-05, or the compare returns something in my lane. **This heading claimed a digest of COMPLETED work until 2026-09-10 17:23Z** -- every bullet under it true, the label wrong, which is the class vc named: the entry is right and its frame is wrong, and nothing checks a frame.

## Delivered -- WP-03, closed 2026-09-10

**ST0017 -- snorkeltoast's `showreel` hoisted into Utilz as a Rust pipeline under `prez showreel`.** Slice narrative in `.history/20260909/` and `.history/20260910/`.

- **EVERYTHING IN WP-03 THAT COULD CLOSE IS CLOSED.** Theme resolution, admission (C1), normalisation (C2), the slide model, `embed`, the template, the plan, delivery naming, the producer stamp, the whole payload, and the **build verb** -- which writes a real artifact and gave `template::render`, `normalise::embed`, `deliver::prune` and `deliver::stamp` their production callers. Twelve red-proof injections across the last two slices, all twelve fired.
- **45h BUILT AND GRADED. Four invocation forms, all byte-identical**, sha `118a63f7...`, 5,462,781 bytes, 23 slides, **ZERO structural diffs**. Artifacts live at `.../artifacts-45h/` (session tmp) -- **I do not sweep them and will not delete them without telling vc.**
- **THE COMPARE FOUND THE ENCODER, IT IS MINE, hv ACCEPTED IT, AND AC-3.15 IS NOW SATISFIED** (`ac10001`) -- `normalise.rs:228` stays. **If ever reopened, the fact that decides it: `image` 0.25's `JpegEncoder` has exactly TWO constructors, neither offering optimize or progressive**, so parity needs a new crate, hv's named sign-off, and vc's AC-3.14 gate moved in the same commit.
- **AND IT IS TWO CAUSES, NOT ONE -- I REPORTED ONE AND SO DID vc.** snorkeltoast's `jpeg-encoder-bytes` entry separated them: **Pillow's `LANCZOS` against `imageops::Lanczos3` moves ANY resized raster** (exempt slides at 0.283 and 0.748, unexplained all day), and **my encoder difference sits on top of that for the JPEGs only.** The entry BOUNDS what it excuses -- ceiling 3.5 against a measured worst of 2.912948, red-proved by dropping it to 1.0 -- because an expectation with no ceiling is a permanent blind spot on exactly the slides carrying the artwork.
- **FIGURES RE-DRIVEN IN ONE EXECUTION, NOT CARRIED. CONTRACT 49/54 as at 2026-09-10 19:54Z** -- and **this line read 48/52, true when I measured it and stale by the time I wrote it**, which is the day's own rule landing on the fold that records it. 3 withdrawn; per-WP 15/15, 16/17, 12/13, 0/2, 2/3, 2/2; **289 tests, clippy 0, doctor 0**; **prez 4,384,912 release and UNMOVED all project, which is AC02's whole sign-off**; showreel 1,981,888; lock 81 entries.
- **hv's SAFETY CAP IS A STANDING RULING AND OUTLIVES ITS ROW: `limits::MAX_EASE_MS` is 2400, NOT the reference's 3000.** AC-3.6 is satisfied (vc drove the red control: move the constant and the payload's `limits` block follows; 3000 also crosses `MIN_DWELL_MS` 2500, which is the defect hv's cap closes). **The number is hv's decision, not a port detail**, so anyone restoring 3000 for parity would be reversing a ruling rather than fixing a divergence. **Lost in localfold 8; restored by the fold's own probe.**
- **`serde_json` IS IN at `0745d32`, hv NAMED**, ruled on the corrected one-argument case. **hv was offered the standing version -- a vc relay counting as sign-off -- and DECLINED it**, so every future crate addition returns to hv (AC-3.9).

## TODO

**EMPTY. Nothing is queued for me** -- WP-03's closable work is done and the remaining rows belong to WP-04, WP-05 or the gated compare. **RELEASED BY:** hv sequencing WP-04 or WP-05, or the compare returning something in my lane.

**This heading read `TODO -- the next slice, in order` until 2026-09-10 17:25Z, promising ordered queued work over a status report.** Third instance today of a frame outliving its contents.

**DONE AND OFF THIS LIST: the slide rows, `Reel::embed_target`'s caller, the build verb, vc's manifest gate.** The gate was the thing sequenced in front of the verb -- `tests/manifest.rs`, 5 tests, green here 2026-09-10. **I verified the target LINKS before believing the run**, because a `tests/` dir under a virtual manifest is silently uncompiled and reads exactly like a passing gate; the root manifest has a `[package]`, so it is real. Their file and the `acceptance.md` view are uncommitted and theirs.

## Not mine, held, or another node's -- nothing here is queued work of mine

**THIS HEADING SAID `Also queued` UNTIL 2026-09-10 17:23Z AND FOUR OF ITS FIVE ENTRIES WERE EXPLICITLY NOT MINE TO DO** -- two named as another node's in their own text. A heading is a claim about everything beneath it and it rots while every entry under it stays true.

- **THE FIVE OPEN ROWS, MEASURED MYSELF: AC-2.1 AC-3.4 AC-4.1 AC-4.2 AC-5.3.** AC-2.1 is the hv-gated compare; AC-3.4/4.1/4.2 are WP-04 by construction; AC-5.3 is WP-05's doctor line. **I am not opening WP-04 or WP-05 to look busy** -- that is hv's sequencing call, not mine.

- **AC-5.3 is JSON-free and NOT startable** -- `utilz doctor` must report `pdftoppm` as an optional line, but there is no showreel manifest, no `bin/` symlink, and `common.sh` is silent on showreel (re-measured 2026-09-10: `grep -c showreel common.sh` = 0, no `bin/showreel`). **THE `prez showreel` DISPATCH IS NOT PART OF THAT GAP AND I HAD IT WRONG** -- `opt/prez/prez:152` routes it and has since `b8dc9f1` yesterday. Needs WP-05's dispatch shape. **Held on vc's call**; opening WP-05 **at WP-03's then-10/12, as it stood on the morning of 2026-09-10**, to fill a gap would have been inventing adjacent work. **WP-03 is 12/13 now and the hold still stands on the same reasoning** -- the figure is dated because it is the reason a MORNING call was made, not a claim about now.
- **AC-3.4 AND AC-4.1 ARE OPEN AND ARE NOT MINE TO MOVE.** Both need WP-04's `init`: AC-3.4 spans two work packages by construction -- the POLICY is built here, its second application is init's -- and AC-4.1 needs population (3), which does not exist until a Rust `init` does. Named so a reader counting eight open rows against six on this board does not go looking.
- **PFIC the scan ordering when next in `admit.rs`** -- vc's, NOT a special trip.
- **Issue 0016** -- gate state in `manifest.sha256`, hv-scheduled as a WP-05 rider.
- Two homeless findings: `todo` verbs unreachable from Emacs; `hoist-rebase.sh`'s dead postcondition.

## Holds

_(none -- hv's `serde_json` ruling released the only one, 2026-09-10.)_

## Open with hv

**NOTHING OF MINE**, and that half I can verify: `serde_json` is ruled, named and closed. **THE REST IS A CLAIM ABOUT vc's QUEUE AND I CANNOT SEE IT** -- as of **2026-09-10 09:00Z** four items were theirs to put up (`SHOWREEL_THEME_PATH` FYI; `intent ac edit --text ""` destroying a criterion silently, an **Intent** defect not a Utilz one; the public-repo fixtures; the QR thread). vc has taken at least two further things to hv since (the `096a676` promote path, and the decisions hv answered with _"crack on"_), so **treat the four as a morning reading, not a live queue.** Peer state is the shortest-half-life thing on any board and there is no edge anyone could build to notice it moving.

## What the compare showed, 2026-09-10

- **AC-2.1 CLOSED. `population_source = stamp` on the port, `adjacency (UNVERIFIED)` on the reference** -- the harness knows what it graded by DERIVATION rather than by standing next to it.
- **6 of 19 graded slides failed, every one an artist artwork JPEG, one cause: the encoder.** Geometry agrees on every slide. hv accepted the divergence; **the residue is snorkeltoast writing it into `PORT_EXPECTATIONS` before the next compare, or every future run re-reports six adjudicated slides as fresh failure.** Not mine, and the kind of item that survives in nobody's TODO because the decision feels like the finish.
- **CARRY FROM snorkeltoast, NOT vc: `producer-fallback-strips` is `designed` on a FALSE `unobserved`** -- it claims no Rust-built artifact exists and **four do.** If the 23-of-23 figure is cited as live before their control runs on a port artifact, it is stale and they have said so themselves.
- **AC-2.19 opened against snorkeltoast's own instrument, by them:** the per-slide floors derive from a control measuring the REFERENCE'S STABILITY, so a zero floor demands bit-exactness no cross-language port can give. **The FAIL survives the correction** -- all six exceed `min_defect` by 4x to 13x.

## Watch-outs

**FIVE FAMILIES. (1)-(3) ARE ABOUT CLAIMS, (4) IS ABOUT THE INSTRUMENT THAT CHECKS THEM, AND (5) IS ABOUT THE FRAME THE CLAIM SITS IN.**

**(1) A CLAIM WHOSE POPULATION IS NOT STATED.** A green generalised across an unenumerated set, one member taken to characterise it, a number that never says what it counted, or two measurements agreeing because they share the error.

**(2) KNOWING A RULE IS NOT BEING PROTECTED BY IT.** I named a tell, corrected two files for carrying it, and wrote it into the next commit three hours later. **The guard belongs in the code, not in the discipline of whoever is typing.** Measured twice more on 2026-09-10, both against rules written on THIS board. Sibling: a red-proof can refute its own author's comment -- one injection moved **not one test** against three paragraphs of mine. **Length is not evidence.**

**(3) WHAT DOES 45h FAIL TO CONTAIN?** vc's generalisation: **45h is the only real config we have and it is WELL-FORMED, so it cannot exercise a refusal path.** A green from it is evidence about what it CONTAINS, and silence is what a reader takes for coverage. **It reaches RULES, not just refusals:** every artifact in `_out/` carries `limits` AND binds it, so a correct rule and an over-broad one pass identically. **Worst case: 45h and the pinned fixture BOTH set `target: 1920` == `normalise::TARGET`**, a three-way collision with the reference's default -- closed structurally (`stamp::producer` takes `&config::Reel`) and **discriminated only by the synthetic reel at 640**, which is the sole citation for that property.

**(4) AN INSTRUMENT REPORTING SOMETHING ADJACENT TO WHAT YOU NEEDED READS AS THE CHECK HAVING BEEN DONE.** **A dozen-plus instances across two nodes on 2026-09-10, every one looking correct at the time.** The instances are archived; the tells are the keepers:

- **A control returning zero needs a positive case proving it CAN return one.** An empty population proves nothing and looks rigorous.
- **The vacuous form looks MOST rigorous.** Sourcing the constant reads as careful; typing the literal reads as lazy; it is the other way round. **When a test's subject is "X derives from Y", the assertion must name X's VALUE, never Y.**
- **PIN THE SUBJECT IN THE SAME COMMAND THAT PRINTS IT**, and **never `head` output whose interesting end is the bottom.** Both of my worst reads were a channel dropping part of the answer silently -- `| head -3` swallowed a rebuild banner and I reported the opposite of the truth; a hardcoded label sat on a bare `git log -1` that reads HEAD while a peer committed.
- **A REGEX IS CODE, AND QUOTING CODE IN PROSE LOSES STRUCTURE SILENTLY.** `fs::(write|create_dir|remove)` re-typed as `fs::write|create_dir|remove` binds the prefix to one alternative and matches error strings. **Send the command AND its own output, from ONE execution** -- I sent both and they came from different runs, so a pattern yielding 52 sat beside the number 43 and nothing in the draft could see itself.
- **WHEN TWO GREPS DISAGREE, STOP TUNING AND ENUMERATE.** Two of us counted one crate: **43 and 36 flat, 3 and 8 filtered**, all honest. The settling move was listing every `fs::` call and classifying it -- **7 functions, 3 of them writes, ALL in `build.rs`: `:206` create_dir_all, `:215` write, `:235` remove_file, with `build.rs:201` `o.dir.join("_out")` the only reel-derived write target. THAT ENUMERATION IS vc's WP-04 TRIGGER** -- init's 2560px masters and the `pdftoppm` shell-out take it past three, and I owe them the fixture-safety condition the moment WP-04 opens. **Lost in localfold 8; restored by the fold's own probe.** **A pattern answers "does this match a rule I chose"; an enumeration answers "what does the code call"**, and only the second is auditable by someone who does not share the rule.
- **AND THE AUDIT IS AN INSTRUMENT AND IT IS IN THE POPULATION** -- vc's, the day's best. It needs a runnable form, a control, and **a population it did not choose by eye.** Both of their misses and both of mine landed at the classification step, the one nobody automated. **Reading cannot distinguish a number that is right from one that WAS right -- they are the same characters.**
- **ASK THE PARTY THAT MADE THE ERROR BEFORE WRITING DOWN WHY.** vc's, earned on me twice; **and I did the mirror to them and wrote a wrong cause about a peer into this board, in my own favour**, which is the worst entry either of us made. **A recorded instance with the wrong cause teaches the wrong guard.**
- **A CLAIM ABOUT A FILE SOMEBODY ELSE IS EDITING HAS A SHELF LIFE IN MINUTES. RE-READ IN THE SAME COMMAND THAT WRITES THE CLAIM**, and **CITE BY TOKEN, NEVER BY LINE NUMBER** -- three line citations into the reference decayed unnoticed, and `grep 'cfg.get("target"'` matches twice where `target = int(cfg.get("target"` matches once.
- **THE NEIGHBOUR OF A THING YOU JUST CORRECTED IS THE LEAST-EXAMINED ITEM ON THE PAGE.** Four instances, two each. Attention narrows to what it is holding. **Stated as a property, not an apology: it predicts where the next one is.**

**(5) THE ENTRY IS RIGHT AND ITS FRAME IS WRONG -- vc's, and nothing checks a frame.** Tense, label, or clock: the container asserts what its contents no longer support, and every entry underneath passes, which is why no gate catches it. Three on this board in one evening -- `DOING` holding completed work, `Also queued` holding four items explicitly not mine, `TODO` promising the next slice and delivering a status report. **A findings-in-TODO misfiles work that does not exist**; a reader at pickup either does it or wonders why nobody has.

**THE COROLLARY DECIDES WHAT MAY SIT ON A BOARD AT ALL: a number about a PAST EVENT stays true forever; a number about CURRENT STATE is a liability.** _"3 of 7 were false positives"_ is safe. _"contract 43/51"_ rots when somebody else commits. **A current-state number carries its clock or it does not get written** -- and computing it at write time beats checking it afterwards, which is a control rather than a guarantee.

### Red-proof mechanics

- **THE REVERT BELONGS IN A `finally`.** A harness that refuses on a post-check and leaves the tree injected reads exactly like "nothing happened", and makes every later measurement that session suspect.
- **A MULTI-FILE INJECTION IS ALL-OR-NOTHING** -- and **an all-or-nothing writer followed by an unconditional commit banks whatever the writer did not change.** Twice.
- **EVERY INJECTION PROVES IT APPLIED BEFORE ITS RESULT IS READ, AND THE APPLIER MUST REFUSE** -- `assert count(old) == 1` raises; a `grep -c` alongside is a reading and gates nothing. **The injection TEXT goes in the commit message.**
- **THE PROOF-OF-APPLICATION IS "the file CHANGED and the new text is present", NOT "the anchor is gone"** -- an append-style injection keeps its anchor by construction.
- **THE COUNT OF FIRING INJECTIONS IS NOT THE CONTROL -- EACH ONE FIRING IS.** A fixture whose values cannot distinguish two wrong answers tests neither: my rounding test's `2.5` case separated the two rounding MODES and was silent on whether rounding happened at all, so `as u32` stayed green until a `2.7` case was added. **Two independent ways to be wrong; the obvious fixture sees one.**
- **READ EVERY EXIT CODE DIRECTLY -- DO NOT PIPE A GATE.** zsh is `${pipestatus[1]}`, lowercase and 1-indexed; `${PIPESTATUS[0]}` is EMPTY and prints nothing while looking like a pass.

### Reading the reference, and reading your own code

- **"PARITY FIX OR DELIBERATE DIVERGENCE" IS ONE COMMAND: does the reference do this too.** **A CONDITION IS NOT A CONSEQUENCE** -- read the `return` under the `if`, not just the `if`.
- **AND WHERE THE REFERENCE IS WRONG, THE TEST IS: does the fix change PIXELS?** Escaping `</script>` decodes identically -- take it. AC-4.2's other half changes WHICH QR is embedded -- not taken silently.
- **TEST AGAINST SOMETHING YOU DID NOT WRITE, and the sharpest instance is a VALUE CLASS rather than a case.** Python `round()` is half-to-even, Rust's is half-away-from-zero, and they differ only on an exact `.5`. `1862 x 0.75 = 1396.5` was the one tie in fourteen live assets and **no fixture we choose can contain one, because nobody chooses 2560x1862.** `round_ties_even()` is Python's rule.
- **A CENSUS OVER THE WRONG UNIT IS STILL A CENSUS.** Census per KIND, and take the key set from an artifact the reference BUILT as well as from its source. `venue` carries `src` and NOT `w`/`h`/`name`.
- **AND `signature()` STRIPS `src` ENTIRELY** (`mark` flattens to `<present>`), so a venue slide LOSING its `src` is invisible to the harness and renders blank. **The payload test is the only thing over that half.** The exclusion is deliberate -- `src` IS pixels -- and doing an undeclared second job.
- **HIGHLANDER'S USUAL CHECK CANNOT SEE A SUBSET DUPLICATE.** A sweep finds the present fields agree; **the absent ones are not there to disagree.** Ask does the second carry every FIELD of the first.
- **BEING CALLED AND HAVING ITS RESULT READ ARE DIFFERENT PROPERTIES.** A `pub fn`-with-no-caller sweep passes a function whose caller discards its output. **Warnings are the acute case: this port made every warning a RETURN VALUE, so an undrained one is silent and nothing fails.**
- **A SUMMARY THAT CONTRADICTS THE THING IT SUMMARISES IS WORSE THAN NO SUMMARY.**
- **zsh DOES NOT WORD-SPLIT AN UNQUOTED VARIABLE** -- run shell tooling under `/bin/bash` with an ARRAY. **QUOTE THE HEREDOC DELIMITER (`<<'EOF'`).** **A COMMAND THAT DID NOT REBUILD REPORTS THE OLD ARTEFACT'S NUMBERS.**

## The estate

- **THE GATES ARE THE PRE-COMMIT ROSTER AND IT RUNS THEM ALL** -- `guards: 4 ran` plus `intent critic gate: 2 of 2` on every commit, so a commit that lands has passed them. By hand: `cargo test --workspace` and `cargo clippy --workspace --all-targets`, from `opt/prez/crate`.
- **NO PUSH TO `upstream` UNTIL hv LIFTS IT** (CI credits, 2026-09-09). upstream sits at **`60153d8`** -- **the SHA, not a count, because a count is stale one commit later.** **THE TRAP IS THE DEFAULT**: `branch.main.remote` is `upstream`, so a bare `git push` fires the matrix. **Name the remote.**
- **THE GIT INDEX HAS NO SINGLE-WRITER RULE.** A bare `git commit` takes the INDEX; the form that holds is **`git commit --only <paths>`**, and **a NEW file needs `git add -N` first**. `--only` plus a reformatting pre-commit hook leaves a **false `MM`** -- the hook's version lands while the index keeps yours; `git restore --staged` clears it.
- **AND `--only` GIVES NO PROTECTION ON A FILE WITH TWO WRITERS.** `intent/.canon/st/ST0017.json` carries vc's criteria AND my attachments, so path isolation stops being file isolation and the guard goes silent exactly where the collision is. Agreed convention (vc took it, declining single-writer): **read the canon DIFF before every canon commit and name every writer present in it**, and commit canon straight after each `intent` write rather than batching. **It makes a collision read rather than silent; it does not prevent one.**
- **A crate added to showreel needs hv's SIGN-OFF NAMED IN THE COMMIT** (AC-3.9), and **hv declined to let a vc relay stand in for it**, so it returns to hv every time. `deliver.rs`'s calendar is hand-written for the same budget reason and duplicates nothing.
- **AN `include_str!` NOBODY REFERENCES IS DROPPED BY THE LINKER** -- `player.html` is 45 KB in the tree and 0 bytes in the binary until `build` wires it, so what covers the shell is the source-level test reading `SHELL` at compile time, not `strings`.
- **Utilz declares its languages in TWO files** -- `bin/.devbin/config.yaml` and `intent/.config/config.json`.
- **THE THREE PATHS, because rediscovering them after a compact cost ten tool calls.** Reference `~/Library/CloudStorage/Dropbox/Projects/Snokeltoast/bin/showreel/` (`showreel`, `player.html`, `themes/`, `FLOORS.md`, `showreel-harness`); live reel `.../Snokeltoast/marketplace/artists/10-active/45h/showreel/`; pinned fixture `opt/prez/crate/crates/showreel/fixtures/45h.showreel.yaml`. **`mdfind -name` finds them and `find` under `~/Devel` does NOT** -- Dropbox lives at `~/Library/CloudStorage`, and the tree is spelled **Snokeltoast**, no `r`.

## Decisions

- (2026-09-10) **hv: TAKE `serde_json`**, on the corrected one-argument case -- escaping over arbitrary YAML text. **The field-order argument was refuted by my own design.md 4.6** and hv ruled without it.
- (2026-09-10) **The `limits` invariant is INTERNAL CONSISTENCY, not a required key.** An artifact whose own embedded player reads `REEL.limits` unguarded must carry the keys that player reads -- answerable from the artifact alone, and it lifts itself when a player guards its read. **The blanket version was refuted by the published build**, which has no such key, embeds the older player and is entirely sound. **A rule that refuses a correct artifact is worse than the blind spot it replaces.**
- (2026-09-09) **vc: an `exclude:` drop is NOT a dropped segment input** -- an author's instruction obeyed, not an accident. **The ROW's text changed, not my position.**
- (2026-09-09) **The producer stamp goes in the PORT's shell, filled by the Rust build only** -- on the two alternatives' costs. **NOT because absence derives Python:** `adjacency (UNVERIFIED)` is a refusal to derive, and vc withdrew that reasoning after it had reached three of my files. **The marker is a TOKEN, never a literal** -- the artifact is `player.html` with substitutions, so a real value would be inherited verbatim and turn an honest refusal into a confident wrong answer.
- (2026-09-09) **hv: the Python fallback is DEAD.** _"Not on your life. We're only doing work that moves this FORWARD."_
- (2026-09-09) **hv: `max_ease` capped at 2400**, closing the `?speed=` crossing STRUCTURALLY. The payload is where it reaches the runtime.
- (2026-09-09) **hv H-C: the command is `prez showreel build <dir>`.**
