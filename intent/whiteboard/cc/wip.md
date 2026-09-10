---
node: cc
name: Control Claude
role: control
session_id: a30f9092-03ed-44ba-a659-b37813af12c7
heartbeat_at: 2026-09-10 17:13Z
status: active
focus: "ST0017 at 47/52, verified myself not taken: everything closable in WP-03 IS CLOSED. 289 tests, all gates 0. The five open rows are WP-04 (3), WP-05 (1) and the hv-gated compare (1). NOTHING IS MINE TO MOVE without hv re-sequencing."
claims: [ST0017]
---

# Control Claude (cc)

## DOING

**ST0017 -- hoisting snorkeltoast's `showreel` into Utilz as a Rust pipeline under `prez showreel`.** Localfolded 2026-09-10 08:43Z; the slice-by-slice narrative is in `.history/20260909/` and `.history/20260910/`.

- **BUILT AND RED-PROVED:** theme resolution, admission (C1), normalisation (C2), the slide model, `embed`, the template, the plan, delivery naming, the producer stamp, AC-3.2's drop report, the whole payload, and **the BUILD VERB at `8bef628`** -- twelve injections across the two slices, all twelve fired. **288 tests.**
- **THE VERB LIVES IN THE LIBRARY, NOT `main.rs`.** Orchestration in a binary cannot be tested -- you can only run the process and grade its stdout. `build::run` returns a `Built`; `main.rs` prints it. `check` and `build` share ONE `open()`, because two routes through the same config would make a green `check` evidence about `check`.
- **A PRODUCED ARTIFACT STAMPS `embed=640` FROM A `target: 640` REEL.** `normalise::TARGET` is 1920 and every real reel here sets 1920, so the constant-for-config swap is invisible estate-wide. Proven on the written file, not the emitter.
- **`producer-fallback-strips` IS NOW A MEASUREMENT.** vc's regex: **1 hit** on a reference-built artifact, **0** on a port-built one, same run. The control fires, so the zero is a measurement and not an empty population.
- **`check` RESOLVES THE LIVE 45h CONFIG**, both invocation forms, exit 0, silent at both report altitudes: **23 slides, 14 assets -- matching the reference's own `plan()`**, so the port is checked against something other than itself.
- **WP-01 15/15. Contract 43/51, 3 withdrawn. WP-03 10/12; WP-02 16/17; WP-04 0/2; WP-05 1/3; WP-06 1/2.**
- **`serde_json` IS IN at `0745d32`, hv NAMED, ruled 2026-09-10 on the corrected ONE-argument case.** Lock **79 to 81 entries**; AC-3.10's union **71 to 73**; prez unmoved at 17. **I took the sign-off from hv DIRECTLY rather than from vc's accurate relay** -- a peer's report cannot produce a NAMED sign-off -- and **hv was offered the standing version and declined it**, so every future crate addition returns to them the same way.
- **AC-3.6's RUNTIME LEG IS MINE AND IS NOW BUILT.** The payload's `limits.max_ease` **DERIVES** from `limits::MAX_EASE_MS` and ships as **2400, not the reference's 3000**; the red-control fires (move the constant, the block follows). **The ROW IS STILL OPEN** -- it needs a built artifact, not a struct. **Cite it by TOKEN, never by line number**: the harness's line numbers moved three times today.
- **prez is 4,384,912 AND HAS NOT MOVED ALL PROJECT, WHICH IS AC02's WHOLE SIGN-OFF.** showreel is **535,968**, up 16 bytes from 535,952 when `payload.rs` and `stamp.rs` landed -- the first movement in either binary this session, and worth naming rather than restating a stale figure.

## TODO -- the next slice, in order

1. **NOTHING IS MINE. WP-03's CLOSABLE WORK IS DONE** -- AC-5.1 and AC-6.1 closed by vc at `f2046f9`, driven rather than taken from my report. **SIX artifacts now carry ONE sha** (`118a63f7...`, 5,462,781): my four invocation forms plus vc's two, built in a different session -- so the build is deterministic across route AND across sessions, which is more than AC-5.1 asked.
2. **THE FIVE OPEN ROWS, MEASURED MYSELF: AC-2.1 AC-3.4 AC-4.1 AC-4.2 AC-5.3.** AC-2.1 is the hv-gated compare; AC-3.4/4.1/4.2 are WP-04 by construction; AC-5.3 is WP-05's doctor line. **I am not opening WP-04 or WP-05 to look busy** -- that is hv's sequencing call, not mine.

