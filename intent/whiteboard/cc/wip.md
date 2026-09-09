---
node: cc
name: Control Claude
role: control
session_id: a30f9092-03ed-44ba-a659-b37813af12c7
heartbeat_at: 2026-09-09 18:22Z
status: active
focus: "ST0017/WP-03. The build path's decision-making is DONE: theme, admission (C1), normalisation (C2), and the slide model. `check` resolves the live 45h reel to 23 slides and 10 assets, exit 0. NEXT is data-URI, then the template pull, then delivery. hv is afk and has delegated sequencing to vc."
claims: [ST0017]
---

# Control Claude (cc)

## DOING

**ST0017 -- hoisting snorkeltoast's `showreel` into Utilz as a Rust pipeline under `prez showreel`.** Localfolded 2026-09-09 18:22Z; earlier boards in `.history/`.

- **`utilz prez showreel check <45h dir>` RESOLVES THE WHOLE CONFIG**, both invocation forms, exit 0: 15 segments, **23 slides, 10 assets**, theme off the search path, 5 fonts and a favicon inlined. Everything a build decides, without embedding anything.
- **WP-01 is DONE.** WP-03 has C1, C2, the slide model, theme resolution and asset inlining landed and red-proved. **215 tests.** prez 4,384,912 against the 8,388,608 budget; showreel 519,232.
- **NEXT, in order: data-URI, the template pull, delivery re-encode.** The template pull carries **AC-3.7's `|| "Snorkeltoast"` drop in the SAME commit** -- vc ruled against pulling it forward, because the gradeability gain is unreachable until there is an artifact to grade.
- **TELL vc BEFORE ANY BUILD POINTS AT 45h.** They will have AC-2.1 leg 2, AC-5.1 and AC-6.1 leg 3 ready to grade in one pass, and **the first `compare` against a Rust artifact happens exactly once.**
- **TELL snorkeltoast TOO.** The live config plans **23** slides against FLOORS.md's **22**, so their `compare` refuses and they re-derive. That gap is between the live config and artifact 008 -- **not** between the port and the Python; my `collect` reaches 23 independently.

## TODO

- **PFIC the scan ordering when next in `admit.rs`** -- vc's, and NOT a special trip. Extract the sort as a pure function over a `Vec` so the test stops depending on the filesystem returning unsorted entries.
- **Issue 0016** -- record gate state in `manifest.sha256`. hv scheduled it as a **WP-05 rider**, not now.
- Two homeless findings, unowned: `todo` verbs unreachable from Emacs; `hoist-rebase.sh`'s dead postcondition.

## Holds

**None.**

## Open with hv

- **The public-repo question is vc's, in hv's inbox.** `matthewsinclair/utilz` is public; the two pinned fixtures carry a named individual and a customer brand. **`upstream` is frozen 156 behind, so nothing is published and it is decidable first.** Not mine to act on either way.
- **`prez showreel build` will need `SHOWREEL_THEME_PATH` set where the Python needed nothing.** 45h names `theme: popupart`, a built-in there and never one here. H3 working, not a regression -- but it is a workflow change hv should know about before the first build.

## What WP-03 is graded by

**`bin/showreel/FLOORS.md` in the Snorkeltoast tree. Read the file, not this summary.** Artifact `daaa503ad7db`, 13 captures a slide, `--min-defect 0.223607`.

- **21 gradeable, 0 undecided, 1 ungradeable, 0 windowless, of 22.** Sums. **19 slides have a floor of EXACTLY 0.000000.** Frame-size independent -- `rmse()` divides by `3*W*H`, so 0.223607 is `sqrt(0.05)`.
- **Slide 14's floor is a CEILING**, three renders, the third a COMBINATION of two binary anti-aliased endpoints.
- **Payload-level grading works for FULL-BLEED slides only.** A contained slide drops the on-screen figure by roughly sqrt(covered fraction). **Payload for the pixel loop, browser for fit.**
- **008 stays true and stops being APPLICABLE.** `cmd_control` takes ONE positional -- the artifact -- so a new build is a different artifact needing its own control run.
- **THE FIRST COMPARE WILL BE A GREEN OVER HALF A PIPELINE.** vc measured: 45h's masters are 2560px, which is Python `init`'s output, so every run is **population (2)** until a Rust `init` exists in WP-04 -- **and nothing in the harness distinguishes (2) from (3)**, because `population_source` derives from the artifact's producer stamp and no manifest key touches init. **Do not read that green as covering the whole pipeline.**

## Watch-outs

**EVERY DOMINANT FAILURE THIS THREAD HAS PRODUCED IS ONE FAMILY: A CLAIM WHOSE POPULATION IS NOT STATED.** Four faces, and seeing them as four cost a day: one green generalised across an unenumerated population; one member taken to characterise a set; a number recorded without naming what it counted; two measurements agreeing because they share the population error.

**AND THE SECOND FAMILY, EARNED TODAY: KNOWING A RULE IS NOT BEING PROTECTED BY IT.**

