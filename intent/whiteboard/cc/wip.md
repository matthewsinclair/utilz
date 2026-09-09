---
node: cc
name: Control Claude
role: control
session_id: a30f9092-03ed-44ba-a659-b37813af12c7
heartbeat_at: 2026-09-09 20:01Z
status: active
focus: "ST0017/WP-03. EVERY JSON-FREE PIECE IS BUILT and 247 tests pass. `check` resolves the live 45h reel to 23 slides and 14 assets -- the same two numbers the reference's own plan() gives. BLOCKED on hv for serde_json, which gates the whole remaining payload. Taking sequencing from vc until hv returns."
claims: [ST0017]
---

# Control Claude (cc)

## DOING

**ST0017 -- hoisting snorkeltoast's `showreel` into Utilz as a Rust pipeline under `prez showreel`.** Localfolded 2026-09-09 20:01Z; the slice-by-slice narrative is in `.history/20260909/`.

- **`utilz prez showreel check <45h dir>` RESOLVES THE WHOLE CONFIG**, both invocation forms, exit 0: 15 segments, **23 slides, 14 assets**, theme off the search path, 5 fonts and a favicon inlined. **Both numbers match the reference's own `plan()` run against the same config** -- so the port is checked against something other than itself.
- **BUILT AND RED-PROVED:** theme resolution, admission (C1), normalisation (C2), the slide model, `embed` (`159f544`), the template (`cb8f2bf`), the plan (`0bb78e0`), delivery naming (`01d3469`). **247 tests.** prez **4,384,912** against the 8,388,608 budget and unchanged all day; showreel 535,952.
- **WP-01 DONE. Contract 42/51, 3 withdrawn; WP-03 9/12.**
- **BLOCKED, AND IT IS THE ONLY THING LEFT IN WP-03: `serde_json` NEEDS hv.** The manifest says a crate addition needs hv's sign-off named in the commit. Net cost measured against THIS tree: **2 packages, 79 to 81** -- `itoa`, `memchr` and `serde_core` are already here. **I nearly reported +4 by reading the crate's own tree instead of the difference.**
- **WHAT THE PAYLOAD STILL OWES:** `build_socials` (with the stale-QR warning, which is AC-4.2's text), `build_bug` (**and its admission -- vc's recorded prediction: `plan.rs` joins `bug.file` unclassified while four `Requires::Image` sites refuse**), the slide rows, the limits block, and the `build` verb that writes `_out/` and calls report + prune.
- **AC-3.6's RUNTIME LEG IS MINE AND REDUCES TO ONE PROPERTY:** the emitted payload's `limits.max_ease` **DERIVES** from `limits::MAX_EASE_MS`, never a restated literal. `player.html:561` is `const LIM = REEL.limits` -- the cap is read off the payload. Red-control: flip the constant to 3000, the payload must follow. **Cite `showreel-harness:232` and `:1098`, NOT `shipped-max-ease`**, which retires itself the day Python is capped.
- **TELL vc BEFORE ANY BUILD POINTS AT 45h** -- AC-2.1 leg 2, AC-5.1 and AC-6.1 leg 3 grade in one pass, and **the first `compare` against a Rust artifact happens exactly once.** **TELL snorkeltoast TOO:** the live config plans **23** against FLOORS.md's **22**, so their `compare` refuses. **The gap is config-vs-008 and no part of it is the port** -- the reference reaches 23 on the same config.

## TODO

- **PFIC the scan ordering when next in `admit.rs`** -- vc's, and NOT a special trip. Extract the sort as a pure function over a `Vec` so the test stops depending on the filesystem returning unsorted entries.
- **Issue 0016** -- record gate state in `manifest.sha256`. hv scheduled it as a **WP-05 rider**, not now.
- Two homeless findings, unowned: `todo` verbs unreachable from Emacs; `hoist-rebase.sh`'s dead postcondition.

## Holds

- **The payload, until hv rules on `serde_json`.** Released by that ruling either way -- a yes takes the crate, a no means hand-rolling the emitter beside `base64.rs`. Everything JSON-free is already built, so there is no adjacent work to do and inventing some would be the error.

## Open with hv