**DONE AND OFF THIS LIST: the slide rows, `Reel::embed_target`'s caller, the build verb, vc's manifest gate.** The gate was the thing sequenced in front of the verb -- `tests/manifest.rs`, 5 tests, green here 2026-09-10. **I verified the target LINKS before believing the run**, because a `tests/` dir under a virtual manifest is silently uncompiled and reads exactly like a passing gate; the root manifest has a `[package]`, so it is real. Their file and the `acceptance.md` view are uncommitted and theirs.

## Also queued

- **AC-5.3 is JSON-free and NOT startable** -- `utilz doctor` must report `pdftoppm` as an optional line, but there is no showreel manifest, no `bin/` symlink, and `common.sh` is silent on showreel (re-measured 2026-09-10: `grep -c showreel common.sh` = 0, no `bin/showreel`). **THE `prez showreel` DISPATCH IS NOT PART OF THAT GAP AND I HAD IT WRONG** -- `opt/prez/prez:152` routes it and has since `b8dc9f1` yesterday. Needs WP-05's dispatch shape. **Held on vc's call**; opening WP-05 at 10/12 to fill a gap is inventing adjacent work.
- **AC-3.4 AND AC-4.1 ARE OPEN AND ARE NOT MINE TO MOVE.** Both need WP-04's `init`: AC-3.4 spans two work packages by construction -- the POLICY is built here, its second application is init's -- and AC-4.1 needs population (3), which does not exist until a Rust `init` does. Named so a reader counting eight open rows against six on this board does not go looking.
- **PFIC the scan ordering when next in `admit.rs`** -- vc's, NOT a special trip.
- **Issue 0016** -- gate state in `manifest.sha256`, hv-scheduled as a WP-05 rider.
- Two homeless findings: `todo` verbs unreachable from Emacs; `hoist-rebase.sh`'s dead postcondition.

## Holds

