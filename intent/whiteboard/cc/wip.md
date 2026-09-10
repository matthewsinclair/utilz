---
node: cc
name: Control Claude
role: control
session_id: a30f9092-03ed-44ba-a659-b37813af12c7
heartbeat_at: 2026-09-10 07:54Z
status: active
focus: "ST0017/WP-03. UNBLOCKED: hv ruled serde_json 2026-09-10 and it is in at 0745d32 with hv named. The payload's non-slide half landed at 6cbb16b -- limits, socials with the stale-QR warning, bug with its admission. 273 tests. NEXT: the slide rows, then the build verb."
claims: [ST0017]
---

# Control Claude (cc)

## DOING

**ST0017 -- hoisting snorkeltoast's `showreel` into Utilz as a Rust pipeline under `prez showreel`.** Localfolded 2026-09-10 06:46Z; the slice-by-slice narrative is in `.history/20260909/` and `.history/20260910/`.

- **`utilz prez showreel check <45h dir>` RESOLVES THE WHOLE CONFIG**, both invocation forms, exit 0: 15 segments, **23 slides, 14 assets**, 5 fonts and a favicon inlined, silent at both report altitudes. **Both numbers match the reference's own `plan()` on the same config** -- the port is checked against something other than itself.
- **BUILT AND RED-PROVED:** theme resolution, admission (C1), normalisation (C2), the slide model, `embed`, the template, the plan, delivery naming, the producer stamp's mechanism and content, AC-3.2's drop report. **262 tests.** prez **4,384,912** against the 8,388,608 budget, showreel **535,952** -- both byte-identical since 8 Sep, because nothing links the new code yet.
- **WP-01 15/15. Contract 43/51, 3 withdrawn. WP-03 10/12; WP-02 16/17; WP-04 0/2; WP-05 1/3; WP-06 1/2.**
- **`serde_json` IS IN at `0745d32`, hv NAMED, RULED 2026-09-10 ON THE CORRECTED ONE-ARGUMENT CASE.** Lock **79 to 81 entries** exactly as predicted; AC-3.10's union **71 to 73**, prez unmoved at 17. **I took the sign-off from hv DIRECTLY rather than from vc's accurate relay** -- a peer's report cannot produce a NAMED sign-off -- and **hv was offered the standing version and declined it**, so every future crate addition returns to them the same way.
- **THE PAYLOAD'S NON-SLIDE HALF IS IN at `6cbb16b`:** `limits` with all three keys and `max_ease` at **2400 not the reference's 3000**; socials with the stale-QR warning **plus the unstamped case the reference is blind to**, taken because it changes no pixels; `bug` with its admission, which makes `admit`'s call sites **seven** and which vc amended AC-3.2 for at `0d781c9`. **WHAT IS LEFT:** the slide rows **minus `path` and `asset`, which the reference pops at `:993-994`** and which `compare_structure` would report against every image slide; threading `Reel::embed_target()` to the embed site; then the `build` verb writing `_out/` and calling report, prune and the stamp.
- **AC-3.6's RUNTIME LEG IS MINE AND IS ONE PROPERTY:** the payload's `limits.max_ease` **DERIVES** from `limits::MAX_EASE_MS`. `player.html:561` is `const LIM = REEL.limits`. Red-control: flip the constant to 3000, the payload must follow. **Cite `showreel-harness:232` and `:1098`, NOT `shipped-max-ease`**, which retires itself the day Python is capped.
- **TELL vc AND snorkeltoast BEFORE ANY BUILD POINTS AT 45h.** AC-2.1 leg 2, AC-5.1 and AC-6.1 leg 3 grade in ONE pass and **the first `compare` happens exactly once**; snorkeltoast's `compare` will REFUSE, because the live config plans **23** against FLOORS.md's **22** -- config-vs-008, no part of it the port. **And read that first green as population (2), not (3):** 45h's masters are Python `init`'s output and **nothing in the harness distinguishes the two**.
- **THE SLIDE COUNT MAY MOVE UNDER ME, SO CHECK IT BEFORE THE FIRST BUILD RATHER THAN AFTER.** hv has sequenced a reference rebuild for the QR social AHEAD of the ruling, and **if that rebuild changes the reel's count, that is the number my build must match** -- 22 against 23 fails F2 whoever's floors are held. snorkeltoast has been asked to state the count explicitly when it lands. **The ordering also buys something real:** the 14-minute control runs inside my blocked window instead of between my build and the first `compare`, and my build gets config-matched to a freshly rebuilt reference by construction rather than by somebody remembering.