- **`serde_json` -- THE decision, in `hv/inbox.cc.md` 19:15Z.** vc escalated it and sharpened the framing: it gates **everything left in WP-03**, not a dependency count. Recommendation: take it. The alternative is a hand-rolled emitter, argued against on where the risk sits -- a calendar is closed and pinnable against outside answers, JSON escaping of arbitrary YAML text is not, and the reference's field order in a second home is a Highlander problem bought to save two packages.
- **`prez showreel build` will need `SHOWREEL_THEME_PATH` where the Python needed nothing.** 45h names `theme: popupart`, a built-in there and never one here. H3 working, not a regression -- but a workflow change to know before the first build.
- **The public-repo question is vc's, in hv's inbox.** `matthewsinclair/utilz` is public; the two pinned fixtures carry a named individual and a customer brand. **`upstream` is frozen, so nothing is published and it is decidable first.** Not mine to act on.

## What WP-03 is graded by

**`bin/showreel/FLOORS.md` in the Snorkeltoast tree. Read the file, not this summary.** Artifact `daaa503ad7db`, 13 captures a slide, `--min-defect 0.223607`.

- **21 gradeable, 0 undecided, 1 ungradeable, 0 windowless, of 22.** Sums. **19 slides have a floor of EXACTLY 0.000000.** Frame-size independent -- `rmse()` divides by `3*W*H`, so 0.223607 is `sqrt(0.05)`.
- **Slide 14's floor is a CEILING**, three renders, the third a COMBINATION of two binary anti-aliased endpoints.
- **Payload-level grading works for FULL-BLEED slides only.** A contained slide drops the on-screen figure by roughly sqrt(covered fraction). **Payload for the pixel loop, browser for fit.**
- **008 stays true and stops being APPLICABLE.** `cmd_control` takes ONE positional -- the artifact -- so a new build is a different artifact needing its own control run.
- **THE FIRST COMPARE WILL BE A GREEN OVER HALF A PIPELINE.** 45h's masters are 2560px, which is Python `init`'s output, so every run is **population (2)** until a Rust `init` exists in WP-04 -- **and nothing in the harness distinguishes (2) from (3)**. Do not read that green as covering the whole pipeline.

## Watch-outs

**FOUR FAMILIES. THE FIRST THREE ARE ABOUT CLAIMS; THE FOURTH IS ABOUT THE INSTRUMENT THAT CHECKS THEM, AND IT IS THE ONE THAT MAKES EVERYTHING ELSE SUSPECT WHEN IT FAILS.**

**(1) A CLAIM WHOSE POPULATION IS NOT STATED.** Four faces, and seeing them as four cost a day: one green generalised across an unenumerated population; one member taken to characterise a set; a number recorded without naming what it counted; two measurements agreeing because they share the population error.

**(2) KNOWING A RULE IS NOT BEING PROTECTED BY IT.** I named "the injection proved applied before its result was read" as the TELL of a reading, corrected two files for carrying it, **and wrote it into the next commit message three hours later.** A compliance census at 17:18Z would have read clean and been wrong within the hour. **The guard belongs in the code, not in the discipline of whoever is typing.** Its sibling: a red-proof can refute its own author's comment, and one did -- C2's reordering injection moved **not one test** against three paragraphs of mine. **Length is not evidence.**

**(3) WHAT DOES 45h FAIL TO CONTAIN?** The most productive question I have, and vc's generalisation is better than my instances: **45h is the only real config we have and it is a WELL-FORMED one, so it cannot exercise a refusal path.** Five known: the bug embed (its `bug.file` IS the logo segment's file, so the total agrees for the wrong reason); AC-3.4's artifact half (no opaque RGBA on the reel at all, refuting design.md 4.2's named instance); the stale-QR warning (the QRs match their config); the collapse arm (three synthetic tests and nothing on the reel); AC-3.2's `files:` site. **A GREEN FROM 45h IS EVIDENCE ABOUT WHAT 45h CONTAINS, AND SILENCE IS WHAT A READER TAKES FOR COVERAGE.** Every one of those decisions was right on its merits; each cost estimate came from reading the code instead of the pictures. **So "test against something you did not write" needs its converse beside it** -- the live config caught a missing `#[serde(rename = "loop")]` and is worth nothing for any detector.

**(4) THE INSTRUMENT ITSELF.**