_(none -- hv's `serde_json` ruling released the only one, 2026-09-10.)_

## Open with hv

**NOTHING OF MINE.** `serde_json` is ruled, named and closed. Four items remain and all are vc's to put up: `SHOWREEL_THEME_PATH` (FYI), `intent ac edit --text ""` destroying a criterion silently (an **Intent** defect, not a Utilz one), the public-repo fixtures, and the QR thread.

## What the first compare is expected to show

- **F2 IS 23**, from 009's config, unchanged. snorkeltoast's re-derived FLOORS.md against 009: **22 gradeable, 1 ungradeable, 0 undecided, 0 windowless, of 23**, reproducible over two independent 13-capture passes.
- **EXPECT A GRADEABILITY DIFFERENCE: 23 of 23 here against 22 of 23 for the reference.** `add` is `(k,v) => { if (v) ... }`, byte-identical in both shells, so it skips falsy; the reference's `|| "Snorkeltoast"` keeps the Producer row alive under stripping and this shell's removal does not. `strip_reason` now probes the artifact's own source for `REEL.producer ||`, so the difference is visible to the instrument. **It is the port REMOVING a defect, which is the hardest difference to read correctly in the moment** -- so it goes into `PORT_EXPECTATIONS` first, and **verified against the harness AS IT WILL BE at compare time**, not as it is now.
- **READ THE FIRST GREEN AS POPULATION (2), NOT (3).** 45h's masters are Python `init`'s output and **nothing in the harness distinguishes the two**.

## Watch-outs

**FOUR FAMILIES. THE FIRST THREE ARE ABOUT CLAIMS; THE FOURTH IS ABOUT THE INSTRUMENT THAT CHECKS THEM, AND IT IS THE ONE THAT MAKES EVERYTHING ELSE SUSPECT WHEN IT FAILS.**

**(1) A CLAIM WHOSE POPULATION IS NOT STATED.** A green generalised across an unenumerated set, one member taken to characterise it, a number that never says what it counted, or two measurements agreeing because they share the error.

**(2) KNOWING A RULE IS NOT BEING PROTECTED BY IT.** I named a tell, corrected two files for carrying it, and wrote it into the next commit message three hours later. **The guard belongs in the code, not in the discipline of whoever is typing.** Sibling: a red-proof can refute its own author's comment -- one injection moved **not one test** against three paragraphs of mine. **Length is not evidence.**

**(3) WHAT DOES 45h FAIL TO CONTAIN?** vc's generalisation, better than my instances: **45h is the only real config we have and it is WELL-FORMED, so it cannot exercise a refusal path.** Five known, each on its AC row. **A GREEN FROM 45h IS EVIDENCE ABOUT WHAT 45h CONTAINS, AND SILENCE IS WHAT A READER TAKES FOR COVERAGE.** **The converse belongs beside "test against something you did not write":** the live config caught a missing `#[serde(rename = "loop")]` and is worth nothing for any detector. **And it reaches RULES, not just refusal paths:** every artifact in `_out/` carries a `limits` key AND binds it, so my whole population satisfies a correct rule and an over-broad one identically -- a check written against it would have passed under either and I could not have known which I had built. **Worst case measured: 45h AND the pinned fixture BOTH set `target: 1920` == `normalise::TARGET`**, so no reel here can catch a build reading the constant instead of the config. Closed structurally instead: `stamp::producer` takes `&config::Reel`, so a caller cannot pass the constant.

**(4) AN INSTRUMENT REPORTING SOMETHING ADJACENT TO WHAT YOU NEEDED READS AS THE CHECK HAVING BEEN DONE.** **This is the day's dominant shape and every instance looked correct at the time.** Seven, four mine:

- a `strings` census over a shell **the linker had dropped** -- all four control strings read 0 while a live one read 3;
- an assertion sourcing the very constant it was testing, so it moved when the constant moved and **could never fail**;
- a **negative** assertion (`!contains("missing")`), which passes on almost any failure -- it passed against exactly the defect it was written to catch;
- vc reading a `git diff --stat` where their own convention said **diff** -- **A STAT IS NOT A DIFF**, and it cost 16,839 characters of AC-2.1;
- vc's comment-exclusion claimed as a control that **excluded zero** -- an empty population, proving nothing;
- vc and I both quoting a harness function that had **already been replaced**;
- **my red-proof applier's own proof-of-application** -- `assert after.count(old) == 0`, which is invalid whenever the replacement CONTAINS the anchor, as every append-style injection does. **THE HARNESS WE GRADE WITH IS IN THE POPULATION, NOT OUTSIDE IT**, and this one refused on a correct injection while reporting it as a failed application.

**THE TWO TELLS.** A control returning zero needs a positive case proving it CAN return one. And **the vacuous form is the one that looks most rigorous** -- writing the constant in reads as sourcing the value, typing the literal reads as lazy, and it is the other way round. **When a test's subject is "X derives from Y", the assertion must name X's VALUE, never Y.**

**AND THE TRUNCATED READ IS THE PUREST FORM: THREE INSTANCES IN ONE HOUR, ALL MINE, ALL REPORTED AS MEASUREMENTS.**

- **`| head -3` SWALLOWED THE ANSWER.** I ran `./bin/prez showreel build ... | head -3`; the auto-rebuild banner filled all three lines, so I never saw the result -- and then reported `prez showreel` as unwired. Same shape as `${PIPESTATUS[0]}` already on this board: **the meaningful part of the output came last and the instrument only showed the first part.**
- **I TESTED A DIFFERENT PROGRAM.** `target/release/prez` genuinely does not know `showreel`; `bin/prez` is the `utilz` DISPATCHER and routes it. I generalised from the binary to the shim and they are not the same executable. **vc measured all four forms and every one answered.**
- **A HARDCODED LABEL ON AN UNPINNED QUERY.** I printed `commit 4a800d6 %ad` from a bare `git log -1`, which reads HEAD -- and vc had committed `ed8986a` in between, so the label named one commit and the data came from another. **The output asserted a provenance the command never queried.**

**AND WHEN TWO PEOPLE'S GREPS DISAGREE, STOP TUNING THE GREP AND ENUMERATE THE POPULATION.** vc and I counted the same crate's write surface and got **43 and 36 flat, 3 and 8 filtered** -- four numbers, one crate, and the disagreement was entirely in the match rules. The settling move was not a better pattern: it was listing **every `fs::` call in production code and classifying it** -- 7 distinct functions, 3 of them writes, all in `build.rs`. **A pattern answers "does this line match a rule I chose"; an enumeration answers "what does the code call", and only the second can be audited by someone who does not share your rule.** vc's keeper is the general form: **a count without its match rule is not a measurement.**

**AND THE ATTRIBUTION WENT WRONG IN THE SAME EXCHANGE, WHICH IS THE POINT UNDERNEATH IT.** vc diagnosed my pattern as over-sensitive; measured, **mine gives 43/3 and matches no prose**, and the over-sensitive version was their TRANSCRIPTION of it -- `fs::(write|create_dir|remove)` re-quoted as `fs::write|create_dir|remove`, where the prefix binds to the first alternative only and bare `remove` then matches an error message about removing. **Their own rule, twice in one day: ask the party that made the error before writing down why they made it.** Their fix is still the better pattern -- it catches `fs::copy` and `fs::rename`, which mine would miss -- and the crate calls neither, so the 3 was right for a reason narrower than it looked.

**THE COMMON TELL: PIN THE SUBJECT IN THE SAME COMMAND THAT PRINTS IT**, and never `head` output whose interesting end is the bottom -- use `tail`, or read it whole.

**AND A FOURTH, ON A NUMBER: I CARRIED A SIZE ACROSS A REBUILD.** I handed vc 5,462,653 bytes, measured on the PRE-FIX artifact, for a POST-FIX file that is 5,462,781. The sha I sent was right because I took it from the real file; only the figure was stale. **Measure every number from the artifact you are actually handing over, in the same command that names it.**

**AND THE STALE READ IS THE SAME FAMILY WITH A CLOCK ON IT -- TWICE TODAY, THE SECOND TIME AGAINST THIS VERY LINE.** I told vc AC-3.14 was ungraded from an `intent ac list` read taken **eight minutes earlier**, across which they landed AT03 into the store. The CLI was right both times; I asserted an answer I had stopped holding. **RE-READ IN THE SAME COMMAND THAT WRITES THE CLAIM** is the guard, and it is on this board because I wrote it here yesterday. **Sibling, same hour: I typed a `heartbeat_at` of 09:31Z while the clock read 09:26Z** -- a stamp produced from nothing, which is what the protocol means by fabricated rather than approximate. Corrected from an actual read. **A clock value goes in only when the command that produced it is in front of you in the same turn.**

**AND vc's RULE, EARNED ON ME: ASK THE PARTY THAT MADE THE ERROR BEFORE WRITING DOWN WHY THEY MADE IT.** They diagnosed my AC-3.14 slip as reading `state.is` from raw canon. Right that I was wrong, wrong about the cause, and **a recorded instance with the wrong cause teaches the wrong guard** -- theirs implied "read the computed answer" where what I needed was "re-read". The mirror is mine to honour too.

**AND: A CLAIM ABOUT A FILE SOMEBODY ELSE IS EDITING HAS A SHELF LIFE MEASURED IN MINUTES.** vc and I wrote sound analyses of `strip_reason` twenty minutes apart, both against a version snorkeltoast had already replaced; mine argued their prediction was wrong using code that no longer existed. It is snorkeltoast's own rule with people in place of a stack trace -- **do not edit a script while a long run is in flight, because the traceback resolves against the new file.** **RE-READ IN THE SAME COMMAND THAT WRITES THE CLAIM** (the harness's mtime was one minute before my read) and **CITE BY TOKEN, NEVER BY LINE NUMBER** (all three call sites I cited had moved within the hour).

