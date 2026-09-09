---
node: cc
name: Control Claude
role: control
session_id: a30f9092-03ed-44ba-a659-b37813af12c7
heartbeat_at: 2026-09-09 12:16Z
status: active
focus: "ST0017 hoist. WP-01 done. WP-03 started: AC-3.5's CSS half built, issues 0014, 0015 and 0017 closed by one fix, red-proved both ways. LIMITS unblocked by snorkeltoast's parity answer and still unported."
claims: [ST0017]
---

# Control Claude (cc)

## DOING

**ST0017 -- hoisting snorkeltoast's `showreel` into Utilz as a Rust pipeline. Claimed today; this board carried `claims: []` while WP-01 was built, which was wrong and is corrected here.**

- **WP-01 is DONE and its evidence is with vc.** One theme resolver + base64 + `Failure` in `opt/prez/crate/crates/artifact/`, linked by prez. `crate/Cargo.toml` is **both the workspace root and prez's package** -- `src/`, `themes/`, `assets/` must stay exact siblings (7 `include_str!` at compile time, plus the shim's freshness walk) and `[profile.*]` is honoured only at a workspace root.
- **WP-03 STARTED (`intent wp start`, `ee1ba88`/`cd0412d`). AC-3.5's CSS half is built; its `theme.yaml` half is R3 and waits on showreel's manifest existing, so the row is NOT satisfied.** `refuse_external` now reads the two sites R2 names as TOKENS rather than hunting spellings, unioned with the coarse absolute-scheme net so nothing that refused before builds now. **Issues 0014, 0015 and 0017 closed by the one fix.** Budget approved: 59 packages, union, `image` at `jpeg,png,webp,gif,tiff`, `fast_image_resize` REFUSED.
- **`LIMITS` is UNBLOCKED.** snorkeltoast measured the 45h config: max ease 900ms against min dwell 5000ms, nothing with ease >= dwell, so the new refusal will not diverge from the Python build on that reel.

## TODO

