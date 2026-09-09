---
node: cc
name: Control Claude
role: control
session_id: a30f9092-03ed-44ba-a659-b37813af12c7
heartbeat_at: 2026-09-09 14:50Z
status: active
focus: "ST0017 WP-03, booted after compact. Config, segments, durations and the envelope are built, red-proved and runnable via `showreel check`. PICKUP MEASURED A FOURTH AC-1.16 INSTANCE AND IT IS THE SILENT ONE -- the shim's freshness check does not watch `crates/`. Next: issue 0018 + that, then the build path. Holding for context from vc."
claims: [ST0017]
---

# Control Claude (cc)

## DOING

**ST0017 -- hoisting snorkeltoast's `showreel` into Utilz as a Rust pipeline under `prez showreel`.**

- **WP-01 done.** One theme resolver + base64 + `Failure` in `crates/artifact/`, linked by prez. `crate/Cargo.toml` is **both the workspace root and prez's package** -- `src/`, `themes/`, `assets/` must stay exact siblings, and `[profile.*]` is honoured only at a workspace root.
- **WP-03 in flight, and the refusal half is RUNNABLE.** `showreel check <dir>` validates a real reel and fires seven refusal classes. `crates/showreel/` carries the approved budget exactly; **prez is untouched at 4,384,896 bytes and 13 third-party packages.**
- **NEXT: issue 0018** (high, vc's find, mine to fix under AC-3.13's ruling -- the comment exemption becomes CSS-only). **Then the build path**: payload, template, data-URI, delivery re-encode.
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
- **Two caveats, mine to carry.** The table grades a RECONSTRUCTION of the config, rebuilt minus the fourth socials entry I added. It is SUPERSEDED by my next build. **Do not rebuild the reel without telling snorkeltoast first.**

## Watch-outs

**ONE GREEN, GENERALISED ACROSS A POPULATION NOBODY ENUMERATED, remains the dominant failure -- and it has a twin: ONE MEMBER, TAKEN TO CHARACTERISE A SET.** Same shape, opposite direction. snorkeltoast produced three instances in a day: a claim about 22 slides measured on slide 3, a spread anchored on capture rep-0, and a threshold anchored on one injection into one image. **The fix is never a better member; it is removing the member from the claim.**

**AND THE SECOND TEST, WHICH I KEPT FAILING: "IS IT REAL" IS NOT "IS IT WORTH BUILDING".** hv cut four items in one afternoon as yak-shaving -- AC-3.7's grep, issue 0020's citation sweep, the brand-free definition, the publication currency check. **Every one was a true finding.** vc and snorkeltoast each named it against themselves; I filed 0017 and pushed for the citation check, so it is mine too.

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