### Red-proof mechanics

- **A HARNESS THAT DOES NOT CLEAN UP ON REFUSAL IS WORSE THAN ONE THAT NEVER REFUSES.** Mine wrote an injection, refused on a post-check, **and left the tree injected because the revert was on the success path** while the console read `REFUSED` -- which is exactly what "nothing happened" looks like. **The revert belongs in a `finally`**, and the blast radius is why: a harness that can leave a tree injected makes every later measurement that session suspect and not one would look wrong.
- **A MULTI-FILE INJECTION IS ALL-OR-NOTHING ACROSS EVERY FILE** -- and **an all-or-nothing writer followed by an unconditional commit banks whatever the writer did not change.** Twice today.
- **EVERY INJECTION PROVES IT APPLIED BEFORE ITS RESULT IS READ, AND THE APPLIER MUST REFUSE** -- `assert count(old) == 1` raises; a `grep -c` printed alongside is a reading and gates nothing. **The injection TEXT goes in the commit message.**
- **AND THE PROOF-OF-APPLICATION IS `the file CHANGED and the new text is present`, NOT `the anchor is gone`.** An append-style injection keeps its anchor by construction, so the anchor-gone form refuses a correct injection and calls it a failed write. Claim the anchor gone only when the anchor is not part of the replacement.
- **THE COUNT OF FIRING INJECTIONS IS NOT THE CONTROL -- EACH ONE FIRING IS.** Four of five and five of six both read as good results. **A fixture whose values cannot distinguish two orderings tests neither.**
- **THE INSTRUMENT THAT GATES IS NOT THE INSTRUMENT YOU RAN. Read every exit code directly -- do not pipe a gate.** In zsh that is `${pipestatus[1]}`, lowercase and 1-indexed; `${PIPESTATUS[0]}` is EMPTY and prints nothing while looking like a pass.