- **A RED-PROOF HARNESS THAT DOES NOT CLEAN UP ON REFUSAL IS WORSE THAN ONE THAT NEVER REFUSES.** Mine wrote the injection, then refused on a post-check whose anchor had collided with an unrelated match arm -- **with the revert on the success path only.** The tree sat with `iso()` not validating dates at all while the console read `REFUSED`, **which is exactly what "nothing happened" looks like.** The revert belongs in a `finally`. **A reassuring failure message is the worst kind**, and the blast radius is why: a harness that can leave a tree injected makes every later measurement in that session suspect -- gates, counts, binary sizes, any `strings` census -- and not one would look wrong.
- **THE COUNT OF FIRING INJECTIONS IS NOT THE CONTROL -- EACH ONE FIRING IS.** Earned twice in one slice: `G` moved nothing because Rust's `Path` compares by components and drops `CurDir` before my helper mattered; `L` moved nothing because a zero-padded fixture makes lexical and numeric order coincide. **Four of five, and five of six, both read as good results.** **A fixture whose values cannot distinguish two orderings tests neither.**
- **EVERY INJECTION PROVES IT APPLIED BEFORE ITS RESULT IS READ, AND THE APPLIER MUST REFUSE** -- `assert s.count(old) == 1` raises; a `grep -c` printed alongside is a reading and gates nothing. **The injection TEXT goes in the commit message**, where a later reader can re-apply it.
- **A TEST CAN ASSERT NOTHING AND LOOK FINE**, and **a FAILED test's zero looks exactly like a passing result.** The LINE COUNT catches it: one line for a 427-line file is not a result. **A control that refuses for its own reason turns every red into a confirmation** -- vc's fixture used a `type:` that does not exist, so all five arms exited 2 including the baseline.
- **A SUPPRESSED PROBE CANNOT TELL A NO-OP FROM A RESULT.** A probe needs its step proved applied exactly as a red-proof does.
- **THE INSTRUMENT THAT GATES IS NOT THE INSTRUMENT YOU RAN.** **Read every exit code directly -- do not pipe a gate.** In zsh that is `${pipestatus[1]}`, lowercase and 1-indexed; `${PIPESTATUS[0]}` is EMPTY and prints nothing while looking like a pass.

### Reading the reference, and reading your own code

- **"PARITY FIX OR DELIBERATE DIVERGENCE" IS ONE COMMAND: does the reference do this too.** I framed `fit: cvoer` as a divergence with `showreel:828` on screen in the same session. **And vc met the mirror twice in one afternoon** -- specifying a guard for a hazard `render()` had already made structurally absent, then a refusal for a pattern (`{nnn}` absent) the reference **deliberately supports** at `:547`. **A CONDITION IS NOT A CONSEQUENCE:** both came from reading an `if` and not the `return` under it. When specifying a refusal, name the input it would reject and check nobody ships it.
- **HIGHLANDER'S USUAL CHECK CANNOT SEE A SUBSET DUPLICATE.** A sweep finds the present fields agree; **the absent ones are not there to disagree.** `main.rs` carried 2 of the pace table's 5 fields and both were CORRECT. Ask **does the second carry every FIELD of the first.**
- **CITE THE TOKEN, NOT THE LINE**, and **correct the TITLE, not only the body** -- a superseded source is indistinguishable from a live one. **And prefer a durable fact to a contingent conclusion**: vc's `shipped-max-ease` citation would have expired on a good day, from a fix landing.
- **zsh DOES NOT WORD-SPLIT AN UNQUOTED VARIABLE** -- run shell tooling under `/bin/bash` with an ARRAY. **QUOTE THE HEREDOC DELIMITER (`<<'EOF'`)** whenever the body carries shell syntax. **A COMMAND THAT DID NOT REBUILD REPORTS THE OLD ARTEFACT'S NUMBERS.**

## The gates this estate runs, enumerated

| gate               | command                                                                     |
| ------------------ | --------------------------------------------------------------------------- |
| unit + integration | `cargo test --release --workspace --no-fail-fast --manifest-path <m>`       |
| lint               | `cargo clippy --all-targets --workspace --manifest-path <m> -- -D warnings` |
| build              | `cargo build --release --workspace --manifest-path <m>`                     |
| acceptance         | `bash opt/prez/crate/test/acceptance.sh` -- 14 ATs                          |
| shell              | `shellcheck -x "${FILES[@]}"` -- **18 files, correct even after a build**   |
| estate             | `utilz test <utility>` -- prez has 4 suites, 28 assertions                  |
| devbin             | `bin/devbin check autotests` -- `3 crate(s), none with a tests/ directory`  |

## The estate

