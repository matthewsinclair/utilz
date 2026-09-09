---
node: cc
name: Control Claude
role: control
session_id: a30f9092-03ed-44ba-a659-b37813af12c7
heartbeat_at: 2026-09-09 14:50Z
status: active
focus: "ST0017. 0018 CLOSED and WP-05's dispatch LANDED -- `utilz prez showreel check <45h dir>` works end to end, both forms, exit 0. Next is the build path: 637 lines of reference across 22 functions, and hv has closed the Python fallback so it is the only route. Contract 32/51."
claims: [ST0017]
---

# Control Claude (cc)

## DOING

**ST0017 -- hoisting snorkeltoast's `showreel` into Utilz as a Rust pipeline under `prez showreel`.**

- **WP-01 done.** One theme resolver + base64 + `Failure` in `crates/artifact/`, linked by prez. `crate/Cargo.toml` is **both the workspace root and prez's package** -- `src/`, `themes/`, `assets/` must stay exact siblings, and `[profile.*]` is honoured only at a workspace root.
- **WP-03 in flight, and the refusal half is RUNNABLE.** `showreel check <dir>` validates a real reel and fires seven refusal classes. `crates/showreel/` carries the approved budget exactly; **prez is untouched at 4,384,896 bytes and 13 third-party packages.**
- **ISSUE 0018 CLOSED** (`538e7fe`): the comment exemption is CSS-only, `Grammar::Css | Grammar::Verbatim`. vc verified at the artifact, 4 arms, 4 of 4. **AC-3.13 and AC-3.5 both SATISFIED.**
- **WP-05'S DISPATCH LANDED** (`b8dc9f1`): `prez showreel <...>` execs the sibling, everything else execs prez's. **`utilz prez showreel check <45h dir>` exit 0, both invocation forms.** AC-5.2 satisfied in the same commit; **AC-5.1 is NOT -- it names `build`.**
- **NEXT: the build path.** 637 lines of Python across 22 functions, `collect_segment` alone 147. Theme resolution, C1 admission, C2 normalisation, data-URI, template, delivery re-encode. **hv killed the Python fallback -- "Python is a backwards step" -- so this is the only route to the bar.**
- **PICKUP MEASURED A FOURTH INSTANCE OF AC-1.16'S CLASS, AND IT IS THE SILENT ONE.** `prez_is_stale`'s `find` walks `src`, `themes`, `assets`, the manifest and the lockfile and **NOT `crates/`** -- so a change to the shared crate prez LINKS leaves the shim reporting fresh and exec'ing the old binary at exit 0. **Measured with a proved control**: `theme.rs` was 30s OLDER than the binary, the touch made it newer, and the shim's own `find` verbatim still returned empty. **The other three fail loudly-ish -- a lint escapes, a binary is missing. This one hands you a stale binary and says nothing**, so 0018's fix would not reach anyone running `prez`. **It is the instrument that would misreport the very change I am about to make**, which is why it goes in 0018's commit and not after it. Issue not yet filed.

## TODO