- **`LIMITS` port -- RULED, unimplemented.** Apply `max_ease` at compile time and refuse a config whose ease meets or exceeds its dwell, by name. **The defect is split enforcement, not the constants**: `showreel:799-800` applies `min_dwell`/`min_ease` and never `max_ease`; the cap lives only in `player.html:549` while `showreel:988` claims the runtime enforces _the same_ floors.
- **Issue 0016 -- record gate state in `manifest.sha256`.** Ratified, filed, unimplemented.
- **WP-03 parity evidence CHANGED SHAPE under me, and it is better.** snorkeltoast's control was anchored on capture rep-0: slide 14 renders 12:1 bimodal, rep-0 was drawn from the minority, so every comparison ran against the minority, all read one value and the spread collapsed to zero. **A slide exactly as bimodal as before read as perfectly reproducible, about one run in thirteen.** Fixed by hashing captures into distinct renders and taking the worst distance BETWEEN renders, anchored on nothing -- and **the count of distinct renders per slide is now reported**, so a Rust build rendering a slide once where Python renders it twice is a difference the harness SHOWS rather than averages away. Take the new floor table before grading anything.
- **Issue 0007 (prez counter contrast) and the two homeless findings** (`todo` verbs unreachable from Emacs; `hoist-rebase.sh`'s dead postcondition) are unchanged and unowned.

## Holds

**None.**

## Watch-outs

**ONE GREEN, GENERALISED ACROSS A POPULATION NOBODY ENUMERATED. This is the dominant failure of the day -- roughly ten instances across three nodes -- and every other item here is a special case of it.** The tell, in snorkeltoast's wording, is worth keeping: _the sentence is about a set while the evidence is about a member._ Mine: a control red-proved by an injection that could not reach the code; two comments asserting more than the arms I had driven; and calling WP-01 green having run two of the six gates CI runs. vc's: telling hv the same thing off clippy-plus-build. snorkeltoast's: "all 22 byte-identical" measured on slide 3.

- **A RED-PROOF NEEDS ITS OWN CONTROL, BECAUSE AN INJECTION THAT DID NOT APPLY AND ONE THAT PASSED PRODUCE THE SAME OUTPUT.** My patch anchor had its `\n` eaten by the shell, matched nothing, and the suite underneath printed `ok ... 12 passed`. Only an `assert count == 1` I had added out of habit separated that from a real proof. **Every injection must prove it applied, and refuse rather than warn, before its result may be read.**
- **THE INSTRUMENT THAT GATES IS NOT THE INSTRUMENT YOU RAN.** Enumerate every gate before calling anything green. This estate runs six (below); I ran three and shipped a red clippy.
- **A GATE THAT RUNS AND FINDS NOTHING HAS A VOICE; A GATE THAT NEVER ACTIVATES DOES NOT, AND THE SUMMARY COUNTS ONLY WHAT SPOKE.** `devbin check all` printed `all check options passed` with `autotests` absent entirely -- not run, not skipped, not named. Two behaviours in one run: `check format` announced its own narrowing correctly two lines above.
- **UPDATING AN EXPECTED VALUE TO MATCH A RULED CHANGE IS IMPLEMENTATION; CHANGING AN ASSERTION'S SHAPE IS A DECISION.** vc's line, and it is the test for whether an edit to a failing test is repair or weakening. AT02 amended under it, red-proved in both arms.
- **A TEST NAME THAT OUTRUNS ITS BODY.** Twice in one file: a name claiming reorder-sensitivity the body could not reach, and one claiming a hole was guarded when it only checked the text before it. **Name the test after what it measures, not what you hope it measures.**
- **zsh DOES NOT WORD-SPLIT AN UNQUOTED VARIABLE.** Bit twice today -- multi-word `cargo add` flags arriving as one argument, and the shellcheck file list. Run shell tooling under `/bin/bash` with an ARRAY.
- **A `grep` PATTERN BEGINNING `--` IS PARSED AS AN OPTION.** My token-uniqueness sweep errored on every call, printed nothing, and reported every token unique. Use `grep -- "$pat"`, and **put a control in the sweep that shows the broken and fixed forms disagree.**
- **AN INSTRUMENT THAT SHARES AN ASSUMPTION WITH ITS SUBJECT CANNOT TEST THAT ASSUMPTION.** My probe read the artifact with a line-oriented, case-sensitive `grep` while measuring a line-oriented, case-sensitive defect, and reported two escapes as clean. **Nothing errored.** Recovered only by keying the detector on the PAYLOAD -- the host fragment -- rather than on the reference's syntax. Reach for the payload first; it is the cheap move that breaks the shared assumption.
- **A CITATION THAT NAMES A LOCATION GOES STALE SILENTLY AND READS EXACTLY LIKE A LIVE ONE.** `player.html:613` is cited by AC-3.7, AC-2.14, their two renderings, vc's board and snorkeltoast's FLOORS.md twice. The literal is at **628**; 613 is now unrelated code. `3903937` moved it -- the crawl fix **I relayed hv's ratification for** -- so the citation decayed as a consequence of a change I carried, and three nodes propagated it because each copied it from the last rather than opening the file. **Cite the TOKEN, not the line**: `REEL.producer || "Snorkeltoast"` greps forever. Our AC-id discipline already refuses an AT row whose id is not in the file it cites; line numbers inside AC TEXT sit under no such check.
- **A COMMAND THAT DID NOT REBUILD REPORTS THE OLD ARTEFACT'S NUMBERS.** `Finished in 0.02s` meant I measured the previous day's binary and called it unchanged.

## The gates this estate runs, enumerated

**Written down because AC-1.12 exists precisely because I did not have this list.** From `.github/workflows/tests.yml`: `test-linux`, `test-macos`, `shellcheck`, `rust`, `clippy`, `test-summary`.

| gate               | command                                                                                                                                                                                         |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| unit + integration | `cargo test --release --workspace --no-fail-fast --manifest-path <m>`                                                                                                                           |
| lint               | `cargo clippy --all-targets --workspace --manifest-path <m> -- -D warnings` -- **`--workspace` added 2026-09-09; without it a MEMBER crate's test code is never linted, proved with both arms** |
| build              | `cargo build --release --manifest-path <m>`                                                                                                                                                     |
| shell              | `shellcheck -x "${FILES[@]}"` -- **18 real files; run locally after a build the collector sees 69, because it has no `target/` exclusion and is correct only by CI job ordering**               |
| estate             | `utilz test <utility>` -- prez has 4 suites; `acceptance.sh` is the one that caught WP-01                                                                                                       |
| devbin             | `bin/devbin check autotests` -- now `3 crate(s), none with a tests/ directory`                                                                                                                  |

## What WP-03 is graded by

**`bin/showreel/FLOORS.md` in the Snorkeltoast tree, build 008, sha256 `daaa503ad7db`, 13 captures a slide.** Read the file, not this summary -- it is generated from `control.json` and never retyped.

- **Criterion:** every gradeable slide at RMSE 0.000000 against **its own floor**, slides 13 and 14 accepted by name, and **the render count matching**. A Rust build rendering a slide once where Python renders it twice is now a visible difference rather than something averaged away.
- **19 gradeable, 2 undecided (13 and 14, both 2-render), 1 presence-unprovable (slide 1), 0 windowless, of 22.** Partition sums.
- **`min_defect` is None, and that is a REFUSAL not an omission.** The red-proof's own injection reads 0.998249 to 2.280042 across eight image slides -- 2.3x for an identical procedure, decided by what the picture is -- so no constant taken from one injection can stand for the set. Naming a magnitude is AC-2.17 and hv's.
- **MOST SLIDES CAN BE GRADED WITH NO BROWSER, AND THE SHORTCUT HAS A STATED DOMAIN.** Slide 6's payload figure 0.999768 against the browser's 0.999752 -- but that agreement holds for a **FULL-BLEED** image, where the frame is essentially the payload scaled to fill. **A letterboxed or contained slide puts unchanged background in the frame, so the on-screen figure falls below the payload figure by roughly the square root of the covered fraction.** Slide 0 is the one to watch: 1024x1024 into 16:9, and its payload figure of 2.280042 is the reel's highest precisely because none of that dilution is in it. **So: payload level for the pixel pipeline's tight loop, browser for the fit and layout classes** -- which is where the difference lives anyway. snorkeltoast's bound, given before I generalised one agreeing pair across every slide, which is the day's dominant failure and would have been mine.
- **Two caveats, both mine to carry.** The table is against a RECONSTRUCTION of 008's config -- snorkeltoast rebuilt it minus the fourth socials entry **I added**, because the live config plans 23 slides against the artifact's 22 and the partition refuses. And it is SUPERSEDED, not merely dated, by the next build. **Do not rebuild the reel without saying so first.**

## The estate

- **NO PUSH TO `upstream` UNTIL hv LIFTS IT.** hv, 2026-09-09: CI/CD credits are exhausted. `local` (a Dropbox path, no CI) is permitted. **THE TRAP IS THE DEFAULT**: `branch.main.remote` is `upstream`, so a bare `git push` on main goes to GitHub and fires the full matrix -- `.github/workflows/tests.yml` triggers on push to main. The cheap remote is the one you have to name. Nothing auto-pushes: neither `pre-commit` nor `pre-commit.intent` contains a push, verified rather than assumed.

- **`utilz` on PATH is the INSTALL** (`opt 16 links, dev 0`). vc republished it at `b6ca749`; 0 of 15 READMEs now carry an absolute home path. **Run `utilz use` rather than trusting this line -- it has been wrong in both directions in two days.**
- **`utilz test` refuses from an install, and every bats suite pins `UTILZ_HOME` from `test_helper.bash`** -- so no suite here can measure a published install. That is issue 0016's root.
- **TN001 exposure is ZERO and measured**: no Rust `tests/` directory anywhere, one unittest target per crate. `autotests` stays at its default deliberately -- setting it false with nothing declared trades a loud waste we do not have for a quiet hole we would create, and devbin's gate skips a crate with no `tests/` before it reaches that branch.
- **Utilz declares its languages in TWO files.** devbin's gates activate off `bin/.devbin/config.yaml`; `check critic` reads `intent/.config/config.json`. Hand-kept until devbin#0062 removes one. **Change one, change both.**
- **AC ids are `AC-<wp>.<seq>`, both parts digits, the group digit being the WORK PACKAGE.** An AT row is refused unless its id appears literally in the file it cites -- which is a better account of the 101 flat ids' cost than the missing rename verb, since a rename is two-sided by construction.

## Decisions

- (2026-09-09) **`artifact` is the ONE addition AC02 has been signed off for, by hv, as a one-off.** AC02's wording was NOT broadened; a second first-party dependency asks the question again from the start.
- (2026-09-09) **showreel is a sibling binary under a `prez showreel` shim, not a merged crate.** AC02's dependency ruling is the reason that does not expire -- it gets worse as the port succeeds.
- (2026-09-09) **Port the consistent normalisation policy, not the Python's alpha asymmetry.** A reference implementation is a reference, not a specification.
- (2026-09-08) **`--help` renders the CURATED `help/<name>.md` from both forms**, not the terse inline usage.
- (2026-07-29) `-v` stays **unbound** on the dispatcher (issue 0003).
- (2026-07-09) todo guard's Intent-project test is anchored on the **target file's directory**, not cwd.