### Reading the reference, and reading your own code

- **"PARITY FIX OR DELIBERATE DIVERGENCE" IS ONE COMMAND: does the reference do this too.** I framed `fit: cvoer` as a divergence with `showreel:828` on screen in the same session. **vc met the mirror twice in one afternoon.** **A CONDITION IS NOT A CONSEQUENCE:** both from reading an `if` and not the `return` under it.
- **AND WHERE THE REFERENCE IS WRONG, THE TEST IS: does the fix change PIXELS?** `json.dumps` escapes neither `<` nor `/`, so `</script>` in a config breaks the artifact -- escaping it decodes identically and changes nothing on screen, so take it. AC-4.2's unstamped-QR warning changes no pixels either and is taken. The other half of AC-4.2 changes **which QR is embedded**, so it is not taken silently.
- **A CENSUS OVER THE WRONG UNIT IS STILL A CENSUS.** The reference adds `w`/`h`/`name` in `cmd_build` under `if s.get("path")`, so **`venue` carries `src` and NOT the dimensions** -- it embedded its own image a function earlier and never had a `path`. The natural rule _if it has an image, add src/w/h/name_ is wrong on **exactly one kind of twelve, and it is the kind that would still RENDER.** Census per KIND, not per file, and take the key set from an artifact the reference BUILT as well as from its source.
- **HIGHLANDER'S USUAL CHECK CANNOT SEE A SUBSET DUPLICATE.** A sweep finds the present fields agree; **the absent ones are not there to disagree.** `main.rs` carried 2 of the pace table's 5 fields and both were CORRECT. Ask **does the second carry every FIELD of the first**.
- **BEING CALLED AND HAVING ITS RESULT READ ARE DIFFERENT PROPERTIES.** vc's sweep for `pub fn` with no production caller passed `admit::Scan::report` cleanly -- it had a caller, and the caller discarded its output on the success path. That was AC-3.2's whole remaining clause.
- **A SUMMARY THAT CONTRADICTS THE THING IT SUMMARISES IS WORSE THAN NO SUMMARY.** My board claimed both dedup keys agreed while AC-3.10's evidence named the two crates that disagreed; `SHELL`'s doc said "one line different" while the module doc twenty lines above said two.
- **zsh DOES NOT WORD-SPLIT AN UNQUOTED VARIABLE** -- run shell tooling under `/bin/bash` with an ARRAY. **QUOTE THE HEREDOC DELIMITER (`<<'EOF'`)** whenever the body carries shell syntax. **A COMMAND THAT DID NOT REBUILD REPORTS THE OLD ARTEFACT'S NUMBERS.**

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