- **NO PUSH TO `upstream` UNTIL hv LIFTS IT** (CI credits, 2026-09-09). upstream sits at `60153d8`, **183 behind**. **THE TRAP IS THE DEFAULT** -- `branch.main.remote` is `upstream`, so a bare `git push` fires the matrix. Name the remote.
- **THE GIT INDEX HAS NO SINGLE-WRITER RULE, AND "STAGE EXPLICIT PATHSPECS" DOES NOT HOLD.** A bare `git commit` takes the INDEX. The form that holds is **`git commit --only <paths>`** -- and **a NEW file needs `git add -N` first**, or `--only` refuses the pathspec. vc's companion finding: `--only` plus a reformatting pre-commit hook leaves a **false `MM`**, because the hook's version is what lands while the main index keeps yours. `git restore --staged` clears it.
- **`artifact` TAKES NO DEPENDENCIES, AND THAT IS AC02's WHOLE SIGN-OFF.** showreel-only machinery stays in showreel; prez has not moved a byte all day. **A crate added to showreel needs hv's sign-off NAMED IN THE COMMIT** (AC-3.9), which is why the calendar in `deliver.rs` is hand-written -- and it duplicates nothing: prez's `scratch()` uses `as_nanos()` as an opaque token and forms no date.
- **AC-3.10's population is normal+build edges, union 71 on name+version**, prez 17. **The lock is 79 by name AND by name+version** -- no crate at two versions -- so both dedup keys agree today.
- **TN001 exposure is ZERO and measured.** showreel is lib+bin, 2 unittest targets, the bin holding none.
- **Utilz declares its languages in TWO files** -- `bin/.devbin/config.yaml` and `intent/.config/config.json`.
- **AN `include_str!` NOBODY REFERENCES IS DROPPED BY THE LINKER, SO THE `strings` GATE IS SILENT ON IT.** `player.html` is 45 KB in the tree and 0 bytes in the binary until `build` wires it: `REEL.producer` and `__TITLE__` both read 0 while a string from live code reads 1. **The H3 zero over the shell is currently an empty population**, and what covers the shell is the source-level test.
- **THE THREE PATHS, because rediscovering them after a compact cost ten tool calls.** Reference `~/Library/CloudStorage/Dropbox/Projects/Snokeltoast/bin/showreel/` (`showreel`, `player.html`, `themes/{default,popupart}`, `FLOORS.md`, `showreel-harness`); live reel `.../Snokeltoast/marketplace/artists/10-active/45h/showreel/`; pinned fixture `opt/prez/crate/crates/showreel/fixtures/45h.showreel.yaml`. **`mdfind -name` finds them and `find` under `~/Devel` does NOT** -- Dropbox lives at `~/Library/CloudStorage`, and the tree is spelled **Snokeltoast**, no `r`.

## Decisions

- (2026-09-09) **vc: `{nnn}` is AT MOST ONE, not exactly one.** Two or more refuses because the port's prefix/suffix `Stem` structurally cannot express it and the reference's replace-all can; zero is a fixed filename the reference **supports** at `:547`. The hazard is the port's own, which is what makes refusing it right.
- (2026-09-09) **vc: the template's marker control is a PROPERTY, not a refusal.** `render()` reads offsets from the unmodified shell, so a value carrying a marker is emitted verbatim; a test that fails against the sequential form buys what a refusal would, and refuses nothing valid.
- (2026-09-09) **vc, sequencing on hv's delegation: no early `build`, and no pulling AC-3.7 forward.** An artifact knowingly incomplete feeds the harness differences that are not in `PORT_EXPECTATIONS`.
- (2026-09-09) **vc: AC-3.3 closes on the BUILD path, not in WP-04** -- the row is about the TYPE, not the generation.
- (2026-09-09) **vc: AC-3.4 will NOT close on C2** -- `normalise_image` is init-only and init is WP-04, so half the row's population is outside this work package.
- (2026-09-09) **hv: the Python fallback is DEAD.** _"Not on your life. We're only doing work that moves this FORWARD."_
- (2026-09-09) **hv: 0018 authorised as a NARROWING only** -- the comment exemption becomes CSS-only.
- (2026-09-09) **hv: `max_ease` capped at 2400**, closing the `?speed=` crossing STRUCTURALLY.
- (2026-09-09) **hv H-C: the command is `prez showreel build <dir>`.**
- (2026-09-09) **Port the consistent normalisation policy, not the Python's alpha asymmetry** -- and its named instance does not occur on 45h, measured.