- **Issue 0016 -- record gate state in `manifest.sha256`.** Ratified, unimplemented.
- **Issue 0007** (prez counter contrast) and the two homeless findings (`todo` verbs unreachable from Emacs; `hoist-rebase.sh`'s dead postcondition) are unchanged and unowned.
- **Optional, ungated: drop `|| "Snorkeltoast"` at template pull.** Parity-neutral; taking it reads 22 of 22 gradeable, leaving it reads 21. **AC-3.7 is WITHDRAWN -- build no check, gate nothing.**

## Holds

**None.**

## What WP-03 is graded by

**`bin/showreel/FLOORS.md` in the Snorkeltoast tree. Read the file, not this summary.** Artifact `daaa503ad7db`, 13 captures a slide, `--min-defect 0.223607`.

- **21 gradeable, 0 undecided, 1 ungradeable, 0 windowless, of 22.** Sums. **19 slides have a floor of EXACTLY 0.000000**, so any movement at all on those is a real difference.
- **The threshold is frame-size independent** -- `rmse()` divides by `3*W*H`, so `f*W*H` pixels at one level over three channels give `sqrt(f)`. Verified identical at 640x360, 1920x1080 and 3840x2160. **0.223607 is sqrt(0.05).**
- **Slide 14's floor is a CEILING.** Three renders, the third a COMBINATION of two binary anti-aliased endpoints, not a new mode. **A 4th render is NOT a regression -- it must land at 0.001553 or 0.002196; any other distance is real.**
- **Payload-level grading works for FULL-BLEED slides only.** A contained slide puts unchanged background in frame, dropping the on-screen figure below the payload figure by roughly sqrt(covered fraction). **Payload for the pixel loop, browser for fit and layout.**
- **My Rust red-proof will NOT match theirs, by construction.** Theirs injects a darkening AND a q86 re-encode (0.030-0.825, 2.241 on the one PNG); mine without the re-encode lands near 1.000000. **Instrument difference, not compiler difference.**
- **Two caveats, mine to carry, and the second was WRONG.** The reconstruction half stands and it reaches `compare` and `redproof`, because `partition()` takes the reel dir and derives the exemption list from `plan()`. **The table is NOT superseded by my next build.** `cmd_control` takes ONE positional -- the ARTIFACT -- plus `--workdir` and `--repeats`, and reads no reel, no config and no `plan()`: verified in the subparser and in the function body, by me, after snorkeltoast raised it and vc verified it. A new build is a DIFFERENT artifact with its own sha needing its own control run. **008 stays true and stops being APPLICABLE, which is not the same as stopping being a result** -- and the wrong version would have had me discard a valid measurement. **Do not rebuild the reel without telling snorkeltoast first.**

## What the build path must carry

**637 lines of Python across 22 functions.** `collect_segment` 147, `cmd_build` 76, `session_stamp` 44, theme resolution 105 (`resolve_theme` + `load_theme` + `favicon_link` + `font_face`), the rest 265. The 45h reel is 6 jpg / 5 svg / 3 png and **contains no PDF**, so `rasterise_pdf` is off this reel's critical path. QR GENERATION is WP-04 -- build needs `load_qr` (12 lines), not `qr_svg` (33).

- **FONTS NEED NO CONVERTER, AND THAT DELETED A DEPENDENCY I WOULD HAVE HAD TO ESCALATE.** snorkeltoast pre-converted the five TTFs to WOFF2 and committed them beside the theme (`95317bc`); `theme.yaml`'s `fonts:` entries point at the `.woff2` and the `.ttf` stay only as provenance. **The port reads the named file, base64s it, emits the `@font-face`. A theme shipping a `.ttf` is REFUSED BY NAME with the conversion command in the remedy** -- never converted, never silently embedded. My budget has no woff2 or brotli crate and hv signed it off item by item.
- **DO NOT REPRODUCE `font_face`'s SHAPE.** It wrapped the conversion in `except Exception:` and on failure embedded the RAW TTF -- different format, roughly double the bytes, and still said "wrote". **The defect is not the exception handling; it is emitting something DIFFERENT and reporting success.** `IN-AG-NO-SILENT-001`. snorkeltoast removed it by deletion rather than repair.
- **BYTE PARITY WITH THE PYTHON OUTPUT WAS NEVER AVAILABLE, and it costs this port nothing -- checked, not assumed.** The old TTF-to-WOFF2 conversion was non-deterministic across processes (one font gave six different sizes in an afternoon; `PYTHONHASHSEED` does not fix it). **No WP-03 or WP-05 row assumes byte-identity** -- the seven byte/sha mentions are the comrak manifest line, prez's binary size, package counts, and AC-2.18's sha-as-a-name. The harness compares CAPTURES, which is why the approach survives.
- **TELL snorkeltoast BEFORE POINTING A BUILD AT 45h.** The live config plans **23** slides against 008's **22**, so their `compare` refuses and they re-derive the floors against whatever I build. Currently moot in a useful way: there is no build path to do it by accident.

## Watch-outs

**ONE GREEN, GENERALISED ACROSS A POPULATION NOBODY ENUMERATED, remains the dominant failure -- and it has a twin: ONE MEMBER, TAKEN TO CHARACTERISE A SET.** Same shape, opposite direction. snorkeltoast produced three instances in a day: a claim about 22 slides measured on slide 3, a spread anchored on capture rep-0, and a threshold anchored on one injection into one image. **The fix is never a better member; it is removing the member from the claim.**

**AND THE SECOND TEST, WHICH I KEPT FAILING: "IS IT REAL" IS NOT "IS IT WORTH BUILDING".** hv cut four items in one afternoon as yak-shaving -- AC-3.7's grep, issue 0020's citation sweep, the brand-free definition, the publication currency check. **Every one was a true finding.** vc and snorkeltoast each named it against themselves; I filed 0017 and pushed for the citation check, so it is mine too.

**AND THE THIRD, WHICH COST ME A WHOLE ISSUE: EXACT AGREEMENT IS A STRONGER TRAP THAN NEAR-AGREEMENT.** I filed 0021 claiming the help renderer prints `**` literally -- 47 lines in `prez --help`, 42 in utilz, 11 in syncz. vc reproduced **all three numbers exactly** and we both read that as confirmation. **It confirmed a shared instrument error: we had both piped stdout, and `glow` picks its `notty` style when stdout is not a terminal, and that style has no bold.** Forced to `-s dark` the same file gives 0 literal `**` and 55 ANSI-bold lines. **A user at a terminal was never affected and `show_help` was never implicated.**

**One-apart makes you look; byte-equal makes you stop.** vc's one-off union this morning is what sent them hunting and found the blank line in their own `cargo tree` filter. My 47 matching their 47 ended the inquiry. **Ask what two measurements SHARE before treating either as confirming the other** -- three instances today: the blank line, a commit timestamp read as a source mtime, and this. **And correct the TITLE, not just the body**: vc's close carried the right cause and the title still asserted the wrong one, which is what a list view shows.

- **A FAILED TEST'S ZERO LOOKS EXACTLY LIKE A PASSING RESULT.** vc tried to settle 0021 with a pty; `script -q /dev/null` died on `tcgetattr`, wrote 59 bytes of error, and `grep -c` scored that as **zero** literal asterisks. **What caught it was the LINE COUNT -- one line of output for a 427-line help file is not a result.** When the environment cannot host the test, change the instrument rather than trusting its zero.

- **A RED-PROOF NEEDS ITS OWN CONTROL: AN INJECTION THAT DID NOT APPLY AND ONE THAT PASSED PRODUCE THE SAME OUTPUT.** Every injection must prove it applied -- `grep -c` the thing removed, to zero -- before its result may be read. Done on every red-proof since.
- **A RED-PROOF ALSO MEASURES WHICH TESTS ARE PROOFS.** Of 7 `limits` tests only 2 can fail on the defect; of 11 `config` tests only 2; of 5 `segment` tests only 3. **The rest are parity controls and bounds, and the modules say so** -- seven green under one heading reads as seven proofs.
- **THE INSTRUMENT THAT GATES IS NOT THE INSTRUMENT YOU RAN.** CI's clippy had no `--workspace`, so a member crate's TEST code was never linted; it caught my own new code within the hour of being widened.
- **A GATE CHAIN JOINED BY `&&` DOES NOT GATE IF EACH GATE IS PIPED.** `cargo clippy ... | tail -1 && git commit` takes its status from `tail` and is always 0. I committed over a failed clippy with `build failed` in the output I had just read. **Read `${pipestatus[1]}`, or do not pipe a gate.**
- **A NUMBER READ OFF THE WRONG STAGE OF A PIPELINE IS A REAL MEASUREMENT AND A FALSE CLAIM.** I minted AC-1.13 saying the shellcheck collector "sees 69 files against 18 real ones, picking up compiled binaries". Re-measured against a 1.2 GB `target/`: `find` EMITS 143, 125 of them binaries, and the `file` type check rejects every one -- `FILES[]` ends at **18** and the gate is correct after a build. **69 was stage one; the claim was about stage three.** Ask which stage produced the number before writing it down.
- **AN INSTRUMENT THAT SHARES AN ASSUMPTION WITH ITS SUBJECT CANNOT TEST THAT ASSUMPTION.** My probe read the artifact with a line-oriented, case-sensitive `grep` while measuring a line-oriented, case-sensitive defect, and reported two escapes as clean. **Key the detector on the PAYLOAD, not the syntax.**
- **A CITATION THAT NAMES A LOCATION GOES STALE SILENTLY, AND RECORDING THE DEAD NUMBER RE-CREATES THE HAZARD.** vc's sweep: eight citations, four stale, **every stale one in the file a commit had touched**. I then shipped one in the module implementing the row about that line. **Cite the TOKEN. Name no numeral even when explaining one was wrong.**
- **A SUPERSEDED SOURCE IS INDISTINGUISHABLE FROM A LIVE ONE TO WHOEVER HOLDS IT.** snorkeltoast asked me to restructure WP-03 against a ruling design.md had already made hours earlier; they were reasoning from their own document and nothing told them.
- **TEST AGAINST SOMETHING YOU DID NOT WRITE.** The live 45h config caught a missing `#[serde(rename = "loop")]` that all five of my refusal cases missed -- they exercise keys I chose, it exercises keys the reel chose.
- **zsh DOES NOT WORD-SPLIT AN UNQUOTED VARIABLE**; run shell tooling under `/bin/bash` with an ARRAY. **A `grep` PATTERN BEGINNING `--` IS PARSED AS AN OPTION.** **A COMMAND THAT DID NOT REBUILD REPORTS THE OLD ARTEFACT'S NUMBERS.**

## The gates this estate runs, enumerated

| gate               | command                                                                             |
| ------------------ | ----------------------------------------------------------------------------------- |
| unit + integration | `cargo test --release --workspace --no-fail-fast --manifest-path <m>`               |
| lint               | `cargo clippy --all-targets --workspace --manifest-path <m> -- -D warnings`         |
| build              | `cargo build --release --workspace --manifest-path <m>`                             |
| shell              | `shellcheck -x "${FILES[@]}"` -- **18 files, and 18 is correct even after a build** |
| estate             | `utilz test <utility>` -- prez has 4 suites; `acceptance.sh` caught WP-01           |
| devbin             | `bin/devbin check autotests` -- `3 crate(s), none with a tests/ directory`          |

**Read every exit code directly. Do not pipe a gate.**

## The estate

- **THE SHIM IS BLIND TO `crates/` IN TWO PLACES.** `prez:155`'s `cargo build` has no `--workspace` (vc's AC-1.16, live), and `prez_is_stale`'s `find` watches no member crate. **Two mechanisms, one blindness, and the estate has FOUR instances now** -- CI clippy, CI build, shim build, shim freshness. The first three were found by reading; the fourth by touching a file and asking the shim.
- **NO PUSH TO `upstream` UNTIL hv LIFTS IT** (CI credits, 2026-09-09). `local` is fine and is current at `e8ce0b1`; HEAD carries vc's `a7faf17` on top, which is theirs to mirror. **THE TRAP IS THE DEFAULT**: `branch.main.remote` is `upstream`, so a bare `git push` fires the matrix. Name the remote. Nothing auto-pushes -- hooks verified.
- **THE GIT INDEX HAS NO SINGLE-WRITER RULE.** `git add -A` swept vc's in-flight canon into my commit. **Stage explicit pathspecs.** hv ruled a pre-commit WARNING not a refusal; issue 0019, not started.
- **`utilz` on PATH is the INSTALL.** Run `utilz use` rather than trusting any line about it. `utilz test` refuses from an install -- issue 0016's root.
- **TN001 exposure is ZERO and measured**: no Rust `tests/` directory anywhere. showreel is a **lib + bin**, which is 2 unittest targets with the bin holding none -- the honest cost of removing a permanent `allow(dead_code)`.
- **Utilz declares its languages in TWO files** -- `bin/.devbin/config.yaml` and `intent/.config/config.json`. Change one, change both.

## Decisions

- (2026-09-09) **hv: `max_ease` capped at 2400**, closing the `?speed=` crossing STRUCTURALLY rather than by refusal. Swept 1,927,206 combinations: zero crossings at 2400.
- (2026-09-09) **hv: AC-3.7 WITHDRAWN, the brand grep dropped, the brand-free definition dropped, the publication currency check dropped, the reel's inputs stay in Dropbox.** Utilz itself being fully tracked is what the hoist depends on.
- (2026-09-09) **hv H-C: the command is `prez showreel build <dir>`.** HOIST section 1's sibling superseded.
- (2026-09-09) **`artifact` is the ONE addition AC02 is signed off for**, as a one-off. A second first-party dependency asks the question again.
- (2026-09-09) **Port the consistent normalisation policy, not the Python's alpha asymmetry.** A reference implementation is a reference, not a specification.
- (2026-09-08) **`--help` renders the CURATED `help/<name>.md`**, not the terse inline usage.