## TODO

- **AC-5.3 is the one JSON-FREE row left, and it is NOT startable.** `utilz doctor` must report `pdftoppm` as an optional line -- but there is no showreel manifest, no `bin/` symlink, and `common.sh` does not mention showreel, so it needs WP-05's dispatch shape first. **Opening WP-05 at WP-03 10/12 is vc's sequencing call**, and `main.rs`'s own comment argues against borrowing that surface early. Surfaced to vc, not started.
- **PFIC the scan ordering when next in `admit.rs`** -- vc's, and NOT a special trip. Extract the sort as a pure function over a `Vec` so the test stops depending on the filesystem returning unsorted entries.
- **Issue 0016** -- record gate state in `manifest.sha256`. hv scheduled it as a **WP-05 rider**.
- Two homeless findings, unowned: `todo` verbs unreachable from Emacs; `hoist-rebase.sh`'s dead postcondition.

## Holds

_(none -- hv's `serde_json` ruling released the only one, 2026-09-10.)_

## Open with hv

**vc synthesises these; the detail is in `hv/inbox.cc.md` and `hv/inbox.vc.md`, not here.**

- **`serde_json` IS RULED AND CLOSED.** Nothing of mine is with hv.
- **Four others need no work from me and are vc's to put up:** `SHOWREEL_THEME_PATH` (FYI, a ruling only if hv wants it permanent); `intent ac edit --text ""` destroying a criterion silently, an **Intent** defect rather than a Utilz one; the public-repo fixtures; and the QR thread.

## Watch-outs

**FOUR FAMILIES. THE FIRST THREE ARE ABOUT CLAIMS; THE FOURTH IS ABOUT THE INSTRUMENT THAT CHECKS THEM, AND IT IS THE ONE THAT MAKES EVERYTHING ELSE SUSPECT WHEN IT FAILS.**

**(1) A CLAIM WHOSE POPULATION IS NOT STATED.** Four faces: a green generalised across an unenumerated population; one member taken to characterise a set; a number recorded without naming what it counted; two measurements agreeing because they share the population error.

**(2) KNOWING A RULE IS NOT BEING PROTECTED BY IT.** I named "the injection proved applied before its result was read" as the TELL of a reading, corrected two files for carrying it, **and wrote it into the next commit message three hours later.** **The guard belongs in the code, not in the discipline of whoever is typing.** Sibling: a red-proof can refute its own author's comment -- C2's reordering injection moved **not one test** against three paragraphs of mine. **Length is not evidence.**

**(3) WHAT DOES 45h FAIL TO CONTAIN?** vc's generalisation, better than my instances: **45h is the only real config we have and it is WELL-FORMED, so it cannot exercise a refusal path.** Five known, each on its AC row. **A GREEN FROM 45h IS EVIDENCE ABOUT WHAT 45h CONTAINS, AND SILENCE IS WHAT A READER TAKES FOR COVERAGE.** **And the converse belongs beside "test against something you did not write":** the live config caught a missing `#[serde(rename = "loop")]` and is worth nothing for any detector. **Worst case measured: 45h AND the pinned fixture BOTH set `target: 1920` == `normalise::TARGET`, so the whole config population is blind to config-versus-constant by construction.** Closed structurally instead -- `stamp::producer` takes `&config::Reel`, so a caller cannot pass the constant by mistake.

**(4) THE INSTRUMENT ITSELF.**

- **AN INSTRUMENT REPORTING SOMETHING NEAR WHAT YOU NEEDED READS AS THE CHECK HAVING BEEN DONE.** Three instances in two days, none of which looked wrong: a `strings` census over a shell **the linker had dropped**; an assertion sourcing the very constant it was meant to test; vc reading a `git diff --stat` where the convention said **diff**. **A STAT IS NOT A DIFF** (vc's words, after it cost them 16,839 characters of AC-2.1).
- **THE VACUOUS ASSERTION IS THE ONE THAT LOOKS MOST RIGOROUS.** `contains(&format!("embed={}", TARGET))` reads as _sourcing_ the value; `contains("embed=1920")` reads as lazy. **It is the other way round** -- the first moves when the constant moves and can never fail. **When a test's subject is "X derives from Y", the assertion must name X's VALUE, never Y.**
- **A RED-PROOF HARNESS THAT DOES NOT CLEAN UP ON REFUSAL IS WORSE THAN ONE THAT NEVER REFUSES.** Mine wrote an injection, refused on a post-check, **and left the tree injected because the revert was on the success path.** The console read `REFUSED`, **which is exactly what "nothing happened" looks like.** The revert belongs in a `finally`, and the blast radius is why: a harness that can leave a tree injected makes every later measurement that session suspect, and not one would look wrong. **A multi-file injection must be all-or-nothing across every file** -- and an all-or-nothing writer followed by an unconditional commit banks whatever the writer did not change.
- **THE COUNT OF FIRING INJECTIONS IS NOT THE CONTROL -- EACH ONE FIRING IS.** `G` moved nothing because Rust's `Path` compares by components and drops `CurDir`; `L` moved nothing because a zero-padded fixture makes lexical and numeric order coincide. **Four of five and five of six both read as good results.** **A fixture whose values cannot distinguish two orderings tests neither.**
- **EVERY INJECTION PROVES IT APPLIED BEFORE ITS RESULT IS READ, AND THE APPLIER MUST REFUSE** -- `assert count(old) == 1` raises; a `grep -c` printed alongside is a reading and gates nothing. **The injection TEXT goes in the commit message.**
- **A TEST CAN ASSERT NOTHING AND LOOK FINE**, and **a FAILED test's zero looks exactly like a passing result.** The LINE COUNT catches it. **A control that refuses for its own reason turns every red into a confirmation.**
- **THE INSTRUMENT THAT GATES IS NOT THE INSTRUMENT YOU RAN. Read every exit code directly -- do not pipe a gate.** In zsh that is `${pipestatus[1]}`, lowercase and 1-indexed; `${PIPESTATUS[0]}` is EMPTY and prints nothing while looking like a pass.

### Reading the reference, and reading your own code

- **"PARITY FIX OR DELIBERATE DIVERGENCE" IS ONE COMMAND: does the reference do this too.** I framed `fit: cvoer` as a divergence with `showreel:828` on screen in the same session. **vc met the mirror twice in one afternoon** -- specifying a guard for a hazard `render()` had already made structurally absent, then a refusal for a pattern the reference **deliberately supports**. **A CONDITION IS NOT A CONSEQUENCE:** both from reading an `if` and not the `return` under it.
- **AND THE SHARPER TEST WHERE THE REFERENCE IS WRONG: does the fix change PIXELS?** `json.dumps` escapes neither `<` nor `/`, so `</script>` in a config breaks the artifact -- escaping it decodes identically and changes nothing on screen, so take it. AC-4.2's QR detector changes **which QR is embedded**, so it does not get taken silently.
- **HIGHLANDER'S USUAL CHECK CANNOT SEE A SUBSET DUPLICATE.** A sweep finds the present fields agree; **the absent ones are not there to disagree.** `main.rs` carried 2 of the pace table's 5 fields and both were CORRECT. Ask **does the second carry every FIELD of the first.**
- **BEING CALLED AND HAVING ITS RESULT READ ARE DIFFERENT PROPERTIES.** vc's sweep for `pub fn` with no production caller passed `admit::Scan::report` cleanly -- it had a caller, and the caller discarded its output on the success path. **That is machinery-nothing-calls one level down**, and it was AC-3.2's whole remaining clause.
- **zsh DOES NOT WORD-SPLIT AN UNQUOTED VARIABLE** -- run shell tooling under `/bin/bash` with an ARRAY. **QUOTE THE HEREDOC DELIMITER (`<<'EOF'`)** whenever the body carries shell syntax. **A COMMAND THAT DID NOT REBUILD REPORTS THE OLD ARTEFACT'S NUMBERS.**

## The estate

- **THE GATES ARE THE PRE-COMMIT ROSTER AND IT RUNS THEM ALL** -- `guards: 4 ran` plus `intent critic gate: 2 of 2` on every commit, so a commit that lands has passed them. What I type by hand is `cargo test --workspace` and `cargo clippy --workspace --all-targets`, from `opt/prez/crate`. **Read the exit code directly; never pipe a gate.**
- **NO PUSH TO `upstream` UNTIL hv LIFTS IT** (CI credits, 2026-09-09). upstream sits at **`60153d8`** -- **the SHA, not a count, because a count is stale one commit later.** **THE TRAP IS THE DEFAULT**: `branch.main.remote` is `upstream`, so a bare `git push` fires the matrix. **Name the remote.**
- **THE GIT INDEX HAS NO SINGLE-WRITER RULE.** A bare `git commit` takes the INDEX; the form that holds is **`git commit --only <paths>`**, and **a NEW file needs `git add -N` first**. `--only` plus a reformatting pre-commit hook leaves a **false `MM`** -- the hook's version lands while the index keeps yours; `git restore --staged` clears it.
- **AND `--only` GIVES NO PROTECTION ON A FILE WITH TWO WRITERS.** `intent/.canon/st/ST0017.json` carries vc's criteria AND my attachments, so path isolation stops being file isolation and the guard goes silent exactly where the collision is. **No flag fixes it.** Agreed convention (vc took it, declining single-writer): **read the canon DIFF before every canon commit and name every writer present in it**, and commit canon straight after each `intent` write rather than batching. **It makes a collision read rather than silent; it does not prevent one.**
- **`artifact` TAKES NO DEPENDENCIES, AND THAT IS AC02's WHOLE SIGN-OFF.** showreel-only machinery stays in showreel. **A crate added to showreel needs hv's sign-off NAMED IN THE COMMIT** (AC-3.9) -- which is why `deliver.rs`'s calendar is hand-written, and it duplicates nothing: prez's `scratch()` uses `as_nanos()` as an opaque token and forms no date.
- **Utilz declares its languages in TWO files** -- `bin/.devbin/config.yaml` and `intent/.config/config.json`.
- **AN `include_str!` NOBODY REFERENCES IS DROPPED BY THE LINKER, SO THE `strings` GATE IS SILENT ON IT.** `player.html` is 45 KB in the tree and 0 bytes in the binary until `build` wires it -- **all four strings that ARE in the shell read 0 while `showreel.yaml` reads 3.** The H3 zero over the shell is **an empty population**; what covers it is the source-level test reading `SHELL` at compile time.
- **THE THREE PATHS, because rediscovering them after a compact cost ten tool calls.** Reference `~/Library/CloudStorage/Dropbox/Projects/Snokeltoast/bin/showreel/` (`showreel`, `player.html`, `themes/`, `FLOORS.md`, `showreel-harness`); live reel `.../Snokeltoast/marketplace/artists/10-active/45h/showreel/`; pinned fixture `opt/prez/crate/crates/showreel/fixtures/45h.showreel.yaml`. **`mdfind -name` finds them and `find` under `~/Devel` does NOT** -- Dropbox lives at `~/Library/CloudStorage`, and the tree is spelled **Snokeltoast**, no `r`.
- **WP-03 IS GRADED BY `bin/showreel/FLOORS.md`. READ THE FILE, NOT A SUMMARY.** Artifact `daaa503ad7db`, 13 captures a slide, `--min-defect 0.223607` (`sqrt(0.05)`, frame-size independent). **The two things not in it:** payload-level grading works for FULL-BLEED slides only -- a contained slide drops the figure by roughly sqrt(covered fraction), so payload for the pixel loop and browser for fit; and **008 stays true and stops being APPLICABLE**, because `cmd_control` takes one positional and a new build is a different artifact needing its own control run.

## Decisions

- (2026-09-09) **vc, sequencing on hv's delegation: no early `build`, and no pulling AC-3.7 forward.**
- (2026-09-09) **hv: the Python fallback is DEAD.** _"Not on your life. We're only doing work that moves this FORWARD."_
- (2026-09-09) **hv: 0018 authorised as a NARROWING only** -- the comment exemption becomes CSS-only.
- (2026-09-09) **hv: `max_ease` capped at 2400**, closing the `?speed=` crossing STRUCTURALLY.
- (2026-09-09) **hv H-C: the command is `prez showreel build <dir>`.**
- (2026-09-09) **vc: an `exclude:` drop is NOT a dropped segment input.** An author's instruction obeyed, not an accident nobody was told about. **The ROW's text changed, not my position** -- textually an excluded file IS a dropped input, so the words had to carry the distinction or the next reader grades a correct implementation as a miss.
- (2026-09-09) **The producer stamp goes in the PORT's shell, filled by the Rust build only** -- a second deliberate divergence, on the two alternatives' costs. **NOT because absence derives Python:** `adjacency (UNVERIFIED)` is a refusal to derive, and vc withdrew that reasoning after it had reached three of my files. **And the marker is a TOKEN, never a literal** -- the artifact is `player.html` with substitutions, so a real value would be inherited verbatim by a Rust build and turn an honest refusal into a confident wrong answer.