- **I wrote the exact phrase I had just diagnosed.** I named "the injection proved applied before its result was read" as the TELL of a reading, corrected two files for carrying it, **and wrote it into the next commit message three hours later.** A compliance census taken at 17:18Z would have read clean and been wrong within the hour. **The guard belongs in the code, not in the discipline of whoever is typing.**
- **A RED-PROOF CAN REFUTE ITS OWN AUTHOR'S COMMENT, AND ONE DID.** C2's reordering injection moved **not one test** against three paragraphs of mine claiming the order was load-bearing. A constant alpha channel resamples to itself. **Length is not evidence.**
- **"PARITY FIX OR DELIBERATE DIVERGENCE" IS ONE COMMAND, AND THE PORT CANNOT ANSWER IT.** A check that was missing and is now present looks IDENTICAL either way; only the reference distinguishes them. I framed `fit: cvoer` alongside the mistyped-`type:` defect -- but the reference already validates at `showreel:828`. **I had that line on screen in the same session before writing the sentence.** Ask _does the reference do this too_ before claiming a gap.
- **A CONTROL THAT REFUSES FOR ITS OWN REASON TURNS EVERY RED INTO A CONFIRMATION.** vc's fixture used a `type:` that does not exist, so **all five arms exited 2 including the baseline.** The exact mirror of the empty population -- in both, treatment and control return the same answer. **My tests are refusal-shaped, so the second GREEN carries as much as the first.**
- **HIGHLANDER'S USUAL CHECK CANNOT SEE A SUBSET DUPLICATE.** A sweep finds the present fields agree; **the absent ones are not there to disagree.** `main.rs` carried 2 of the pace table's 5 fields and both were CORRECT, which is why it survived. Ask **does the second carry every FIELD of the first.**
- **A SUPPRESSED PROBE CANNOT TELL A NO-OP FROM A RESULT.** I ran `rm`, build and check as one line with output discarded, read "present", and nearly told vc their trap did not reproduce. **A probe needs its step proved applied exactly as a red-proof does.**
- **A RED-PROOF NEEDS ITS OWN CONTROL AND ALSO MEASURES WHICH TESTS ARE PROOFS.** Every injection proves it applied before its result is read, and **the applier must REFUSE** -- `assert s.count(old) == 1` raises; a `grep -c` printed alongside is a reading and gates nothing. **The injection TEXT goes in the commit message**, where a later reader can re-apply it; a comment has nothing left to run.
- **A TEST CAN ASSERT NOTHING AND LOOK FINE**, and **a FAILED test's zero looks exactly like a passing result.** The LINE COUNT catches it: one line for a 427-line file is not a result.
- **THE INSTRUMENT THAT GATES IS NOT THE INSTRUMENT YOU RAN.** Derive the population from the manifest, or from the TREE where no manifest is read. **Read every exit code directly -- do not pipe a gate.** In zsh that is `${pipestatus[1]}`, lowercase and 1-indexed; `${PIPESTATUS[0]}` is EMPTY and prints nothing while looking like a pass.
- **CITE THE TOKEN, NOT THE LINE**, and **correct the TITLE, not only the body** -- a superseded source is indistinguishable from a live one.
- **TEST AGAINST SOMETHING YOU DID NOT WRITE.** The live 45h config caught a missing `#[serde(rename = "loop")]`; popupart's `theme.yaml` is pinned for the same reason. **And count what you checked** -- a live-data test that checks nothing passes.
- **zsh DOES NOT WORD-SPLIT AN UNQUOTED VARIABLE** -- run shell tooling under `/bin/bash` with an ARRAY. **QUOTE THE HEREDOC DELIMITER (`<<'EOF'`)** whenever the body carries shell syntax, and re-read what landed. **A COMMAND THAT DID NOT REBUILD REPORTS THE OLD ARTEFACT'S NUMBERS.**

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

- **NO PUSH TO `upstream` UNTIL hv LIFTS IT** (CI credits, 2026-09-09). upstream sits at `60153d8`, **156 behind**. **THE TRAP IS THE DEFAULT** -- `branch.main.remote` is `upstream`, so a bare `git push` fires the matrix. Name the remote.
- **THE GIT INDEX HAS NO SINGLE-WRITER RULE, AND "STAGE EXPLICIT PATHSPECS" DOES NOT HOLD.** vc staged explicit pathspecs and a bare `git commit` took two of my files anyway, because **it commits the INDEX**. The form that holds is **`git commit --only <paths>`**. The window is what matters and staging early opens it.
- **`artifact` TAKES NO DEPENDENCIES, AND THAT IS AC02's WHOLE SIGN-OFF.** showreel-only machinery stays in showreel. Two showreel-driven additions so far: `refuse_external_target` (+16 bytes to prez) and `Theme.dir` (**0 bytes**). **Zero is a fact about that field, not a licence.**
- **AC-3.10's population is normal+build edges, union 71 on name+version**, prez 17. vc's 71 and my 69 differ only by dedup key: two names occur at two versions. Six of six of my figures reproduce under name-dedup.
- **TN001 exposure is ZERO and measured.** showreel is lib+bin, 2 unittest targets, the bin holding none.
- **Utilz declares its languages in TWO files** -- `bin/.devbin/config.yaml` and `intent/.config/config.json`.

## Decisions

- (2026-09-09) **vc, sequencing on hv's delegation: no early `build`, and no pulling AC-3.7 forward.** An artifact that is knowingly incomplete feeds the harness differences that are not in `PORT_EXPECTATIONS`, turning a detector into noise at the moment its value is highest.
- (2026-09-09) **vc: AC-3.3 closes on the BUILD path, not in WP-04** -- the row is about the TYPE, not the generation.
- (2026-09-09) **vc: AC-3.4 will NOT close on C2** -- `normalise_image` is init-only and init is WP-04, so half the row's population is outside this work package. Not split, because one policy governing both is the whole property.
- (2026-09-09) **hv: the Python fallback is DEAD.** _"Not on your life. We're only doing work that moves this FORWARD."_
- (2026-09-09) **hv: 0018 authorised as a NARROWING only** -- the comment exemption becomes CSS-only.
- (2026-09-09) **hv: `max_ease` capped at 2400**, closing the `?speed=` crossing STRUCTURALLY.
- (2026-09-09) **hv H-C: the command is `prez showreel build <dir>`.**
- (2026-09-09) **Port the consistent normalisation policy, not the Python's alpha asymmetry.**
